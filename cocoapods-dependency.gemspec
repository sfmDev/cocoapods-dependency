# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-dependency/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-dependency'
  spec.version       = CocoapodsDependency::VERSION
  spec.authors       = ['sfmDev']
  spec.email         = ['sfmdeveloper@icloud.com']
  spec.description   = %q{Show project dependencies with HTML file.}
  spec.summary       = %q{Show project dependencies with HTML file.}
  spec.homepage      = 'https://github.com/sfmDev/cocoapods-dependency'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'

  spec.add_dependency "launchy"
end
