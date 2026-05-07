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

This creates:

- `config/initializers/robot_lab.rb` — configuration
- `app/robots/` — directory for your robots
- Database tables for conversation history

## Background Jobs

`RobotLab::Job` is an `ActiveJob::Base` subclass that handles the full robot-run lifecycle: robot class resolution, Turbo Stream wiring, thread-record persistence, and completion/error broadcasting.

**Generic job** (robot class supplied at enqueue time):

```bash
rails generate robot_lab:install   # creates app/jobs/robot_run_job.rb
```

```ruby
# app/jobs/robot_run_job.rb  (generated)
class RobotRunJob < RobotLab::Job
  queue_as :default
end

# Enqueue from a controller:
RobotRunJob.perform_later(
  robot_class: "SupportRobot",
  message:     params[:message],
  thread_id:   session_id
)
```

**Dedicated job** (robot class bound at the class level via DSL):

```bash
rails generate robot_lab:job Support            # binds to SupportRobot, queue: default
rails generate robot_lab:job Support --queue ai # custom queue
```

```ruby
# app/jobs/support_job.rb  (generated)
class SupportJob < RobotLab::Job
  queue_as :default
  robot_class SupportRobot
end

# Enqueue (no robot_class: needed):
SupportJob.perform_later(message: params[:message], thread_id: session_id)
```

Omitting `thread_id` runs the robot in fire-and-forget mode — no persistence, no broadcasting.

## Turbo Stream Streaming

When `thread_id` is provided and [turbo-rails](https://github.com/hotwired/turbo-rails) is installed, `RobotLab::Job` automatically:

- Wires `on_content` / `on_tool_call` Turbo Stream callbacks so the UI updates in real time
- Broadcasts a **completion** event to `"robot_lab_thread_#{thread_id}"` when the run finishes
- Broadcasts an **error** event (HTML-escaped) if the job raises

In your view:

```erb
<%= turbo_stream_from "robot_lab_thread_#{session[:id]}" %>
<div id="robot_response"></div>
<div id="robot_status"></div>
```

## Links

- [Rails Integration Guide](https://madbomber.github.io/robot_lab-rails/guides/rails-integration)
- [Rails Application Example](https://madbomber.github.io/robot_lab-rails/examples/rails-application)
- [RobotLab Core](https://github.com/MadBomber/robot_lab)
- [RubyGems](https://rubygems.org/gems/robot_lab-rails)

## License

MIT License - Copyright (c) 2025 Dewayne VanHoozer

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MadBomber/robot_lab-rails.
