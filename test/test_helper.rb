# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Stub RobotLab::Error so rails_integration files can reference it
# without requiring the full robot_lab gem.
module RobotLab
  Error = StandardError unless defined?(Error)
end

require "active_support/isolated_execution_state"
require "active_support/core_ext/numeric/time"
require "active_support/core_ext/string/inflections"

unless defined?(ActiveJob::Base)
  module ActiveJob
    class DeserializationError < StandardError; end
    class Base
      def self.retry_on(*) = nil
      def self.discard_on(*) = nil
      def self.queue_as(*) = nil
    end
  end
end

unless Time.respond_to?(:current)
  class << Time
    def current = now
  end
end

require "robot_lab/rails/version"
require "robot_lab/rails_integration/turbo_stream_callbacks"
require "robot_lab/rails_integration/job"

require "minitest/autorun"
