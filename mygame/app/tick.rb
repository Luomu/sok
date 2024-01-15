$core_fsm  = nil
$init_done = false
$gtk.disable_reset_via_ctrl_r # already handled by us

def initialize_new_game args, quickstart = true
  args.state.company  = Company.new()
  args.state.missions = []
  args.state.available_soldiers = []
  # Used to produce the weekly report
  args.state.weekly_data = Strategy::init_weekly_stats()
  if quickstart
    args.state.company.setup_initial_team!
  end
end

def initialize_saved_game args
  #eh nothing to do?
end

def tick args
  # Uncomment if hunting for puts source
  # $gtk.add_caller_to_puts!

  if !$init_done
    $game_events.clear()
    if !$gtk.production
      # Register dice roll logger
      # Only once per app lifetime
      # $dice_logger ||= Debug::DiceLogger.new
      # $dice_logger.hook()
    end
    $init_done = true
    $core_fsm  = CoreFsm.new
    Input.initialize(args)
    Gui.initialize(args)
    ScreenManager.initialize(args)
    Music.initialize(args)
    initialize_new_game(args) #only initialized here for testing
  end

  #Quick restart
  if Input.pressed_debug_restart(args)
    $gtk.reset_next_tick(seed:Time.now.to_i)
    $init_done = false
    return
  end

  Debug.new_frame()
  Gui.newframe(args)

  $core_fsm.update(args)

  Gui.update(args)
  Gui.render(args)

  Notify.update(args)

  Debug.add_state_text($core_fsm.current_state_name)
  Debug.render_layout_grid(args)

  # Some dev keys - unsafe results may occur
  if Debug.cheats_enabled?
    kb  = args.inputs.keyboard
    fsm = $core_fsm

    if kb.key_down.zero
      Debug.toggle_layout_grid()
    end

    # Skip to main menu
    if kb.key_down.one
      # Due to sloppy cleanup when cheating
      ScreenManager.delete_all()
      fsm.transition_to(:corefsm_state_menu)
    end

    # Skip to strategy mode
    if kb.key_down.two
      $state.intro_viewed = true
      ScreenManager.delete_all()
      fsm.transition_to(:corefsm_state_strategy)
    end

    # Skip to adventure
    if kb.key_down.three
      $state.intro_viewed  = true
      $state.company.turn  = 1
      ScreenManager.delete_all()
      fsm.transition_to(:corefsm_state_adventure)
    end

    # Skip to final results
    if kb.key_down.four
      $state.intro_viewed = true
      ScreenManager.delete_all()
      fsm.transition_to(:corefsm_state_results)
    end

    #if kb.key_down.five
    #reserved

    if kb.key_down.six
      $state.intro_viewed  = true
      $state.company.turn  = 1
      $state.combat_test   = true
      ScreenManager.delete_all()
      fsm.transition_to(:corefsm_state_adventure)
    end

    if kb.key_down.seven
      Debug.toggle_fast_forward()
    end
  end

  Debug.render_framerate(args)
end
