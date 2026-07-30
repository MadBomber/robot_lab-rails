# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'

  add_group 'Rails', 'lib/robot_lab/rails_integration'

  enable_coverage :branch
end

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

require 'minitest/autorun'
require 'minitest/reporters'

# rubocop:disable Style/FileOpen, Style/GlobalStdStream, Layout/LineLength
$stdout = File.open('test_output.txt', 'w').tap { |f| f.sync = true }

class TerminalSummaryReporter < Minitest::Reporters::BaseReporter
  def report
    super
    ok    = failures.zero? && errors.zero?
    badge = ok ? "\e[32mPASS\e[0m" : "\e[31mFAIL\e[0m"
    STDOUT.puts "[#{badge}] #{count} tests, #{failures} failures, #{errors} errors, #{skips} skips (#{format('%.2f', total_time)}s) — see test_output.txt"
    STDOUT.flush
  end
end
# rubocop:enable Style/FileOpen, Style/GlobalStdStream, Layout/LineLength

Minitest::Reporters.use! [
  Minitest::Reporters::DefaultReporter.new(color: false, slow_count: 5),
  TerminalSummaryReporter.new
]
