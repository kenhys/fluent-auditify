# frozen_string_literal: true

require_relative '../test_helper'
require 'fluent/auditify/parser/v1config_parser'

class Fluent::AuditifyV1ConfigParserTest < Test::Unit::TestCase

  setup do
    @logger = Logger.new(nil)
  end

  teardown do
    discard
  end

  sub_test_case 'system test cases' do
    test 'parse system directive' do
      config = <<~EOS
      <system>
        workers 2
      </system>
      EOS
      @parser = Fluent::Auditify::Parser::V1ConfigParser.new
      object = @parser.parse(config)
      expected = [[1, 1],
                  [2, 3],
                  [{system: '<system>', body: [{name: 'workers', value: '2'}]}]]
      assert_equal(expected,
                   [object.first[:system].line_and_column,
                    object.first[:body].first[:name].line_and_column,
                    object])
    end
  end

  sub_test_case 'source test cases' do
    test 'parse source directive' do
      config = <<~EOS
      <source>
        @type tail
        path /tmp/foo
        id foo
      </source>
      EOS
      @parser = Fluent::Auditify::Parser::V1ConfigParser.new
      object = @parser.parse(config)
      expected = [[1, 1],
                  [[2, 3],
                   [3, 3],
                   [4, 3]],
                  [{source: '<source>', body: [{name: '@type', value: 'tail'},
                                               {name: 'path', value: '/tmp/foo'},
                                               {name: 'id', value: 'foo'}
                                              ]}]]
      assert_equal(expected,
                   [object.first[:source].line_and_column,
                    object.first[:body].map { |v| v[:name].line_and_column },
                    object])
    end
  end

  sub_test_case 'filter test cases' do
    data('filter directive' => ["<filter>\n  @type stdout\n</filter>",
                                [[1, 1],
                                 [[2, 3]],
                                 [{filter: '<filter',
                                   body: [{name: '@type', value: 'stdout'}],
                                   pattern: nil}
                                 ]]],
         'filter * directive' => ["<filter *>\n  @type stdout\n</filter>",
                                  [[1, 1],
                                   [[2, 3]],
                                   [{filter: '<filter',
                                     body: [{name: '@type', value: 'stdout'}],
                                     pattern: '*'}
                                   ]]],
         'filter ** directive' => ["<filter **>\n  @type stdout\n</filter>",
                                   [[1, 1],
                                    [[2, 3]],
                                    [{filter: '<filter',
                                      body: [{name: '@type', value: 'stdout'}],
                                      pattern: '**'}
                                    ]]],
         'filter *.** directive' => ["<filter *.**>\n  @type stdout\n</filter>",
                                     [[1, 1],
                                      [[2, 3]],
                                      [{filter: '<filter',
                                        body: [{name: '@type', value: 'stdout'}],
                                        pattern: '*.**'}
                                      ]]])
    test 'parse filter directive' do |data|
      config, expected = data
      @parser = Fluent::Auditify::Parser::V1ConfigParser.new
      object = @parser.parse(config)
      assert_equal(expected,
                   [object.first[:filter].line_and_column,
                    object.first[:body].map { |v| v[:name].line_and_column },
                    object])
    end
  end

  sub_test_case 'match test cases' do
    data('match directive' => ["<match>\n  @type stdout\n</match>",
                                [[1, 1],
                                 [[2, 3]],
                                 [{match: '<match',
                                   body: [{name: '@type', value: 'stdout'}],
                                   pattern: nil}
                                 ]]],
         'match * directive' => ["<match *>\n  @type stdout\n</match>",
                                  [[1, 1],
                                   [[2, 3]],
                                   [{match: '<match',
                                     body: [{name: '@type', value: 'stdout'}],
                                     pattern: '*'}
                                   ]]],
         'match ** directive' => ["<match **>\n  @type stdout\n</match>",
                                   [[1, 1],
                                    [[2, 3]],
                                    [{match: '<match',
                                      body: [{name: '@type', value: 'stdout'}],
                                      pattern: '**'}
                                    ]]],
         'match *.** directive' => ["<match *.**>\n  @type stdout\n</match>",
                                     [[1, 1],
                                      [[2, 3]],
                                      [{match: '<match',
                                        body: [{name: '@type', value: 'stdout'}],
                                        pattern: '*.**'}
                                      ]]])
    test 'parse match directive' do |data|
      config, expected = data
      @parser = Fluent::Auditify::Parser::V1ConfigParser.new
      object = @parser.parse(config)
      assert_equal(expected,
                   [object.first[:match].line_and_column,
                    object.first[:body].map { |v| v[:name].line_and_column },
                    object])
    end
  end

  sub_test_case 'label test cases' do
  end

  sub_test_case 'include test cases' do
  end
end
