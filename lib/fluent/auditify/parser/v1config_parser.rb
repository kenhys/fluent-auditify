require 'parslet'

module Fluent
  module Auditify
    module Parser
      class V1ConfigParser < ::Parslet::Parser

        rule(:space)  { match('\s').repeat(1) }
        rule(:space?) { space.maybe }
        rule(:newline) { match('[\r\n]').repeat(1) }
        rule(:newline?) { newline.maybe }
        rule(:integer) { match('[0-9]').repeat(1) }
        rule(:string) { match('".+"').repeat(1) }
        rule(:identifier) { match('[A-Za-z0-9_]').repeat(1) }
        rule(:pattern) { match("[A-Za-z0-9_.*{},#'\"\\[\\]]").repeat(1) }
        rule(:pattern?) { pattern.maybe }
        rule(:empty_line) { space? >> newline }
        rule(:comment) { str('#') >> (newline.absent? >> any).repeat >> newline? }

        rule(:key) { match('@?[a-zA-Z_]').repeat(1) }
        rule(:path) { match('[.a-zA-Z_-]+').repeat(1) }
        rule(:value) { integer | string | path }
        rule(:key_value) { space? >> key.as(:name) >> space >> value.as(:value) >> space? >> newline? }
        rule(:system) do
          space? >> str('<system>').as(:system) >> space? >> newline? >>
            (comment | key_value | empty_line).repeat.as(:body) >>
            space? >> str('</system>') >> space? >> newline?
        end
        rule(:conf_path) { (match("[^\s\.]+").repeat(1) >> str('.conf')) }
        rule(:yaml_path) do
          (match("[^\s\.]+").repeat(1) >> str('.yaml')) |
            (match("[^\s\.]+").repeat(1) >> str('.yml'))
        end
        rule(:include_directive) do
          space? >> str('@include').as(:include) >> space >> 
            (conf_path | yaml_path).as(:include_path) >>
            space? >> newline?
        end
        rule(:source) do
          space? >> str('<source>').as(:source) >> space? >> newline? >>
            (comment | key_value | empty_line).repeat.as(:body) >>
            space? >> str('</source>') >> space? >> newline?
        end
        rule(:filter) do
          space? >> str('<filter').as(:filter) >> space? >> pattern?.as(:pattern) >> str('>') >> space? >> newline? >>
            (comment | key_value | empty_line).repeat.as(:body) >>
            space? >> str('</filter>') >> space? >> newline?
        end
        # match is reserved word
        rule(:match_directive) do
          space? >> str('<match').as(:match) >> space? >> pattern?.as(:pattern) >> str('>') >> space? >> newline? >>
            (comment | key_value | empty_line).repeat.as(:body) >>
            space? >> str('</match>') >> space? >> newline?
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
