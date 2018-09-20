Gem::Specification.new do |s|
  s.name        = 'xcmv'
  s.version     = '0.0.1'
  s.date        = '2018-08-19'
  s.summary     = "Xcode Move"
  s.description = "mv-like command that moves files between xcode projects"
  s.authors     = ["Elliott Williams"]
  s.email       = 'emw@yelp.com'
  s.files       = Dir["lib/**/*.rb", "bin/*"]
  s.license       = 'MIT'
  s.add_runtime_dependency 'xcodeproj', '~> 1.6'
  s.executables << 'xcmv'
end
