# frozen_string_literal: true

require_relative '../llm'
require_relative '../monster'
require_relative '../population'
require_relative '../genetic_algorithm'
require_relative '../race'
require_relative 'display'

module CLI
  class Runner
    attr_reader :config, :display, :adapter

    def initialize(config:, display: Display.new, adapter: nil)
      @config = config
      @display = display
      @adapter = adapter || build_adapter(config.llm_mode)
    end

    def call
      @rng = config.seed ? Random.new(config.seed) : Random.new

      display.banner('Evolving Monsters — Phase 5')
      display.provider_line(LLM::Client.describe(adapter), auto_fallback: auto_fell_back_to_null?)
      display.config_summary(config)

      population = Population.new(size: config.population_size, random: @rng)
      name_population(population)

      display.banner('Generation 0 — initial race', color: :yellow)
      gen_zero = run_race(population.monsters)
      display.leaderboard(gen_zero.results)

      display.banner('Evolution loop', color: :magenta)
      run_evolution(population)

      display.banner('Emergence', color: :green)
      render_emergence(population)

      display.banner('Evolutionary arc', color: :blue)
      narration = adapter.narrate_evolution(population.history)
      display.narration_box('Narration', narration)

      display.closing('Run complete.')
      population
    end

    private

    def build_adapter(mode)
      case mode
      when :null then LLM::Null.new
      when :auto then LLM::Client.auto_detect
      else
        raise ArgumentError, "Unknown llm_mode: #{mode.inspect}"
      end
    end

    def auto_fell_back_to_null?
      config.llm_mode == :auto && adapter.is_a?(LLM::Null)
    end

    def name_population(population)
      display.banner("Naming #{population.size} monsters", color: :cyan)
      population.monsters.each_with_index do |monster, i|
        identity = display.with_spinner("[#{i + 1}/#{population.size}] generating identity") do
          adapter.generate_identity(monster)
        end
        monster.name = identity[:name]
        monster.backstory = identity[:backstory]
        monster.battle_cry = identity[:battle_cry]
        monster.special_ability = identity[:special_ability]
      end
    end

    def run_race(monsters)
      Race.call(monsters, random: @rng)
    end

    def run_evolution(population)
      ga = GeneticAlgorithm.new(
        population_size: config.population_size,
        tournament_size: config.tournament_size,
        crossover_rate: config.crossover_rate,
        mutation_rate: config.mutation_rate,
        crossover_strategy: config.crossover_strategy,
        elitism: config.elitism,
        random: @rng
      )

      latest_race = nil
      advance = display.generation_advance(total: config.generations)

      stats_callback = lambda do |stats|
        advance.call(stats, stats[:diversity])
        maybe_commentate(stats[:generation], latest_race)
      end

      ga.evolve(population, generations: config.generations, on_generation: stats_callback) do |monsters|
        latest_race = Race.call(monsters, random: @rng)
      end
    end

    def maybe_commentate(generation, latest_race)
      return if config.narrate_every <= 0
      return unless (generation % config.narrate_every).zero?
      return unless latest_race

      commentary = display.with_spinner("commentating gen #{generation}") do
        adapter.commentate_race(latest_race.results)
      end
      display.narration_box("Gen #{generation} commentary", commentary)
    end

    def render_emergence(population)
      display.drift_table(population.history)
      display.diversity_sparkline(population.history)
      display.archetype_line(population.history)
    end
  end
end
