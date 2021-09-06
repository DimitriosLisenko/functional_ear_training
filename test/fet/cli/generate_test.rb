# frozen_string_literal: true

require "test_helper"
require "securerandom"

module Fet
  class GenerateTest < Minitest::Test
    def setup
      @directory_prefix = File.join("tmp", SecureRandom.uuid)
    end

    def teardown
      FileUtils.rm_rf(@directory_prefix)
    end

    def test_generate_listening
      options = {
        exercises: 1, degrees: 1, tempo: 120,
        "all-single-degree": false, directory_prefix: @directory_prefix,
      }
      Fet::Cli::Generate::Listening.run(nil, options, nil)
    end

    def test_generate_single_note_listening
      options = { tempo: 120, directory_prefix: @directory_prefix }
      Fet::Cli::Generate::SingleNoteListening.run(nil, options, nil)
    end

    def test_generate_singing
      options = { tempo: 120, pause: 3, directory_prefix: @directory_prefix }
      Fet::Cli::Generate::Singing.run(nil, options, nil)
    end
  end
end
