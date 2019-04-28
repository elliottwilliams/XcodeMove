lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xcmv/version'

Gem::Specification.new do |s|
  s.name        = 'xcmv'
  s.version     = XcodeMove::VERSION
  s.date        = '2018-08-19'
  s.summary     = 'Xcode Move'
  s.description = 'mv-like command that moves files between xcode projects'
  s.authors     = ['Elliott Williams']
  s.homepage    = 'https://github.com/elliottwilliams/XcodeMove'
  s.email       = 'emw@yelp.com'
  s.files       = Dir['lib/**/*.rb', 'bin/*']
  s.license = 'MIT'
  s.add_runtime_dependency 'xcodeproj', '~> 1.6'
  s.executables << 'xcmv'
end
