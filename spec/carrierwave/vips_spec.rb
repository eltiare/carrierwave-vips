# encoding: utf-8

require 'spec_helper'

def create_instance(file = 'landscape.jpg')
  klass = Class.new do
    include CarrierWave::Uploader::Processing
    include CarrierWave::Vips
  end

  file_copy = file.split('.').insert(-2, 'copy').join('.')

  instance = klass.new
  FileUtils.cp(file_path(file), file_path(file_copy))
  instance.stub(:current_path).and_return(file_path(file_copy))
  instance.stub(:enable_processing).and_return(true)
  instance.stub(:cached?).and_return true
  instance
end

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::Vips

  version :big_thumb do
    process :resize_to_fill => [800,800]
  end

  version :thumb do
    process :resize_to_fill => [280, 280]
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
    Dir[file_path('*.copy.jpg')].each do |file|
      FileUtils.rm(file)
    end
  end

  # Gotta figure out how to test this properly.
  it "performs multiple operations properly"

  describe "#convert" do
    it "converts from one format to another" do
      @instance.convert('png')
      @instance.process!
    end

    it "throws an error on gif" do
      expect { @instance.convert('gif') }.to raise_error(ArgumentError)
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

    it "does not throw error on exact dimensions" do
      @instance.resize_to_fill(640,480)
      @instance.process!
      @instance.should have_dimensions(640,480)
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
      expect {
        Vips::Image.new(@instance.current_path).get_value("exif-ifd0-Software")
      }.to raise_error Vips::Error
    end

    it "strips out exif and icc data from images that are being converted" do
      @instance.convert('jpeg')
      @instance.strip
      @instance.process!
      expect {
        Vips::Image.new(@instance.current_path).exif.should_not include 'ACD Systems Digital Imaging'
      }.to raise_error Vips::Error
    end
  end

  describe '#auto_orient' do

    it 'runs when EXIF tag is not present' do
      @instance.auto_orient
    end

    it 'orients properly with related tags' do
      instance = create_instance('landscape-with-orientation.jpg')
      instance.auto_orient
      instance.process!
      instance = create_instance('portrait-with-orientation.jpg')
      instance.auto_orient
      instance.process!
    end
  end

  describe '#process!', :slow => true do
    it "does not run out of file descriptors on long batch runs" do
      2000.times {
        instance = create_instance
        instance.convert('png')
        instance.process!
      }
    end

    it "does not run out of file descriptors when used in conjunction with DataMapper" do
      2000.times {
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
