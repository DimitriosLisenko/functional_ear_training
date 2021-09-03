# frozen_string_literal: true

require "pry-byebug"

module Fet
  module Ui
    # Determines and outputs the time spent playing
    class Timer
      def initialize(game)
        self.game = game
      end

      def start
        self.start_time = current_time
        self.text = generate_text
      end

      def handle_event_loop(event); end

      def handle_update_loop
        update_time_elapsed
      end

      private

      attr_accessor :game, :text, :start_time

      def update_time_elapsed
        text.text = time_elapsed
      end

      def time_elapsed
        seconds_elapsed = current_time - start_time

        minutes_elapsed = seconds_elapsed / 60
        seconds_elapsed -= minutes_elapsed * 60

        hours_elapsed = minutes_elapsed / 60
        minutes_elapsed -= (hours_elapsed * 60)

        return format_time_elapsed(hours_elapsed, minutes_elapsed, seconds_elapsed)
      end

      def format_time_elapsed(hours, minutes, seconds)
        hours_elapsed = format("%02d", hours)
        minutes_elapsed = format("%02d", minutes)
        seconds_elapsed = format("%02d", seconds)

        result = "#{minutes_elapsed}:#{seconds_elapsed}"
        result = "#{hours_elapsed}:#{result}" unless hours.zero?
        return result
      end

      def current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC).to_i
      end

      def generate_text
        Text.new(
          time_elapsed,
          x: 88, y: 337,
          font: "assets/fonts/PTSans/PTSans-Regular.ttf",
          size: 36,
          color: Fet::Ui::ColorScheme::WHITE,
        )
      end
    end
  end
end
