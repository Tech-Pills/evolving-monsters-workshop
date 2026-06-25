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
    monsters.each_with_index.map do |monster, index|
      stage_scores = STAGES.map { |stage| score_stage(monster, stage) }
      {
        monster: monster,
        index: index,
        stage_scores: stage_scores,
        total_score: stage_scores.sum
      }
    end
  end

  def rank_by_total_score(scored)
    scored.sort_by { |entry| [-entry[:total_score], entry[:index]] }
  end

  # Linear Ranking
  def assign_fitness_by_rank(ranked)
    # Returns:     Array of hashes with keys {monster, stage_scores, total_score, placement}
    # Constraints: also sets monster.fitness as a side effect (1st place gets monsters.length,
    #              last place gets 1); `ranked` is already sorted best-first, do not re-sort it
    # Example:     for 3 monsters in `ranked`, the returned hashes have placement values 1, 2, 3
    #              and the monsters end up with fitness 3, 2, 1 respectively
    # Hint:        each_with_index gives 0-based rank; placement = rank + 1;
    #              fitness = monsters.length - placement + 1
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
