# encoding: utf-8

require 'spec_helper'

def create_instance
  klass = Class.new do
    include CarrierWave::Uploader::Processing
    include CarrierWave::Vips
  end

  instance = klass.new
  FileUtils.cp(file_path('landscape.jpg'), file_path('landscape_copy.jpg'))
  instance.stub(:current_path).and_return(file_path('landscape_copy.jpg'))
  instance.stub(:enable_processing).and_return(true)
  instance.stub(:cached?).and_return true
  instance
end

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::Vips

  version :big_thumb do
    process resize_to_fill: [800,800]
  end

  version :thumb do
    process resize_to_fill: [280, 280]
  end

  def store_dir
    "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

end

class Dummy
  include DataMapper::Resource
  property :id, Serial
  mount_uploader :image, ImageUploader
end

Dummy.auto_migrate!


describe CarrierWave::Vips do

  before do
    @instance = create_instance
  end

  after do
    FileUtils.rm(file_path('landscape_copy.jpg'))
  end

  describe "#convert" do
    it "converts from one format to another" do
      @instance.convert('png')
      @instance.process!
    end

    it "throws an error on gif" do
      lambda { @instance.convert('gif') }.should raise_error(ArgumentError)
    end
  end

  describe '#resize_to_fill' do
    it "resizes the image to exactly the given dimensions" do
      @instance.resize_to_fill(200, 200)
      @instance.process!
      @instance.should have_dimensions(200, 200)
    end

    it "scales up the image if it smaller than the given dimensions" do
      @instance.resize_to_fill(1000, 1000)
      @instance.process!
      @instance.should have_dimensions(1000, 1000)
    end
  end

  describe '#resize_to_fit' do
    it "resizes the image to fit within the given dimensions" do
      @instance.resize_to_fit(200, 200)
      @instance.process!
      @instance.should have_dimensions(200, 150)
    end

    it "scales up the image if it smaller than the given dimensions" do
      @instance.resize_to_fit(1000, 1000)
      @instance.process!
      @instance.should have_dimensions(1000, 750)
    end
  end

  describe '#resize_to_limit' do
    it "resizes the image to fit within the given dimensions" do
      @instance.resize_to_limit(200, 200)
      @instance.process!
      @instance.should have_dimensions(200, 150)
    end

    it "does not scale up the image if it is smaller than the given dimensions" do
      @instance.resize_to_limit(1000, 1000)
      @instance.process!
      @instance.should have_dimensions(640, 480)
    end
  end

  describe '#strip' do
    it "strips all exif and icc data from the image" do
      @instance.strip
      @instance.process!
      VIPS::Image.new(@instance.current_path).exif.should_not include 'ACD Systems Digital Imaging'
    end

    it "strips out exif and icc data from images that are being converted" do
      @instance.convert('jpeg')
      @instance.strip
      @instance.process!
      VIPS::Image.new(@instance.current_path).exif.should_not include 'ACD Systems Digital Imaging'
    end
  end

  describe '#process!', slow: true do
    it "does not run out of file descriptors on long batch runs" do
      2000.times {
        instance = create_instance
        instance.convert('png')
        instance.process!
      }
    end

    it "does not run out of file descriptors when used in conjunction with DataMapper", slow: true do
      1100.times {
        dummy = Dummy.new
        dummy.image = File.open(file_path('landscape.jpg'))
        dummy.save
      }
      Dummy.all.each { |dummy|
        dummy.image.recreate_versions!
      }
    end
  end

end
