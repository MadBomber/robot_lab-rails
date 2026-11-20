# frozen_string_literal: true

class ChatRobot
  SYSTEM_PROMPT = "You are a friendly assistant. Be concise."

  def self.build(**options)
    RobotLab.build(
      name: "chat",
      system_prompt: SYSTEM_PROMPT,
      local_tools: [TimeTool],
      **llm_options,
      **options
    )
  end

  # CHAT_PROVIDER and CHAT_MODEL pick the LLM, e.g. CHAT_PROVIDER=lms
  # CHAT_MODEL=openai/gpt-oss-20b for a local LM Studio model. The provider
  # has to be named here: robot_lab 0.6 only uses a provider passed to the
  # robot itself. With neither set, the robot runs on RobotLab's default model.
  def self.llm_options(env = ENV)
    { provider: env["CHAT_PROVIDER"].presence&.to_sym, model: env["CHAT_MODEL"].presence }.compact
  end
end
