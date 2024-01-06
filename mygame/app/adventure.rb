require 'app/adventure_crawl.rb'
require 'app/adventure_event.rb'
require 'app/adventure_fx.rb'
require 'app/adventure_combat_rules.rb'
require 'app/adventure_combat.rb'
require 'app/adventure_results.rb'
require 'app/adventure_debug.rb'

# Constants
module Adventure
  # Various encounter types for adventure
  ENCOUNTER_COMBAT = :adventure_encounter_combat
  ENCOUNTER_EVENT  = :adventure_encounter_event
  ENCOUNTER_REST   = :adventure_encounter_rest
  ENCOUNTER_END    = :adventure_encounter_end

  INTRO_LENGTH = 60 * 5

  EVENT_HIGHLIGHT_CHARACTER = :event_highlight_character
  EVENT_HIGHLIGHT_TARGET    = :event_highlight_target
  EVENT_CHEAT_KILL_ENEMIES  = :event_cheat_kill_enemies
  EVENT_CHEAT_KILL_PARTY    = :event_cheat_kill_party
  EVENT_CHEAT_HEAL_PARTY    = :event_cheat_heal_party
  EVENT_CHEAT_END_MISSION   = :event_cheat_end_mission

  #Adventure.eventsbus.publish(...), .subscribe(...)
  def self.eventbus
    return @@adventure_eventbus
  end

  def self.init
    @@adventure_eventbus = EventBus.new()
  end
end

