# frozen_string_literal: true

require_relative '../test_helper'
require 'fluent/auditify/plugin/conf_plugin_params'

class Fluent::AuditifyV1ConfTest < Test::Unit::TestCase

  setup do
    @logger = Logger.new(nil)
    @plugin = Fluent::Auditify::Plugin::ConfPluginParams.new
    @plugin.instance_variable_set(:@log, @logger)
  end

  teardown do
    discard
  end

  sub_test_case 'conf test cases' do

    # FIXME: support content and location
    data('tail unknown' => ['tail/unknown_param.conf',
                            [['unknown <unknown> parameter',
                              {content: nil, line: nil, path: 'tail_unknown_param.conf'}]]])
    test 'input unknown params' do |data|
      conf, expected = data
      @plugin.parse(test_fixture_path(conf))
      assert_equal(expected, test_mask_charges)
    end

    data('tail unknown' => ['tail/unknown_directive.conf',
                            [['unknown <unknown> parameter',
                              {content: nil, line: nil, path: 'tail_unknown_param.conf'}]]])
    test 'input unknown params' do |data|
    end
  end

  sub_test_case 'yaml test cases' do
  end
end
