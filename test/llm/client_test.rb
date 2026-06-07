# frozen_string_literal: true

require_relative '../test_helper'
require 'llm'

module LLM
  class ClientTest < Minitest::Test
    def test_returns_claude_when_api_key_present
      adapter = LLM::Client.auto_detect(
        env: { 'ANTHROPIC_API_KEY' => 'sk-test' },
        ollama_probe: -> { raise 'should not probe' }
      )

      assert_kind_of LLM::Claude, adapter
    end

    def test_returns_ollama_when_api_key_absent_and_probe_succeeds
      adapter = LLM::Client.auto_detect(
        env: {},
        ollama_probe: -> { true }
      )

      assert_kind_of LLM::Ollama, adapter
    end

    def test_returns_null_when_api_key_absent_and_probe_fails
      adapter = nil
      _out, err = capture_io do
        adapter = LLM::Client.auto_detect(
          env: {},
          ollama_probe: -> { false }
        )
      end

      assert_kind_of LLM::Null, adapter
      assert_match(/falling back to Null/, err)
    end

    def test_treats_empty_api_key_as_unset
      adapter = LLM::Client.auto_detect(
        env: { 'ANTHROPIC_API_KEY' => '' },
        ollama_probe: -> { true }
      )

      assert_kind_of LLM::Ollama, adapter
    end

    def test_describe_returns_a_string_label
      assert_equal 'Claude', LLM::Client.describe(LLM::Claude.new(api_key: 'x', client: Object.new))
      assert_equal 'Ollama', LLM::Client.describe(LLM::Ollama.new(transport: ->(*) {}))
      assert_equal 'Null',   LLM::Client.describe(LLM::Null.new)
    end
  end
end
