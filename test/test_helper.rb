# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fluent/auditify"
require "fluent/auditify/plugin"

require "test-unit"

def test_fixture_path(path)
  File.join(File.expand_path('../fixtures', __FILE__), path)
end

def discard
  Fluent::Auditify::Plugin.discard
end

def test_mask_charges(options={})
  masked = []
  Fluent::Auditify::Plugin.charges.each do |entry|
    attrs = entry.last
    value = {
      path: File.basename(attrs[:path]),
      content: attrs[:content],
      line: attrs[:line]
    }
    if options[:omit_line]
      value.delete(:line)
    end
    masked << [entry.first, value]
  end
  masked
end