# Dungeon Crawling mode
# 1. Dungeon scrolls automatically
# 2. Random encounters trigger randomly
# 3. Random events trigger less often
# 4. Periodically, offer a choice to REST or EXTRACT (push your luck)
class GameState_Adventure < FsmState
  attr_accessor :progress
  attr_accessor :is_over
  attr_accessor :encounters
  attr_accessor :current_encounter
  attr_reader   :party #team_squad without the empty slots
  attr_reader   :mission
  attr_accessor :collected_loot
  attr_accessor :stat_checkpoints_reached
  attr_accessor :stat_enemies_killed

  # Adventure mode begins
  def on_enter args
    Adventure.init()

    # when testing, generate a dummy mission
    if !args.state.mission
      $gtk.log_info("No mission set, generating test mission")
      args.state.mission = Mission.new(rand())
      args.state.mission.challenge = TEST_MISSION_CHALLENGE
    end

    # Seed the randomizer for this mission - used to pick encounters etc
    srand(args.state.mission.random_seed)

    @mission           = args.state.mission
    @progress          = 0
    @is_over           = false
    @mission_name      = "Operation " + args.state.mission.name.upcase
    @encounters        = Encounter.build_encounter_list(@mission)
    @current_encounter = nil
    @debug_screen      = nil
    @collected_loot    = []

    @stat_checkpoints_reached = 0
    @stat_enemies_killed      = 0

    # team_squad without the empty slots
    @party = args.state.company.team_squad.select { |soldier| soldier != nil }
    @party.each do |soldier|
      # Set up a sprite wrapper to track the on screen location
      soldier.combat_graphic = Adventure::SoldierSprite.new(0, 0, PORTRAIT_WIDTH, PORTRAIT_HEIGHT)
    end
    set_up_initial_equipment(args.state.company)

    @fsm = Fsm.new()
    @fsm.states[:adventure_state_intro]   = Adventure::State_Intro.new(@fsm)
    @fsm.states[:adventure_state_crawl]   = Adventure::State_Crawl.new(@fsm, self)
    @fsm.states[:adventure_state_event]   = Adventure::State_Event.new(@fsm, self)
    @fsm.states[:adventure_state_combat]  = Adventure::State_Combat.new(@fsm, self)
    @fsm.states[:adventure_state_results] = Adventure::State_Results.new(@fsm, self)
    @fsm.transition_to(:adventure_state_intro)

    if args.state.combat_test
      @fsm.transition_to(:adventure_state_combat)
    end

    @highlighted_soldier = nil
    Adventure.eventbus.subscribe(Adventure::EVENT_HIGHLIGHT_CHARACTER, method(:on_soldier_highlight_changed))
    Adventure.eventbus.subscribe(Adventure::EVENT_CHEAT_KILL_PARTY,    method(:on_cheat_kill_party))
    Adventure.eventbus.subscribe(Adventure::EVENT_CHEAT_HEAL_PARTY,    method(:on_cheat_heal_party))
    Adventure.eventbus.subscribe(Adventure::EVENT_CHEAT_END_MISSION,   method(:on_cheat_end_mission))

    $game_events.publish(Events::ENTER_ADVENTURE)
  end

  # Give everyone armor/weapons based on the company unlocks
  def set_up_initial_equipment company
    raise "No party?" if @party == nil or party.empty?
    melee_wpn  = Rules.get_melee_weapon_for_level(company.weapon_level)
    ranged_wpn = Rules.get_ranged_weapon_for_level(company.weapon_level)
    @party.each do |soldier|
      soldier.armor.max = soldier.armor.current = company.armor_level
      if soldier.strength.current > soldier.dexterity.current
        soldier.weapon = melee_wpn
      else
        soldier.weapon = ranged_wpn
      end
    end
  end

  # Apply results
  # Clean up since the state has global lifetime
  def on_exit args
    @collected_loot = nil
    @fsm            = nil

    $game_events.publish(Events::EXIT_ADVENTURE)
    #events don't need to be cleaned up as eventbus is re-initialized on next on_enter
  end

  def on_update args
    # Return to base
    if @is_over
      @parent_fsm.transition_to(:corefsm_state_strategy)
      return
    end

    # Operation name at the top
    Rendering.set_color(COLOR_TEXT_NORMAL)
    Rendering.text_left(30, 40.from_top, @mission_name)
    Rendering.text_left(30, 65.from_top, "Loot collected: #{@collected_loot.length}")

    render_squad(args)
    @fsm.update(args)

    Gui.draw_hotkeys()

    if Debug.cheats_enabled? and args.inputs.keyboard.key_down.five
      if @debug_screen
        ScreenManager.close(@debug_screen)
        @debug_screen = nil
      else
        @debug_screen = ScreenManager.open(AdventureDebugScreen.new(self))
      end
    end

    ScreenManager.update(args)

    #Some debug info
    Adventure.render_debug_info(args, self)
  end

  def party_dead?
    return @party.none? { |soldier| soldier.alive? }
  end

  def render_stat label, stat, prims, xpos, ypos
    col_r, col_g, col_b = COLOR_WHITE
    if stat.current == 0
      col_r, col_g, col_b = COLOR_RED
    elsif stat.current < stat.max
      col_r, col_g, col_b = COLOR_YELLOW_P8
    end
    prims << {x: xpos, y: ypos, text: "#{label} #{stat.current}/#{stat.max}", font: FONT_DEFAULT, r: col_r, g: col_g, b: col_b}.label!
  end

  STAT_WIDTH = 110
  def render_squad args
    prims = args.outputs.primitives
    xpos  = 120
    @party.each do |soldier|
      ypos = 140
      if soldier
        #move the portrait slightly up
        if soldier == @highlighted_soldier
          ypos = 160
        end

        # Bit of hack, update the on screen center location of the sprite
        soldier.combat_graphic.x = xpos
        soldier.combat_graphic.y = ypos - 90

        # Character name
        prims << { x: xpos, y: ypos, text: "#{soldier.firstname}", font: FONT_DEFAULT, r: 255, g: 255, b: 255 }.label!
        # Character portrait
        Portrait.render(soldier, soldier.combat_graphic.x, soldier.combat_graphic.y, prims)
        # Combat (or other situation) character highlight
        if soldier == @highlighted_soldier
          Rendering.set_color(COLOR_GREEN_P8)
          Rendering.rectangle(xpos, ypos - 90, PORTRAIT_WIDTH, PORTRAIT_HEIGHT)
        end

        # Character stats
        xpos += 55
        #prims << {x: xpos, y: ypos - 20, text: "#{soldier.hits_current}/#{soldier.hits_max}", font: FONT_DEFAULT, r: 255, g: 255, b: 255}.label!
        ypos -= 20
        render_stat("STR", soldier.strength,  prims, xpos, ypos)
        render_stat("DEX", soldier.dexterity, prims, xpos + STAT_WIDTH, ypos)
        render_stat("END", soldier.endurance, prims, xpos, ypos - 20)
        render_stat("INT", soldier.intellect, prims, xpos + STAT_WIDTH, ypos - 20)

        # Defense / Attack (placeholder) info
        wpn_name = soldier.weapon ? soldier.weapon.name : "SuperSoaker"
        ypos -= 40
        Gui.draw_icon(xpos, ypos-19, Gui::ICON_ATTACK)
        prims << {x: xpos + 18, y: ypos, text: wpn_name, font: FONT_DEFAULT, size_enum: -1, r: 255, g: 0, b: 77}.label!

        ypos -= 20
        Gui.draw_icon(xpos, ypos-20, Gui::ICON_DEFENSE)
        prims << {x: xpos + 18, y: ypos, text: soldier.armor.current, font: FONT_DEFAULT, size_enum: -1, r: 41, g: 173, b: 255}.label!

        xpos += 220
      end
    end
  end

  def on_soldier_highlight_changed soldier
    @highlighted_soldier = soldier
  end

  def on_cheat_kill_party args
    @party.each do |soldier|
      soldier.take_damage(9999)
    end
  end

  def on_cheat_heal_party args
    @party.each do |soldier|
      soldier.heal_all()
    end
  end

  def on_cheat_end_mission args
    @fsm.transition_to(:adventure_state_results)
  end
