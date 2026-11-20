# Rails Application

Full Rails integration with Action Cable and background jobs.

## Overview

This example demonstrates integrating RobotLab into a Rails application with real-time streaming via Action Cable, background job processing, and persistent conversation history.

## Setup

### 1. Add to Gemfile

```ruby
# Gemfile
gem "robot_lab"
gem "robot_lab-rails"

# The examples below use the Claude Code agent as the model. Its provider
# registers itself as :claude_code when required.
gem "ruby_llm-providers-claude_code", require: "ruby_llm/providers/claude_code"

# Optional: local models served by LM Studio (registers the :lms provider,
# defaults to http://localhost:1234/v1, no API key needed).
gem "ruby_llm-providers-lms", require: "ruby_llm/providers/lms"
```

The `claude_code` provider runs the Claude Code CLI (`claude`), which must be on your `PATH` and logged in. To use a hosted API instead, skip that gem and set a provider such as `anthropic` with its API key.

With the LM Studio gem loaded, a robot can run on a local model by naming the provider when it is built:

```ruby
RobotLab.build(
  name: "local_bot",
  provider: :lms,
  model: "qwen/qwen3.8-27b",
  system_prompt: "You are a helpful assistant."
)
```

### 2. Run Generator

```bash
rails generate robot_lab:install
```

This creates:

- `config/initializers/robot_lab.rb`
- `app/robots/` directory
- `app/tools/` directory
- Database migration for conversation history (`db/migrate/*_create_robot_lab_tables.rb`)
- `app/models/robot_lab_thread.rb` and `app/models/robot_lab_result.rb`
- `app/jobs/robot_run_job.rb`

### 3. Run Migrations

```bash
rails db:migrate
```

## Configuration

RobotLab uses MywayConfig for configuration. Settings are not written in a `RobotLab.configure` block (that method only yields the config object, for runtime attributes such as the logger). Instead, configuration is loaded automatically from multiple sources in priority order:

1. Bundled defaults (`lib/robot_lab/config/defaults.yml`)
2. Environment-specific overrides (development, test, production)
3. XDG user config (`~/.config/robot_lab/robot_lab.yml`)
4. Project config (`./config/robot_lab.yml`)
5. Environment variables (`ROBOT_LAB_*` prefix)

### Config File

In a Rails app this file is keyed by Rails environment, and only the section matching `Rails.env` is read. A top-level `defaults:` section is ignored, so share common settings with a YAML anchor. Write values as plain strings (`log_level: debug`); YAML symbols such as `:debug` are rejected when the app boots.

```yaml
# config/robot_lab.yml
ruby_llm_shared: &ruby_llm
  provider: claude_code
  model: sonnet-5.5
  anthropic_api_key: <%= ENV['ANTHROPIC_API_KEY'] %>

development:
  ruby_llm:
    <<: *ruby_llm
    log_level: debug

production:
  ruby_llm:
    <<: *ruby_llm
    request_timeout: 180
    max_retries: 5
```

The configured `model` is used by every robot built without a `model:` of its own. The configured `provider` is not applied yet: robot_lab 0.6 only uses a provider passed to the robot itself, so the robot below names it in `RobotLab.build`.

### Environment Variables

```bash
# Provider API keys
ROBOT_LAB_RUBY_LLM__ANTHROPIC_API_KEY=sk-ant-...
ROBOT_LAB_RUBY_LLM__OPENAI_API_KEY=sk-...

# Model configuration
ROBOT_LAB_RUBY_LLM__PROVIDER=claude_code
ROBOT_LAB_RUBY_LLM__MODEL=sonnet-5.5
ROBOT_LAB_RUBY_LLM__REQUEST_TIMEOUT=120
```

### Accessing Configuration

```ruby
# Read configuration values at runtime
RobotLab.config.ruby_llm.provider         #=> "claude_code"
RobotLab.config.ruby_llm.model            #=> "sonnet-5.5"
RobotLab.config.ruby_llm.request_timeout  #=> 120

# The logger defaults to Rails.logger when running in Rails
RobotLab.config.logger  #=> Rails.logger
```

