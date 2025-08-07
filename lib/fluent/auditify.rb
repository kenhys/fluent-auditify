# frozen_string_literal: true

require_relative "auditify/version"

module Fluent
  module Auditify
    class DuplicatedPluginError < StandardError; end
  end
end
