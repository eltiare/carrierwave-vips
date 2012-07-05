module CarrierWave
  module Vips
    
    SHARPEN_MASK = begin
      conv_mask = [
        [ -1, -1, -1 ],
        [ -1, 16, -1 ],
        [ -1, -1, -1 ]
      ]
      ::VIPS::Mask.new conv_mask, 8
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
    end

    ##
    # Change quality of the image (if supported by file format)
    #
    #
    # === Parameters
    # [percent (Integer)] quality from 0 to 100
    #
    def quality(percent)
      manipulate! do |image|
        image.quality = percent if image.respond_to?(:quality=)
        image
      end
    end
    
    ##
    # Convert the file to a different format
    #
    #
    # === Parameters
    # [f (String)] the format for the file format (jpeg, png, gif)
    # [opts (Hash)] options to be passed to converting function (ie, :interlace => true for png)
    #
    def convert(f, opts = {})
      f = f.to_s.downcase
      allowed = %w(jpeg png gif)
      raise ArgumentError, "Format must be one of: #{allowed.join(',')}" unless allowed.include?(f)
      @_format = f
      @_format_opts = opts
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
        
        if image.x_size > new_width
          top = 0
          left = (image.x_size - new_width) / 2
        elsif image.y_size > new_height
          left = 0
          top = (image.y_size - new_height) / 2
        end
        
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
        image = resize_image(image,new_width,new_height) if new_width < image.x_size || new_height < image.y_size
        image
      end
    end

    ##
    # Manipulate the image with Vips. Saving of the image is delayed until after
    # all the process blocks have been called. Make sure you always return an
    # VIPS::Image object from the block
    #
    # === Gotcha
    #
    # This method assumes that the object responds to +current_path+.
    # Any class that this module is mixed into must have a +current_path+ method.
    # CarrierWave::Uploader does, so you won't need to worry about this in
    # most cases.
    #
    # === Yields
    #
    # [VIPS::Image] for further manipulation
    #
    # === Raises
    #
    # [CarrierWave::ProcessingError] if manipulation failed.
    #

    def manipulate!
      cache_stored_file! if !cached?
      @_vimage ||= VIPS::Image.new(current_path)
      @_vimage = yield @_vimage
    rescue => e
      raise CarrierWave::ProcessingError.new("Failed to manipulate file, maybe it is not an image? Original Error: #{e}")
    end
    
    def process!(*)
      ret = super
      if @_vimage
        tmp_name = current_path.sub(/(\.[a-z]+)$/i, '_tmp\1')
        if @_format
          @vimage.send(format, tmp_name, @_format_opts)
        else
          @_vimage.write(tmp_name)
        end
        FileUtils.mv(tmp_name, current_path)
        @_vimage = nil
        @_format = nil
      end
      ret
    end
    
  private
    
    def resize_image(image, width, height, min_or_max = :min)
      
      ratio = get_ratio image, width, height, min_or_max
      
      if ratio > 1
        image = image.affinei_resize :nearest, ratio
      elsif ratio < 1
        if ratio <= 0.5
          image = image.shrink((1/ratio).floor)
          ratio = get_ratio image, width, height, min_or_max
        end
        image = image.affinei_resize :bilinear, ratio unless ratio == 1
        image = image.conv SHARPEN_MASK
      end
      
      image
    
    end
    
    def get_ratio(image, width,height, min_or_max = :min)
      width_ratio = width.to_f / image.x_size
      height_ratio = height.to_f / image.y_size
      [width_ratio, height_ratio].send(min_or_max)
    end
    

  end # Vips
end # CarrierWave
