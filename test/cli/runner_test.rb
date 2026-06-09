# frozen_string_literal: true

require 'stringio'
require_relative '../test_helper'
require 'cli/runner'
require 'cli/display'
require 'cli/config'
require 'llm/null'

module CLI
  class RunnerTest < Minitest::Test
    def setup
      @io = StringIO.new
      @display = Display.new(output: @io)
      @config = Config.parse(['--llm', 'null', '--population', '6',
                              '--generations', '4', '--mutation-rate', '0.1',
                              '--narrate-every', '2', '--seed', '7'])
      @runner = Runner.new(config: @config, display: @display, adapter: LLM::Null.new(random: Random.new(7)))
    end

    def test_run_completes_end_to_end
      population = @runner.call

      assert_kind_of Population, population
      assert_equal 5, population.history.length
      assert_equal 4, population.generation
    end

    def test_output_contains_expected_sections
      @runner.call

      output = @io.string

      assert_match(/Evolving Monsters/, output)
      assert_match(/Generation 0/, output)
      assert_match(/Evolution loop/, output)
      assert_match(/Emergence/, output)
      assert_match(/Evolutionary arc/, output)
      assert_match(/Archetype/, output)
      assert_match(/Run complete/, output)
    end

    def test_output_includes_per_generation_lines
      @runner.call

      output = @io.string

      assert_match(/gen\s+1\s+best=/, output)
      assert_match(/gen\s+4\s+best=/, output)
      assert_match(/diversity=/, output)
    end

    def test_narration_fires_on_configured_cadence
      @runner.call

      output = @io.string

      assert_match(/Gen 2 commentary/, output)
      assert_match(/Gen 4 commentary/, output)
    end

    def test_no_intermediate_narration_when_disabled
      config = Config.parse(['--llm', 'null', '--population', '5',
                             '--generations', '3', '--narrate-every', '0', '--seed', '11'])
      io = StringIO.new
      runner = Runner.new(config: config, display: Display.new(output: io),
                          adapter: LLM::Null.new(random: Random.new(11)))
      runner.call

      output = io.string

      refute_match(/Gen \d+ commentary/, output)
      assert_match(/Narration/, output)
    end

    def test_seeded_runs_produce_identical_history
      a_io = StringIO.new
      b_io = StringIO.new
      a_config = Config.parse(['--llm', 'null', '--population', '6', '--generations', '3',
                               '--mutation-rate', '0.1', '--seed', '99'])
      b_config = Config.parse(['--llm', 'null', '--population', '6', '--generations', '3',
                               '--mutation-rate', '0.1', '--seed', '99'])
      a = Runner.new(config: a_config, display: Display.new(output: a_io),
                     adapter: LLM::Null.new(random: Random.new(99))).call
      b = Runner.new(config: b_config, display: Display.new(output: b_io),
                     adapter: LLM::Null.new(random: Random.new(99))).call

      a_diversity = a.history.map { |h| h[:diversity].round(4) }
      b_diversity = b.history.map { |h| h[:diversity].round(4) }

      assert_equal a_diversity, b_diversity
    end

    def test_runner_does_not_mutate_global_srand
      srand(12_345)
      baseline = rand

      srand(12_345)
      config = Config.parse(['--llm', 'null', '--population', '5', '--generations', '2',
                             '--mutation-rate', '0.1', '--seed', '42'])
      Runner.new(config: config, display: Display.new(output: StringIO.new),
                 adapter: LLM::Null.new(random: Random.new(42))).call
      after_run = rand

      assert_equal baseline, after_run, 'Runner leaked srand into the global RNG'
    end
  end
end
