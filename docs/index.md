# robot_lab-rails

Rails integration for the [RobotLab](https://github.com/MadBomber/robot_lab) LLM agent framework.

> [!CAUTION]
> This gem is under active development. APIs may change without notice.

## What it provides

- **Rails Engine** — autoloads `app/robots/` and `app/tools/` in your application
- **Railtie** — wires `RobotLab.config` to `Rails.logger` and applies Rails-specific configuration
- **`RobotLab::Job`** — ActiveJob base class with Turbo Stream streaming, thread persistence, and error broadcasting
- **Generators** — `rails generate robot_lab:install`, `robot_lab:robot NAME`, `robot_lab:job NAME`

## Installation

Add to your Gemfile:

```ruby
gem "robot_lab"
gem "robot_lab-rails"
```

Then run the installer:

```bash
rails generate robot_lab:install
rails db:migrate
```

## Quick Example

```ruby
# app/robots/support_robot.rb
class SupportRobot
  SYSTEM_PROMPT = "You are a helpful support assistant."

  def self.build(**options)
    RobotLab.build(
      name: "support",
      system_prompt: SYSTEM_PROMPT,
      **options
    )
  end
end

# app/jobs/support_robot_job.rb
class SupportRobotJob < RobotLab::Job
  queue_as :default
  robot_class SupportRobot
end

# From a controller:
SupportRobotJob.perform_later(
  message:   params[:message],
  thread_id: session[:id]
)
```

## Turbo Stream Streaming

When `thread_id:` is provided and `turbo-rails` is installed, streaming token output is broadcast automatically:

```erb
<%= turbo_stream_from "robot_lab_thread_#{session[:id]}" %>
<div id="robot_response"></div>
<div id="robot_status"></div>
```

## Links

- [Rails Integration Guide](guides/rails-integration.md)
- [Rails Application Example](examples/rails-application.md)
- [RobotLab Core](https://github.com/MadBomber/robot_lab)
- [RubyGems](https://rubygems.org/gems/robot_lab-rails)