### Rails Engine and Railtie

RobotLab provides both a Rails Engine (`RobotLab::RailsIntegration::Engine`) and a Railtie (`RobotLab::RailsIntegration::Railtie`). These are loaded automatically when Rails is detected. The Engine isolates the RobotLab namespace and adds your application's `app/robots` and `app/tools` to the autoload paths. The Railtie points `RobotLab.config.logger` at `Rails.logger` and registers the generators.

## Models

```ruby
# app/models/conversation_thread.rb
class ConversationThread < ApplicationRecord
  belongs_to :user
  has_many :messages, class_name: "ConversationMessage", dependent: :destroy

  validates :external_id, presence: true, uniqueness: true

  def self.find_or_create_for(user:, external_id: nil)
    external_id ||= SecureRandom.uuid
    find_or_create_by!(user: user, external_id: external_id)
  end
end

# app/models/conversation_message.rb
class ConversationMessage < ApplicationRecord
  belongs_to :thread, class_name: "ConversationThread"

  validates :role, presence: true
  validates :content, presence: true

  scope :ordered, -> { order(:position) }
end
```

## Robot Definitions

Robots are built using `RobotLab.build` with named parameters. Tools are Ruby classes that inherit from `RubyLLM::Tool`.

```ruby
# app/tools/get_user_info_tool.rb
class GetUserInfoTool < RubyLLM::Tool
  description "Get information about the current user"

  parameter :user_id, type: :integer, description: "The user ID to look up"

  def execute(user_id:)
    user = User.find(user_id)
    {
      name: user.name,
      email: user.email,
      plan: user.subscription&.plan || "free",
      member_since: user.created_at.to_date.to_s
    }
  rescue ActiveRecord::RecordNotFound
    { error: "User not found" }
  end
end

# app/tools/get_orders_tool.rb
class GetOrdersTool < RubyLLM::Tool
  description "Get user's recent orders"

  parameter :user_id, type: :integer, description: "The user ID"
  parameter :limit, type: :integer, description: "Number of orders to return (default 5)", required: false

  def execute(user_id:, limit: 5)
    orders = Order.where(user_id: user_id)
                  .order(created_at: :desc)
                  .limit(limit)

    orders.map do |order|
      {
        id: order.external_id,
        status: order.status,
        total: order.total.to_f,
        created_at: order.created_at.iso8601
      }
    end
  end
end

# app/tools/create_ticket_tool.rb
class CreateTicketTool < RubyLLM::Tool
  description "Create a support ticket"

  parameter :user_id, type: :integer, description: "The user ID"
  parameter :subject, type: :string, description: "Ticket subject"
  parameter :description, type: :string, description: "Ticket description"
  parameter :priority, type: :string, description: "Priority level: low, medium, or high", required: false

  def execute(user_id:, subject:, description:, priority: "medium")
    ticket = SupportTicket.create!(
      user_id: user_id,
      subject: subject,
      description: description,
      priority: priority
    )

    {
      success: true,
      ticket_id: ticket.external_id,
      message: "Ticket created successfully"
    }
  rescue => e
    { success: false, error: e.message }
  end
end
```

```ruby
# app/robots/support_robot.rb
class SupportRobot
  def self.build(user_id:)
    RobotLab.build(
      name: "support",
      provider: :claude_code,
      model: "sonnet-5.5",
      system_prompt: <<~PROMPT,
        You are a helpful customer support assistant for our company.
        Be friendly, professional, and thorough in your responses.
        If you need to look up information, use the available tools.
        The current user ID is #{user_id}.
      PROMPT
      local_tools: [GetUserInfoTool, GetOrdersTool, CreateTicketTool]
    )
  end
end
```

## Network Configuration

Networks use `create_network` with a block DSL that defines tasks and their dependencies:

```ruby
# app/robots/support_network.rb
class SupportNetwork
  def self.build(user_id:)
    support = SupportRobot.build(user_id: user_id)

    RobotLab.create_network(name: "support_network") do
      task :support, support, depends_on: :none
    end
  end
end
```

