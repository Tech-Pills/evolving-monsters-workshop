# frozen_string_literal: true

require 'optparse'

module CLI
  class Config
    DEFAULTS = {
      population_size: 12,
      generations: 10,
      crossover_strategy: :uniform,
      crossover_rate: 0.7,
      mutation_rate: 0.05,
      elitism: 2,
      tournament_size: 3,
      narrate_every: 0, # 0 = only narrate final generation
      seed: nil,
      llm_mode: :auto, # :auto | :null
      interactive: false
    }.freeze

    CROSSOVER_CHOICES = %i[single_point two_point uniform].freeze
    LLM_CHOICES = %i[auto null].freeze

    attr_reader :population_size, :generations, :crossover_strategy,
                :crossover_rate, :mutation_rate, :elitism, :tournament_size,
                :narrate_every, :seed, :llm_mode

    def self.parse(argv, prompt: nil)
      opts = DEFAULTS.dup
      explicit = explicit_flags!(opts, argv.dup)

      should_prompt = opts[:interactive] || explicit.empty?
      opts = prompt_for_overrides(opts, prompt, explicit: explicit) if should_prompt && prompt

      new(**opts.except(:interactive))
    end

    def initialize(population_size:, generations:, crossover_strategy:,
                   crossover_rate:, mutation_rate:, elitism:, tournament_size:,
                   narrate_every:, seed:, llm_mode:)
      @population_size = population_size
      @generations = generations
      @crossover_strategy = crossover_strategy
      @crossover_rate = crossover_rate
      @mutation_rate = mutation_rate
      @elitism = elitism
      @tournament_size = tournament_size
      @narrate_every = narrate_every
      @seed = seed
      @llm_mode = llm_mode
      validate!
      freeze
    end

    def to_h
      {
        population_size: population_size,
        generations: generations,
        crossover_strategy: crossover_strategy,
        crossover_rate: crossover_rate,
        mutation_rate: mutation_rate,
        elitism: elitism,
        tournament_size: tournament_size,
        narrate_every: narrate_every,
        seed: seed,
        llm_mode: llm_mode
      }
    end

    def self.explicit_flags!(opts, argv)
      explicit = []

      parser = OptionParser.new do |o|
        o.banner = 'Usage: bin/evolve [options]'

        o.on('--population N', Integer, 'Monsters per generation (default: 12)') do |v|
          opts[:population_size] = v
          explicit << :population_size
        end
        o.on('--generations N', Integer, 'Generations to evolve (default: 10)') do |v|
          opts[:generations] = v
          explicit << :generations
        end
        o.on('--crossover STRATEGY', CROSSOVER_CHOICES,
             "Crossover strategy: #{CROSSOVER_CHOICES.join('|')} (default: uniform)") do |v|
          opts[:crossover_strategy] = v
          explicit << :crossover_strategy
        end
        o.on('--crossover-rate F', Float, 'Crossover probability 0.0-1.0 (default: 0.7)') do |v|
          opts[:crossover_rate] = v
          explicit << :crossover_rate
        end
        o.on('--mutation-rate F', Float, 'Mutation probability 0.0-1.0 (default: 0.05)') do |v|
          opts[:mutation_rate] = v
          explicit << :mutation_rate
        end
        o.on('--elitism N', Integer, 'Top N preserved each gen (default: 2)') do |v|
          opts[:elitism] = v
          explicit << :elitism
        end
        o.on('--tournament-size N', Integer, 'Tournament selection size (default: 3)') do |v|
          opts[:tournament_size] = v
          explicit << :tournament_size
        end
        o.on('--narrate-every N', Integer,
             'Race commentary every N gens; 0 = only final (default: 0)') do |v|
          opts[:narrate_every] = v
          explicit << :narrate_every
        end
        o.on('--seed N', Integer, 'Seed Ruby RNG for reproducible runs') do |v|
          opts[:seed] = v
          explicit << :seed
        end
        o.on('--llm MODE', LLM_CHOICES, "LLM mode: #{LLM_CHOICES.join('|')} (default: auto)") do |v|
          opts[:llm_mode] = v
          explicit << :llm_mode
        end
        o.on('--interactive', 'Force interactive prompt even with flags') do
          opts[:interactive] = true
        end
        o.on('-h', '--help', 'Show this help') do
          puts o
          exit 0
        end
      end

      parser.parse!(argv)
      explicit
    end
    private_class_method :explicit_flags!

    def self.prompt_for_overrides(opts, prompt, explicit: [])
      opts = opts.dup
      opts[:llm_mode] = prompt.select('LLM mode:', LLM_CHOICES, default: 1) unless explicit.include?(:llm_mode)
      unless explicit.include?(:population_size)
        opts[:population_size] = prompt.ask('Population size?', default: opts[:population_size].to_s, convert: :int)
      end
      unless explicit.include?(:generations)
        opts[:generations] = prompt.ask('Generations?', default: opts[:generations].to_s, convert: :int)
      end
      unless explicit.include?(:crossover_strategy)
        opts[:crossover_strategy] = prompt.select('Crossover strategy:', CROSSOVER_CHOICES, default: 3)
      end
      unless explicit.include?(:mutation_rate)
        opts[:mutation_rate] = prompt.ask('Mutation rate (0.0-1.0)?',
                                          default: opts[:mutation_rate].to_s,
                                          convert: :float)
      end
      unless explicit.include?(:narrate_every)
        opts[:narrate_every] = prompt.ask('Narrate commentary every N gens (0 = final only)?',
                                          default: opts[:narrate_every].to_s,
                                          convert: :int)
      end
      opts
    end
    private_class_method :prompt_for_overrides

    private

    def validate!
      raise ArgumentError, "population_size must be >= 2, got #{population_size}" unless population_size >= 2
      raise ArgumentError, "generations must be >= 1, got #{generations}" unless generations >= 1
      unless CROSSOVER_CHOICES.include?(crossover_strategy)
        raise ArgumentError, "crossover_strategy must be one of #{CROSSOVER_CHOICES}"
      end
      unless (0.0..1.0).cover?(crossover_rate)
        raise ArgumentError, "crossover_rate must be 0.0-1.0, got #{crossover_rate}"
      end
      raise ArgumentError, "mutation_rate must be 0.0-1.0, got #{mutation_rate}" unless (0.0..1.0).cover?(mutation_rate)
      unless elitism >= 0 && elitism < population_size
        raise ArgumentError, "elitism must be >= 0 and < population_size, got #{elitism}"
      end
      unless tournament_size.between?(2, population_size)
        raise ArgumentError, "tournament_size must be >= 2 and <= population_size, got #{tournament_size}"
      end
      raise ArgumentError, "narrate_every must be >= 0, got #{narrate_every}" unless narrate_every >= 0
      raise ArgumentError, "llm_mode must be one of #{LLM_CHOICES}" unless LLM_CHOICES.include?(llm_mode)
    end
  end
end
