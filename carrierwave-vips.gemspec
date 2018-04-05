Gem::Specification.new do |s|
  s.name        = 'carrierwave-vips'
  s.version     = '1.1.3'
  s.date        = '2016-10-26'
  s.summary     = "Adds VIPS support to CarrierWave"
  s.description = "Adds VIPS support to CarrierWave"
  s.authors     = ["Jeremy Nicoll"]
  s.email       = 'eltiare@github.com'
  s.files       = ["lib/carrierwave-vips.rb", "lib/carrierwave/vips.rb"]
  s.homepage   = 'https://github.com/eltiare/carrierwave-vips'

  s.add_runtime_dependency 'carrierwave', '>= 0.11.0'
  s.add_runtime_dependency 'image_processing', '~> 1.0'

end
