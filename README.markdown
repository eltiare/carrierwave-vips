CarrierWave-VIPS
======================

[![Build Status](https://secure.travis-ci.org/eltiare/carrierwave-vips.png?branch=master)](http://travis-ci.org/eltiare/carrierwave-vips)

This adds support to CarrierWave for the ultrafast and resource efficient
VIPS library. It is ready for production - but if you do encounter any
problems please be sure to report them on Github so that we can fix them.

Installation
---------------------

    gem install carrierwave-vips

You will also need ruby-vips. For instructions on how to install that see the repo: https://github.com/jcupitt/ruby-vips

If you are using bundler, add this to your Gemfile:

    gem 'carrierwave-vips'


A quick overview
---------------------

See the instructions for CarrierWave to use this processor. You will need
to include the Vips module in the upload class:

    class AvatarUploader < CarrierWave::Uploader::Base
      include CarrierWave::Vips
    end

You can use the following methods to change your images. All methods keep
aspect ratio:

* `resize_to_fill(x,y)` Will increase/decrease the size of the image and match the specified dimensions exactly, chopping off any extraneous bits.
* `resize_to_fit(x,y)` Will increase/decrease the size of the image to fit within the specified dimensions. One dimension may be less than specified.
* `resize_to_limit(x,y)` Just like resize_to_fit except will not increase size of image.
* `format("jpeg|png")` Changes the format of the image
* `quality(0-100)` Sets the quality of the image being saved if JPEG
* `strip` Removes any exif and ICC metadata contained in the image to reduce filesize.

Please note that GIF writing is not supported by libvips, and therefore cannot be supported by ruby-vips nor this library. GIF reading is still supported.

In order to use the strip method, a recent version of libvips is required. It is recommended to use at least 7.30.2. Tested on 7.30 on Debian + OS X 10.7.3/HomeBrew

Libraries which rely on CarrierWave-VIPS
---------------------
* The carrierwave-daltonize gem corrects images for color-blindness: https://github.com/gingerlime/carrierwave-daltonize

Contributors
---------------------
* John Cupitt (@jcupitt)
* Stanislaw Pankevich (@stanislaw)
* Mario Visic (@mariovisic)
