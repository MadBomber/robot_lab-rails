# frozen_string_literal: true

module RobotLab
  module RailsIntegration
    # Base class for RobotLab background jobs.
    #
    # @example Minimal subclass using the robot_class DSL
    #   class SupportRobotJob < RobotLab::Job
    #     queue_as :default
    #     robot_class SupportRobot
    #   end
    #
    class Job < ActiveJob::Base
      def self.robot_class(klass = nil)
        klass ? @robot_class = klass : @robot_class
      end

      retry_on StandardError, wait: 5.seconds, attempts: 3
      discard_on ActiveJob::DeserializationError

      # :reek:TooManyStatements -- the job's one linear resolve/run/persist/broadcast orchestration.
      def perform(message:, robot_class: nil, thread_id: nil, **context)
        klass  = resolve_robot_class(robot_class)
        thread = setup_thread(thread_id, message)
        robot  = build_robot(klass, thread_id)
        result = robot.run(message, **context)

        if thread
          persist_result(thread, result)
          broadcast_completion(thread_id)
        end

        result
      rescue StandardError => e
        broadcast_error(thread_id, e) if thread_id
        raise
      end

      private

      # :reek:ControlParameter -- nil runtime_class means "fall back to the class-level robot_class DSL", a default, not a mode switch.
      def resolve_robot_class(runtime_class)
        klass = runtime_class || self.class.robot_class
        unless klass
          raise ArgumentError,
                "No robot class specified. Pass robot_class: to perform or set robot_class on the job class."
        end

        return klass if klass.is_a?(Class)

        klass.to_s.constantize
      end

      def setup_thread(thread_id, message)
        return nil unless thread_id

        thread = "RobotLabThread".constantize.find_or_create_by_session_id(thread_id)
        thread.update!(last_user_message: message, last_user_message_at: Time.current)
        thread
      end

      # :reek:FeatureEnvy -- factory method: the job wires its own Turbo callbacks into klass.build; the robot class cannot know them.
      def build_robot(klass, thread_id)
        if thread_id && turbo_available?
          stream_name  = "robot_lab_thread_#{thread_id}"
          on_content   = TurboStreamCallbacks.build_content_callback(stream_name: stream_name)
          on_tool_call = TurboStreamCallbacks.build_tool_call_callback(stream_name: stream_name)
          klass.build(on_content: on_content, on_tool_call: on_tool_call)
        else
          klass.build
        end
      end

      def persist_result(thread, result)
        sequence = thread.results.maximum(:sequence_number).to_i + 1
        exported = result.export

        thread.results.create!(
          robot_name:      result.robot_name,
          sequence_number: sequence,
          output_data:     exported[:output],
          tool_calls_data: exported[:tool_calls],
          stop_reason:     result.stop_reason,
          checksum:        result.checksum
        )
      end

      def broadcast_completion(thread_id)
        return unless turbo_available?

        Turbo::StreamsChannel.broadcast_replace_to(
          "robot_lab_thread_#{thread_id}",
          target: "robot_status",
          html: "<div id=\"robot_status\"><span class=\"complete\">Complete</span></div>"
        )
      end

      def broadcast_error(thread_id, error)
        return unless turbo_available?

        Turbo::StreamsChannel.broadcast_append_to(
          "robot_lab_thread_#{thread_id}",
          target: "robot_errors",
          html: "<div class=\"error\">#{ERB::Util.html_escape(error.message)}</div>"
        )
      end

      def turbo_available?
        defined?(Turbo::StreamsChannel)
      end
    end
  end
end
