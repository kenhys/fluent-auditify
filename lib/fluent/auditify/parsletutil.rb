module Fluent
  module Auditify
    class ParsletUtil
      def initialize
        @indent_level = 0
        @align = 2
      end

      def export(object)
        begin
          object.each do |directive|
            if directive[:source]
              puts "#{' ' * @align * @indent_level}#{directive[:source].to_s}"
              export_body(directive)
              puts "</source>"
            elsif directive[:match]
              puts "#{' ' * @align * @indent_level}#{directive[:match].to_s}>"
              export_body(directive)
              puts "</match>"
            elsif directive[:system]
              puts "#{' ' * @align * @indent_level}#{directive[:system].to_s}"
              export_body(directive)
              puts "</system>"
            elsif directive[:empty_line]
              puts
            else
            end
          rescue => e
            p e
          end
        end
      end

      def export_body(directive)
        @indent_level += 1
        directive[:body].each do |child|
          if child[:section]
            export_section(child)
          elsif child[:empty_line]
            puts
          elsif child[:value]
            puts "#{' ' * @align * @indent_level}#{child[:name].to_s} #{child[:value].to_s}"
          elsif child[:name]
            puts "#{' ' * @align * @indent_level}#{child[:name].to_s}"
          else
          end
        end
        @indent_level -= 1
      end

      def export_section(section)
        puts "#{' ' * @align * @indent_level}<#{section[:section][:name].to_s}>"
        @indent_level += 1
        section[:body].each do |child|
          if child[:name]
            puts "#{' ' * @align * @indent_level}#{child[:name].to_s} #{child[:value].to_s}"
          elsif child[:section]
            p child
            export_section(child)
          end
        end
        @indent_level -= 1
        puts "#{' ' * @align * @indent_level}</#{section[:name].to_s}>"
      end
    end
  end
end
