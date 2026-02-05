# frozen_string_literal: true

require_relative "lib/bug_tracker/version"

Gem::Specification.new do |spec|
  spec.name = "bug_tracker"
  spec.version = BugTracker::VERSION
  spec.authors = ["Tomáš Landovsky"]
  spec.email = ["landovsky@gmail.com"]

  spec.summary = "Unified error tracking adapter for Rails applications"
  spec.description = "A flexible error tracking gem that provides a unified interface for multiple error tracking providers (Sentry, Bugsnag, etc.) with integrated BaseError support."
  spec.homepage = "https://github.com/yourusername/bug-tracker"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  # Note: sentry-ruby is optional - only needed if using Sentry adapter
  spec.add_development_dependency "sentry-ruby", ">= 4.0"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
