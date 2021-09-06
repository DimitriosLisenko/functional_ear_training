# frozen_string_literal: true

require "test_helper"

module Fet
  module Ui
    module GameTestHelper
      def teardown
        Ruby2D::Window.clear
      end

      private

      def select_correct_note_with_tests(game, select_using_mouse)
        assert(!game.level.over?)
        correct_note_box = game.level.note_boxes.note_boxes.detect(&:correct?)
        assert_note_box_original_color(correct_note_box)
        select_using_mouse ? click_note_box(game, correct_note_box) : keyboard_select_note_box(game, correct_note_box)
        assert_note_box_correct_color(correct_note_box)
        assert(game.level.over?)
      end

      def select_wrong_note_with_tests(game, select_using_mouse)
        assert(!game.level.over?)
        correct_note_box = correct_note_box(game)
        wrong_note_box = any_wrong_note_box(game)
        assert_note_box_original_color(correct_note_box)
        assert_note_box_original_color(wrong_note_box)
        select_using_mouse ? click_note_box(game, wrong_note_box) : keyboard_select_note_box(game, wrong_note_box)
        assert_note_box_correct_color(correct_note_box)
        assert_note_box_wrong_color(wrong_note_box)
        assert(game.level.over?)
      end

      def correct_note_box(game)
        return game.level.note_boxes.note_boxes.detect(&:correct?)
      end

      def any_wrong_note_box(game)
        return game.level.note_boxes.note_boxes.reject(&:correct?).first
      end

      def note_box_square(note_box)
        return note_box.send(:square)
      end

      def assert_note_box_original_color(note_box)
        degree = Degree.new(note_box.degree_name)
        if degree.degree_accidental.nil?
          assert_color_equal(Ruby2D::Color.new(Fet::Ui::ColorScheme::WHITE), note_box_square(note_box).color)
        else
          assert_color_equal(Ruby2D::Color.new(Fet::Ui::ColorScheme::GREY), note_box_square(note_box).color)
        end
      end

      def assert_note_box_correct_color(note_box)
        assert_color_equal(Ruby2D::Color.new(Fet::Ui::ColorScheme::GREEN), note_box_square(note_box).color)
      end

      def assert_note_box_wrong_color(note_box)
        assert_color_equal(Ruby2D::Color.new(Fet::Ui::ColorScheme::RED), note_box_square(note_box).color)
      end

      def click_note_box(game, note_box)
        click_event = Ruby2D::Window::MouseEvent.new(
          :down, :left, nil,
          note_box_square(note_box).x + (note_box_square(note_box).size / 2),
          note_box_square(note_box).y + (note_box_square(note_box).size / 2),
        )
        game.handle_event_loop(click_event)
      end

      def keyboard_select_note_box(game, note_box)
        degree_name_to_button_presses(note_box.degree_name).each { |key| press_key(game, key) }
      end

      def press_key(game, key)
        key_event = Ruby2D::Window::KeyEvent.new(:down, key)
        game.handle_event_loop(key_event)
      end

      def game_instance_test(game)
        with_stubs do
          game.start
          yield
          game.stop
        end
      end

      def with_stubs
        stub_ruby2d_objects { stub_our_objects { yield } }
      end

      def stub_our_objects
        stub_score_writing { yield }
      end

      def stub_ruby2d_objects
        stub_window_show { stub_window_close { stub_music_instance_play { stub_music_initialize { stub_text_initialize { yield } } } } }
      end

      def stub_window_show
        Ruby2D::Window.stub(:show, nil) { yield }
      end

      def stub_window_close
        Ruby2D::Window.stub(:close, nil) { yield }
      end

      def stub_music_instance_play
        Ruby2D::Music.stub_any_instance(:play, nil) { yield }
      end

      def stub_text_initialize
        Ruby2D::Text.stub(:new, FakeText.method(:new)) { yield }
      end

      def stub_music_initialize
        Ruby2D::Music.stub(:new, FakeMusic.method(:new)) { yield }
      end

      def stub_score_writing
        # NOTE: in order to make this work correctly, need to make sure that
        # the stub for Ruby2D::Window stays running until it receives a signal. However,
        # Ruby2D really doesn't like being called from a thread (throws random exceptions),
        # so might have to run the test inside a thread + use Queue.new for sync?
        Fet::Ui::Game.stub_any_instance(:write_score_to_file, nil) { yield }
      end

      def assert_color_equal(expected, actual)
        assert_in_delta(expected.r, actual.r)
        assert_in_delta(expected.g, actual.g)
        assert_in_delta(expected.b, actual.b)
        assert_in_delta(expected.a, actual.a)
      end

      def degree_name_to_button_presses(degree_name)
        degree = Degree.new(degree_name)

        result = []
        result << case degree.degree_accidental
                  when "b"
                    "-"
                  when "#"
                    "+"
                  end
        result << degree.degree_value.to_s
        return result.compact
      end
    end

    # NOTE: this is required because it seems that at the moment even initializing the Ruby2D::Text object
    # starts up a Ruby process that I guess is supposed to be the UI, and makes GitHub actions fail with
    # Error: (SDL_Init) No available video device
    # NOTE: if this resolves the issue of the Ruby process starting, then maybe we can run the game in a thread for tests
    class FakeText
      attr_accessor :text, :color, :x, :y, :size, :font

      def initialize(text, **args)
        self.text = text
        self.color = args[:color]
        self.x = args[:x]
        self.y = args[:y]
        self.size = args[:size]
        self.font = args[:font]
      end
    end

    # NOTE: also load Ruby process as Ruby2D::Text
    class FakeMusic
      attr_accessor :path, :loop, :number_of_times_played

      def initialize(path)
        self.path = path
        self.number_of_times_played = 0
      end

      def play
        self.number_of_times_played += 1
      end
    end
  end
end
