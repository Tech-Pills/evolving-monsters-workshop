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
      attribute_averages: attribute_averages
    }
  end
end
