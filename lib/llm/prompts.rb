# frozen_string_literal: true

require 'json'
require_relative 'error'

module LLM
  module Prompts
    SYSTEM = <<~PROMPT.strip
      You are a creative fantasy game narrator for a monster-racing arena.
      Generate vivid, fun, slightly mythic monster identities and play-by-play.
      When asked for an identity, respond with VALID JSON ONLY (no prose, no
      markdown code fences) matching the schema given in the user message.
      For commentary and narration, respond in 2-4 short sentences of plain text.
    PROMPT

    REQUIRED_IDENTITY_KEYS = %i[name backstory battle_cry special_ability].freeze

    module_function

    def identity_user(monster)
      <<~PROMPT.strip
        Generate an identity for this monster. Respond with JSON only.

        Stats (sum to 100):
          speed: #{monster.speed}
          strength: #{monster.strength}
          stamina: #{monster.stamina}
          intelligence: #{monster.intelligence}
          luck: #{monster.luck}
        Dominant attribute: #{monster.dominant_attribute}

        JSON schema:
        {
          "name": "<2-4 word fantasy name>",
          "backstory": "<one-sentence origin story>",
          "battle_cry": "<one short line>",
          "special_ability": "<2-4 word ability tied to the dominant attribute>"
        }
      PROMPT
    end

    def commentary_user(race_results)
      lines = race_results.sort_by { |r| r[:placement] }.first(5).map do |r|
        name = r[:monster].name
        label = name && !name.empty? ? name : 'Unnamed'
        "#{r[:placement]}. #{label} (#{r[:total_score].round})"
      end
      <<~PROMPT.strip
        A 5-stage monster race just finished. Final placements (top 5):
        #{lines.join("\n")}

        Write 2-3 sentences of energetic play-by-play commentary on the result.
      PROMPT
    end

    def evolution_user(history)
      first = history.first
      last = history.last
      first_avgs = first[:attribute_averages]
      last_avgs = last[:attribute_averages]
      drift = first_avgs.keys.map { |k| "#{k}: #{first_avgs[k].round(1)} -> #{last_avgs[k].round(1)}" }.join(', ')
      <<~PROMPT.strip
        A monster population evolved across #{last[:generation] - first[:generation]} generations.
        Attribute averages drift: #{drift}.

        In 2-3 sentences, narrate the population's evolutionary arc.
      PROMPT
    end

    def parse_identity(raw)
      json = strip_fences(raw)
      data = JSON.parse(json)
      missing = REQUIRED_IDENTITY_KEYS.reject { |k| data.key?(k.to_s) }
      raise LLM::Error, "identity JSON missing keys: #{missing.join(', ')}" unless missing.empty?

      REQUIRED_IDENTITY_KEYS.to_h { |k| [k, data.fetch(k.to_s).to_s] }
    rescue JSON::ParserError => e
      raise LLM::Error, "identity JSON parse failed: #{e.message}"
    end

    def strip_fences(raw)
      raw.to_s.strip.sub(/\A```(?:json)?\s*/, '').sub(/\s*```\z/, '')
    end
    private_class_method :strip_fences
  end
end
