# frozen_string_literal: true

require 'anthropic'
require_relative 'error'
require_relative 'prompts'

module LLM
  class Claude
    DEFAULT_MODEL = 'claude-haiku-4-5-20251001'
    IDENTITY_MAX_TOKENS = 400
    TEXT_MAX_TOKENS = 350

    def initialize(api_key: ENV.fetch('ANTHROPIC_API_KEY', nil), client: nil, model: DEFAULT_MODEL)
      @client = client || Anthropic::Client.new(api_key: api_key)
      @model = model
    end

    def generate_identity(monster)
      raw = call(LLM::Prompts.identity_user(monster), max_tokens: IDENTITY_MAX_TOKENS)
      LLM::Prompts.parse_identity(raw)
    end

    def commentate_race(race_results)
      call(LLM::Prompts.commentary_user(race_results), max_tokens: TEXT_MAX_TOKENS).strip
    end

    def narrate_evolution(history)
      call(LLM::Prompts.evolution_user(history), max_tokens: TEXT_MAX_TOKENS).strip
    end

    private

    def call(user_content, max_tokens:)
      message = @client.messages.create(
        model: @model,
        max_tokens: max_tokens,
        system_: LLM::Prompts::SYSTEM,
        messages: [{ role: 'user', content: user_content }]
      )
      extract_text(message)
    rescue LLM::Error
      raise
    rescue StandardError => e
      raise LLM::Error, "Claude API call failed: #{e.message}"
    end

    def extract_text(message)
      block = message.content.find { |b| b.type == :text } || message.content.first
      raise LLM::Error, 'Claude response had no text content' unless block.respond_to?(:text)

      block.text
    end
  end
end
