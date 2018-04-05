# encoding: utf-8

require 'image_processing/vips'
require 'fileutils'

module CarrierWave
  module Vips

    def self.configure
      @config ||= Struct.new(:sharpen_mask, :sharpen_scale).new
      yield @config if block_given?
      @config
    end

    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def resize_to_limit(width, height)
        process :resize_to_limit => [width, height]
      end

      def resize_to_fit(width, height)
        process :resize_to_fit => [width, height]
      end

      def resize_to_fill(width, height)
        process :resize_to_fill => [width, height]
      end

      def quality(percent)
        process :quality => percent
      end

      def convert(extension)
        process :convert => extension
      end

      def strip
        process :strip
      end

      def auto_orient
        process :auto_orient
      end
    end

    ##
    # Read the camera EXIF data to determine orientation and adjust accordingly
    #
    def auto_orient
      chain! { |builder| builder.autorot }
    end

    ##
    # Change quality of the image (if supported by file format)
    #
    #
    # === Parameters
    # [percent (Integer)] quality from 0 to 100
    #
    def quality(percent)
      chain! { |builder| builder.saver(Q: percent) }
    end

    ##
    # Remove all exif and icc data when writing to a file. This method does
    # not actually remove any metadata but rather marks it to be removed when
    # writing the file.
    #
    def strip
      chain! { |builder| builder.saver(strip: true) }
    end

    ##
    # Convert the file to a different format
    #
    #
    # === Parameters
    # [format (String)] the format for the file format (jpeg, png)
    # [opts (Hash)] options to be passed to converting function (ie, :interlace => true for png)
    #
    def convert(format, opts = {})
      format = format.to_s.downcase
      format = 'jpg' if format == 'jpeg'

      chain! { |builder| builder.convert(format).saver(opts) }
    end

    ##
    # Resize the image to fit within the specified dimensions while retaining
    # the original aspect ratio. The image may be shorter or narrower than
    # specified in the smaller dimension but will not be larger than the
    # specified values.
    #
    #
    # === Parameters
    #
    # [width (Integer)] the width to scale the image to
    # [height (Integer)] the height to scale the image to
    # [opts (Hash)] options to be passed to thumbnail function
    #
    def resize_to_fit(width, height, opts = {})
      thumbnail!(:resize_to_fit, width, height, opts)
    end

    ##
    # Resize the image to fit within the specified dimensions while retaining
    # the aspect ratio of the original image. If necessary, crop the image in
    # the larger dimension.
    #
    #
    # === Parameters
    #
    # [width (Integer)] the width to scale the image to
    # [height (Integer)] the height to scale the image to
    # [opts (Hash)] options to be passed to thumbnail function
    #
    def resize_to_fill(width, height, opts = {})
      thumbnail!(:resize_to_fill, width, height, opts)
    end

    ##
    # Resize the image to fit within the specified dimensions while retaining
    # the original aspect ratio. Will only resize the image if it is larger than the
    # specified dimensions. The resulting image may be shorter or narrower than specified
    # in the smaller dimension but will not be larger than the specified values.
    #
    # === Parameters
    #
    # [width (Integer)] the width to scale the image to
    # [height (Integer)] the height to scale the image to
    # [opts (Hash)] options to be passed to thumbnail function
    #
    def resize_to_limit(width, height, opts = {})
      thumbnail!(:resize_to_limit, width, height, opts)
    end

    ##
    # Resize the image to fit within the specified dimensions while retaining
    # the original aspect ratio, padding the image to keep the input dimensions.
    # The resulting image is centered, the default background color is black (see options).
    #
    #
    # === Parameters
    #
    # [width (Integer)] the width to scale the image to
    # [height (Integer)] the height to scale the image to
    # [opts (Hash)] options to be passed to extending and thumbnail function (ie, :background => [200, 0, 100])
    #
    def resize_and_pad(width, height, opts = {})
      thumbnail!(:resize_and_pad, width, height, opts)
    end

    ##
    # Manipulate the image with Vips. Saving of the image is delayed until after
    # all the process blocks have been called. Make sure you always return an
    # Vips::Image object from the block
    #
    # === Gotcha
    #
    # This method assumes that the object responds to +current_path+ and +file+.
    # Any class that this module is mixed into must have a +current_path+ and a +file+ method.
    # CarrierWave::Uploader does, so you won't need to worry about this in
    # most cases.
    #
    # === Yields
    #
    # [Vips::Image] for further manipulation
    #
    # === Raises
    #
    # [CarrierWave::ProcessingError] if manipulation failed.
    #

    def chain!
      @_vips_builder ||= get_vips_builder
      @_vips_builder = yield @_vips_builder
    end

    def process!(*)
      ret = super
      return ret unless @_vips_builder

      result = @_vips_builder.call # execute processing
      self.format_override = @_vips_builder.options[:format]

      result.close
      FileUtils.mv(result.path, current_path)

      @_vips_builder = nil

      ret
    rescue => e
      raise CarrierWave::ProcessingError.new("Failed to process file, maybe it is not a supported image? Original Error: #{e}")
    end

    def filename
      return unless original_filename
      format_override ? original_filename.sub(/\.[[:alnum:]]+$/, ".#{format_override}") : original_filename
    end

  private

    attr_accessor :format_override

    def get_vips_builder
      cache_stored_file! unless cached?

      ImageProcessing::Vips.source(current_path).loader(autorot: false)
    end

    def thumbnail!(resizer, *args)
      opts = opts.merge(sharpen: cwv_sharpen_mask) if cwv_config.sharpen_mask
      opts = opts.merge(sharpen: false) if cwv_config.sharpen_mask == false

      chain! { |builder| builder.send(resizer, *args) }
    end

    def cwv_config
      CarrierWave::Vips.configure
    end

    def cwv_sharpen_mask(mask = cwv_config.sharpen_mask, scale = cwv_config.sharpen_scale)
      ::Vips::Image.new_from_array(mask, scale) if mask
    end

  end # Vips
end # CarrierWave
