# frozen_string_literal: true

require_relative "lib/fluent/auditify/version"

Gem::Specification.new do |spec|
  spec.name = "fluent-auditify"
  spec.version = Fluent::Auditify::VERSION
  spec.authors = ["Kentaro Hayashi"]
  spec.email = ["kenhys@gmail.com"]

  spec.summary = "Audit tool for your Fluentd configuration"
  spec.description = "Audit your Fluentd configuration and raise attention to you"
  spec.homepage = "https://github.com/kenhys/fluent-auditify"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kenhys/fluent-auditify"
  spec.metadata["changelog_uri"] = "https://github.com/kenhys/fluent-auditify/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "fluentd", "< 2.0"
  spec.add_dependency "parslet", "~> 2.0.0"
  spec.add_dependency "pastel", "~> 0.8.0"
  spec.add_dependency "diff-lcs", "~> 1.6.2"
  spec.add_dependency "term-ansicolor", "~> 1.11.2"

end
