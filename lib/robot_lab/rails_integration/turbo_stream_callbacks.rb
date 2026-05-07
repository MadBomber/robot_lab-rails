# frozen_string_literal: true

module RobotLab
  module RailsIntegration
    # Stateless utility module that builds callback Procs for Turbo Stream broadcasting.
    #
    # Safe to require even without turbo-rails installed — checks at call time
    # via `defined?(Turbo::StreamsChannel)`.
    #
    module TurboStreamCallbacks
      def self.available?
        defined?(Turbo::StreamsChannel) ? true : false
      end

      def self.build_content_callback(stream_name:, target: "robot_response")
        ->(chunk) {
          content = chunk.respond_to?(:content) ? chunk.content : chunk.to_s
          return unless content && TurboStreamCallbacks.available?

          Turbo::StreamsChannel.broadcast_append_to(
            stream_name,
            target: target,
            html: ERB::Util.html_escape(content)
          )
        }
      end

      def self.build_tool_call_callback(stream_name:, target: "robot_tools")
        ->(tool_call) {
          return unless TurboStreamCallbacks.available?

          name = tool_call.respond_to?(:name) ? tool_call.name : tool_call.to_s
          Turbo::StreamsChannel.broadcast_append_to(
            stream_name,
            target: target,
            html: "<span class=\"tool-badge\">Using: #{ERB::Util.html_escape(name)}</span>"
          )
        }
      end
    end
  end
end
