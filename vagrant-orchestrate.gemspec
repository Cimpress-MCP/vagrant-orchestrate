# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-orchestrate/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-orchestrate"
  spec.version       = VagrantPlugins::Orchestrate::VERSION
  spec.authors       = ["Christopher Baldauf"]
  spec.email         = ["cbaldauf@cimpress.com"]
  spec.summary       = %q{Vagrant plugin to orchestrate the deployment of managed servers.}
  spec.homepage      = ""
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec'
  # See Gemfile for additional development dependencies that were not available
  # on rubygems (or another gem source), but needed to be downloaded from git.
end
