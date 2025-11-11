require 'stringio'

module Fluent
  module Auditify
    class ParsletUtil
      def initialize(options={})
        reset_style
      end

      def reset_style
        @indent_level = 0
        @align = 2
        @content = StringIO.new
      end

      def export(object, options={})
      end

      def to_s(object, options={})
        object.each do |directive|
          if directive[:source]
            @content.puts "#{' ' * @align * @indent_level}#{directive[:source].to_s}"
            stringify_body(directive)
            @content.puts "</source>"
          elsif directive[:match]
            @content.puts "#{' ' * @align * @indent_level}#{directive[:match].to_s}>"
            stringify_body(directive)
            @content.puts "</match>"
          elsif directive[:system]
            @content.puts "#{' ' * @align * @indent_level}#{directive[:system].to_s}"
            stringify_body(directive)
            @content.puts "</system>"
          elsif directive[:empty_line]
            @content.puts
          else
          end
        rescue => e
          p e
        end
        @content.string
      end

      private

      def stringify_body(directive)
        @indent_level += 1
        directive[:body].each do |child|
          if child[:section]
            stringify_section(child)
          elsif child[:empty_line]
            @content.puts
          elsif child[:value]
            @content.puts "#{' ' * @align * @indent_level}#{child[:name].to_s} #{child[:value].to_s}"
          elsif child[:name]
            @content.puts "#{' ' * @align * @indent_level}#{child[:name].to_s}"
          else
          end
        end
        p @content.string
        @indent_level -= 1
      end

      def stringify_section(section)
        @content.puts "#{' ' * @align * @indent_level}<#{section[:section][:name].to_s}>"
        @indent_level += 1
        section[:body].each do |child|
          if child[:section]
            stringify_section(child)
          elsif child[:name]
            @content.puts "#{' ' * @align * @indent_level}#{child[:name].to_s} #{child[:value].to_s}"
          end
        end
        @indent_level -= 1
        @content.puts "#{' ' * @align * @indent_level}</#{section[:name].to_s}>"
        p @content.string
      end
    end
  end
end
