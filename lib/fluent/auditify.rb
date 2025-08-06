# frozen_string_literal: true

require_relative "auditify/version"
require_relative "auditify/syntax_checker"

module Fluent
  module Auditify
    class DuplicatedPluginError < StandardError; end
  end
end
