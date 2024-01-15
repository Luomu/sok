require 'app/core_dicetest.rb'
require 'app/core_curvetest.rb'
require 'app/core_intro_outro.rb'
require 'app/core_results.rb'

# Overall game states
# 1. Main menu
# 2. Intro
# 3. Strategy mode
# 4. Adventure mode
# 5. Win/lose cinematic
# 6. Final results
class CoreFsm < Fsm
  def initialize
    super

    states[:corefsm_state_menu]      = GameState_MainMenu.new(self)
    states[:corefsm_state_intro]     = GameState_Intro.new(self)
    states[:corefsm_state_strategy]  = GameState_Strategy.new(self)
    states[:corefsm_state_adventure] = GameState_Adventure.new(self)
    states[:corefsm_state_outro]     = GameState_Outro.new(self)
    states[:corefsm_state_results]   = GameState_Results.new(self)

    #states[:dicetest]  = GameState_DiceTest.new(self)
    #states[:curvetest] = GameState_CurveTest.new(self)
    #transition_to(:dicetest)
    #transition_to(:curvetest)
    transition_to(:corefsm_state_menu)

    $game_events.subscribe(Events::ENABLE_AUTOSAVE, method(:save_to_slot_and_enable_autosave))
    $game_events.subscribe(Events::AUTOSAVE,        method(:save_game))
  end

  # Transition to adventure
  def begin_mission
    transition_to(:corefsm_state_adventure)
  end

  # Transition to outro and then results
  def retire
    transition_to(:corefsm_state_outro)
  end

  SAVE_DIR = "data"
  # Returns an array of three save slots: nil if no save
  def enumerate_saves
    saves    = [nil, nil, nil]
    files    = $gtk.list_files(SAVE_DIR)
    return [
      files.select { |x| x == "savegame1.txt" }.first,
      files.select { |x| x == "savegame2.txt" }.first,
      files.select { |x| x == "savegame3.txt" }.first
    ]
  end

  def load_game save_name
    parsed_state = $gtk.deserialize_state("#{SAVE_DIR}/#{save_name}")
    raise "Failed to parse save game" unless parsed_state
    $gtk.args.state = parsed_state
    $state          = $gtk.args.state
    # Do these really need to be manually deserialized?
    missions = []
    parsed_state.missions.each do |m|
      missions << Mission.new(m.fetch(:seed))
    end

    soldier_pool = []
    parsed_state.available_soldiers.each do |s|
      char = Character.new
      char.from_hash(s)
      soldier_pool << char
    end

    $gtk.args.state.company            = Company.deserialize(parsed_state.company)
    $gtk.args.state.missions           = missions
    $gtk.args.state.available_soldiers = soldier_pool
    $gtk.args.state.quickstart         = true
    $gtk.args.state.intro_viewed       = true
    initialize_saved_game($args)
    transition_to(:corefsm_state_strategy)
    Notify.send("Game loaded", 100)
  end

  def save_game payload
    slot_idx = $state.save_slot_idx
    $gtk.args.state.save_version = SAVEGAME_VERSION
    if slot_idx
      $gtk.serialize_state("#{SAVE_DIR}/savegame#{slot_idx}.txt", $gtk.args.state)
      # Strategy.eventbus.publish(Events::GAME_SAVED, ...)
      Notify.send("Game saved to slot #{slot_idx}", 100)
    end
  end

  # Save game support
  def save_to_slot_and_enable_autosave slot_number
    raise "Invalid slot number" unless [1,2,3].include? (slot_number)
    Strategy.eventbus.publish(Events::MESSAGE, "Game saved to Slot #{slot_number}. Autosaving after every mission.")
    $state.save_slot_idx = slot_number
    save_game(nil)
  end
end
