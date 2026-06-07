#  frozen_string_literal: true

require_relative '../test_helper'
require 'llm/error'
require 'llm/null'
require 'monster'
require 'race'

module LLM
  class NullTest < Minitest::Test
    def setup
      @adapter = LLM::Null.new(random: Random.new(42))
      @monster = Monster.new(speed: 30, strength: 20, stamina: 25, intelligence: 15, luck: 10)
    end

    def test_generate_identity_returns_required_keys
      identity = @adapter.generate_identity(@monster)

      assert_equal %i[name backstory battle_cry special_ability].sort, identity.keys.sort
      identity.each_value { |v| assert_kind_of String, v }
      refute_empty identity[:name]
    end

    def test_generate_identity_is_deterministic_with_seeded_random
      a = LLM::Null.new(random: Random.new(7)).generate_identity(@monster)
      b = LLM::Null.new(random: Random.new(7)).generate_identity(@monster)

      assert_equal a, b
    end

    def test_generate_identity_varies_by_dominant_attribute
      fast = Monster.new(speed: 60, strength: 10, stamina: 10, intelligence: 10, luck: 10)
      smart = Monster.new(speed: 10, strength: 10, stamina: 10, intelligence: 60, luck: 10)
      fast_id = LLM::Null.new(random: Random.new(0)).generate_identity(fast)
      smart_id = LLM::Null.new(random: Random.new(0)).generate_identity(smart)

      refute_equal fast_id[:special_ability], smart_id[:special_ability]
    end

    def test_commentate_race_returns_non_empty_string
      monsters = Array.new(3) { Monster.random }
      results = Race.call(monsters).results
      text = @adapter.commentate_race(results)

      assert_kind_of String, text
      refute_empty text.strip
    end

    def test_narrate_evolution_handles_empty_history
      assert_kind_of String, @adapter.narrate_evolution([])
    end

    def test_commentate_race_handles_empty_results
      text = @adapter.commentate_race([])

      assert_kind_of String, text
      refute_empty text.strip
    end

    def test_commentate_race_handles_missing_winner
      monster = Monster.new(speed: 20, strength: 20, stamina: 20, intelligence: 20, luck: 20)
      results = [{ placement: 2, monster: monster, total_score: 10.0 }]

      text = @adapter.commentate_race(results)

      assert_kind_of String, text
      refute_empty text.strip
    end

    def test_narrate_evolution_substitutes_when_no_drift
      avgs = { speed: 20, strength: 20, stamina: 20, intelligence: 20, luck: 20 }
      history = [
        { generation: 0, best_fitness: 5, avg_fitness: 3.0, attribute_averages: avgs },
        { generation: 3, best_fitness: 5, avg_fitness: 3.0, attribute_averages: avgs.dup }
      ]

      text = @adapter.narrate_evolution(history)

      assert_match(/no measurable drift/, text)
      refute_match(/: \./, text)
    end
  end
end
