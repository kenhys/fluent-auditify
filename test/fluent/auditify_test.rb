# frozen_string_literal: true

require "test_helper"

class Fluent::AuditifyTest < Test::Unit::TestCase
  test "VERSION" do
    assert do
      ::Fluent::Auditify.const_defined?(:VERSION)
    end
  end

end
