# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require_relative 'error'
require_relative 'prompts'

module LLM
  class Ollama
    DEFAULT_ENDPOINT = URI('http://localhost:11434/api/generate')
    # You can just curl http://localhost:11434 to make sure
    DEFAULT_MODEL = 'llama3.2'
    DEFAULT_OPEN_TIMEOUT = 10
    DEFAULT_READ_TIMEOUT = 120
    DEFAULT_NUM_PREDICT = 350

    def initialize(model: DEFAULT_MODEL, endpoint: DEFAULT_ENDPOINT, transport: nil,
                   open_timeout: DEFAULT_OPEN_TIMEOUT, read_timeout: DEFAULT_READ_TIMEOUT,
                   num_predict: DEFAULT_NUM_PREDICT)
      @model = model
      @endpoint = endpoint
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @num_predict = num_predict
      @transport = transport || method(:default_transport)
    end

    def generate_identity(monster)
      raw = call(LLM::Prompts.identity_user(monster), format: LLM::Prompts::IDENTITY_SCHEMA)
      LLM::Prompts.parse_identity(raw)
    end

    def commentate_race(race_results)
      call(LLM::Prompts.commentary_user(race_results)).strip
    end

    def narrate_evolution(history)
      call(LLM::Prompts.evolution_user(history)).strip
    end

    def summarize_run(history:, drift:, config_summary:)
      call(LLM::Prompts.summary_user(history, drift, config_summary)).strip
    end

    private

    def call(user_content, format: nil)
      payload = {
        model: @model,
        prompt: user_content,
        system: LLM::Prompts::SYSTEM,
        stream: false,
        options: { num_predict: @num_predict }
      }
      payload[:format] = format if format

      response = @transport.call(@endpoint, payload)
      raise LLM::Error, "Ollama response missing 'response' field: #{response.inspect}" unless response.key?('response')

      response.fetch('response')
    rescue LLM::Error
      raise
    rescue StandardError => e
      raise LLM::Error, "Ollama call failed: #{e.message}"
    end

    def default_transport(uri, payload)
      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json'
      req.body = payload.to_json
      res = Net::HTTP.start(uri.hostname, uri.port,
                            open_timeout: @open_timeout,
                            read_timeout: @read_timeout) { |http| http.request(req) }
      raise "HTTP #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body)
    end
  end
end
