# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fluent/auditify"
require "fluent/auditify/plugin"
require "fluent/auditify/helper/test"

require "test-unit"
require 'pastel'

include Fluent::Auditify::Helper::Test

def test_fixture_path(path)
  File.join(File.expand_path('../fixtures', __FILE__), path)
end

def discard
  Fluent::Auditify::Plugin.discard
end

