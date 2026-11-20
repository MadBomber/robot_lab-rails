# frozen_string_literal: true

# Runs one robot_lab generator into a destination directory. Run in a
# subprocess by generators_test.rb, because the rest of the suite stubs Rails.
#
# Usage: ruby generator_probe.rb DESTINATION GENERATOR [ARGS...]
#   GENERATOR is one of: install, robot, job

require "logger"
require "rails"
require "rails/generators"

begin
  require "rails/generators/active_record"
rescue LoadError
  $LOAD_PATH.unshift File.expand_path("stubs", __dir__)
end

require "robot_lab"
require "robot_lab/rails"
require "generators/robot_lab/install_generator"
require "generators/robot_lab/robot_generator"
require "generators/robot_lab/job_generator"

destination, generator, *args = ARGV

generators = {
  "install" => RobotLab::Generators::InstallGenerator,
  "robot"   => RobotLab::Generators::RobotGenerator,
  "job"     => RobotLab::Generators::JobGenerator
}

generators.fetch(generator).start(args, destination_root: destination)
