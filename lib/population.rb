# frozen_string_literal: true

require_relative 'monster'

class Population
  attr_reader :monsters, :generation, :history

  def initialize(size: 20, random: Random.new)
    raise ArgumentError, "Population size must be at least 1, got #{size}" if size < 1

    @random = random

    @monsters = Array.new(size) { Monster.random(random: random) }
    @generation = 0
    @history = []
  end

  def size
    monsters.length
  end

  def best
    monsters.max_by(&:fitness)
  end

  def worst
    monsters.min_by(&:fitness)
  end

  def average_fitness
    return 0.0 if monsters.empty?

    monsters.sum(&:fitness).to_f / monsters.length
  end

  def attribute_averages
    return {} if monsters.empty?

    Monster::ATTRIBUTES.to_h do |attr|
      [attr, monsters.sum { |m| m.to_h[attr] }.to_f / monsters.length]
    end
  end

  # Mean pairwise Euclidean distance
  def genome_diversity
    n = monsters.length
    return 0.0 if n < 2

    genomes = monsters.map(&:genome)
    total = 0.0

    genomes.each_with_index do |g1, i|
      genomes[(i + 1)..].each do |g2|
        sq_sum = g1.zip(g2).sum { |a, b| (a - b)**2 }
        total += Math.sqrt(sq_sum)
      end
    end

    total / (n * (n - 1) / 2)
  end

  def replace(new_monsters)
    raise ArgumentError, 'Cannot replace with an empty population' if new_monsters.empty?

    @monsters = new_monsters
    @generation += 1
    record_snapshot
  end

  def record_snapshot
    @history << {
      generation: generation,
      best_fitness: best.fitness,
      avg_fitness: average_fitness,
      attribute_averages: attribute_averages,
      diversity: genome_diversity
    }
  end
end
