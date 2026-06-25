#  frozen_string_literal: true

module LLM
  class Null
    ADJECTIVES = %w[
      Ancient Blazing Crimson Dread Eldritch Feral Gilded Howling
      Iron Jagged Knell Lurking Molten Nimble Obsidian Phantom
      Quicksilver Ragged Stoic Tempest Umbral Vexing Wraith Zealous
    ].freeze

    NOUNS = %w[
      Beast Champion Drake Echo Fang Gargoyle Hydra Imp
      Juggernaut Kraken Leviathan Manticore Nemesis Ogre Phoenix Quagmire
      Reaver Specter Titan Usurper Vagabond Warden Xenomorph Yeti
    ].freeze

    ABILITIES = {
      speed: ['Blink Step', 'Slipstream Dash', 'Afterimage'],
      strength: ['Bone Shatter', 'Earthcrush', 'Iron Grip'],
      stamina: ['Endless March', 'Second Wind', 'Iron Lung'],
      intelligence: ['Mind Maze', 'Pattern Sight', 'Sage Whisper'],
      luck: ["Fortune's Gift", 'Last-Second Pivot', 'Lucky Dodge']
    }.freeze

    BACKSTORIES = [
      'Born under a blood moon and raised in the obsidian wastes.',
      'Survivor of the Great Collapse, hardened by a hundred fights.',
      'Trained by reclusive monks high atop the cloud peaks.',
      'A laboratory escapee whose origin records were destroyed.',
      'Sole heir to a forgotten dynasty of arena champions.'
    ].freeze

    BATTLE_CRIES = [
      'You will remember this name.',
      'I am inevitability!',
      'No retreat. No regret.',
      'The arena is mine.',
      'Try to keep up.'
    ].freeze

    def initialize(random: Random.new)
      @random = random
    end

    def generate_identity(monster)
      dom = monster.dominant_attribute
      {
        name: "#{ADJECTIVES.sample(random: @random)} #{NOUNS.sample(random: @random)}",
        backstory: BACKSTORIES.sample(random: @random),
        battle_cry: BATTLE_CRIES.sample(random: @random),
        special_ability: ABILITIES.fetch(dom).sample(random: @random)
      }
    end

    def commentate_race(race_results)
      return 'The arena was empty.' if race_results.empty?

      winner = race_results.find { |r| r[:placement] == 1 }
      return 'No clear winner emerged.' unless winner

      runner_up = race_results.find { |r| r[:placement] == 2 }
      parts = []
      parts << "#{label(winner[:monster])} crossed the line first with #{winner[:total_score].round} points."
      parts << "#{label(runner_up[:monster])} pushed hard for second." if runner_up
      parts.join(' ')
    end

    def narrate_evolution(history)
      return 'No generations recorded.' if history.empty?

      first = history.first
      last = history.last
      generations = last[:generation] - first[:generation]
      drift = drift_summary(first[:attribute_averages], last[:attribute_averages])
      drift = 'no measurable drift' if drift.empty?
      "Across #{generations} generation#{'s' if generations != 1} the population shifted: #{drift}."
    end

    def summarize_run(history:, drift:, config_summary:)
      return 'No generations recorded.' if history.empty?

      first = history.first
      last = history.last
      generations = last[:generation] - first[:generation]
      diversity_arc = describe_diversity(first[:diversity], last[:diversity])
      largest = drift.max_by { |d| d[:delta].abs }
      strong_drift = drift.count { |d| d[:delta].abs >= 3 }

      parts = []
      parts << "Across #{generations} generations diversity #{diversity_arc}."
      parts << "Largest attribute drift: #{largest[:attribute]} #{format('%+.1f', largest[:delta])}." if largest
      parts << "#{strong_drift} of 5 attributes drifted by more than 3 points." if strong_drift.positive?
      parts.join(' ')
    end

    private

    def describe_diversity(first, last)
      return 'data unavailable' unless first && last && first.positive?

      ratio = last.to_f / first
      if ratio < 0.2 then 'collapsed sharply'
      elsif ratio < 0.6 then 'declined steadily'
      elsif ratio < 1.0 then 'shifted modestly'
      else 'stayed stable'
      end
    end

    def label(monster)
      monster.name.to_s.empty? ? "Monster #{monster.dominant_attribute}" : monster.name
    end

    def drift_summary(first_avgs, last_avgs)
      first_avgs.keys.map do |attr|
        delta = (last_avgs[attr] - first_avgs[attr]).round(1)
        next nil if delta.zero?

        "#{attr} #{'+' if delta.positive?}#{delta}"
      end.compact.join(', ')
    end
  end
end
