# encoding: utf-8

require 'spec_helper'
require 'carrierwave-vips'

def create_instance(file = 'landscape.jpg')
  klass = Class.new(CarrierWave::Uploader::Base) {
    include CarrierWave::Vips
  }
  file_copy = file.split('.').insert(-2, 'copy').join('.')
  instance = klass.new
  FileUtils.cp(file_path(file), file_path(file_copy))
  allow(instance).to receive(:file).and_return(CarrierWave::SanitizedFile.new(file_path(file_copy)))
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

class Dummy < ActiveRecord::Base
  mount_uploader :image, ImageUploader
end


describe CarrierWave::Vips do
  
  let(:instance) { create_instance }
  
  after do
    Dir[file_path('*.copy.jpg')].each do |file|
      FileUtils.rm(file)
    end
  end

  # Gotta figure out how to test this properly.
  it 'performs multiple operations properly'

  describe "#convert" do

    it 'converts from one format to another' do
      instance.convert('png')
      instance.process!
      expect(instance.filename).to match(/png$/)
    end

    it 'throws an error on gif' do
      expect { instance.convert('gif') }.to raise_error(ArgumentError)
    end

    context 'when allowed formats are configured' do
      around do |example|
        original_formats = CarrierWave::Vips.configure.allowed_formats
        example.run
      ensure
        CarrierWave::Vips.configure { |c| c.allowed_formats = original_formats }
      end

      context 'when a file format is allowed' do
        before { CarrierWave::Vips.configure { |c| c.allowed_formats = %w(webp) } }

        it 'does not raise an error' do
          expect { instance.convert('webp') }.not_to raise_error
        end
      end

      context 'when a file format is not allowed' do
        before { CarrierWave::Vips.configure { |c| c.allowed_formats = %w(jpg) } }

        it 'blows up' do
          expect { instance.convert('png') }.to raise_error(ArgumentError)
        end
      end
    end

  end

  describe '#resize_to_fill' do
    
    it 'resizes the image to exactly the given dimensions' do
      instance.resize_to_fill(200,200)
      instance.process!
      expect(instance).to have_dimensions(200, 200)
    end

    it 'scales up the image if it smaller than the given dimensions' do
      instance.resize_to_fill(1000,1000)
      instance.process!
      expect(instance).to have_dimensions(1000, 1000)
    end

    it 'does not throw error on exact dimensions' do
      instance.resize_to_fill(640,480)
      instance.process!
      expect(instance).to have_dimensions(640,480)
    end

    it 'recovers on floating point errors leading to overcrops' do
      instance = create_instance('wonky-resize.jpg')
      instance.resize_to_fill(200,200)
      instance.process!
    end

  end

  describe '#resize_to_fit' do
    
    it 'resizes the image to fit within the given dimensions' do
      instance.resize_to_fit(200, 200)
      instance.process!
      expect(instance).to have_dimensions(200, 150)
    end

    it 'scales up the image if it smaller than the given dimensions' do
      instance.resize_to_fit(1000, 1000)
      instance.process!
      expect(instance).to have_dimensions(1000, 750)
    end
    
  end

  describe '#resize_to_limit' do
    
    it 'resizes the image to fit within the given dimensions' do
      instance.resize_to_limit(200, 200)
      instance.process!
      expect(instance).to have_dimensions(200, 150)
    end

    it 'does not scale up the image if it is smaller than the given dimensions' do
      instance.resize_to_limit(1000, 1000)
      instance.process!
      expect(instance).to have_dimensions(640, 480)
    end

  end

  describe '#strip' do

    it 'strips all exif and icc data from the image' do
      instance.strip
      instance.process!
      image = Vips::Image.new_from_buffer(File.open(instance.current_path, 'rb').read, '')
      expect { image.get_value('exif-ifd0-Software') }.to raise_error(Vips::Error)
    end

    it 'strips out exif and icc data from images that are being converted' do
      instance.convert('jpeg')
      instance.strip
      instance.process!
      image = Vips::Image.new_from_buffer(File.open(instance.current_path, 'rb').read, '')
      expect { image.get_value('exif-ifd0-Software') }.to raise_error(Vips::Error)
    end

  end

  describe '#auto_orient' do

    it 'runs when EXIF tag is not present' do
      instance.auto_orient
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

  describe '#process!' do

    it 'does not run out of file descriptors on long batch runs', slow: true do
      2000.times {
        instance = create_instance
        instance.convert('png')
        instance.process!
      }
    end

    it 'does not run out of file descriptors when used in conjunction with ActiveRecord', slow: true do
      Dummy.connection.execute 'CREATE TABLE IF NOT EXISTS dummies ( id INT, image VARCHAR(255) );'
      2000.times {
        dummy = Dummy.new
        dummy.image = File.open(file_path('landscape.jpg'))
        dummy.save
      }
      Dummy.all.each_with_index { |dummy|
        dummy.image.recreate_versions!
      }
    end

  end

end
