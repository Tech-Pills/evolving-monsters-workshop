# frozen_string_literal: true

require_relative 'monster'

class Race
  STAGES = [
    { name: 'Sprint',          primary: :speed,        secondary: :stamina      },
    { name: 'Obstacle Course', primary: :strength,     secondary: :speed        },
    { name: 'Endurance Run',   primary: :stamina,      secondary: :strength     },
    { name: 'Puzzle Maze',     primary: :intelligence, secondary: :stamina      },
    { name: 'Wildcard',        primary: :luck,         secondary: :intelligence }
  ].freeze

  PRIMARY_WEIGHT   = 0.6
  SECONDARY_WEIGHT = 0.2
  LUCK_WEIGHT      = 0.1
  RANDOM_RANGE     = (0..10)

  attr_reader :monsters, :random, :results

  def initialize(monsters, random: Random.new)
    raise ArgumentError, 'Cannot race an empty monster list' if monsters.empty?

    @monsters = monsters
    @random = random
    @results = nil
  end

  def run
    scored = score_all_monsters
    ranked = rank_by_total_score(scored)
    @results = assign_fitness_by_rank(ranked)
    self
  end

  def self.call(monsters, random: Random.new)
    new(monsters, random: random).run
  end

  private

  def score_all_monsters
    # Build one record per monster: { monster:, index:, stage_scores:, total_score: }.
    # Keep the original `index`. assign_fitness_by_rank uses it as a tiebreaker
    # when two monsters tie on total score.
    # Hint: monsters.each_with_index.map yields (monster, index) per iteration.
  end

  def rank_by_total_score(scored)
    # Sort entries with the highest total_score first. Break ties using the
    # original index so the same inputs always rank the same way.
    # Hint: sort_by returns ascending order. To sort descending on a
    # numeric key, pass [-value, ...] as the sort key.
  end

  # Linear Ranking
  def assign_fitness_by_rank(ranked)
    # `ranked` is sorted best-first. Set each monster.fitness based on
    # placement: 1st gets `monsters.length`, last gets 1. That side-effect
    # is what plugs Race into GA#evolve. Return result hashes with keys
    # monster, stage_scores, total_score, placement.
    # Hint: each_with_index gives 0-based rank; placement = rank + 1.
  end

  def score_stage(monster, stage)
    attrs = monster.to_h
    primary   = attrs.fetch(stage[:primary])
    secondary = attrs.fetch(stage[:secondary])
    luck      = attrs.fetch(:luck)

    (primary * PRIMARY_WEIGHT) +
      (secondary * SECONDARY_WEIGHT) +
      (luck * LUCK_WEIGHT) +
      random.rand(RANDOM_RANGE)
  end
end
