# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"

# Runs the generators for real, in a subprocess (the rest of the suite stubs
# Rails), and inspects the files they write.
class RobotLab::GeneratorsTest < Minitest::Test
  PROBE = File.expand_path("../support/generator_probe.rb", __dir__)

  def setup
    @destination = Dir.mktmpdir("robot_lab_rails_generators")
  end

  def teardown
    FileUtils.remove_entry(@destination)
  end

  # ── robot_lab:install ────────────────────────────────────────────────────────

  def test_install_creates_every_documented_file
    generate("install")

    assert_generated "config/initializers/robot_lab.rb"
    assert_generated "app/models/robot_lab_thread.rb"
    assert_generated "app/models/robot_lab_result.rb"
    assert_generated "app/jobs/robot_run_job.rb"
    assert_generated "app/robots"
    assert_generated "app/tools"
    assert_equal 1, migrations.size, "expected exactly one timestamped migration"
  end

  def test_install_migration_creates_both_tables
    generate("install")
    migration = File.read(migrations.first)

    assert_match(/\A\d+_create_robot_lab_tables\.rb\z/, File.basename(migrations.first))
    assert_includes migration, "create_table :robot_lab_threads"
    assert_includes migration, "create_table :robot_lab_results"
  end

  def test_install_skip_migration_skips_migration_and_models
    generate("install", "--skip-migration")

    assert_empty migrations
    refute_generated "app/models/robot_lab_thread.rb"
    refute_generated "app/models/robot_lab_result.rb"
    assert_generated "app/jobs/robot_run_job.rb"
  end

  def test_install_skip_job_skips_the_job
    generate("install", "--skip-job")

    refute_generated "app/jobs/robot_run_job.rb"
    assert_equal 1, migrations.size
  end

  def test_generated_initializer_is_valid_ruby_and_wires_the_logger
    generate("install", "--skip-migration")
    path = generated("config/initializers/robot_lab.rb")

    assert_includes File.read(path), "RobotLab.config.logger = Rails.logger"
    assert system(RbConfig.ruby, "-c", path, out: File::NULL, err: File::NULL)
  end

  # ── robot_lab:robot ──────────────────────────────────────────────────────────

  def test_robot_generates_factory_robot_and_test
    generate("robot", "Support")
    robot = File.read(generated("app/robots/support_robot.rb"))

    assert_includes robot, "class SupportRobot\n"
    assert_includes robot, 'name: "support"'
    assert_includes robot, 'description: "A helpful Support robot"'
    assert_generated "test/robots/support_robot_test.rb"
  end

  def test_robot_routing_generates_robot_subclass
    generate("robot", "Router", "--routing")

    assert_includes File.read(generated("app/robots/router_robot.rb")), "class RouterRobot < RobotLab::Robot"
  end

  def test_robot_tools_accepts_space_separated_names
    generate("robot", "Support", "--tools", "order_lookup", "refund_processor")

    assert_tool_placeholders
  end

  def test_robot_tools_accepts_comma_separated_names
    generate("robot", "Support", "--tools=order_lookup,refund_processor")

    assert_tool_placeholders
  end

  # ── robot_lab:job ────────────────────────────────────────────────────────────

  def test_job_binds_to_the_matching_robot_class
    generate("job", "Support")
    job = File.read(generated("app/jobs/support_job.rb"))

    assert_includes job, "class SupportJob < RobotLab::Job"
    assert_includes job, "queue_as :default"
    assert_includes job, "robot_class SupportRobot"
  end

  def test_job_queue_option
    generate("job", "Support", "--queue", "ai")

    assert_includes File.read(generated("app/jobs/support_job.rb")), "queue_as :ai"
  end

  private

  def generate(*)
    _out, err, status = Open3.capture3(RbConfig.ruby, PROBE, @destination, *)

    assert status.success?, "generator_probe.rb failed:\n#{err}"
  end

  def generated(relative_path) = File.join(@destination, relative_path)

  def migrations = Dir[generated("db/migrate/*.rb")]

  def assert_generated(relative_path)
    assert_path_exists generated(relative_path)
  end

  def refute_generated(relative_path)
    refute_path_exists generated(relative_path)
  end

  def assert_tool_placeholders
    robot = File.read(generated("app/robots/support_robot.rb"))

    assert_includes robot, "# OrderLookup,\n"
    assert_includes robot, "# RefundProcessor,\n"
  end
end
