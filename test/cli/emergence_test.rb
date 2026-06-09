# frozen_string_literal: true

require_relative '../test_helper'
require 'cli/emergence'

module CLI
  class EmergenceTest < Minitest::Test
    def test_archetype_for_dominant_speed
      snapshot = { attribute_averages: { speed: 40, strength: 20, stamina: 20, intelligence: 10, luck: 10 } }

      assert_equal 'Sprinter', Emergence.archetype_for(snapshot)
    end

    def test_archetype_for_dominant_intelligence
      snapshot = { attribute_averages: { speed: 10, strength: 10, stamina: 20, intelligence: 50, luck: 10 } }

      assert_equal 'Sage', Emergence.archetype_for(snapshot)
    end

    def test_archetype_for_empty_snapshot
      assert_equal 'Unformed', Emergence.archetype_for({ attribute_averages: {} })
      assert_equal 'Unformed', Emergence.archetype_for({})
    end

    def test_drift_table_orders_by_attributes
      history = [
        { attribute_averages: { speed: 20.0, strength: 20.0, stamina: 20.0, intelligence: 20.0, luck: 20.0 } },
        { attribute_averages: { speed: 40.0, strength: 30.0, stamina: 15.0, intelligence: 10.0, luck: 5.0 } }
      ]

      rows = Emergence.drift_table(history)

      assert_equal(Monster::ATTRIBUTES, rows.map { |r| r[:attribute] })
      assert_in_delta(20.0, rows.first[:start])
      assert_in_delta(40.0, rows.first[:finish])
      assert_in_delta(20.0, rows.first[:delta])
      assert_in_delta(-15.0, rows.last[:delta])
    end

    def test_drift_table_empty_history
      assert_empty Emergence.drift_table([])
    end

    def test_diversity_series_extracts_gen_diversity_pairs
      history = [
        { generation: 0, diversity: 50.0 },
        { generation: 1, diversity: 30.0 },
        { generation: 2, diversity: 10.0 }
      ]

      assert_equal [[0, 50.0], [1, 30.0], [2, 10.0]], Emergence.diversity_series(history)
    end

    def test_diversity_series_handles_missing_diversity_key
      history = [{ generation: 0 }, { generation: 1, diversity: 5.0 }]

      assert_equal [[0, 0.0], [1, 5.0]], Emergence.diversity_series(history)
    end

    def test_collapsed_when_diversity_falls_below_threshold
      history = [{ generation: 0, diversity: 100.0 }, { generation: 5, diversity: 5.0 }]

      assert Emergence.collapsed?(history, threshold: 0.2)
    end

    def test_not_collapsed_when_diversity_holds
      history = [{ generation: 0, diversity: 100.0 }, { generation: 5, diversity: 80.0 }]

      refute Emergence.collapsed?(history, threshold: 0.2)
    end

    def test_collapsed_returns_false_for_single_snapshot
      refute Emergence.collapsed?([{ generation: 0, diversity: 50.0 }])
    end
  end
end
