# frozen_string_literal: true

require_relative '../test_helper'
require 'llm/error'
require 'llm/prompts'
require 'llm/claude'
require 'monster'
require 'race'

module LLM
  class ClaudeTest < Minitest::Test
    class FakeMessages
      attr_reader :last_params

      def initialize(text)
        @text = text
      end

      def create(params)
        @last_params = params
        block = Struct.new(:type, :text).new(:text, @text)
        Struct.new(:content).new([block])
      end
    end

    class FakeAnthropicClient
      attr_reader :messages

      def initialize(text)
        @messages = FakeMessages.new(text)
      end
    end

    def setup
      @monster = Monster.new(speed: 40, strength: 20, stamina: 20, intelligence: 10, luck: 10)
    end

    def test_generate_identity_calls_messages_create_with_expected_params
      json = '{"name":"Ironclad","backstory":"a tale","battle_cry":"rawr","special_ability":"smash"}'
      fake = FakeAnthropicClient.new(json)
      adapter = LLM::Claude.new(client: fake, model: 'test-model')

      identity = adapter.generate_identity(@monster)

      assert_equal 'Ironclad', identity[:name]
      params = fake.messages.last_params

      assert_equal 'test-model', params[:model]
      assert_equal LLM::Prompts::SYSTEM, params[:system_]
      assert_predicate params[:max_tokens], :positive?
      assert_equal 1, params[:messages].length
      assert_equal 'user', params[:messages].first[:role]
      assert_match(/40/, params[:messages].first[:content])
    end

    def test_generate_identity_sends_json_schema_output_config
      json = '{"name":"Ironclad","backstory":"a tale","battle_cry":"rawr","special_ability":"smash"}'
      fake = FakeAnthropicClient.new(json)
      adapter = LLM::Claude.new(client: fake)

      adapter.generate_identity(@monster)
      output_config = fake.messages.last_params[:output_config]

      assert_kind_of Hash, output_config
      assert_equal 'json_schema', output_config[:format][:type]
      assert_equal LLM::Prompts::IDENTITY_SCHEMA, output_config[:format][:schema]
    end

    def test_commentate_race_omits_output_config
      fake = FakeAnthropicClient.new('What a thrilling finish!')
      adapter = LLM::Claude.new(client: fake)
      results = Race.call(Array.new(3) { Monster.random }).results

      adapter.commentate_race(results)

      refute fake.messages.last_params.key?(:output_config),
             'Free-form text calls should not constrain output format'
    end

    def test_commentate_race_returns_text_content
      fake = FakeAnthropicClient.new('What a thrilling finish!')
      adapter = LLM::Claude.new(client: fake)
      monsters = Array.new(3) { Monster.random }
      results = Race.call(monsters).results

      text = adapter.commentate_race(results)

      assert_equal 'What a thrilling finish!', text
    end

    def test_narrate_evolution_returns_text_content
      fake = FakeAnthropicClient.new('The population grew stronger over time.')
      adapter = LLM::Claude.new(client: fake)
      history = [
        { generation: 0, best_fitness: 5, avg_fitness: 3.0,
          attribute_averages: { speed: 20, strength: 20, stamina: 20, intelligence: 20, luck: 20 } },
        { generation: 3, best_fitness: 8, avg_fitness: 5.0,
          attribute_averages: { speed: 25, strength: 22, stamina: 18, intelligence: 19, luck: 16 } }
      ]

      text = adapter.narrate_evolution(history)

      assert_equal 'The population grew stronger over time.', text
    end

    def test_raises_llm_error_on_invalid_identity_json
      fake = FakeAnthropicClient.new('not json')
      adapter = LLM::Claude.new(client: fake)
      assert_raises(LLM::Error) { adapter.generate_identity(@monster) }
    end

    def test_raises_llm_error_when_content_is_empty
      empty_messages = Object.new
      def empty_messages.create(_params)
        Struct.new(:content).new([])
      end
      fake = Object.new
      fake.define_singleton_method(:messages) { empty_messages }

      adapter = LLM::Claude.new(client: fake)

      assert_raises(LLM::Error) { adapter.generate_identity(@monster) }
    end

    def test_raises_llm_error_on_transport_failure
      fake = Object.new
      def fake.messages
        self
      end

      def fake.create(_)
        raise StandardError, 'boom'
      end

      adapter = LLM::Claude.new(client: fake)

      err = assert_raises(LLM::Error) { adapter.generate_identity(@monster) }
      assert_match(/boom/, err.message)
    end
  end
end
