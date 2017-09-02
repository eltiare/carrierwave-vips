# encoding: utf-8

module CarrierWave
  module Vips

    def self.configure
      @config ||= begin
        c = Struct.new(:sharpen_mask, :sharpen_scale).new
        c.sharpen_mask = [ [ -1, -1, -1 ], [ -1, 24, -1 ], [ -1, -1, -1 ] ]
        c.sharpen_scale = 16
        c
      end
      @config
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
      manipulate! do |image|
        o = image.get('exif-Orientation').to_i rescue nil
        o ||= image.get('exif-ifd0-Orientation').to_i rescue 1
        case o
          when 1
            # Do nothing, everything is peachy
          when 6
            image.rot270
          when 8
            image.rot180
          when 3
            image.rot90
          else
            raise('Invalid value for Orientation: ' + o.to_s)
        end

        image.set_type GObject::GSTR_TYPE, 'exif-Orientation', ''
        image.set_type GObject::GSTR_TYPE, 'exif-ifd0-Orientation', ''
      end
    end

    ##
    # Change quality of the image (if supported by file format)
    #
    #
    # === Parameters
    # [percent (Integer)] quality from 0 to 100
    #
    def quality(percent)
      write_opts[:Q] = percent
      get_image
    end

    ##
    # Remove all exif and icc data when writing to a file. This method does
    # not actually remove any metadata but rather marks it to be removed when
    # writing the file.
    #
    def strip
      write_opts[:strip] = true
      get_image
    end

    ##
    # Convert the file to a different format
    #
    #
    # === Parameters
    # [f (String)] the format for the file format (jpeg, png)
    # [opts (Hash)] options to be passed to converting function (ie, :interlace => true for png)
    #
    def convert(f, opts = {})
      opts = opts.dup
      f = f.to_s.downcase
      allowed = %w(jpeg jpg png)
      raise ArgumentError, "Format must be one of: #{allowed.join(',')}" unless allowed.include?(f)
      self.format_override = f == 'jpeg' ? 'jpg' : f
      opts[:Q] = opts.delete(:quality) if opts.has_key?(:quality)
      write_opts.merge!(opts)
      get_image
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
    #
    def resize_to_fit(new_width, new_height)
      manipulate! do |image|
        resize_image(image,new_width,new_height)
      end
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
    #
    def resize_to_fill(new_width, new_height)
      manipulate! do |image|

        image = resize_image image, new_width, new_height, :max

        if image.width > new_width
          top = 0
          left = (image.width - new_width) / 2
        elsif image.height > new_height
          left = 0
          top = (image.height - new_height) / 2
        else
          left = 0
          top = 0
        end

        # Floating point errors can sometimes chop off an extra pixel
        # TODO: fix all the universe so that floating point errors never happen again
        new_height = image.height if image.height < new_height
        new_width = image.width if image.width < new_width

        image.extract_area(left, top, new_width, new_height)

      end
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
    #
    def resize_to_limit(new_width, new_height)
      manipulate! do |image|
        image = resize_image(image,new_width,new_height) if new_width < image.width || new_height < image.height
        image
      end
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

    def manipulate!
      @_vimage ||= get_image
      @_vimage = yield @_vimage
    rescue => e
      raise CarrierWave::ProcessingError.new("Failed to manipulate file, maybe it is not a supported image? Original Error: #{e}")
    end

    def process!(*)
      ret = super
      if @_vimage
        ext_regex = /(\.[[:alnum:]]+)$/
        ext = format_override ? "_tmp.#{format_override}" : '_tmp\1'
        tmp_name = current_path.sub(ext_regex, ext)
        opts = write_opts.dup
        opts.delete(:Q) unless write_jpeg?(tmp_name)
        @_vimage.write_to_file(tmp_name, **opts)
        FileUtils.mv(tmp_name, current_path)
        @_vimage = nil
      end
      ret
    end

    def filename
      return unless original_filename
      format_override ? original_filename.sub(/\.[[:alnum:]]+$/, ".#{format_override}") : original_filename
    end

  private

    attr_accessor :format_override

    def get_image
      cache_stored_file! unless cached?
      @_vimage ||= if jpeg? || png?
                     ::Vips::Image.new_from_file(current_path, access: :sequential)
                   else
                     ::Vips::Image.new_from_file(current_path)
                   end
    end

    def write_opts
      @_write_opts ||= {}
    end

    def resize_image(image, width, height, min_or_max = :min)
      ratio = get_ratio image, width, height, min_or_max
      return image if ratio == 1
      if ratio > 1
        image = image.resize(ratio, kernel: :nearest)
      else
        image = image.resize(ratio, kernel: :cubic)
        image = image.conv(cwv_sharpen_mask) if cwv_config.sharpen_mask
      end
      image
    end

    def get_ratio(image, width,height, min_or_max = :min)
      width_ratio = width.to_f / image.width
      height_ratio = height.to_f / image.height
      [width_ratio, height_ratio].send(min_or_max)
    end

    def jpeg?(path = current_path)
      %w(jpg jpeg).include? ext(path)
    end

    def png?(path = current_path)
      ext(path) == 'png'
    end

    def write_jpeg?(path)
      format_override == 'jpg' || jpeg?(path)
    end

    def ext(path)
      matches = /\.([[:alnum:]]+)$/.match(path)
      matches && matches[1].downcase
    end

    def cwv_config
      CarrierWave::Vips.configure
    end

    def cwv_sharpen_mask(mask = cwv_config.sharpen_mask, scale = cwv_config.sharpen_scale)
      ::Vips::Image.new_from_array(mask, scale)
    end

  end # Vips
end # CarrierWave
