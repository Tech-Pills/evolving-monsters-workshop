# frozen_string_literal: true

require_relative '../test_helper'
require 'llm/error'
require 'llm/prompts'
require 'llm/ollama'
require 'monster'
require 'race'

module LLM
  class OllamaTest < Minitest::Test
    class RecordingTransport
      attr_reader :calls

      def initialize(response)
        @response = response
        @calls = []
      end

      def call(uri, payload)
        @calls << { uri: uri, payload: payload }
        @response
      end
    end

    def setup
      @monster = Monster.new(speed: 35, strength: 25, stamina: 20, intelligence: 10, luck: 10)
    end

    def test_generate_identity_posts_to_generate_endpoint
      json = '{"name":"Ironclad","backstory":"a tale","battle_cry":"rawr","special_ability":"smash"}'
      transport = RecordingTransport.new('response' => json)
      adapter = LLM::Ollama.new(model: 'llama3.2', transport: transport)

      identity = adapter.generate_identity(@monster)

      assert_equal 'Ironclad', identity[:name]
      assert_equal 1, transport.calls.length
      call = transport.calls.first

      assert_equal '/api/generate', call[:uri].path
      assert_equal 11_434, call[:uri].port
      assert_equal 'llama3.2', call[:payload][:model]
      refute call[:payload][:stream]
      assert_equal LLM::Prompts::IDENTITY_SCHEMA, call[:payload][:format]
      assert_equal LLM::Prompts::SYSTEM, call[:payload][:system]
      assert_match(/35/, call[:payload][:prompt])
    end

    def test_commentate_race_omits_format
      transport = RecordingTransport.new('response' => 'wow what a race')
      adapter = LLM::Ollama.new(transport: transport)
      results = Race.call(Array.new(3) { Monster.random }).results

      text = adapter.commentate_race(results)

      assert_equal 'wow what a race', text
      refute transport.calls.first[:payload].key?(:format),
             'Free-form text calls should not constrain output format'
    end

    def test_narrate_evolution_returns_text
      transport = RecordingTransport.new('response' => 'an arc of strength')
      adapter = LLM::Ollama.new(transport: transport)
      history = [
        { generation: 0, best_fitness: 5, avg_fitness: 3.0,
          attribute_averages: { speed: 20, strength: 20, stamina: 20, intelligence: 20, luck: 20 } },
        { generation: 4, best_fitness: 8, avg_fitness: 5.0,
          attribute_averages: { speed: 25, strength: 22, stamina: 18, intelligence: 19, luck: 16 } }
      ]

      assert_equal 'an arc of strength', adapter.narrate_evolution(history)
    end

    def test_raises_llm_error_on_transport_failure
      transport = ->(_uri, _payload) { raise StandardError, 'connection refused' }
      adapter = LLM::Ollama.new(transport: transport)

      err = assert_raises(LLM::Error) { adapter.generate_identity(@monster) }
      assert_match(/connection refused/, err.message)
    end

    def test_raises_llm_error_on_missing_response_field
      transport = RecordingTransport.new('error' => 'model not found')
      adapter = LLM::Ollama.new(transport: transport)

      assert_raises(LLM::Error) { adapter.generate_identity(@monster) }
    end

    def test_raises_llm_error_on_invalid_identity_json
      transport = RecordingTransport.new('response' => 'this is not json')
      adapter = LLM::Ollama.new(transport: transport)

      assert_raises(LLM::Error) { adapter.generate_identity(@monster) }
    end

    def test_call_includes_num_predict_in_options_payload
      transport = RecordingTransport.new('response' => 'go go go')
      adapter = LLM::Ollama.new(transport: transport)
      results = Race.call(Array.new(3) { Monster.random }).results

      adapter.commentate_race(results)

      options = transport.calls.first[:payload][:options]

      assert_kind_of Hash, options
      assert_equal LLM::Ollama::DEFAULT_NUM_PREDICT, options[:num_predict]
    end

    def test_custom_num_predict_kwarg_is_passed_through
      transport = RecordingTransport.new('response' => 'short')
      adapter = LLM::Ollama.new(transport: transport, num_predict: 50)
      results = Race.call(Array.new(3) { Monster.random }).results

      adapter.commentate_race(results)

      assert_equal 50, transport.calls.first[:payload][:options][:num_predict]
    end

    def test_custom_timeouts_are_stored
      adapter = LLM::Ollama.new(transport: ->(*) { {} }, open_timeout: 1, read_timeout: 7)

      assert_equal 1, adapter.instance_variable_get(:@open_timeout)
      assert_equal 7, adapter.instance_variable_get(:@read_timeout)
    end
  end
end
