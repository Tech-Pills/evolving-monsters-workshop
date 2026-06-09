# frozen_string_literal: true

require_relative 'test_helper'
require 'population'

class PopulationTest < Minitest::Test
  def test_initialize_creates_monsters
    pop = Population.new(size: 10)

    assert_equal 10, pop.size
    pop.monsters.each do |monster|
      assert_instance_of Monster, monster
      assert_equal Monster::BUDGET, monster.genome.sum
    end
  end

  def test_default_size_is_20
    pop = Population.new

    assert_equal 20, pop.size
  end

  def test_starts_at_generation_zero
    pop = Population.new(size: 5)

    assert_equal 0, pop.generation
  end

  def test_initialize_raises_on_zero_size
    assert_raises(ArgumentError) { Population.new(size: 0) }
  end

  def test_initialize_raises_on_negative_size
    assert_raises(ArgumentError) { Population.new(size: -1) }
  end

  def test_initialize_with_size_one_works
    pop = Population.new(size: 1)

    assert_equal 1, pop.size
  end

  def test_replace_raises_on_empty_array
    pop = Population.new(size: 5)

    assert_raises(ArgumentError) { pop.replace([]) }
  end

  def test_best_returns_highest_fitness
    pop = Population.new(size: 5)
    pop.monsters.each_with_index { |m, i| m.fitness = (i + 1) * 10 }

    assert_equal 50, pop.best.fitness
  end

  def test_worst_returns_lowest_fitness
    pop = Population.new(size: 5)
    pop.monsters.each_with_index { |m, i| m.fitness = (i + 1) * 10 }

    assert_equal 10, pop.worst.fitness
  end

  def test_average_fitness
    pop = Population.new(size: 4)
    pop.monsters.each_with_index { |m, i| m.fitness = (i + 1) * 10 }

    assert_in_delta(25.0, pop.average_fitness)
  end

  def test_average_fitness_with_empty_population
    pop = Population.new(size: 1)
    pop.instance_variable_set(:@monsters, [])

    assert_in_delta(0.0, pop.average_fitness)
  end

  def test_attribute_averages
    pop = Population.new(size: 2)
    pop.instance_variable_set(:@monsters, [
                                Monster.new(speed: 40, strength: 20, stamina: 20, intelligence: 10, luck: 10),
                                Monster.new(speed: 20, strength: 40, stamina: 20, intelligence: 10, luck: 10)
                              ])

    averages = pop.attribute_averages

    assert_in_delta(30.0, averages[:speed])
    assert_in_delta(30.0, averages[:strength])
    assert_in_delta(20.0, averages[:stamina])
    assert_in_delta(10.0, averages[:intelligence])
    assert_in_delta(10.0, averages[:luck])
  end

  def test_replace_advances_generation
    pop = Population.new(size: 5)
    new_monsters = Array.new(5) { Monster.random }

    pop.replace(new_monsters)

    assert_equal 1, pop.generation
    assert_equal new_monsters, pop.monsters
  end

  def test_replace_records_history_snapshot
    pop = Population.new(size: 5)
    pop.monsters.each { |m| m.fitness = 10 }
    pop.record_snapshot

    new_monsters = Array.new(5) { Monster.random }
    new_monsters.each { |m| m.fitness = 20 }
    pop.replace(new_monsters)

    assert_equal 2, pop.history.length

    first_snapshot = pop.history[0]

    assert_equal 0, first_snapshot[:generation]
    assert_equal 10, first_snapshot[:best_fitness]

    second_snapshot = pop.history[1]

    assert_equal 1, second_snapshot[:generation]
    assert_equal 20, second_snapshot[:best_fitness]
    assert_in_delta(20.0, second_snapshot[:avg_fitness])
  end

  def test_record_snapshot_captures_current_state
    pop = Population.new(size: 5)
    pop.monsters.each { |m| m.fitness = 10 }
    pop.record_snapshot

    assert_equal 1, pop.history.length
    assert_equal 0, pop.history[0][:generation]
    assert_equal 10, pop.history[0][:best_fitness]
    assert_in_delta(10.0, pop.history[0][:avg_fitness])
  end

  def test_history_tracks_attribute_averages
    pop = Population.new(size: 5)
    pop.record_snapshot

    snapshot = pop.history[0]

    assert snapshot[:attribute_averages].key?(:speed)
    assert snapshot[:attribute_averages].key?(:strength)
    assert snapshot[:attribute_averages].key?(:stamina)
    assert snapshot[:attribute_averages].key?(:intelligence)
    assert snapshot[:attribute_averages].key?(:luck)
  end

  def test_genome_diversity_is_zero_for_clones
    pop = Population.new(size: 4)
    clone = Monster.new(speed: 40, strength: 20, stamina: 20, intelligence: 10, luck: 10)
    pop.instance_variable_set(:@monsters, Array.new(4) { Monster.from_genome(clone.genome) })

    assert_in_delta(0.0, pop.genome_diversity)
  end

  def test_genome_diversity_is_positive_for_spread_population
    pop = Population.new(size: 2)
    pop.instance_variable_set(:@monsters, [
                                Monster.new(speed: 100, strength: 0, stamina: 0, intelligence: 0, luck: 0),
                                Monster.new(speed: 0, strength: 100, stamina: 0, intelligence: 0, luck: 0)
                              ])

    assert_operator pop.genome_diversity, :>, 0.0
  end

  def test_genome_diversity_is_zero_for_single_monster
    pop = Population.new(size: 1)

    assert_in_delta(0.0, pop.genome_diversity)
  end

  def test_snapshot_includes_diversity_key
    pop = Population.new(size: 3)
    pop.record_snapshot

    assert pop.history[0].key?(:diversity)
    assert_kind_of Float, pop.history[0][:diversity]
  end

  def test_history_starts_empty
    pop = Population.new(size: 5)

    assert_empty pop.history
  end
end
