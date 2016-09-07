Gem::Specification.new do |s|
  s.name        = 'carrierwave-vips'
  s.version     = '1.1.0'
  s.date        = '2016-09-06'
  s.summary     = "Adds VIPS support to CarrierWave"
  s.description = "Adds VIPS support to CarrierWave"
  s.authors     = ["Jeremy Nicoll"]
  s.email       = 'eltiare@github.com'
  s.files       = ["lib/carrierwave-vips.rb", "lib/carrierwave/vips.rb"]
  s.homepage   = 'https://github.com/eltiare/carrierwave-vips'

  s.add_runtime_dependency 'ruby-vips', '~> 1.0.2'
  s.add_runtime_dependency 'carrierwave'
  s.add_development_dependency 'rmagick'

end
