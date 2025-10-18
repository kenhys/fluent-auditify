# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in fluent-auditify.gemspec
gemspec

gem "rake", "~> 13.0"

if File.exist?('Gemfile.local')
  eval_gemfile('Gemfile.local')
end

# For Ruby 2.7
gem "dotenv", "~> 2.8.1"
gem "test-unit", "~> 3.0"

gem "rubocop", "< 2"
gem "rubocop-fluentd", "~> 0.2.4"
gem "rubocop-performance", "~> 1.25"

