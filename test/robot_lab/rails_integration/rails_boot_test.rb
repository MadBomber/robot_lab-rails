# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "json"
require "open3"
require "rbconfig"
require "tmpdir"

# Boots a real (minimal) Rails application in a subprocess. The rest of the
# suite stubs Rails and ActiveJob, which is exactly how the bugs covered here
# went unnoticed.
class RobotLab::RailsIntegration::RailsBootTest < Minitest::Test
  PROBE = File.expand_path("../../support/rails_probe.rb", __dir__)

  def setup
    @app_root = Dir.mktmpdir("robot_lab_rails_probe")
    write_app_file("app/robots/probe_robot.rb", "class ProbeRobot; end\n")
    write_app_file("app/tools/probe_tool.rb", "class ProbeTool; end\n")
  end

  def teardown
    FileUtils.remove_entry(@app_root)
  end

  def test_robot_lab_job_is_the_public_name_of_the_job_base_class
    report = probe

    assert_equal true, report["job_alias"]
    assert_equal "ActiveJob::Base", report["job_superclass"]
    assert_equal true, report["extension_loaded"]
  end

  def test_boots_without_default_model_or_provider
    report = probe

    assert_equal true, report["logger_is_rails"]
    refute_empty report["model"]
  end

  def test_default_model_and_provider_reach_the_robot_lab_config
    report = probe("app-model", "lms")

    assert_equal "app-model", report["model"]
    assert_equal "lms", report["provider"]
  end

  def test_autoload_paths_point_at_the_application_not_the_gem
    report   = probe
    paths    = report["autoload_paths"]
    gem_root = File.expand_path("../../..", __dir__)

    assert_includes paths, File.join(File.realpath(@app_root), "app", "robots")
    assert_includes paths, File.join(File.realpath(@app_root), "app", "tools")
    refute_includes paths, File.join(gem_root, "app", "robots")
    refute_includes paths, File.join(gem_root, "app", "tools")
    assert_equal "ProbeRobot", report["robot_autoloaded"]
    assert_equal "ProbeTool", report["tool_autoloaded"]
  end

  private

  def write_app_file(relative_path, content)
    path = File.join(@app_root, relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def probe(*)
    out, err, status = Open3.capture3(RbConfig.ruby, PROBE, File.realpath(@app_root), *)

    assert status.success?, "rails_probe.rb failed:\n#{err}"
    JSON.parse(out)
  end
end
