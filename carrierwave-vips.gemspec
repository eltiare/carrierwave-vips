Gem::Specification.new do |s|
  s.name        = 'carrierwave-vips'
  s.version     = '1.2.0'
  s.date        = '2018-05-03'
  s.summary     = "Adds VIPS support to CarrierWave"
  s.description = "Adds VIPS support to CarrierWave"
  s.authors     = ["Jeremy Nicoll"]
  s.email       = 'eltiare@github.com'
  s.files       = ["lib/carrierwave-vips.rb", "lib/carrierwave/vips.rb"]
  s.homepage   = 'https://github.com/eltiare/carrierwave-vips'

  s.add_runtime_dependency 'ruby-vips', '~> 2.0', '>= 2.0.2'
  s.add_runtime_dependency 'carrierwave', '>= 0.11.0'
  s.add_development_dependency 'rmagick'

end
