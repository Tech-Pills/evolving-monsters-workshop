# frozen_string_literal: true

require 'socket'
require_relative 'claude'
require_relative 'ollama'
require_relative 'null'

module LLM
  module Client
    OLLAMA_HOST = 'localhost'
    OLLAMA_PORT = 11_434
    OLLAMA_PROBE_TIMEOUT = 0.5

    module_function

    def auto_detect(env: ENV, ollama_probe: method(:default_ollama_probe))
      key = env['ANTHROPIC_API_KEY']
      return LLM::Claude.new(api_key: key) if key && !key.empty?
      return LLM::Ollama.new if ollama_probe.call

      warn 'LLM: no provider available (no ANTHROPIC_API_KEY, no Ollama on ' \
           "#{OLLAMA_HOST}:#{OLLAMA_PORT}); falling back to Null adapter."
      LLM::Null.new
    end

    def describe(adapter)
      case adapter
      when LLM::Claude then 'Claude'
      when LLM::Ollama then 'Ollama'
      when LLM::Null   then 'Null'
      end
    end

    PROBE_EXPECTED_ERRORS = [Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
                             Errno::ETIMEDOUT, Errno::ENETUNREACH].freeze

    def default_ollama_probe
      Socket.tcp(OLLAMA_HOST, OLLAMA_PORT, connect_timeout: OLLAMA_PROBE_TIMEOUT) { true }
    rescue *PROBE_EXPECTED_ERRORS
      false
    rescue StandardError => e
      warn "LLM: unexpected Ollama probe error (#{e.class}: #{e.message})"
      false
    end
  end
end
