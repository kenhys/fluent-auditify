require 'parslet'

module Fluent
  module Auditify
    module Parser
      class V1ConfigBaseParser < ::Parslet::Parser
        rule(:space)  { match('[ \t]').repeat(1) }
        rule(:space?) { space.maybe }
        rule(:newline) { str("\r\n") | str("\n") | str("\r") }
        rule(:newline?) { newline.maybe }
        rule(:integer) { match('[0-9]').repeat(1) }
        rule(:string) { str('"') >> match('[^"]').repeat >> str('"') }
        rule(:identifier) { match('[A-Za-z0-9_-]').repeat(1) }
        rule(:pattern) { match("[A-Za-z0-9_.*{},#'\"\\[\\]]").repeat(1) }
        rule(:pattern?) { pattern.maybe }
        rule(:empty_line) { space? >> newline }
        rule(:comment) { space? >> str('#') >> match('[^\r\n]').repeat >> newline }
        rule(:space_or_newline) { (space | newline).repeat(1) }

        rule(:eof?) { (newline | any.absent?).maybe }
        rule(:key) { str('@').maybe >> match('[a-zA-Z0-9_]').repeat(1) }
        rule(:path) { match('[.a-z0-9A-Z_/\\*\\-]').repeat(1) }
        rule(:ipv4) {
          match('[0-9]').repeat(1,3) >>
            (str('.') >> match('[0-9]').repeat(1,3)).repeat(3) }
        rule(:nonspace_nonquote_char) { match('[^" \t\r\n]') }
        rule(:unquoted_word) { (str('"').absent? >> nonspace_nonquote_char.repeat(1)) }
        rule(:value) { string | unquoted_word }
        rule(:key_value) { space? >> key.as(:name) >> space >> value.as(:value) >>
                           space? >> newline }
        rule(:key_line) { space? >> key.as(:name) >> space_or_newline }

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

        rule(:conf) { (comment | key_value | key.as(:name) | empty_line).repeat.as(:body) }

        root :conf
      end

      class V1ConfigSectionParser < V1ConfigBaseParser
        # @include section conf
        rule(:tag_name) { match('[a-zA-Z0-9_]').repeat(1) }
        rule(:open_tag) { str('<') >> tag_name.as(:name) >>
                          (space >> tag_name.as(:section_arg)).maybe >> str('>') }
        rule(:close_tag) { str('</') >> tag_name.as(:name) >> str('>') }
        rule(:section) do
          space? >> open_tag.as(:section) >> space_or_newline >>
            (comment | key_value | section | key.as(:name) | empty_line.as(:empty_line)).repeat.as(:body) >>
            space? >> close_tag >> space? >> eof?
        end

        rule(:conf) { (comment | key_value | key.as(:name) | empty_line.as(:empty_line) | section).repeat }
        root :conf
      end

      class V1ConfigParser < V1ConfigBaseParser

        rule(:system) do
          space? >> str('<system>').as(:system) >> space_or_newline.maybe >>
            (comment | key_value | empty_line.as(:empty_line) | section).repeat.as(:body) >>
            space? >> str('</system>') >> space? >> eof?
        end
        rule(:include_directive) do
          space? >> str('@include').as(:include) >> space >>
            (conf_path | yaml_path).as(:include_path) >> eof?
        end
        rule(:source) do
          space? >> str('<source>').as(:source) >> space_or_newline >>
            (comment | empty_line.as(:empty_line) | key_value | key_line | section).repeat.as(:body) >>
            space? >> str('</source>') >> space_or_newline.maybe >> eof?
        end
        rule(:section) do
          space? >> open_tag.as(:section) >> space_or_newline >>
            (comment | key_value | empty_line | key_line | section).repeat.as(:body) >>
            space? >> close_tag >> eof?
        end
        rule(:filter) do
          space? >> str('<filter').as(:filter) >> space? >> pattern?.as(:pattern) >> str('>') >> space_or_newline >>
            (comment | key_value | empty_line | section).repeat.as(:body) >>
            space? >> str('</filter>') >> eof?
        end
        # match is reserved word
        rule(:match_directive) do
          space? >> str('<match').as(:match) >> space? >> pattern?.as(:pattern) >> str('>') >> space_or_newline >>
            (comment | key_value | empty_line.as(:empty_line) | section).repeat.as(:body) >>
            space? >> str('</match>') >> eof?
        end
        rule(:label) do
          space? >> str('<label').as(:label) >> space? >> key.as(:name) >> str('>') >> space_or_newline >>
            (comment | filter | match_directive).repeat.as(:body) >>
            space? >> str('</label>') >> eof?
        end
        rule(:directive) { system | source | filter | match_directive | include_directive | label} # | filter | match | label | empty_line }
        rule(:conf) { (directive | comment | empty_line.as(:empty_line)).repeat(1) }

        root :conf

        # expand @include directive
        def self.eval(object, base_dir: "", path: "", include: true)
          modified = []
          object.each do |directive|
            directive[:__BASE__] = base_dir
            directive[:__PATH__] = path
            unless directive[:include]
              if directive[:body]
                modified << eval_body(directive, base_dir: base_dir)
              else
                modified << directive
              end
              next
            end
            # top-level @include
            eval_include(directive, base_dir: base_dir).each do |child|
              child[:__PARENT__] = path
              modified << child
            end
          end
          modified
        end

        def self.eval_body(directive, base_dir: '')
          # include section
          modified_body = []
          directive[:body].each do |body_element|
            if body_element[:name].to_s == '@include'
              parser = Fluent::Auditify::Parser::V1ConfigSectionParser.new
              pattern = File.expand_path(body_element[:value].to_s, base_dir)
              Dir.glob(pattern).sort.each do |path|
                object = parser.parse(File.read(path))
                object.each do |element|
                  element[:__PATTERN__] = body_element[:value].to_s
                  element[:__PATH__] = File.basename(path)
                  if element[:section]
                    pp eval_body(element, base_dir: base_dir)
                    element[:body] = eval_body(element, base_dir: base_dir)[:body]
                    modified_body << element
                  else
                    modified_body << element
                  end
                end
              end
            elsif body_element[:section]
              section_body = []
              body_element[:body].each do |child|
                child[:__PATH__] = body_element[:__PATH__]
                section_body << child
              end
              body_element[:body] = section_body
              modified_body << body_element
            else
              body_element[:__PATH__] = directive[:__PATH__]
              modified_body << body_element
            end
          end
          directive[:body] = modified_body
          directive
        end

        def self.eval_include(directive, base_dir: '')
          parser = Fluent::Auditify::Parser::V1ConfigParser.new
          pattern = File.expand_path(directive[:include_path].to_s, base_dir)
          modified = []
          Dir.glob(pattern).sort.each do |path|
            included =  parser.parse(File.read(path))
            included.each do |included_directive|
              included_directive[:__PATTERN__] = directive[:include_path].to_s
              included_directive[:__PATH__] = Pathname.new(path).relative_path_from(base_dir).to_s
              included_directive[:__BASE__] = base_dir
              included_directive[:body] = eval_body(included_directive, base_dir: base_dir)[:body]
              modified << included_directive
            end
          end
          modified
        end

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
