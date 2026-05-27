# frozen_string_literal: true

require_relative 'test_helper'
require 'monster'

class MonsterTest < Minitest::Test
  def test_initialize_with_attributes
    monster = Monster.new(speed: 30, strength: 20, stamina: 25, intelligence: 15, luck: 10)

    assert_equal 30, monster.speed
    assert_equal 20, monster.strength
    assert_equal 25, monster.stamina
    assert_equal 15, monster.intelligence
    assert_equal 10, monster.luck
    assert_equal 0, monster.fitness
  end

  def test_genome_returns_attribute_array
    monster = Monster.new(speed: 30, strength: 20, stamina: 25, intelligence: 15, luck: 10)

    assert_equal [30, 20, 25, 15, 10], monster.genome
  end

  def test_to_h_returns_attribute_hash
    monster = Monster.new(speed: 30, strength: 20, stamina: 25, intelligence: 15, luck: 10)

    expected = { speed: 30, strength: 20, stamina: 25, intelligence: 15, luck: 10 }

    assert_equal expected, monster.to_h
    assert_equal Monster::ATTRIBUTES, monster.to_h.keys
  end

  def test_random_creates_monster_with_budget
    monster = Monster.random

    assert_equal Monster::BUDGET, monster.genome.sum
    monster.genome.each do |value|
      assert_operator value, :>=, 0, "Attribute value #{value} should be >= 0"
    end
  end

  def test_random_produces_different_monsters
    monsters = Array.new(10) { Monster.random }
    genomes = monsters.map(&:genome).uniq

    assert_operator genomes.length, :>, 1, 'Expected different random monsters, got all identical'
  end

  def test_random_genome_respects_budget
    10.times do
      monster = Monster.random

      assert_equal Monster::BUDGET, monster.genome.sum
    end
  end

  def test_random_genome_has_correct_length
    assert_equal Monster::ATTRIBUTES.length, Monster.random.genome.length
  end

  def test_from_genome_creates_monster
    genome = [30, 20, 25, 15, 10]
    monster = Monster.from_genome(genome)

    assert_equal genome, monster.genome
  end

  def test_from_genome_normalizes_to_budget
    genome = [60, 40, 50, 30, 20]

    _out, err = capture_io { @monster = Monster.from_genome(genome) }

    assert_equal Monster::BUDGET, @monster.genome.sum
    assert_includes err, 'Normalizing'
  end

  def test_from_genome_preserves_proportions
    genome = [60, 40, 50, 30, 20]

    _out, _err = capture_io { @monster = Monster.from_genome(genome) }

    assert_equal 30, @monster.speed
    assert_equal 20, @monster.strength
    assert_equal 25, @monster.stamina
    assert_equal 15, @monster.intelligence
    assert_equal 10, @monster.luck
  end

  def test_from_genome_raises_on_too_few_elements
    assert_raises(ArgumentError) { Monster.from_genome([50, 50]) }
  end

  def test_from_genome_raises_on_too_many_elements
    assert_raises(ArgumentError) { Monster.from_genome([20, 20, 20, 20, 10, 10]) }
  end

  def test_from_genome_raises_on_empty_array
    assert_raises(ArgumentError) { Monster.from_genome([]) }
  end

  def test_from_genome_handles_already_correct_sum
    genome = [20, 20, 20, 20, 20]
    monster = Monster.from_genome(genome)

    assert_equal genome, monster.genome
  end

  def test_normalize_genome_largest_remainder
    result = Monster.normalize_genome([1, 1, 1], target: 100)

    assert_equal 100, result.sum
    assert_equal [33, 33, 34], result.sort, 'Expected two 33s and one 34'
  end

  def test_normalize_genome_no_negative_values
    genome = [0, 0, 100, 0, 0]
    result = Monster.normalize_genome(genome)

    assert_equal Monster::BUDGET, result.sum
    result.each do |value|
      assert_operator value, :>=, 0, "Attribute value #{value} should be >= 0"
    end
  end

  def test_normalize_genome_zero_sum_distributes_evenly
    genome = [0, 0, 0, 0, 0]
    result = Monster.normalize_genome(genome)

    assert_equal Monster::BUDGET, result.sum
    result.each do |value|
      assert_operator value, :>=, 20, 'Each value should be at least 20 for even distribution'
    end
  end

  def test_normalize_genome_floats_summing_to_target
    genome = [20.6, 20.6, 19.6, 19.6, 19.6]
    result = Monster.normalize_genome(genome)

    assert_equal Monster::BUDGET, result.sum
    result.each do |value|
      assert_kind_of Integer, value
    end
  end

  def test_dominant_attribute
    monster = Monster.new(speed: 40, strength: 20, stamina: 20, intelligence: 10, luck: 10)

    assert_equal :speed, monster.dominant_attribute
  end

  def test_fitness_is_mutable
    monster = Monster.random
    monster.fitness = 42

    assert_equal 42, monster.fitness
  end

  def test_identity_attributes_are_mutable
    monster = Monster.random
    monster.name = 'Blaze'
    monster.backstory = 'Born in fire'
    monster.battle_cry = 'ROAR!'
    monster.special_ability = 'Fire breath'

    assert_equal 'Blaze', monster.name
    assert_equal 'Born in fire', monster.backstory
    assert_equal 'ROAR!', monster.battle_cry
    assert_equal 'Fire breath', monster.special_ability
  end

  def test_to_s_includes_name
    monster = Monster.random
    monster.name = 'Blaze'

    assert_includes monster.to_s, 'Blaze'
  end

  def test_to_s_includes_attribute_names
    monster = Monster.random

    Monster::ATTRIBUTES.each do |attr|
      assert_includes monster.to_s.downcase, attr.to_s
    end
  end

  def test_inspect_format
    monster = Monster.new(speed: 30, strength: 20, stamina: 25, intelligence: 15, luck: 10)
    monster.name = 'Blaze'
    monster.fitness = 5

    assert_includes monster.inspect, 'Blaze'
    assert_includes monster.inspect, '30, 20, 25, 15, 10'
    assert_includes monster.inspect, 'fitness=5'
  end
end
