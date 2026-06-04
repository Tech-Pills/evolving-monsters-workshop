# frozen_string_literal: true

require_relative 'test_helper'
require 'race'
require 'genetic_algorithm'

class RaceTest < Minitest::Test
  def test_stages_is_frozen
    assert_predicate Race::STAGES, :frozen?
  end

  def test_has_exactly_five_stages
    assert_equal 5, Race::STAGES.length
  end

  def test_stage_attributes_are_valid
    Race::STAGES.each do |stage|
      assert_includes Monster::ATTRIBUTES, stage[:primary],
                      "Stage #{stage[:name]} primary must be a valid attribute"
      assert_includes Monster::ATTRIBUTES, stage[:secondary],
                      "Stage #{stage[:name]} secondary must be a valid attribute"
    end
  end

  def test_stage_names_are_unique
    names = Race::STAGES.map { |s| s[:name] }

    assert_equal names.length, names.uniq.length
  end

  def test_initialize_raises_on_empty_monsters
    assert_raises(ArgumentError) { Race.new([]) }
  end

  def test_initialize_with_default_random
    monsters = [Monster.random]

    race = Race.new(monsters)

    assert_instance_of Random, race.random
  end

  def test_initialize_with_injected_random
    monsters = [Monster.random]
    seeded = Random.new(42)

    race = Race.new(monsters, random: seeded)

    assert_same seeded, race.random
  end

  def test_increasing_primary_attribute_increases_sprint_score_proportionally
    fast   = Monster.from_genome([40, 30, 20, 0, 10])
    faster = Monster.from_genome([60, 10, 20, 0, 10])

    sprint_a = Race.new([fast],   random: Random.new(42)).run.results.first[:stage_scores][0]
    sprint_b = Race.new([faster], random: Random.new(42)).run.results.first[:stage_scores][0]

    # Only speed changed (+20). Expected delta: 20 * 0.6 = 12.0
    assert_in_delta 12.0, sprint_b - sprint_a, 1e-9
  end

  def test_primary_weight_is_applied
    monster = Monster.from_genome([100, 0, 0, 0, 0])
    race = Race.new([monster], random: Random.new(1)).run
    stage_scores = race.results.first[:stage_scores]

    sprint_score = stage_scores[0]
    # Expected Sprint score: 60 + 0 + 0 + rand(0..10) => in 60..70
    assert_operator sprint_score, :>=, 60.0
    assert_operator sprint_score, :<=, 70.0
  end

  def test_deterministic_with_same_seed
    monsters = Array.new(5) { Monster.random }
    race_a = Race.new(monsters, random: Random.new(42)).run
    race_b = Race.new(monsters, random: Random.new(42)).run

    race_a.results.zip(race_b.results).each do |a, b|
      assert_in_delta a[:total_score], b[:total_score], 1e-9
      assert_equal a[:placement], b[:placement]
    end
  end

  def test_run_returns_self
    race = Race.new([Monster.random])

    assert_same race, race.run
  end

  def test_run_populates_results
    race = Race.new([Monster.random, Monster.random])

    assert_nil race.results
    race.run

    refute_nil race.results
  end

  def test_results_has_one_entry_per_monster
    monsters = Array.new(4) { Monster.random }
    race = Race.new(monsters).run

    assert_equal 4, race.results.length
  end

  def test_stage_scores_has_correct_length
    race = Race.new([Monster.random]).run

    assert_equal Race::STAGES.length, race.results.first[:stage_scores].length
  end

  def test_total_equals_sum_of_stage_scores
    race = Race.new(Array.new(3) { Monster.random }).run

    race.results.each do |result|
      assert_in_delta result[:stage_scores].sum, result[:total_score], 1e-9
    end
  end

  def test_placements_are_unique_and_sequential
    monsters = Array.new(8) { Monster.random }
    race = Race.new(monsters).run

    placements = race.results.map { |r| r[:placement] }

    assert_equal (1..8).to_a, placements.sort
  end

  def test_results_ordered_by_placement
    monsters = Array.new(10) { Monster.random }
    race = Race.new(monsters).run

    placements = race.results.map { |r| r[:placement] }

    assert_equal placements, placements.sort
  end

  def test_results_ordered_by_descending_total_score
    monsters = Array.new(10) { Monster.random }
    race = Race.new(monsters).run

    totals = race.results.map { |r| r[:total_score] }

    assert_equal totals, totals.sort.reverse
  end

  def test_fitness_assignment_linear_placement
    monsters = Array.new(5) { Monster.random }
    race = Race.new(monsters).run

    race.results.each do |result|
      expected_fitness = monsters.length - result[:placement] + 1

      assert_equal expected_fitness, result[:monster].fitness
    end
  end

  def test_first_place_has_highest_fitness
    monsters = Array.new(6) { Monster.random }
    race = Race.new(monsters).run

    winner = race.results.first

    assert_equal 1, winner[:placement]
    assert_equal 6, winner[:monster].fitness
  end

  def test_last_place_has_fitness_one
    monsters = Array.new(6) { Monster.random }
    race = Race.new(monsters).run

    loser = race.results.last

    assert_equal 6, loser[:placement]
    assert_equal 1, loser[:monster].fitness
  end

  def test_tiebreak_is_stable_by_input_index
    monster_a = Monster.from_genome([20, 20, 20, 20, 20])
    monster_b = Monster.from_genome([20, 20, 20, 20, 20])

    race = Race.new([monster_a, monster_b], random: Random.new(99)).run

    placements = race.results.map { |r| r[:placement] }

    assert_equal [1, 2], placements.sort
  end

  def test_single_monster_race
    monster = Monster.random
    race = Race.new([monster]).run

    assert_equal 1, race.results.length
    assert_equal 1, race.results.first[:placement]
    assert_equal 1, monster.fitness
  end

  def test_zero_luck_monster_still_scores
    monster = Monster.from_genome([25, 25, 25, 25, 0])
    race = Race.new([monster], random: Random.new(0)).run
    result = race.results.first

    assert_operator result[:total_score], :>, 0.0
    result[:stage_scores].each do |s|
      assert_operator s, :>=, 0.0
    end
  end

  def test_class_level_call_returns_race_instance
    monsters = Array.new(3) { Monster.random }

    race = Race.call(monsters)

    assert_instance_of Race, race
    refute_nil race.results
  end

  def test_class_level_call_assigns_fitness
    monsters = Array.new(3) { Monster.random }

    Race.call(monsters)

    monsters.each { |m| assert_operator m.fitness, :>, 0 }
  end

  def test_race_integrates_with_genetic_algorithm_evolve
    ga = GeneticAlgorithm.new(population_size: 10, tournament_size: 3)
    pop = Population.new(size: 10)

    ga.evolve(pop, generations: 3) { |monsters| Race.call(monsters) }

    assert_equal 3, pop.generation
    pop.history.each do |snapshot|
      assert_operator snapshot[:best_fitness], :>, 0,
                      "Snapshot gen #{snapshot[:generation]} should have non-zero best_fitness"
    end
  end
end
