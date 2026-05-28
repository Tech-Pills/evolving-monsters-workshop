# frozen_string_literal: true

require_relative 'monster'

class Population
  attr_reader :monsters, :generation, :history

  def initialize(size: 20)
    raise ArgumentError, "Population size must be at least 1, got #{size}" if size < 1

    @monsters = Array.new(size) { Monster.random }
    @generation = 0
    @history = []
  end

  def size
    monsters.length
  end

  def best
    # Return the monster with the highest fitness
  end

  def worst
    # Return the monster (not the fitness value) with the lowest fitness
  end

  def average_fitness
    # Return the mean fitness across all monsters as a float
    # Edge case: an empty population should return 0.0 (avoid divide-by-zero)
  end

  def attribute_averages
    # Return a hash mapping each ATTRIBUTES key to the population's average value
    # for that attribute, e.g. { speed: 24.5, strength: 30.0, ... }
    # Edge case: an empty population should return {}
  end

  def replace(new_monsters)
    # Replace @monsters with new_monsters, advance the generation counter,
    # then record a snapshot of the new state to history
    # Order matters: update monsters and bump the generation BEFORE calling
    # record_snapshot, since the snapshot reads the current state
    # Raise ArgumentError if new_monsters is empty
  end

  def record_snapshot
    @history << {
      generation: generation,
      best_fitness: best.fitness,
      avg_fitness: average_fitness,
      attribute_averages: attribute_averages
    }
  end
end