end

module Adventure
  # Short transition cinematic
  # Mission XXX - Begin!
  class State_Intro < FsmState
    def initialize parent_fsm
      super
    end

    def on_enter args
      op_number = args.state.company.num_operations
      op_name   = args.state.mission.name.upcase()
      @dialogue = Dialogue.new()
        .add_message({ text: "Operation #{op_number}:\n#{op_name}...\n\n begin!", portrait: nil})
      @dialogue.handle_input = false #running on timer
      @timer = 0
      @timer = INTRO_LENGTH - 60 if Cheats::QUICK_ADVENTURE_INTRO
    end

    def on_update args
      Gui.set_next_window_flags(WINDOWFLAG_CENTER_X)
      Gui.begin_menu("situation_image", 0, 64.from_top)
      if @timer > 140
        Gui.image("sprites/image/image-soldiers01.png", 256, 256)
      else
        Gui.image("sprites/image/image-boarding.png", 256, 256)
      end
      Gui.end_menu()

      if @timer > 50
        @dialogue.update(args)
      end

      @timer += 1 * Debug.speed_multiplier()
      if @timer > INTRO_LENGTH
        @parent_fsm.transition_to(:adventure_state_crawl)
      end
    end
  end

  # Event where the player has to make a choice
  # Continue/extract is a special event
  class State_Event < FsmState
    def initialize parent_fsm, adventure_
      super(parent_fsm)
      @adventure = adventure_
    end

    def on_enter args
      # Random event, or a predetermined rest event
      @ended = false
      case @adventure.current_encounter
      when Adventure::ENCOUNTER_REST
        @adventure.stat_checkpoints_reached += 1
        @current_event = Adventure::RestEvent.new(@adventure)
      when Adventure::ENCOUNTER_END
        @adventure.stat_checkpoints_reached += 1
        @current_event = Adventure::EndEvent.new(@adventure)
      else
        @current_event = Adventure::EventFactory.make_random_event(@adventure)
      end
    end

    def on_update args
      @current_event.update(args)
      if @current_event.is_over?
        # assuming the party is always alive
        if @current_event.event_result == :event_result_continue
          @parent_fsm.transition_to(:adventure_state_crawl)
        else
          @parent_fsm.transition_to(:adventure_state_results)
        end
      end
      Debug.add_state_text(@current_event)
    end
  end
end
