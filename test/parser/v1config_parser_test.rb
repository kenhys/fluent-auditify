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
      object = test_parse_content_with_debug(config)
      expected = [[1, 1],
                  [2, 3],
                  [{system: '<system>', body: [{name: 'workers', value: '2'}]}]]
      assert_equal(expected,
                   [object.first[:system].line_and_column,
                    object.first[:body].first[:name].line_and_column,
                    object])
    end

    data('empty string' => ["<system>\nconfig_include_dir \"\"\n</system>",
                            [{system: '<system>',
                              body: [{name: 'config_include_dir', value: '""'}]}]],
         'path string' => ["<system>\nconfig_include_dir \"conf.d\"\n</system>",
                           [{system: '<system>',
                             body: [{name: 'config_include_dir', value: '"conf.d"'}]}]],
         'path' => ["<system>\nconfig_include_dir conf.d\n</system>",
                           [{system: '<system>',
                             body: [{name: 'config_include_dir', value: 'conf.d'}]}]])
    test 'parse config_include_dir' do |data|
      config, expected = data
      object = test_parse_content_with_debug(config)
      assert_equal(expected, [{system: object.first[:system].to_s,
                               body: [{name: object.first[:body].first[:name].to_s,
                                       value: object.first[:body].first[:value].to_s}]}])
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
      object = test_parse_content_with_debug(config)
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
      object = test_parse_content_with_debug(config)
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
                                      ]]],
         'match embedded code directive' => ["<match \"app.\#{ENV['FOO']}\">\n  @type stdout\n</match>",
                                     [[1, 1],
                                      [[2, 3]],
                                      [{match: '<match',
                                        body: [{name: '@type', value: 'stdout'}],
                                        pattern: "\"app.\#{ENV['FOO']}\""}
                                      ]]])
    test 'parse match directive' do |data|
      config, expected = data
      object = test_parse_content_with_debug(config)
      assert_equal(expected,
                   [object.first[:match].line_and_column,
                    object.first[:body].map { |v| v[:name].line_and_column },
                    object])
    end
  end

  sub_test_case 'label test cases' do
  end

  sub_test_case 'include test cases' do
    data('top-level @include' => ["@include foo.conf",
                                  [[1, 1],
                                   [1, 10],
                                   [{include: "@include", include_path: "foo.conf"}]]],
         'top-level @include with newline' => ["@include foo.conf\n",
                                  [[1, 1],
                                   [1, 10],
                                   [{include: "@include", include_path: "foo.conf"}]]],
         'top-level @include with extra space and newline' => [" @include  foo.conf\n",
                                  [[1, 2],
                                   [1, 12],
                                   [{include: "@include", include_path: "foo.conf"}]]],
         'top-level @include with path separator' => ["@include foo/bar.conf\n",
                                  [[1, 1],
                                   [1, 10],
                                   [{include: "@include", include_path: "foo/bar.conf"}]]],
         'top-level @include with wildcard' => ["@include foo/*.conf\n",
                                  [[1, 1],
                                   [1, 10],
                                   [{include: "@include", include_path: "foo/*.conf"}]]])
    test 'parse @include' do |data|
      config, expected = data
      object = test_parse_content_with_debug(config)
      assert_equal(expected,
                   [object.first[:include].line_and_column,
                    object.first[:include_path].line_and_column,
                    object])
    end

    data('top-level @include and included' => ['include/directive.conf',
                 'include/included_directives.conf',
                 ['included_directives.conf', [5, 10],
                  [5, 4], '@type', 'json'],
                ])
    test 'include directive test cases' do |data|
      parent_path, child_path, expected = data
      parent = test_parse_path_with_debug(parent_path)
      child = test_parse_path_with_debug(child_path)
      assert_equal(expected,
                   [parent.last[:include_path].to_s,
                    parent.last[:include_path].line_and_column,
                    child.first[:body].last[:section][:name].line_and_column,
                    child.first[:body].last[:body].first[:name].to_s,
                    child.first[:body].last[:body].first[:value].to_s])
    end

    data('include section and included' => ['include/section.conf',
                                            'include/included_section.conf',
                                            ['included_section.conf',
                                             [7, 12],
                                             'parse',
                                             [1, 2]]])
    test 'include section test cases' do |data|
      parent_path, child_path, expected = data
      parent = test_parse_path_with_debug(parent_path)
      child = test_parse_path_with_debug(child_path, klass: Fluent::Auditify::Parser::V1ConfigSectionParser)
      assert_equal(expected,
                   [parent.last[:body].last[:value].to_s,
                    parent.last[:body].last[:value].line_and_column,
                    child.first[:section][:name].to_s,
                    child.first[:section][:name].line_and_column
                   ])
    end

    data('include params test cases' => ['include/params.conf',
                                         'include/included_params.conf',
                                         ['included_params.conf',
                                          [7, 12],
                                          ['port','bind'],
                                          [[1, 1], [2, 1]]]])
    test 'include params test cases' do |data|
      parent_path, child_path, expected = data
      parent = test_parse_path_with_debug(parent_path)
      child = test_parse_path_with_debug(child_path, klass: Fluent::Auditify::Parser::V1ConfigParamParser)
      assert_equal(expected,
                   [parent.last[:body].last[:value].to_s,
                    parent.last[:body].last[:value].line_and_column,
                    child[:body].collect { |v| v[:name].to_s },
                    child[:body].collect { |v| v[:name].line_and_column }
                   ])
    end



  end

  sub_test_case 'evaluate @include test cases' do
    data('evaluate top-level @include and included' => ['include/directive.conf',
                                                        [['<system>', '@include'],
                                                         ['<system>', '<source>']]])
    test 'include directive test cases' do |data|
      parent_path, expected = data
      parent = test_parse_path_with_debug(parent_path)
      parser = Fluent::Auditify::Parser::V1ConfigParser.new
      modified = parser.eval(parent,
                             base_dir: File.dirname(test_fixture_path(parent_path)))
      assert_equal(expected,
                   [[parent.first[:system].to_s,
                    parent.last[:include].to_s],
                   [modified.first[:system].to_s,
                    modified.last[:source].to_s]])
    end
  end

end
