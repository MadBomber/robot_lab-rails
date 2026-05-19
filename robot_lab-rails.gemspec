# frozen_string_literal: true

require_relative "lib/robot_lab/rails/version"

Gem::Specification.new do |spec|
  spec.name = "robot_lab-rails"
  spec.version = RobotLab::Rails::VERSION
  spec.authors = ["Dewayne VanHoozer"]
  spec.email = ["dewayne@vanhoozer.me"]

  spec.summary = "Rails integration for the robot_lab LLM agent framework"
  spec.description = "Provides Rails Engine, Railtie, ActiveJob base class with Turbo Stream support, " \
                     "persistence models, and generators for using robot_lab in Rails applications."
  spec.homepage = "https://github.com/MadBomber/robot_lab-rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"]    = "https://rubygems.org"
  spec.metadata["homepage_uri"]         = spec.homepage
  spec.metadata["source_code_uri"]      = spec.homepage
  spec.metadata["changelog_uri"]        = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ sig/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "robot_lab", "~> 0.2.0"
  spec.add_dependency "railties",      ">= 7.0"
  spec.add_dependency "activejob",     ">= 7.0"
  spec.add_dependency "activesupport", ">= 7.0"
end
