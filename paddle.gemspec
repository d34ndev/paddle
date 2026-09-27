# frozen_string_literal: true

require_relative "lib/paddle/version"

Gem::Specification.new do |spec|
  spec.name          = "paddle"
  spec.version       = Paddle::VERSION
  spec.authors       = [ "Dean Perry" ]
  spec.email         = [ "dean@deanpcmad.com" ]

  spec.summary       = "Ruby library for the Paddle Billing & Classic APIs"
  spec.homepage      = "https://github.com/d34ndev/paddle"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/d34ndev/paddle"
  spec.metadata["changelog_uri"] = "https://github.com/d34ndev/paddle/blob/main/CHANGELOG.md"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "faraday", ">= 2.14.3", "< 3"
end