## Service Object

```ruby
# app/services/chat_service.rb
class ChatService
  def initialize(user:, thread_id: nil)
    @user = user
    @thread_id = thread_id
  end

  def call(message:)
    robot = SupportRobot.build(user_id: @user.id)
    result = robot.run(message)

    {
      response: result.last_text_content,
      has_tool_calls: result.has_tool_calls?
    }
  end
end
```

## Controller

```ruby
# app/controllers/api/chats_controller.rb
module Api
  class ChatsController < ApplicationController
    before_action :authenticate_user!

    def create
      service = ChatService.new(
        user: current_user,
        thread_id: params[:thread_id]
      )

      result = service.call(message: params[:message])

      render json: {
        response: result[:response]
      }
    end
  end
end
```

## Action Cable Integration

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def receive(data)
    ChatJob.perform_later(
      user_id: current_user.id,
      thread_id: data["thread_id"],
      message: data["message"]
    )
  end
end

# app/jobs/chat_job.rb
class ChatJob < ApplicationJob
  queue_as :default

  def perform(user_id:, thread_id:, message:)
    user = User.find(user_id)
    robot = SupportRobot.build(user_id: user.id)

    result = robot.run(message)

    ChatChannel.broadcast_to(
      user,
      type: "complete",
      content: result.last_text_content
    )
  end
end
```

## Frontend (Stimulus)

```javascript
// app/javascript/controllers/chat_controller.js
import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["messages", "input", "response"]

  connect() {
    this.consumer = createConsumer()
    this.channel = this.consumer.subscriptions.create("ChatChannel", {
      received: (data) => this.handleMessage(data)
    })
  }

  disconnect() {
    this.channel?.unsubscribe()
  }

  send() {
    const message = this.inputTarget.value.trim()
    if (!message) return

    this.appendMessage("user", message)
    this.inputTarget.value = ""

    // Create response container
    this.currentResponse = document.createElement("div")
    this.currentResponse.className = "message assistant"
    this.messagesTarget.appendChild(this.currentResponse)

    this.channel.send({
      message: message,
      thread_id: this.threadId
    })
  }

  handleMessage(data) {
    switch (data.type) {
      case "complete":
        this.currentResponse.textContent = data.content
        break
    }
  }

  appendMessage(role, content) {
    const div = document.createElement("div")
    div.className = `message ${role}`
    div.textContent = content
    this.messagesTarget.appendChild(div)
  }
}
```

## View

```erb
<!-- app/views/chats/show.html.erb -->
<div data-controller="chat">
  <div class="messages" data-chat-target="messages">
    <!-- Messages appear here -->
  </div>

  <form data-action="submit->chat#send">
    <input type="text"
           data-chat-target="input"
           placeholder="Type a message..."
           autocomplete="off">
    <button type="submit">Send</button>
  </form>
</div>
```

## Running

```bash
# Install dependencies
bundle install
yarn install

# Setup database
rails db:migrate

# Set API key (or configure via config/robot_lab.yml)
export ANTHROPIC_API_KEY="your-key"

# Start server
bin/dev
```

## Key Concepts

1. **Robot Factory**: `RobotLab.build(name:, system_prompt:, local_tools:, ...)` creates robot instances
2. **MywayConfig**: Configuration via YAML files and environment variables; `RobotLab.configure` is only for runtime attributes such as the logger
3. **`robot.run("message")`**: Send a message as a positional string argument
4. **`result.last_text_content`**: Extract the response text from a `RobotResult`
5. **Memory**: Robots have `robot.memory` for key-value storage; networks share memory
6. **Tools**: Ruby classes inheriting from `RubyLLM::Tool`, passed via `local_tools:`
7. **Action Cable**: Real-time streaming to browser
8. **Background Jobs**: Non-blocking processing

## See Also

- [Rails Integration Guide](../guides/rails-integration.md)
- [Streaming Guide](https://madbomber.github.io/robot_lab/guides/streaming/)
