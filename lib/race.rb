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

  def assign_fitness_by_rank(ranked)
    ranked.each_with_index.map do |entry, rank|
      placement = rank + 1
      entry[:monster].fitness = monsters.length - placement + 1
      {
        monster: entry[:monster],
        stage_scores: entry[:stage_scores],
        total_score: entry[:total_score],
        placement: placement
      }
    end
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
