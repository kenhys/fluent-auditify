# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fluent/auditify"
require "fluent/auditify/plugin"

require "test-unit"
require 'pastel'

def test_fixture_path(path)
  File.join(File.expand_path('../fixtures', __FILE__), path)
end

def discard
  Fluent::Auditify::Plugin.discard
end

def test_mask_charges(options={})
  masked = []
  Fluent::Auditify::Plugin.charges.each do |entry|
    attrs = entry.last
    value = {
      path: File.basename(attrs[:path]),
      content: attrs[:content],
      line: attrs[:line]
    }
    if options[:omit_line]
      value.delete(:line)
    end
    if options[:strip_content]
      value[:content].strip!
    end
    masked << [entry.first, value]
  end
  masked
end

def test_parse_with_debug(klass, path_or_content)
  begin
    parser = klass.new
    if File.exist?(test_fixture_path(path_or_content))
      object = parser.parse(File.read(test_fixture_path(path_or_content)))
    else
      object = parser.parse(path_or_content)
    end
  rescue => e
    pastel = Pastel.new
    puts pastel.white.on_red("[FAIL]") + " class: #{klass}, path: #{path_or_content}"
    if File.exist?(test_fixture_path(path_or_content))
      puts ">>>\n" + File.read(test_fixture_path(path_or_content)) + "<<<\n"
    else
      puts ">>>\n" + path_or_content.strip + "\n<<<\n"
    end
    puts e.parse_failure_cause.ascii_tree
  end
  object
end

def test_parse_includes(params)
  parent = test_parse_with_debug(params[:parent_class], params[:parent_path])
  child = test_parse_with_debug(params[:child_class], params[:child_path])
  yield parent, child
end
