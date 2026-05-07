# frozen_string_literal: true

require "test_helper"

class RobotLab::TestRails < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RobotLab::Rails::VERSION
  end
end
