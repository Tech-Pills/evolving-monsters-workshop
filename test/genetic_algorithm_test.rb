# frozen_string_literal: true

require_relative 'test_helper'
require 'genetic_algorithm'

class GeneticAlgorithmTest < Minitest::Test
  def test_default_configuration
    ga = GeneticAlgorithm.new

    assert_equal 20, ga.population_size
    assert_equal 3, ga.tournament_size
    assert_in_delta 0.7, ga.crossover_rate
    assert_in_delta 0.05, ga.mutation_rate
    assert_equal :single_point, ga.crossover_strategy
    assert_equal 2, ga.elitism
  end

  def test_custom_configuration
    ga = GeneticAlgorithm.new(
      population_size: 50,
      tournament_size: 5,
      crossover_rate: 0.9,
      mutation_rate: 0.1,
      crossover_strategy: :uniform,
      elitism: 4
    )

    assert_equal 50, ga.population_size
    assert_equal 5, ga.tournament_size
    assert_in_delta 0.9, ga.crossover_rate
    assert_in_delta 0.1, ga.mutation_rate
    assert_equal :uniform, ga.crossover_strategy
    assert_equal 4, ga.elitism
  end

  def test_raises_on_invalid_crossover_strategy
    assert_raises(ArgumentError) do
      GeneticAlgorithm.new(crossover_strategy: :bogus)
    end
  end

  def test_raises_on_tournament_size_less_than_two
    assert_raises(ArgumentError) do
      GeneticAlgorithm.new(tournament_size: 1)
    end
  end

  def test_raises_on_crossover_rate_out_of_range
    assert_raises(ArgumentError) { GeneticAlgorithm.new(crossover_rate: 1.5) }
    assert_raises(ArgumentError) { GeneticAlgorithm.new(crossover_rate: -0.1) }
  end

  def test_raises_on_mutation_rate_out_of_range
    assert_raises(ArgumentError) { GeneticAlgorithm.new(mutation_rate: 2.0) }
    assert_raises(ArgumentError) { GeneticAlgorithm.new(mutation_rate: -0.1) }
  end

  def test_raises_on_population_size_less_than_one
    assert_raises(ArgumentError) { GeneticAlgorithm.new(population_size: 0) }
    assert_raises(ArgumentError) { GeneticAlgorithm.new(population_size: -1) }
  end

  def test_raises_on_elitism_exceeding_population
    assert_raises(ArgumentError) do
      GeneticAlgorithm.new(population_size: 20, elitism: 20)
    end
  end

  def test_select_returns_a_monster
    ga = GeneticAlgorithm.new(population_size: 10, tournament_size: 3)
    pop = Population.new(size: 10)
    pop.monsters.each_with_index { |m, i| m.fitness = i }

    result = ga.select(pop)

    assert_instance_of Monster, result
    assert_includes pop.monsters, result
  end

  def test_select_returns_fittest_when_tournament_is_whole_population
    ga = GeneticAlgorithm.new(population_size: 5, tournament_size: 5)
    pop = Population.new(size: 5)
    pop.monsters.each_with_index { |m, i| m.fitness = (i + 1) * 10 }

    best = pop.monsters.max_by(&:fitness)
    result = ga.select(pop)

    assert_equal best, result
  end

  def test_crossover_single_point_preserves_budget
    ga = GeneticAlgorithm.new(crossover_strategy: :single_point)
    parent_a = Monster.from_genome([40, 10, 20, 20, 10])
    parent_b = Monster.from_genome([10, 40, 10, 10, 30])

    children = ga.crossover(parent_a, parent_b)

    children.each do |child|
      assert_equal Monster::BUDGET, child.genome.sum
    end
  end

  def test_crossover_two_point_preserves_budget
    ga = GeneticAlgorithm.new(crossover_strategy: :two_point)
    parent_a = Monster.from_genome([40, 10, 20, 20, 10])
    parent_b = Monster.from_genome([10, 40, 10, 10, 30])

    children = ga.crossover(parent_a, parent_b)

    children.each do |child|
      assert_equal Monster::BUDGET, child.genome.sum
    end
  end

  def test_crossover_uniform_preserves_budget
    ga = GeneticAlgorithm.new(crossover_strategy: :uniform)
    parent_a = Monster.from_genome([40, 10, 20, 20, 10])
    parent_b = Monster.from_genome([10, 40, 10, 10, 30])

    children = ga.crossover(parent_a, parent_b)

    children.each do |child|
      assert_equal Monster::BUDGET, child.genome.sum
    end
  end

  def test_crossover_returns_two_children
    ga = GeneticAlgorithm.new
    parent_a = Monster.from_genome([40, 10, 20, 20, 10])
    parent_b = Monster.from_genome([10, 40, 10, 10, 30])

    children = ga.crossover(parent_a, parent_b)

    assert_equal 2, children.length
    children.each { |child| assert_instance_of Monster, child }
  end

  def test_crossover_children_have_valid_genomes
    ga = GeneticAlgorithm.new
    parent_a = Monster.from_genome([40, 10, 20, 20, 10])
    parent_b = Monster.from_genome([10, 40, 10, 10, 30])

    children = ga.crossover(parent_a, parent_b)

    children.each do |child|
      assert_equal Monster::ATTRIBUTES.length, child.genome.length
      child.genome.each do |value|
        assert_operator value, :>=, 0, "Attribute value #{value} should be >= 0"
      end
    end
  end

  def test_crossover_single_point_mixes_parent_genes
    ga = GeneticAlgorithm.new(crossover_strategy: :single_point)
    parent_a = Monster.from_genome([40, 10, 10, 10, 30])
    parent_b = Monster.from_genome([10, 40, 30, 10, 10])

    found_different = false
    20.times do
      children = ga.crossover(parent_a, parent_b)
      children.each do |child|
        found_different = true if child.genome != parent_a.genome && child.genome != parent_b.genome
      end
      break if found_different
    end

    assert found_different, 'Expected crossover to produce children different from both parents'
  end

  def test_mutate_preserves_budget
    ga = GeneticAlgorithm.new
    monster = Monster.from_genome([20, 20, 20, 20, 20])

    20.times do
      mutated = ga.mutate(monster)

      assert_equal Monster::BUDGET, mutated.genome.sum
    end
  end

  def test_mutate_returns_new_monster
    ga = GeneticAlgorithm.new
    monster = Monster.from_genome([20, 20, 20, 20, 20])

    mutated = ga.mutate(monster)

    refute_same monster, mutated
  end

  def test_mutate_changes_genome
    ga = GeneticAlgorithm.new
    monster = Monster.from_genome([20, 20, 20, 20, 20])

    found_different = false
    20.times do
      mutated = ga.mutate(monster)
      if mutated.genome != monster.genome
        found_different = true
        break
      end
    end

    assert found_different, 'Expected mutation to produce a different genome'
  end

  def test_mutate_no_negative_attributes
    ga = GeneticAlgorithm.new
    monster = Monster.from_genome([0, 50, 20, 20, 10])

    20.times do
      mutated = ga.mutate(monster)

      mutated.genome.each do |value|
        assert_operator value, :>=, 0, "Attribute value #{value} should be >= 0"
      end
    end
  end

  def test_mutate_handles_extreme_genome
    ga = GeneticAlgorithm.new
    monster = Monster.from_genome([100, 0, 0, 0, 0])

    20.times do
      mutated = ga.mutate(monster)

      assert_equal Monster::BUDGET, mutated.genome.sum
      mutated.genome.each do |value|
        assert_operator value, :>=, 0, "Attribute value #{value} should be >= 0"
      end
    end
  end

  def test_elitism_preserves_top_monsters
    ga = GeneticAlgorithm.new(population_size: 5, tournament_size: 2,
                              crossover_rate: 0.7, mutation_rate: 0.0, elitism: 2)
    pop = Population.new(size: 5)
    fitness_fn = ->(monsters) { monsters.each { |m| m.fitness = m.speed } }

    fitness_fn.call(pop.monsters)
    elite_genomes = pop.monsters.sort_by(&:fitness).last(2).map(&:genome)

    ga.evolve(pop, generations: 1, &fitness_fn)

    new_genomes = pop.monsters.map(&:genome)

    elite_genomes.each do |elite_genome|
      assert_includes new_genomes, elite_genome,
                      "Elite genome #{elite_genome} should be in new population"
    end
  end

  def test_evolve_runs_without_error
    ga = GeneticAlgorithm.new(population_size: 10, tournament_size: 3)
    pop = Population.new(size: 10)

    ga.evolve(pop, generations: 3) { |monsters| monsters.each { |m| m.fitness = m.speed } }
  end

  def test_evolve_advances_generation
    ga = GeneticAlgorithm.new(population_size: 10, tournament_size: 3)
    pop = Population.new(size: 10)

    ga.evolve(pop, generations: 5) { |monsters| monsters.each { |m| m.fitness = m.speed } }

    assert_equal 5, pop.generation
  end

  def test_evolve_populates_history
    ga = GeneticAlgorithm.new(population_size: 10, tournament_size: 3)
    pop = Population.new(size: 10)

    ga.evolve(pop, generations: 5) { |monsters| monsters.each { |m| m.fitness = m.speed } }

    assert_equal 6, pop.history.length
  end

  def test_evolve_preserves_population_size
    ga = GeneticAlgorithm.new(population_size: 10, tournament_size: 3)
    pop = Population.new(size: 10)

    ga.evolve(pop, generations: 3) { |monsters| monsters.each { |m| m.fitness = m.speed } }

    assert_equal 10, pop.size
  end

  def test_evolve_raises_without_fitness_evaluator
    ga = GeneticAlgorithm.new(population_size: 10, tournament_size: 3)
    pop = Population.new(size: 10)

    assert_raises(ArgumentError) do
      ga.evolve(pop, generations: 3)
    end
  end

  def test_evolve_history_has_correct_fitness_values
    ga = GeneticAlgorithm.new(population_size: 10, tournament_size: 3)
    pop = Population.new(size: 10)

    ga.evolve(pop, generations: 3) { |monsters| monsters.each { |m| m.fitness = m.speed } }

    pop.history.each do |snapshot|
      assert_operator snapshot[:best_fitness], :>, 0,
                      "Snapshot gen #{snapshot[:generation]} should have non-zero best_fitness"
    end
  end
end
