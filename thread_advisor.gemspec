# frozen_string_literal: true

require_relative "lib/thread_advisor/version"

Gem::Specification.new do |spec|
  spec.name          = "thread_advisor"
  spec.version       = ThreadAdvisor::VERSION
  spec.summary       = "Estimate optimal thread count from IO ratio using Amdahl's law"
  spec.description   = "Measures block or request IO ratio and advises optimal threads considering CPU cores and AR pool."
  spec.authors       = ["Your Name"]
  spec.email         = ["you@example.com"]
  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "activesupport", ">= 7.2"
  spec.add_dependency "railties", ">= 7.2"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "gvl_timing"
end
