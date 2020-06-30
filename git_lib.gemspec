# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git/version'

Gem::Specification.new do |spec|
  spec.name          = "git_lib"
  spec.version       = Git::VERSION
  spec.authors       = ["Invoca Development"]
  spec.email         = ["development@invoca.com"]
  spec.summary       = %q{Git wrapper library.}
  spec.homepage      = ""

  spec.metadata = {
    'allowed_push_host' => "https://rubygems.org"
  }

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport', '>= 4.2'
end
