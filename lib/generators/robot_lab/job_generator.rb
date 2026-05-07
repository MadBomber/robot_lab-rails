# frozen_string_literal: true

require "rails/generators"

module RobotLab
  module Generators
    class JobGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      class_option :queue, type: :string, default: "default",
                           desc: "ActiveJob queue name"

      def create_job_file
        template "robot_job.rb.tt", "app/jobs/#{file_name}_job.rb"
      end

      private

      def queue_name
        options[:queue]
      end

      def robot_class_name
        "#{class_name}Robot"
      end
    end
  end
end
