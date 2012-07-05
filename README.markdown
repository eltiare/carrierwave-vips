CarrierWave-VIPS
======================

This adds support to CarrierWave for the ultrafast and resource efficient VIPS library. It passes all of the rspec tests
with the exception of one, which is due to a change in the API of the ruby-vips gem. The confidence level of this CWV is currently at 90%.
That being said, please verify the output of this processor thoroughly before deploying to production.

A quick overview:
---------------------

See the instructions for CarrierWave to use this processor. You will need to include the Vips module in the upload
class:


    class AvatarUploader < CarrierWave::Uploader::Base
      include CarrierWave::Vips
    end

You can use the following methods to resize your images. All methods keep aspect ratio:

* resize_to_fill(x,y) Will increase/decrease the size of the image and match the specified dimensions exactly, chopping off any extraneous bits.
* resize_to_fit(x,y) Will increase/decrease the size of the image to fit within the specified dimensions. One dimension may be less than specified.
* resize_to_limit(x,y) Just like resize_to_fit except will not increase size of image.
* format("jpeg|png|gif") Changes the format of the image
* quality(0-100) Sets the quality of the image being saved if JPEG