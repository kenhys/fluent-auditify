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
        rule(:string) { match("[a-zA-Z/_'\"]").repeat(1) }
        rule(:identifier) { match('[A-Za-z0-9_]').repeat(1) }
        rule(:pattern) { match('[A-Za-z0-9_.*]').repeat(1) }
        rule(:pattern?) { pattern.maybe }
        rule(:empty_line) { space? >> newline }
        rule(:comment) { str('#') >> (newline.absent? >> any).repeat >> newline? }

        rule(:key) { match('@?[a-zA-Z_]').repeat(1) }
        rule(:value) { integer | string }
        rule(:key_value) { space? >> key.as(:name) >> space >> value.as(:value) >> space? >> newline? }
        rule(:system) do
          space? >> str('<system>').as(:system) >> space? >> newline? >>
            (comment | key_value | empty_line).repeat.as(:body) >>
            space? >> str('</system>') >> space? >> newline?
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
=begin
        rule(:match) do
          space? >> str('<match').as(:match) >> space? >> pattern?.as(:pattern) >> str('>') >> space? >> newline? >>
            (comment | key_value | empty_line).repeat.as(:body) >>
            space? >> str('</match>') >> space? >> newline?
        end
        rule(:label) do
          space? >> str('<label') >> identifier >> str('>') >> space? >> newline? >>
            key_value.repeat(1) >>
            str('</label>') >> space? >> newline?
        end
=end
        rule(:directive) { system | source | filter | empty_line } # | filter | match | label | empty_line }
        rule(:conf) { directive.repeat(1) }

        root :conf
      end
    end
  end
end
