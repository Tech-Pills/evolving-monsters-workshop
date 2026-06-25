# frozen_string_literal: true

require 'json'
require_relative 'error'

module LLM
  module Prompts
    SYSTEM = <<~PROMPT.strip
      You are a creative fantasy game narrator for a monster-racing arena.
      Generate vivid, fun, slightly mythic monster identities and play-by-play.
      When asked for an identity, respond with VALID JSON ONLY matching the
      requested schema (no prose, no markdown code fences).
      For commentary and narration, respond in 2-4 short sentences of plain text.
    PROMPT

    REQUIRED_IDENTITY_KEYS = %i[name backstory battle_cry special_ability].freeze

    IDENTITY_SCHEMA = {
      type: 'object',
      properties: {
        name: { type: 'string' },
        backstory: { type: 'string' },
        battle_cry: { type: 'string' },
        special_ability: { type: 'string' }
      },
      required: REQUIRED_IDENTITY_KEYS.map(&:to_s),
      additionalProperties: false
    }.freeze

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

      diversity_line = ''
      if first[:diversity] && last[:diversity]
        diversity_line = "\nGenome diversity drift: #{first[:diversity].round(2)} -> #{last[:diversity].round(2)}."
      end

      <<~PROMPT.strip
        A monster population evolved across #{last[:generation] - first[:generation]} generations.
        Attribute averages drift: #{drift}.#{diversity_line}

        In 2-3 sentences, narrate the population's evolutionary arc.
      PROMPT
    end

    def summary_user(history, drift, config_line)
      first = history.first
      last = history.last
      generations = last[:generation] - first[:generation]
      diversity_traj = downsample(history.map { |h| h[:diversity]&.round(2) }.compact)

      drift_lines = drift.map do |row|
        "  #{row[:attribute]}: #{row[:start].round(1)} -> #{row[:finish].round(1)} (#{format('%+.1f', row[:delta])})"
      end.join("\n")

      <<~PROMPT.strip
        Analyze a #{generations}-generation GA run on a 5-attribute monster population
        (100-point budget per monster, fitness = race placement across 5 stages).

        Configuration: #{config_line}

        Genome diversity per generation: #{diversity_traj.join(', ')}

        Attribute drift across the run (start -> finish):
        #{drift_lines}

        Describe what happened in 3-4 sentences using GA vocabulary like
        convergence, diversity collapse, archetype emergence, plateau, drift.
        You may explain the causal relationship between the configuration and
        the observed behavior (e.g., "tight selection pressure produced rapid
        convergence"). Do NOT recommend specific parameter values or suggest
        what to try next — that is left to the reader.
      PROMPT
    end

    def downsample(values, max_points: 50)
      return values if values.length <= max_points

      step = (values.length.to_f / max_points).ceil
      ([values.first] + values.each_slice(step).map(&:first) + [values.last]).uniq
    end

    def parse_identity(raw)
      data = JSON.parse(raw)
      REQUIRED_IDENTITY_KEYS.to_h { |k| [k, data.fetch(k.to_s).to_s] }
    rescue JSON::ParserError => e
      raise LLM::Error, "identity JSON parse failed: #{e.message}"
    end
  end
end
