# frozen_string_literal: true

require_relative '../test_helper'
require 'llm/error'
require 'llm/prompts'
require 'monster'
require 'race'

module LLM
  class PromptsTest < Minitest::Test
    def setup
      @monster = Monster.new(speed: 30, strength: 20, stamina: 25, intelligence: 15, luck: 10)
    end

    def test_system_prompt_mentions_json
      assert_match(/JSON/i, LLM::Prompts::SYSTEM)
    end

    def test_identity_prompt_includes_all_stats
      prompt = LLM::Prompts.identity_user(@monster)

      %w[speed strength stamina intelligence luck].each do |attr|
        assert_match(/#{attr}/i, prompt)
      end
      assert_match(/30/, prompt)
      assert_match(/json/i, prompt)
      assert_match(/name/i, prompt)
      assert_match(/backstory/i, prompt)
      assert_match(/battle_cry/i, prompt)
      assert_match(/special_ability/i, prompt)
    end

    def test_commentary_prompt_includes_placements
      monsters = Array.new(3) { Monster.random }
      results = Race.call(monsters).results
      prompt = LLM::Prompts.commentary_user(results)

      assert_match(/1\.|first|placement/i, prompt)
      refute_empty prompt
    end

    def test_evolution_prompt_includes_generation_count
      history = [
        { generation: 0, best_fitness: 5, avg_fitness: 3.0,
          attribute_averages: { speed: 20, strength: 20, stamina: 20, intelligence: 20, luck: 20 } },
        { generation: 5, best_fitness: 8, avg_fitness: 5.0,
          attribute_averages: { speed: 25, strength: 22, stamina: 18, intelligence: 19, luck: 16 } }
      ]
      prompt = LLM::Prompts.evolution_user(history)

      assert_match(/5/, prompt)
      assert_match(/speed|stamina|strength|intelligence|luck/i, prompt)
    end

    def test_parse_identity_returns_required_string_fields
      raw = '{"name":"Ironclad","backstory":"a tale","battle_cry":"rawr","special_ability":"smash"}'
      result = LLM::Prompts.parse_identity(raw)

      assert_equal 'Ironclad', result[:name]
      assert_equal 'a tale', result[:backstory]
      assert_equal 'rawr', result[:battle_cry]
      assert_equal 'smash', result[:special_ability]
    end

    def test_parse_identity_strips_markdown_fences
      raw = "```json\n{\"name\":\"X\",\"backstory\":\"y\",\"battle_cry\":\"z\",\"special_ability\":\"w\"}\n```"
      result = LLM::Prompts.parse_identity(raw)

      assert_equal 'X', result[:name]
    end

    def test_parse_identity_raises_on_missing_keys
      assert_raises(LLM::Error) { LLM::Prompts.parse_identity('{"name":"X"}') }
    end

    def test_parse_identity_raises_on_invalid_json
      assert_raises(LLM::Error) { LLM::Prompts.parse_identity('not json at all') }
    end
  end
end
