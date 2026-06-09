# frozen_string_literal: true

require_relative '../monster'

module CLI
  module Emergence
    ARCHETYPES = {
      speed: 'Sprinter',
      strength: 'Tank',
      stamina: 'Marathoner',
      intelligence: 'Sage',
      luck: 'Trickster'
    }.freeze

    module_function

    def archetype_for(snapshot)
      averages = snapshot[:attribute_averages]
      return 'Unformed' if averages.nil? || averages.empty?

      dominant = averages.max_by { |_, v| v }.first
      ARCHETYPES.fetch(dominant, 'Unformed')
    end

    def drift_table(history)
      return [] if history.empty?

      first = history.first[:attribute_averages] || {}
      last = history.last[:attribute_averages] || {}

      Monster::ATTRIBUTES.map do |attr|
        start = (first[attr] || 0.0).to_f
        finish = (last[attr] || 0.0).to_f
        {
          attribute: attr,
          start: start,
          finish: finish,
          delta: finish - start
        }
      end
    end

    def diversity_series(history)
      history.map { |snap| [snap[:generation], (snap[:diversity] || 0.0).to_f] }
    end

    def collapsed?(history, threshold: 0.2)
      series = diversity_series(history)
      return false if series.length < 2

      initial = series.first.last
      final = series.last.last
      return false if initial.zero?

      (final / initial) < threshold
    end
  end
end
