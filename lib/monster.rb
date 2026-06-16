# frozen_string_literal: true

class Monster
  ATTRIBUTES = %i[speed strength stamina intelligence luck].freeze
  BUDGET = 100

  attr_reader :speed, :strength, :stamina, :intelligence, :luck
  attr_accessor :fitness, :name, :backstory, :battle_cry, :special_ability

  def initialize(speed:, strength:, stamina:, intelligence:, luck:)
    @speed = speed
    @strength = strength
    @stamina = stamina
    @intelligence = intelligence
    @luck = luck
    @fitness = 0
  end

  def self.random
    genome = random_genome
    from_genome(genome)
  end

  def self.from_genome(genome)
    unless genome.length == ATTRIBUTES.length
      raise ArgumentError, "Genome must have exactly #{ATTRIBUTES.length} elements, got #{genome.length}"
    end

    warn "Monster.from_genome: genome sums to #{genome.sum}, expected #{BUDGET}. Normalizing." if genome.sum != BUDGET

    normalized = normalize_genome(genome)
    attrs = ATTRIBUTES.zip(normalized).to_h
    new(**attrs)
  end

  # With Largest Remainder Method (Hamilton's method)
  def self.normalize_genome(genome, target: BUDGET)
    current_sum = genome.sum.to_f

    if current_sum.zero?
      base = target / genome.length
      remainder = target % genome.length
      return Array.new(genome.length) { |i| i < remainder ? base + 1 : base }
    end

    return genome.map(&:to_i) if current_sum == target && genome.all? { |v| v == v.to_i }

    scaled = genome.map { |v| v * target / current_sum }
    floored = scaled.map(&:floor)
    remainders = scaled.zip(floored).map { |s, f| s - f }

    deficit = target - floored.sum
    indices = remainders.each_with_index.sort_by { |r, _| -r }.map(&:last)

    deficit.times { |i| floored[indices[i]] += 1 }

    floored
  end

  def genome
    [speed, strength, stamina, intelligence, luck]
  end

  def to_h
    ATTRIBUTES.zip(genome).to_h
  end

  def dominant_attribute
    to_h.max_by { |_, value| value }.first
  end

  def to_s
    parts = [name || 'Unnamed Monster']
    parts << "(Fitness: #{fitness})" if fitness.positive?
    parts << "\n"
    to_h.each do |attr, value|
      bar_length = (value / 5.0).round.clamp(0, 20)
      bar = "#{'█' * bar_length}#{'░' * (20 - bar_length)}"
      label = "#{attr.capitalize}:"
      parts << format("  %-14<label>s %<bar>s  %<value>d/%<budget>d\n",
                      label: label, bar: bar, value: value, budget: BUDGET)
    end
    parts.join
  end

  def inspect
    "#<Monster #{name || 'unnamed'} [#{genome.join(', ')}] fitness=#{fitness}>"
  end

  private

  # Simple Random Partition
  def self.random_genome
    buckets = Array.new(ATTRIBUTES.length, 0)
    BUDGET.times { buckets[rand(ATTRIBUTES.length)] += 1 }
    buckets
  end

  private_class_method :random_genome
end
