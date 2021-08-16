#!/usr/bin/env ruby

require "fileutils"
require "./midi.rb"

# All 12 degrees
DEGREES = ["1", "b2", "2", "b3", "3", "4", "b5", "5", "b6", "6", "b7", "7"]

# All keys. First element is 5 sharps, 4 sharps, ... 0 sharps/flats, 1 flat, ... all the way up to 6 flats.
# No 6 sharps because the 6 flat versions are enharmonic and more common.
# These keys chosen because they contain only flats and sharps, no double flats/sharps.
MAJOR_KEYS = ["B", "E", "A", "D", "G", "C", "F", "Bb", "Eb", "Ab", "Db", "Gb"]
MINOR_KEYS = ["G#", "C#", "F#", "B", "E", "A", "D", "G", "C", "F", "Bb", "Eb"]

# In midilib, 0 is C(-2).
MIDI_VALUE_C0 = 24
MIDI_VALUE_C1 = 36
MIDI_VALUE_C2 = 48
MIDI_VALUE_C3 = 60
MIDI_VALUE_C4 = 72
MIDI_VALUE_C5 = 84
MIDI_VALUE_C6 = 96
MIDI_VALUE_C7 = 108
MIDI_VALUE_C8 = 120

MIDI_VALUE_ADDITION_C = 0
MIDI_VALUE_ADDITION_C_SHARP = 1
MIDI_VALUE_ADDITION_D_FLAT = 1
MIDI_VALUE_ADDITION_D = 2
MIDI_VALUE_ADDITION_D_SHARP = 3
MIDI_VALUE_ADDITION_E_FLAT = 3
MIDI_VALUE_ADDITION_E = 4
MIDI_VALUE_ADDITION_F = 5
MIDI_VALUE_ADDITION_F_SHARP = 6
MIDI_VALUE_ADDITION_G_FLAT = 6
MIDI_VALUE_ADDITION_G = 7
MIDI_VALUE_ADDITION_G_SHARP = 8
MIDI_VALUE_ADDITION_A_FLAT = 8
MIDI_VALUE_ADDITION_A = 9
MIDI_VALUE_ADDITION_A_SHARP = 10
MIDI_VALUE_ADDITION_B_FLAT = 10
MIDI_VALUE_ADDITION_B = 11

# Maps root note to MIDI value
MAJOR_KEY_ROOT_NOTE = {
  "B" => 47,
  "E" => 40,
  "A" => 45,
  "D" => 50,
  "G" => 43,
  "C" => 48,
  "F" => 41,
  "Bb" => 46,
  "Eb" => 51,
  "Ab" => 44,
  "Db" => 49,
  "Gb" => 42
}
MAJOR_KEY_ROOT_NOTE.each { |k, v| MAJOR_KEY_ROOT_NOTE[k] = v + 12 } # Octave higher sounds better
MINOR_KEY_ROOT_NOTE = MINOR_KEYS.zip(MAJOR_KEY_ROOT_NOTE.values.map { |i| i - 3 }).to_h


# MAJOR_PROGRESSION = [[0, 4, 7], [5, 9, 12], [7, 11, 14], [0, 4, 7]]
# MINOR_PROGRESSION = [[0, 3, 7], [5, 8, 12], [7, 10, 14], [0, 3, 7]]
MAJOR_PROGRESSION = [[0, 4, 7], [0, 5, 9], [-1, 5, 7], [0, 4, 7]]
MINOR_PROGRESSION = [[0, 3, 7], [0, 5, 8], [-1, 5, 7], [0, 3, 7]]

# PIANO_RANGE = ((MIDI_VALUE_C0 + MIDI_VALUE_ADDITION_A)..MIDI_VALUE_C8).to_a # A0 - C8 Maybe reduce range a little? Can vary wildly atm
PIANO_RANGE = ((MIDI_VALUE_C0 + MIDI_VALUE_ADDITION_A)..MIDI_VALUE_C6).to_a # A0 - C6
# GUITAR_RANGE = ((MIDI_VALUE_C2 + MIDI_VALUE_ADDITION_E)..(MIDI_VALUE_C6 + MIDI_VALUE_ADDITION_E)).to_a # E2 - E6

def main
  number_degrees = ARGV[0].to_i
  if !(1..11).to_a.include?(number_degrees)
    puts "Usage: ruby main.rb {number of degrees} {number of exercises} {tempo}"
    puts "Please enter number of degrees from 1 to 11 inclusive"
    return
  end
  number_exercises = ARGV[1].to_i
  if !(1..1000).to_a.include?(number_exercises)
    puts "Usage: ruby main.rb {number of degrees} {number of exercises} {tempo}"
    puts "Please enter number of exercises to create from 1 to 200 inclusive"
    return
  end
  tempo = ARGV[2].to_i
  if !(40..250).to_a.include?(tempo)
    puts "Usage: ruby main.rb {number of degrees} {number of exercises} {tempo}"
    puts "Please enter tempo from 40 to 250 inclusive"
    return
  end

  FileUtils.mkdir_p("listening/minor")
  FileUtils.mkdir_p("listening/major")

  number_exercises.times do
    # Create major key exercises
    root = MAJOR_KEY_ROOT_NOTE.to_a.sample
    until select_notes_recursive(PIANO_RANGE, [], root, number_degrees, "major", tempo); end

    # Create minor key exercises
    root = MINOR_KEY_ROOT_NOTE.to_a.sample
    until select_notes_recursive(PIANO_RANGE, [], root, number_degrees, "minor", tempo); end
  end
end

def select_notes_recursive(all_notes, chosen_notes, root, number_degrees, key_type, tempo)
  if number_degrees == 0
    chosen_notes.sort! # So file name corresponds to degree of lowest to highest
    info = "Key: #{root[0]} #{key_type} Degrees: #{chosen_notes.map { |i| DEGREES[(i - root[1]) % 12] }} Notes: #{chosen_notes}"
    puts info if ARGV[3] == "debug"

    if key_type == "major"
      progression = MAJOR_PROGRESSION.map { |chord| chord.map { |note| note + root[1] } }
    elsif key_type == "minor"
      progression = MINOR_PROGRESSION.map { |chord| chord.map { |note| note + root[1] } }
    end

    file_name = "./listening/#{key_type}/#{root[0]}#{key_type == "major" ? "M" : "m"}_#{chosen_notes.map { |i| "#{DEGREES[(i - root[1]) % 12]}(#{i})" }.join("_")}.mid"
    return false if File.exists?(file_name)

    create_midi_file(tempo, progression, chosen_notes, info, file_name)
    return true
  end

  random_note = all_notes.sample
  chosen_notes << random_note

  degree = (random_note - root[1]) % 12
  all_notes_without_note_degree = all_notes.select { |note| (note - root[1]) % 12 != degree }
  select_notes_recursive(all_notes_without_note_degree, chosen_notes, root, number_degrees - 1, key_type, tempo)
end

main

# All 12 notes (ended up not using it, but could use it later to show note)
# "Note Names: #{chosen_notes.map { |i| NOTES[i % 12] }}" # Would need to figure out whether to use flat/natural/sharp for a given key - could have map with this info
# To get notes for starting from a specific root, do something like
# root_index = NOTES.index { |note| note.include?(root_note) }
# x[root_index..-1] + x[0...root_index]
# NOTES = [["B#", "C"], ["C#", "Db"], ["D"], ["D#", "Eb"], ["E", "Fb"], ["E#", "F"], ["F#", "Gb"], ["G"], ["G#", "Ab"], ["A"], ["A#", "Bb"], ["B", "Cb"]]
