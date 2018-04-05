CarrierWave-VIPS
======================

[![Build Status](https://secure.travis-ci.org/eltiare/carrierwave-vips.png?branch=master)](http://travis-ci.org/eltiare/carrierwave-vips)

Debian does not have a library for VIPS 8 yet. As soon as I can work out how to get it in a Travis build the tests should pass. In the meantime you can clone this repo yourself and run `rspec` in the base directory.

This adds support to CarrierWave for the ultrafast and resource efficient
VIPS library.


Installation
---------------------

    gem install carrierwave-vips

If you need support for VIPS 7 please install a 1.0.x version of this gem. You will also need ruby-vips for VIPS 8.  For instructions on how to install that see the repo: https://github.com/jcupitt/ruby-vips

If you are using bundler, add this to your Gemfile:

    gem 'carrierwave-vips'
    
Writing GIFs is not supported by ruby-vips or this library.


A quick overview
---------------------

See the instructions for CarrierWave to use this processor. You will need
to include the Vips module in the upload class:

    class AvatarUploader < CarrierWave::Uploader::Base
      include CarrierWave::Vips
    end

You can use the following methods to change your images.

* `resize_to_fill(x,y)` Will increase/decrease the size of the image and match the specified dimensions exactly, chopping off any extraneous bits.
* `resize_to_fit(x,y)` Will increase/decrease the size of the image to fit within the specified dimensions. One dimension may be less than specified.
* `resize_to_limit(x,y)` Just like resize_to_fit except will not increase size of image.
* `convert("jpeg|png")` Changes the format of the image
* `quality(0-100)` Sets the quality of the image being saved if JPEG
* `strip` Removes any exif and ICC metadata contained in the image to reduce filesize.
* `auto_orient` Rotates the image according to the Orientation EXIF tag and then removes the tag.

To see how vips stands up to other image processing libraries, see this benchmark:  https://github.com/stanislaw/carrierwave-vips-benchmarks

Configuration
-------------

When reducing the size of images, a sharpening mask is used. To change or disable this behavior:

```
CarrierWave::Vips.configure do |c|
  c.sharpen_mask = false  # Disable sharpening mask on image reduction
  c.sharpen_mask = [      # Default mask
    [ -1, -1, -1 ], 
    [ -1, 24, -1 ], 
    [ -1, -1, -1 ] 
  ]
  c.sharpen_scale = 16     
end
```

See VIPS::Image.new_from_array for more information on what these two do. 

Special considerations
----------------------

If you use `convert` this library overrides the `filename` method used by CarrierWave to give the proper extension to the upload. If you want to override this method yourself, you can use the `format_override` method to get the file extension. 

Libraries which rely on CarrierWave-VIPS
---------------------
* The carrierwave-daltonize gem corrects images for color-blindness: https://github.com/gingerlime/carrierwave-daltonize


Contributors
---------------------
* John Cupitt (@jcupitt)
* Stanislaw Pankevich (@stanislaw)
* Mario Visic (@mariovisic)
* Thom van Kalkeren (@fletcher91)
