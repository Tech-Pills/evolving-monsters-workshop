#  frozen_string_literal: true

require_relative '../test_helper'
require 'cli/config'

module CLI
  class ConfigTest < Minitest::Test
    def test_defaults_when_no_flags_and_no_prompt
      config = Config.parse([])

      assert_equal 12, config.population_size
      assert_equal 10, config.generations
      assert_equal :uniform, config.crossover_strategy
      assert_in_delta(0.05, config.mutation_rate)
      assert_equal 0, config.narrate_every
      assert_equal :auto, config.llm_mode
      assert_nil config.seed
    end

    def test_flags_override_defaults
      config = Config.parse(['--population', '20', '--generations', '5',
                             '--crossover', 'single_point', '--mutation-rate', '0.2',
                             '--narrate-every', '3', '--seed', '42', '--llm', 'null'])

      assert_equal 20, config.population_size
      assert_equal 5, config.generations
      assert_equal :single_point, config.crossover_strategy
      assert_in_delta(0.2, config.mutation_rate)
      assert_equal 3, config.narrate_every
      assert_equal 42, config.seed
      assert_equal :null, config.llm_mode
    end

    def test_config_is_frozen
      config = Config.parse(['--llm', 'null'])

      assert_predicate config, :frozen?
    end

    def test_raises_on_invalid_population
      assert_raises(ArgumentError) { Config.parse(['--population', '1']) }
    end

    def test_raises_on_invalid_mutation_rate
      assert_raises(ArgumentError) { Config.parse(['--mutation-rate', '1.5']) }
    end

    def test_raises_on_tournament_larger_than_population
      assert_raises(ArgumentError) { Config.parse(['--population', '4', '--tournament-size', '5']) }
    end

    def test_raises_on_elitism_equal_to_population
      assert_raises(ArgumentError) { Config.parse(['--population', '4', '--elitism', '4']) }
    end

    def test_prompt_used_when_no_flags
      prompt = FakePrompt.new(
        select: { 'LLM mode:' => :null, 'Crossover strategy:' => :two_point },
        ask: { 'Population size?' => 8, 'Generations?' => 3,
               'Mutation rate (0.0-1.0)?' => 0.1, 'Narrate commentary every N gens (0 = final only)?' => 2 }
      )

      config = Config.parse([], prompt: prompt)

      assert_equal :null, config.llm_mode
      assert_equal 8, config.population_size
      assert_equal 3, config.generations
      assert_equal :two_point, config.crossover_strategy
      assert_in_delta(0.1, config.mutation_rate)
      assert_equal 2, config.narrate_every
    end

    def test_prompt_skipped_when_any_flag_given
      prompt = FakePrompt.new(select: {}, ask: {})

      config = Config.parse(['--llm', 'null'], prompt: prompt)

      assert_equal :null, config.llm_mode
      assert_equal 12, config.population_size
    end

    def test_interactive_skips_prompts_for_fields_set_via_flags
      prompt = FakePrompt.new(
        select: { 'LLM mode:' => :null, 'Crossover strategy:' => :uniform },
        ask: { 'Generations?' => 4,
               'Mutation rate (0.0-1.0)?' => 0.05,
               'Narrate commentary every N gens (0 = final only)?' => 0 }
      )

      config = Config.parse(['--population', '20', '--interactive'], prompt: prompt)

      assert_equal 20, config.population_size
      assert_equal 4, config.generations
      assert_equal :null, config.llm_mode
    end

    def test_interactive_skips_multiple_explicit_fields
      prompt = FakePrompt.new(
        select: { 'Crossover strategy:' => :two_point },
        ask: { 'Generations?' => 7,
               'Mutation rate (0.0-1.0)?' => 0.15,
               'Narrate commentary every N gens (0 = final only)?' => 1 }
      )

      config = Config.parse(['--population', '15', '--llm', 'null', '--interactive'], prompt: prompt)

      assert_equal 15, config.population_size
      assert_equal :null, config.llm_mode
      assert_equal :two_point, config.crossover_strategy
      assert_equal 7, config.generations
    end

    def test_parse_does_not_mutate_argv
      argv = ['--population', '8', '--llm', 'null']
      original = argv.dup

      Config.parse(argv)

      assert_equal original, argv, 'Config.parse must not mutate the input argv'
    end

    def test_to_h_round_trip
      config = Config.parse(['--llm', 'null', '--seed', '7'])
      h = config.to_h

      assert_equal :null, h[:llm_mode]
      assert_equal 7, h[:seed]
      assert_equal config.population_size, h[:population_size]
    end

    class FakePrompt
      def initialize(select:, ask:)
        @select_answers = select
        @ask_answers = ask
      end

      def select(question, _choices, **_opts)
        @select_answers.fetch(question) { raise "Unexpected select prompt: #{question}" }
      end

      def ask(question, **_opts)
        @ask_answers.fetch(question) { raise "Unexpected ask prompt: #{question}" }
      end
    end
  end
end
