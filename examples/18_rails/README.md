# RobotLab Rails 8 Demo

Minimal Rails 8 app that demonstrates RobotLab's full Rails integration:

- **ChatRobot** with a custom `TimeTool`
- **RobotRunJob** for background execution
- **Turbo Stream** token streaming to the browser
- **Persistence** via `RobotLabThread` + `RobotLabResult`
- **Conversation history** on page reload

## Prerequisites

- Ruby 4.0.9+ (required by `robot_lab-rails`)
- An LLM to talk to — one of:
  - `ANTHROPIC_API_KEY` in your env (the default model is RobotLab's configured default, a Claude model)
  - a local [LM Studio](https://lmstudio.ai) server: `CHAT_PROVIDER=lms CHAT_MODEL=openai/gpt-oss-20b`
  - the Claude Code CLI, logged in: `CHAT_PROVIDER=claude_code CHAT_MODEL=sonnet-5.5`
  - any other hosted model RubyLLM knows, with that provider's API key: `CHAT_MODEL=gpt-4o-mini`
- `robot_lab-rails` newer than 0.6.1 (0.6.1 does not define `RobotLab::Job`, which `RobotRunJob` inherits from)

## Setup

```bash
cd examples/18_rails
bin/setup
```

## Run

```bash
bin/dev
# or, on a local LM Studio model:
CHAT_PROVIDER=lms CHAT_MODEL=openai/gpt-oss-20b bin/dev
# Open http://localhost:3000
```

`CHAT_PROVIDER` / `CHAT_MODEL` are read by `ChatRobot` (`app/robots/chat_robot.rb`).

## Try It

1. Type "What time is it?" — the robot will call TimeTool and stream the response
2. Refresh the page — conversation history is preserved
3. Check `db/development.sqlite3` to see persisted threads and results

## Architecture

```
app/
  controllers/chat_controller.rb  — index + create actions
  views/chat/index.html.erb       — form + Turbo Stream subscription
  models/                         — RobotLabThread, RobotLabResult
  robots/chat_robot.rb            — robot factory with system prompt + tool
  tools/time_tool.rb              — simple RobotLab::Tool subclass
  jobs/robot_run_job.rb           — enqueues robot.run() with Turbo callbacks
```

No Redis, no Solid Queue, no asset pipeline. Uses `:async` adapters for both ActiveJob and ActionCable.
