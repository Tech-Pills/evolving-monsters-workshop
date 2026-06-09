# frozen_string_literal: true

require 'pastel'
require 'tty-box'
require 'tty-progressbar'
require 'tty-spinner'
require 'tty-table'

require_relative 'emergence'
require_relative '../monster'

module CLI
  class Display
    DIVERSITY_BLOCKS = %w[▁ ▂ ▃ ▄ ▅ ▆ ▇ █].freeze

    attr_reader :output, :pastel

    def initialize(output: $stdout)
      @output = output
      @pastel = Pastel.new(enabled: output.respond_to?(:tty?) && output.tty?)
    end

    def banner(title, color: :cyan)
      text = pastel.decorate(" #{title} ", color, :bold)
      output.puts
      output.puts TTY::Box.frame(text, padding: [0, 1], align: :left, border: :light)
    end

    def header_line(message)
      output.puts pastel.dim("  #{message}")
    end

    def provider_line(provider, auto_fallback: false)
      output.puts pastel.dim("  LLM provider: #{pastel.bold(provider)}")
      return unless auto_fallback

      output.puts pastel.dim(
        '  (no Claude/Ollama detected — pass --llm null to silence this notice)'
      )
    end

    def config_summary(config)
      entries = config.to_h.map { |k, v| [pastel.bold(k.to_s), v.inspect] }
      rows = entries.each_slice(2).map do |pair|
        left, right = pair
        right ||= ['', '']
        [left[0], left[1], right[0], right[1]]
      end
      table = TTY::Table.new(rows)
      output.puts table.render(:unicode, padding: [0, 1])
    end

    def leaderboard(race_results, limit: 10)
      header = ['#', 'Name', 'Speed', 'Str', 'Sta', 'Int', 'Lck', 'Score', 'Fitness']
      rows = race_results.first(limit).map do |r|
        m = r[:monster]
        [
          r[:placement],
          m.name || '—',
          m.speed, m.strength, m.stamina, m.intelligence, m.luck,
          r[:total_score].round,
          m.fitness.round
        ]
      end
      table = TTY::Table.new(header, rows)
      output.puts table.render(:unicode, padding: [0, 1],
                                         alignments: %i[right left right right right right right right right])
    end

    def generation_line(stats, diversity)
      line = format('  gen %<gen>2d  best=%<best>5.1f  avg=%<avg>5.1f  diversity=%<div>6.2f',
                    gen: stats[:generation], best: stats[:best_fitness],
                    avg: stats[:avg_fitness], div: diversity)
      output.puts pastel.dim(line)
    end

    def generation_advance(total:)
      if output.respond_to?(:tty?) && output.tty?
        bar = TTY::ProgressBar.new(
          'Evolving [:bar] gen :current/:total  best=:best  avg=:avg  div=:div',
          total: total, width: 20, output: output, complete: '█', incomplete: '░'
        )
        lambda do |stats, diversity|
          bar.advance(1,
                      best: format('%5.1f', stats[:best_fitness]),
                      avg: format('%5.1f', stats[:avg_fitness]),
                      div: format('%6.2f', diversity))
        end
      else
        ->(stats, diversity) { generation_line(stats, diversity) }
      end
    end

    def with_spinner(label)
      if output.respond_to?(:tty?) && output.tty?
        spinner = TTY::Spinner.new("[:spinner] #{label}", format: :dots, output: output)
        spinner.auto_spin
        cleaned = false
        begin
          result = yield
          spinner.success(pastel.green('done'))
          cleaned = true
          result
        rescue StandardError => e
          spinner.error(pastel.red("error: #{e.message}"))
          cleaned = true
          raise
        ensure
          spinner.stop unless cleaned
        end
      else
        output.print "  #{label}... "
        result = yield
        output.puts 'done'
        result
      end
    end

    def drift_table(history)
      rows = Emergence.drift_table(history).map do |r|
        delta = r[:delta].round(1)
        arrow = if delta.positive?
                  pastel.green("+#{delta}")
                elsif delta.negative?
                  pastel.red(delta.to_s)
                else
                  pastel.dim('0.0')
                end
        [pastel.bold(r[:attribute].to_s), r[:start].round(1), r[:finish].round(1), arrow]
      end
      table = TTY::Table.new(%w[Attribute Start Finish Δ], rows)
      output.puts table.render(:unicode, padding: [0, 1], alignments: %i[left right right right])
    end

    def diversity_sparkline(history)
      series = Emergence.diversity_series(history)
      return if series.empty?

      max = series.map(&:last).max
      return if max.zero?

      blocks = series.map do |(_, value)|
        idx = ((value / max) * (DIVERSITY_BLOCKS.length - 1)).round
        DIVERSITY_BLOCKS[idx.clamp(0, DIVERSITY_BLOCKS.length - 1)]
      end
      output.puts "  Diversity: #{pastel.magenta(blocks.join)}  (max #{max.round(2)})"
    end

    def archetype_line(history)
      label = Emergence.archetype_for(history.last || {})
      collapsed = Emergence.collapsed?(history)
      tag = collapsed ? pastel.yellow.bold(' (converged tightly)') : ''
      output.puts "  Archetype: #{pastel.cyan.bold(label)}#{tag}"
    end

    def narration_box(title, body)
      framed = TTY::Box.frame(
        body.to_s.strip,
        padding: [0, 1],
        title: { top_left: " #{title} " },
        border: :light
      )
      output.puts framed
    end

    def closing(message)
      output.puts
      output.puts pastel.green.bold("  #{message}")
    end
  end
end
