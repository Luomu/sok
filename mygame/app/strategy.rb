# Strategy mode
# 1. Hire soldiers
# 2. Manage soldiers
# 3. Pick a mission
# 4. Pick team members
# 5. Adventure
# 6. Review results
# Other stuff
# - Retire
# - Save/Quit
# - Shop (buy equipment)
# - Budget review every quarter?
# - Loot (view treasures, grid view)
# Persistent elements:
# - Image related to the current screen
# - Status bar showing the current time and money

require 'app/strategy_screens.rb'
require 'app/strategy_screens_treasure.rb'
require 'app/strategy_screens_shop.rb'
require 'app/strategy_screens_system.rb'
require 'app/strategy_evaluation.rb'

# Event bus + misc constants for the strategy mode
module Strategy
  def Strategy.eventbus
    @@strategy_eventbus
  end

  def Strategy.initialize
    @@strategy_eventbus = EventBus.new
  end

  EVENT_HIGHLIGHT_CHARACTER = :event_highlight_character

  MESSAGEWINDOW_YPOS = 165
  QUICKHELP_YPOS     = 210
end #module Strategy

# Strategy mode inside CoreFsm
class GameState_Strategy < FsmState
  # Root screen of the strategy mode
  class StrategyScreen < Screen
    def initialize args
      super()

      #title, callback, tooltip
      @options = [
        ["Team",      -> { ScreenManager.open(Strategy::TeamScreen.new)    }, "View and manage your team"],
        ["Recruit",   -> { ScreenManager.open(Strategy::RecruitScreen.new) }, "Recruit soldiers"],
        ["Shop",      -> { ScreenManager.open(Strategy::ShopScreen.new)    }, "Buy and sell equipment"],
        ["Treasures", -> { ScreenManager.open(Strategy::TreasuresScreen.new(args)) }, "View your loot"],
        ["Missions",  -> { ScreenManager.open(Strategy::MissionsScreen.new)        }, "Begin a mission"],
        ["Wait",      -> { on_wait()   }, "Wait one day"],
        ["Retire",    -> { on_retire() }, "Retire with your earnings"],
        ["Help",      -> { ScreenManager.open(Strategy::HelpScreen.new)   }, "Help"],
        ["System",    -> { ScreenManager.open(Strategy::SystemScreen.new) }, "Saving & options"]
      ]

      @selected_option     = -1

      # We won't need to unsub these as the eventbus is recreated on re-entry
      Strategy.eventbus.subscribe(Events::ENTER_SHOP, -> (payload) { set_scene(:scene_shop) })
      Strategy.eventbus.subscribe(Events::EXIT_SHOP,  -> (payload) { set_scene(:scene_station) })
      Strategy.eventbus.subscribe(Events::ENTER_LOOT, -> (payload) { set_scene(:scene_treasureroom) })
      Strategy.eventbus.subscribe(Events::EXIT_LOOT,  -> (payload) { set_scene(:scene_station) })

      @scene_image = "sprites/image/image-hangar01.png"
    end

    def on_update args
      # Flavour image for the current subscreen
      #Gui.set_next_window_pos(100, 64.from_top)
      #Gui.begin_menu("station_window")
      #Gui.image(@scene_image, 256, 256)
      #Gui.end_menu()

      # Options to navigate between station screens
      Gui.set_next_window_flags(0)
      Gui.set_next_window_pos(332, 40.from_top)
      Gui.begin_menu("station_window_2")
      Gui.header("STATION")
      @options.each do |option|
        Gui.menu_option_call(option[0], option[1])
      end

      if Gui.highlighted_option_index != @selected_option
        Strategy.eventbus.publish(:strategy_event_quickhelp, @options[Gui.highlighted_option_index][2])
        @selected_option = Gui.highlighted_option_index
      end

      Gui.end_menu()
    end

    def set_scene scene
      if scene == :scene_shop
        @scene_image = "sprites/image/image-shopkeeper01.png"
        Music.play_shop_music()
      elsif scene == :scene_treasureroom
        @scene_image = "sprites/image/image-shopkeeper01.png"
        Music.play_treasure_music()
      else
        @scene_image = "sprites/image/image-placeholder.png"
        Music.play_station_music(nil)
      end
    end

    def on_retire
      current_funds = $args.state.company.money
      num_treasures = $args.state.company.treasures.length
      ScreenManager.open(
        Strategy::ConfirmationDialog.new("Retire with your loot?\nFunds: #{current_funds}\nTreasures: #{num_treasures}"))
        .set_on_yes(-> { $core_fsm.retire() })
    end

    def on_wait
      if $state.company.money < DEBT_LIMIT
        ScreenManager.open(MessageScreen.new("You are too much in debt to continue!"))
      else
        Strategy.eventbus.publish(:strategy_event_newturn, $args)
      end
    end
  end #StrategyScreen

  # Begin Strategy methods
  def on_enter args
    Strategy.initialize()
    @messages = MessageLog.new()
    @messages.set_ypos(Strategy::MESSAGEWINDOW_YPOS)
    @stat_tracker = Strategy::CompanyStatsTracker.new()
    if args.state.company.turn == 0
      start_new_turn(args)
    else
      on_return_from_mission(args)
    end
    ScreenManager.open(StrategyScreen.new(args))

    if not args.state.intro_viewed
      play_intro()
    end

    @quickhelp_text      = ""
    @highlighted_soldier = nil
    Strategy.eventbus.subscribe(:strategy_event_quickhelp, method(:on_quickhelp_changed))
    Strategy.eventbus.subscribe(:strategy_event_newturn,   method(:end_turn))
    Strategy.eventbus.subscribe(:strategy_soldier_healed,  method(:on_soldier_healed))
    Strategy.eventbus.subscribe(:strategy_soldier_hired,   method(:on_soldier_hired))
    Strategy.eventbus.subscribe(:strategy_soldier_fired,   method(:on_soldier_departed))
    Strategy.eventbus.subscribe(Strategy::EVENT_HIGHLIGHT_CHARACTER, method(:on_soldier_highlight_changed))
    Strategy.eventbus.subscribe(Events::MESSAGE, -> (payload) { @messages.queue_message(payload) })

    $game_events.publish(Events::ENTER_STRATEGY)

    @planet_view = StationPlanetView.new()
    @ambience    = StationAmbience.new()
  end

  def on_quickhelp_changed payload
    @quickhelp_text = payload
  end

  def on_soldier_healed soldier
    @messages.queue_message("#{soldier.firstname} is fully healed")
  end

  def on_soldier_hired soldier
    @messages.queue_message("#{soldier.firstname} #{soldier.lastname} has been hired. Welcome to the company!")
  end

  def on_soldier_departed soldier
    @messages.queue_message("#{soldier.firstname} #{soldier.lastname} has left the company. We wish them all the best!")
  end

  def on_soldier_highlight_changed soldier
    @highlighted_soldier = soldier
  end

  def on_exit args
    ScreenManager.delete_all()
  end

  def end_turn args
    state   = args.state
    company = args.state.company

    # Expenses
    # Pay soldiers
    company.spend_money(company.daily_fees)
    @messages.queue_message("Daily expenses paid: #{company.daily_fees}Cr")

    company.monthly_fees_due_days -= 1
    if company.monthly_fees_due_days <= 0
      @messages.queue_message("Monthly expenses paid: #{company.monthly_fees}Cr")
      company.spend_money(company.monthly_fees)
      company.monthly_fees_due_days = RENT_PERIOD_DAYS
    end

    # Update injured soldiers
    injured_soldiers = company.team_hospital.clone()
    injured_soldiers.each do |soldier|
      soldier.heal_daily()
      if soldier.healthy?
        company.assign_soldier_to_reserve(soldier)
        Strategy.eventbus.publish(:strategy_soldier_healed, soldier)
      end
    end

    Strategy.eventbus.publish(Events::TURN_ENDED, nil)
    @stat_tracker.trigger_evaluation()

    start_new_turn(args)
    @messages.queue_message("A day has passed")
  end

  def start_new_turn args
    state   = args.state
    company = args.state.company

    company.daily_fees   = Rules.calculate_daily_fees(company)
    company.monthly_fees = Rules.calculate_monthly_fees(company)

    # generate new missions
    company.turn += 1
    state.missions.clear()
    3.times do
      state.missions << Mission.generate()
    end

    # generate available recruits
    # todo: these shouldn't change constantly
    state.available_soldiers.clear()
    6.times do
      state.available_soldiers << Character.generate()
    end
  end

  def on_return_from_mission args
    return unless args.state.mission

    # There should always be a result... except when cheating
    result = args.state.mission_result
    if !result
      result = {
        success:    false,
        loot:       [],
        money:      0,
        reputation: 0
      }
    end

    company = args.state.company
    starting_rep = company.reputation
    company.gain_money(result.money)
    company.num_operations += 1
    company.treasures      += result.loot
    company.gain_reputation(result.reputation)

    # Remove dead soldiers from the team
    company.team.reverse.each do |soldier|
      if not soldier.alive?
        company.lose_reputation(Rules.calculate_reputation_penalty_for_dead_soldier(soldier))
        company.kill_soldier(soldier)
        @messages.queue_message("#{soldier.firstname} has been killed in action")
      end
    end

    if company.squad_empty?
      @messages.queue_message("Nobody survived the mission")
    else
      @messages.queue_message("The squad has returned from a mission")
    end

    # Wounded soldiers to the infirmary
    # Should probably show in the results screen
    company.team.each do |soldier|
      if soldier.injured? and soldier.assignment != ASSIGNMENT_HOSPITAL
        company.assign_soldier_to_hospital(soldier)
        @messages.queue_message("#{soldier.firstname} has been hospitalized")
      end
    end

    args.state.mission        = nil
    args.state.mission_result = nil

    # Level up/down, depending on reputation
    # This should perhaps be limited to every week/month?
    old_rank = company.rank
    company.rank = Rules.calculate_rank_for_reputation(company.reputation)
    if company.rank > old_rank
      @messages.queue_message("Our standing has increased")
    elsif company.rank < old_rank
      @messages.queue_message("Our standing has decreased")
    end

    # Finally, autosave, if autosave has been enabled
    $game_events.publish(Events::AUTOSAVE, nil)
  end

  def do_background args
    # Background graphic
    args.outputs.primitives << {
      x: 0,
      y: 0,
      w: SCREEN_W,
      h: SCREEN_H,
      r: 255,
      g: 255,
      b: 255,
      a: 255,
      path: 'images/strategy-background.png'
    }.sprite!

    # Planet window
    @planet_view.update(args)
    @ambience.update(args)

    # Menu borders
    args.outputs.primitives << {
      x: 0,
      y: 0,
      w: SCREEN_W,
      h: SCREEN_H,
      r: 255,
      g: 255,
      b: 255,
      a: 255,
      path: 'images/strategy-mainscreen.png'
    }.sprite!
  end

  # Left-side Company status panel
  def do_status_panel args
    STATUS_HEIGHT = 48
    company = args.state.company

    money = company.money
    day   = company.turn
    ops   = company.num_operations
    rank  = company.level
    loot  = company.treasures.size

    daily_fees = company.daily_fees
    rent       = company.monthly_fees
    rent_due   = company.monthly_fees_due_days

    armor_lvl   = company.armor_level
    weapons_lvl = company.weapon_level

    x_label = 30
    x_value = 200
    y_line  = 50.from_top
    h_line  = 25

    color_normal    = COLOR_DARK_GREEN_P8
    color_warning   = COLOR_RED_P8
    color_attention = COLOR_YELLOW_P8

    Rendering.set_color(color_normal)
    Rendering.text_left(x_label-8, y_line, "Company")
    y_line -= h_line
    Rendering.text_left(x_label, y_line, "Day")
    Rendering.text_left(x_value, y_line, day)
    y_line -= h_line
    Rendering.text_left(x_label, y_line, "Rank")
    rank.times do |i|
      args.outputs.primitives << {
        x: x_value + i * 16,
        y: y_line - 16,
        w: 16,
        h: 16,
        r: 255,
        g: 255,
        b: 255,
        path: 'sprites/ui/icon-star.png'
      }.sprite!
    end
    y_line -= h_line
    Rendering.text_left(x_label, y_line, "Funds")
    if money < 0
      Rendering.set_color(color_warning)
    end
    Rendering.text_left(x_value, y_line, "#{money}Cr")
    Rendering.set_color(color_normal)
    y_line -= h_line
    Rendering.text_left(x_label, y_line, "Treasures")
    Rendering.text_left(x_value, y_line, loot)
    y_line -= h_line
    Rendering.text_left(x_label, y_line, "Missions")
    Rendering.text_left(x_value, y_line, ops)
    y_line -= h_line * 2
    Rendering.text_left(x_label, y_line, "Daily expenses:")
    Rendering.text_left(x_value, y_line, "#{daily_fees} Cr")
    y_line -= h_line
    Rendering.text_left(x_label, y_line, "Station fees:")
    Rendering.text_left(x_value, y_line, "#{rent} Cr")
    y_line -= h_line
    Rendering.text_left(x_label, y_line, "Fees due in:")
    if rent_due < 5
      Rendering.set_color(color_attention)
    end
    Rendering.text_left(x_value, y_line, "#{rent_due} days")
    Rendering.set_color(color_normal)

    y_line -= h_line * 2
    Gui.draw_icon(x_label, y_line - 18, Gui::ICON_ATTACK)
    Rendering.set_color(COLOR_ATTACK)
    Rendering.text_left(x_label + 20, y_line, "Lvl #{weapons_lvl}")

    y_line -= h_line
    Gui.draw_icon(x_label, y_line - 18, Gui::ICON_DEFENSE)
    Rendering.set_color(COLOR_DEFENSE)
    Rendering.text_left(x_label + 20, y_line, "Lvl #{armor_lvl}")
  end

  # Always on screen contextual help text window
  def do_quickhelp
    Gui.set_next_window_flags(0)
    Gui.set_next_window_pos(40, Strategy::QUICKHELP_YPOS.from_bottom)
    Gui.set_next_window_size(1200, 40)
    Gui.set_next_window_padding(8)
    Gui.begin_window("window-quickhelp")
    Gui.label(@quickhelp_text)
    Gui.end_window()
  end

  def do_soldier_team title, team, args, ypos, show_health = false
    prims        = args.outputs.primitives
    start_x      = 320.from_right
    xpos         = start_x
    line_height  = 100
    num_per_line = 4
    current      = 0
    # header
    prims << {x: xpos, y: ypos, text: title, font: FONT_DEFAULT, r: 255, g: 255, b: 255}.label!
    ypos -= 100

    # soldiers/slots
    team.each_with_index do |soldier, index|
      if soldier
        Portrait.render(soldier, xpos, ypos, prims)
        # selection highlight
        if soldier == @highlighted_soldier
          Rendering.set_color(COLOR_GREEN_P8)
          Rendering.rectangle(xpos, ypos, PORTRAIT_WIDTH, PORTRAIT_HEIGHT)
        end
        if show_health
          prims << {x: xpos, y: ypos+20, text: "#{soldier.hits_current}/#{soldier.hits_max}", font: FONT_DEFAULT, r: 255, g: 255, b: 255}.label!
        end
        prims << {x: xpos, y: ypos, text: soldier.firstname, font: FONT_DEFAULT, r: 255, g: 255, b: 255}.label!
      else
        # draw an empty slot
        prims << {x: xpos, y: ypos, w: PORTRAIT_WIDTH, h: PORTRAIT_HEIGHT, r: 100, g: 100, b: 100, path: "sprites/gradient01.png"}.sprite!
        prims << {x: xpos, y: ypos, text: "Empty", font: FONT_DEFAULT}.label!
      end
      current += 1
      xpos += 80
      if current % num_per_line == 0
        xpos = start_x
        ypos -= line_height
      elsif index == team.length - 1
        ypos -= line_height
      end
    end

    return ypos += line_height - 40
  end

  def do_soldiers_panel args
    company = args.state.company

    ypos = 50.from_top
    ypos = do_soldier_team("Active Squad", company.team_squad, args, ypos)
    ypos = do_soldier_team("Reserve", company.team_reserve, args, ypos)
    ypos = do_soldier_team("Hospital", company.team_hospital, args, ypos, show_health = true)
  end

  def do_messages args
    #one by one, pop a message from the queue and show it with a typewriter effect
    @messages.update(args)
  end

  def on_update args
    do_background(args)
    do_status_panel(args)
    do_soldiers_panel(args)
    do_messages(args)
    do_quickhelp()
    Gui.draw_hotkeys()
    ScreenManager.update(args)
  end

  def play_intro
    INTRO_PORTRAIT = "sprites/portraits/portrait01.png"
    dialogue = ScreenManager.open(DialogueScreen.new())
    dialogue.add_message({ text: "Upon your arrival, you are approached by a man wearing the company uniform.", portrait: nil})
    dialogue.add_message({ text: "Welcome to Sirocco Station. You must be the new franchise manager. I've taken care of establishing the location, but the rest will be in your hands.", portrait: INTRO_PORTRAIT})
    dialogue.add_message({ text: "He gives you a tour of the local H.Q. - nothing more than a small rental office - and you spend the next few hours reviewing and signing paperwork.", portrait: nil})
    dialogue.add_message({ text: "Our credit balance is nothing to brag about, but it should allow you to get a team going and start running missions. Don't forget the station fees have to be paid at the end of every month. Air's not free, you know.", portrait: INTRO_PORTRAIT})
    dialogue.add_message({ text: "If you need to raise quick funds, you should be able to sell any treasures you recover, but keep in mind the local merchants will never give you the best price. And corporate HQ expects you to bring the best ones home.", portrait: INTRO_PORTRAIT})
    dialogue.add_message({ text: "He wishes you good luck before heading to the departure terminal, and you settle in for the first day on the job.", portrait: nil})
    dialogue.add_message({ text: "Your first objective: Hire a squad of four soldiers and launch your first expedition. Keep your credit balance positive. You can choose to RETIRE at any time to return home with your loot.", portrait: nil})

    $state.intro_viewed = true
  end
end
