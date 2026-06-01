# frozen_string_literal: true

require_relative 'monster'
require_relative 'population'

class GeneticAlgorithm
  CROSSOVER_STRATEGIES = %i[single_point two_point uniform].freeze

  attr_reader :population_size, :tournament_size, :crossover_rate, :mutation_rate, :crossover_strategy, :elitism

  def initialize(population_size: 20, tournament_size: 3, crossover_rate: 0.7, mutation_rate: 0.05,
                 crossover_strategy: :single_point, elitism: 2)
    @population_size = population_size
    @tournament_size = tournament_size
    @crossover_rate = crossover_rate
    @mutation_rate = mutation_rate
    @crossover_strategy = crossover_strategy
    @elitism = elitism

    validate_params!
  end

  def select(population)
    population.monsters.sample(tournament_size).max_by(&:fitness)
  end

  def crossover(parent_a, parent_b)
    genome_a = parent_a.genome
    genome_b = parent_b.genome

    raw_child1, raw_child2 = send(:"crossover_#{crossover_strategy}", genome_a, genome_b)

    [
      Monster.from_genome(Monster.normalize_genome(raw_child1)),
      Monster.from_genome(Monster.normalize_genome(raw_child2))
    ]
  end

  def mutate(monster)
    genome = monster.genome.dup
    indices = (0...genome.length).to_a.sample(2)
    increase_idx, decrease_idx = indices

    delta = rand(1..10)
    delta = [delta, genome[decrease_idx]].min

    genome[increase_idx] += delta
    genome[decrease_idx] -= delta

    Monster.from_genome(genome)
  end

  def evolve(population, generations:, &fitness_fn)
    raise ArgumentError, 'must pass a fitness block' unless fitness_fn

    fitness_fn.call(population.monsters)
    population.record_snapshot

    generations.times do
      elites = population.monsters.sort_by(&:fitness).last(elitism)
      new_monsters = []

      while new_monsters.size < population.size - elitism
        parent_a = select(population)

        children = if rand < crossover_rate
                     parent_b = select(population)
                     crossover(parent_a, parent_b)
                   else
                     [Monster.from_genome(parent_a.genome)]
                   end

        children.each do |child|
          child = mutate(child) if rand < mutation_rate
          new_monsters << child
        end
      end

      new_monsters = elites + new_monsters.first(population.size - elitism)
      fitness_fn.call(new_monsters)
      population.replace(new_monsters)
    end

    population
  end

  private

  def validate_params!
    raise ArgumentError, "population_size must be >= 1, got #{@population_size}" unless @population_size >= 1
    raise ArgumentError, "tournament_size must be >= 2, got #{@tournament_size}" unless @tournament_size >= 2

    unless (0.0..1.0).cover?(@crossover_rate)
      raise ArgumentError, "crossover_rate must be between 0.0 and 1.0, got #{@crossover_rate}"
    end

    unless (0.0..1.0).cover?(@mutation_rate)
      raise ArgumentError, "mutation_rate must be between 0.0 and 1.0, got #{@mutation_rate}"
    end

    unless CROSSOVER_STRATEGIES.include?(@crossover_strategy)
      raise ArgumentError,
            "crossover_strategy must be one of #{CROSSOVER_STRATEGIES}, got #{@crossover_strategy.inspect}"
    end

    return if @elitism >= 0 && @elitism < @population_size

    raise ArgumentError, "elitism must be >= 0 and < population_size (#{@population_size}), got #{@elitism}"
  end

  def crossover_single_point(genome_a, genome_b)
    cut = rand(1...genome_a.length)
    child1 = genome_a[0...cut] + genome_b[cut..]
    child2 = genome_b[0...cut] + genome_a[cut..]
    [child1, child2]
  end

  def crossover_two_point(genome_a, genome_b)
    points = (1...genome_a.length).to_a.sample(2).sort
    cut1, cut2 = points
    child1 = genome_a[0...cut1] + genome_b[cut1...cut2] + genome_a[cut2..]
    child2 = genome_b[0...cut1] + genome_a[cut1...cut2] + genome_b[cut2..]
    [child1, child2]
  end

  def crossover_uniform(genome_a, genome_b)
    child1 = []
    child2 = []
    genome_a.zip(genome_b).each do |gene_a, gene_b|
      if rand < 0.5
        child1 << gene_a
        child2 << gene_b
      else
        child1 << gene_b
        child2 << gene_a
      end
    end
    [child1, child2]
  end
end
