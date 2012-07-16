# -*- encoding: utf-8 -*-
require File.expand_path('../lib/snapimage/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Wesley Wong"]
  gem.email         = ["wesley@snapeditor.com"]
  gem.description   = %q{Rack Middleware for handling the SnapImage API}
  gem.summary       = %q{SnapImage API Rack Middleware}
  gem.homepage      = "http://SnapEditor.com"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "snapimage"
  gem.require_paths = ["lib"]
  gem.version       = SnapImage::VERSION

  gem.add_dependency("rack")
  gem.add_dependency("rmagick")

  gem.add_development_dependency("rspec")
  gem.add_development_dependency("autotest")
  gem.add_development_dependency("rack-test")
end
