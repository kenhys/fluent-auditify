# frozen_string_literal: true

require_relative 'test_helper'
require 'fluent/auditify/parser/v1config_parser'
require 'fluent/auditify/parsletutil'

def capture_stdout
  old = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = old
end

class Fluent::AuditifyParsletUtilTest < Test::Unit::TestCase
  setup do
    @util = Fluent::Auditify::ParsletUtil.new
  end

  sub_test_case 'export' do

    data('system' => ["<system>\n  config_include_dir \"\"\n</system>\n"],
         'source' => ["<source>\n  @type forward\n</source>\n"],
         'match' => ["<match>\n  @type stdout\n</match>\n"])
    test 'export' do |data|
      config, _ = data
      object = test_parse_content_with_debug(config)
      output = capture_stdout do
        @util.export(object)
      end
      assert_equal(config, output)
    end

    data('system' => ["<system>\n  config_include_dir \"\"\n  <log>\n    rotate_age 14\n  </log>\n</system>\n",
                      "  config_include_dir \"\"\n  <log>\n    rotate_age 14\n  </log>\n"],
         'source' => ["<source>\n  @type forward\n</source>\n",
                      "  @type forward\n"],
         'match' => ["<match>\n  @type stdout\n</match>\n",
                     "  @type stdout\n"])
    test 'export_body' do
      config, expected = data
      object = test_parse_content_with_debug(config)
      output = capture_stdout do
        @util.export_body(object.first)
      end
      assert_equal(expected, output)
    end

    data('system' => ["<system>\nconfig_include_dir \"\"\n<log>\nrotate_age 14\n</log>\n</system>\n",
                      "<log>\n  rotate_age 14\n</log>\n"],
         'source' => ["<source>\n@type tail\n<parse>\n@type json\n</parse>\n</source>\n",
                      "<parse>\n  @type json\n</parse>\n"],
         'match' => ["<match>\n@type http\n<format>\n@type json\n</format>\n</match>\n",
                     "<format>\n  @type json\n</format>\n"],
         'nested section' => ["<source>\n@type forward\n<security>\n<user>\nuser john\n</user>\n</security>\n</source>\n",
                              "<security>\n  <user>\n    user john\n  </user>\n</security>\n"])
    test 'export_section' do |data|
      config, expected = data
      object = test_parse_content_with_debug(config)
      output = capture_stdout do
        @util.export_section(object.first[:body][1])
      end
      assert_equal(expected, output)
    end
  end
end
