# encoding: utf-8

require 'spec_helper'

describe CarrierWave::Vips do

  before do
    @klass = Class.new do
      include CarrierWave::Uploader::Processing
      include CarrierWave::Vips
    end

    @instance = @klass.new
    FileUtils.cp(file_path('landscape.jpg'), file_path('landscape_copy.jpg'))
    @instance.stub(:current_path).and_return(file_path('landscape_copy.jpg'))
    @instance.stub(:enable_processing).and_return(true)
    @instance.stub(:cached?).and_return true
  end

  after do
    FileUtils.rm(file_path('landscape_copy.jpg'))
  end

  describe "#convert" do
    it "should convert from one format to another" do
      @instance.convert('png')
      @instance.process!
      img.send(:format).should =~ /PNG/
    end
  end

  describe '#resize_to_fill' do
    it "should resize the image to exactly the given dimensions" do
      @instance.resize_to_fill(200, 200)
      @instance.process!
      @instance.should have_dimensions(200, 200)
    end

    it "should scale up the image if it smaller than the given dimensions" do
      @instance.resize_to_fill(1000, 1000)
      @instance.process!
      @instance.should have_dimensions(1000, 1000)
    end
  end

  describe '#resize_to_fit' do
    it "should resize the image to fit within the given dimensions" do
      @instance.resize_to_fit(200, 200)
      @instance.process!
      @instance.should have_dimensions(200, 150)
    end

    it "should scale up the image if it smaller than the given dimensions" do
      @instance.resize_to_fit(1000, 1000)
      @instance.process!
      @instance.should have_dimensions(1000, 750)
    end
  end

  describe '#resize_to_limit' do
    it "should resize the image to fit within the given dimensions" do
      @instance.resize_to_limit(200, 200)
      @instance.process!
      @instance.should have_dimensions(200, 150)
    end

    it "should not scale up the image if it is smaller than the given dimensions" do
      @instance.resize_to_limit(1000, 1000)
      @instance.process!
      @instance.should have_dimensions(640, 480)
    end
  end

end
