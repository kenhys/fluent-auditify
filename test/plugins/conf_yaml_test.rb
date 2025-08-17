# frozen_string_literal: true

require "test_helper"
require 'fluent/auditify/plugin/conf_yaml'

class TestYamlConf
  def initialize
    @logger = Logger.new(nil)
    @plugin = Fluent::Auditify::Plugin::YamlConf.new
    @plugin.instance_variable_set(:@log, @logger)
  end

  def parse(conf)
    @plugin.parse(conf)
  end
end

class Fluent::AuditifyConfYamlTest < Test::Unit::TestCase

  setup do
    @plugin = TestYamlConf.new
  end

  teardown do
    discard
  end

  data('unknown directive' => 'wrong_directive.yaml',
       'unknown directive with broken indent' => 'wrong_directive_broken_indent.yaml')
  test "wrong directive should be detected" do |data|
    conf = test_fixture_path(data)
    @plugin.parse(conf)
    assert_equal([['top level directive must be system or config, not <unknown>',
                   {content: 'unknown:', line: 1, path: data}]],
                 test_mask_charges)
  end

  data('no source directive' => 'no_source.yaml',
       'no match directive' => 'no_match.yaml')
  test "directive must exist" do |data|
    conf = test_fixture_path(data)
    @plugin.parse(conf)
    directive = data.include?('source') ? 'source' : 'match'
    assert_equal([["no #{directive} directive",
                   {content: nil, line: nil, path: data}]],
                 test_mask_charges)
  end

  test "broken indent with config param" do
    conf = test_fixture_path('broken_source_config_param_indent.yaml')
    @plugin.parse(conf)
    assert_equal([["source must not be empty. parameter for <source:> indent might be broken",
                   {content: "  - source:\n", line: 2, path: 'broken_source_config_param_indent.yaml'}]],
                 test_mask_charges)
  end

  test "unknown config element" do
    conf = test_fixture_path('wrong_config_element.yaml')
    @plugin.parse(conf)
    assert_equal([['config element must be either source, match, filter and label, not <unknown>',
                   {content: "  - unknown:\n", line: 2, path: 'wrong_config_element.yaml'}]],
                 test_mask_charges)
  end
  
  data('use $type instead of @type' => ['source_at_type.yaml', 'type', '@type: forward'],
       'use $tag instead of @tag' => ['source_at_tag.yaml', 'tag', '@tag: foo'],
       'use $label instead of @label' => ['source_at_label.yaml', 'label', "@label: '@SYSTEM'"],
       'use $log_level instead of @log_level' => ['source_at_log_level.yaml', 'log_level', "@log_level: 'debug'"],
       'use $arg instead of @arg' => ['worker_at_arg.yaml', 'arg', "@arg: 0"],
       'use $name instead of @name' => ['label_at_name.yaml', 'name', "@name: '@SYSTEM'"])
  test "wrong @ prefix" do |(path, label, content)|
    conf = test_fixture_path(path)
    @plugin.parse(conf)
    message = "use '$#{label}' special YAML element instead of '@#{label}'"
    assert_equal([[message,
                   {content: content, path: path}]],
                 test_mask_charges({omit_line: true, strip_content: true}))
  end
end
