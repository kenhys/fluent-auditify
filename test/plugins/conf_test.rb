# frozen_string_literal: true

require 'test_helper'
require 'fluent/auditify/plugin/conf_v1dupid'

class Fluent::AuditifyV1ConfTest < Test::Unit::TestCase

  setup do
    @logger = Logger.new(nil)
    @plugin = Fluent::Auditify::Plugin::V1DuplicatedId.new
    @plugin.instance_variable_set(:@log, @logger)
  end

  teardown do
    discard
  end

  test "duplicated @id should be detected" do
    conf = test_fixture_path("dup_id.conf")
    @plugin.parse(conf)
    assert_equal([['foo is duplicated', {content: '  @id foo', line: 3, path: "dup_id.conf"}],
                  ['foo is duplicated', {content: '  @id foo', line: 8, path: "dup_id.conf"}]],
                 test_mask_charges)
  end
end
