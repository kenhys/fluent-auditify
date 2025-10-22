require 'parslet'

module Fluent
  module Auditify
    module Parser
      class V1ConfigBaseParser < ::Parslet::Parser
        rule(:space)  { match('[ \t]').repeat(1) }
        rule(:space?) { space.maybe }
        rule(:newline) { match('[\r\n]').repeat(1) }
        rule(:newline?) { newline.maybe }
        rule(:integer) { match('[0-9]').repeat(1) }
        rule(:string) { str('"') >> match('[^"]').repeat >> str('"') }
        rule(:identifier) { match('[A-Za-z0-9_]').repeat(1) }
        rule(:pattern) { match("[A-Za-z0-9_.*{},#'\"\\[\\]]").repeat(1) }
        rule(:pattern?) { pattern.maybe }
        rule(:empty_line) { space? >> newline }
        rule(:comment) { space? >> str('#') >> (newline.absent? >> any).repeat >> newline? }
        rule(:space_or_newline) { (match('[ \t]') | str("\n")).repeat }

        rule(:key) { match('@?[a-zA-Z0-9_]').repeat(1) }
        rule(:path) { match('[.a-zA-Z_/-]').repeat(1) }
        rule(:value) { integer | string | path }
        rule(:key_value) { space_or_newline >> key.as(:name) >> space >> value.as(:value) >> space_or_newline }

        rule(:tag_name) { match('[a-zA-Z0-9_]').repeat(1) }
        rule(:open_tag) { str('<') >> tag_name.as(:name) >>
                          (space >> tag_name.as(:section_arg)).maybe >> str('>') }
        rule(:close_tag) { str('</') >> tag_name.as(:name) >> str('>') }

        rule(:conf_path) { (match("[^\s\.]+").repeat(1) >> str('.conf')) }
        rule(:yaml_path) do
          (match("[^\s\.]+").repeat(1) >> str('.yaml')) |
            (match("[^\s\.]+").repeat(1) >> str('.yml'))
        end
      end

      class V1ConfigParamParser < V1ConfigBaseParser
        # @include key-value-pair conf

        rule(:conf) { space_or_newline >> (comment | key_value | empty_line).repeat.as(:body) }

        root :conf
      end

      class V1ConfigSectionParser < V1ConfigBaseParser
        # @include section conf
        rule(:tag_name) { match('[a-zA-Z0-9_]').repeat(1) }
        rule(:open_tag) { str('<') >> tag_name.as(:name) >>
                          (space >> tag_name.as(:section_arg)).maybe >> str('>') }
        rule(:close_tag) { str('</') >> tag_name.as(:name) >> str('>') }
        rule(:section) do
          space_or_newline >> open_tag.as(:section) >> space_or_newline >>
            (comment | key_value | section | key.as(:name) | empty_line).repeat.as(:body) >>
            space_or_newline >> close_tag >> space_or_newline
        end

        rule(:conf) { (comment | key_value | empty_line | section).repeat }
        root :conf
      end

      class V1ConfigParser < V1ConfigBaseParser

        rule(:system) do
          space_or_newline >> str('<system>').as(:system) >> space_or_newline >>
            (comment | key_value | empty_line).repeat.as(:body) >>
            space_or_newline >> str('</system>') >> space_or_newline
        end
        rule(:include_directive) do
          space_or_newline >> str('@include').as(:include) >> space_or_newline >> 
            (conf_path | yaml_path).as(:include_path) >>
            space_or_newline
        end
        rule(:source) do
          space_or_newline >> str('<source>').as(:source) >> space_or_newline >>
            (comment | key_value | section | key.as(:name) | empty_line).repeat.as(:body) >>
            space_or_newline >> str('</source>') >> space_or_newline
        end
        rule(:section) do
          space_or_newline >> open_tag.as(:section) >> space_or_newline >>
            (comment | key_value | empty_line | section).repeat.as(:body) >>
            space_or_newline >> close_tag >> space_or_newline
        end
        rule(:filter) do
          space_or_newline >> str('<filter').as(:filter) >> space? >> pattern?.as(:pattern) >> str('>') >> space_or_newline >>
            (comment | key_value | empty_line | section).repeat.as(:body) >>
            space_or_newline >> str('</filter>') >> space_or_newline
        end
        # match is reserved word
        rule(:match_directive) do
          space_or_newline >> str('<match').as(:match) >> space? >> pattern?.as(:pattern) >> str('>') >> space_or_newline >>
            (comment | key_value | empty_line).repeat.as(:body) >>
            space_or_newline >> str('</match>') >> space_or_newline
        end
=begin
        rule(:label) do
          space? >> str('<label') >> identifier >> str('>') >> space? >> newline? >>
            key_value.repeat(1) >>
            str('</label>') >> space? >> newline?
        end
=end
        rule(:directive) { system | source | filter | match_directive | include_directive | empty_line | comment } # | filter | match | label | empty_line }
        rule(:conf) { directive.repeat(1) }

        root :conf

        def find_nth_element(object, nth: 1, elements: [])
          count = 0
          elements.each do |element|
            if element[object.intern]
              count += 1
              if nth == count
                return element
              end
            end
          end
          nil
        end
      end
    end
  end
end
