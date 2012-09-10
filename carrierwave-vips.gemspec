Gem::Specification.new do |s|
  s.name        = 'carrierwave-vips'
  s.version     = '1.0.3'
  s.date        = '2012-09-10'
  s.summary     = "Adds VIPS support to CarrierWave"
  s.description = "Adds VIPS support to CarrierWave"
  s.authors     = ["Jeremy Nicoll"]
  s.email       = 'eltiare@github.com'
  s.files       = ["lib/carrierwave-vips.rb", "lib/carrierwave/vips.rb"]
  s.homepage   = 'https://github.com/eltiare/carrierwave-vips'

  s.add_runtime_dependency 'ruby-vips', '>=0.2.0'
  s.add_runtime_dependency 'carrierwave'
  s.add_runtime_dependency 'rmagick'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'dm-core'
  s.add_development_dependency 'dm-sqlite-adapter'
  s.add_development_dependency 'dm-migrations'
end
