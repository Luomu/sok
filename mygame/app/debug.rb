# Dev tools

# Cheat buttons
class GTK::Console::Menu
  def custom_buttons
    [
      (button id: :btn_dosh,       row: 4, col: 20, text: "DOSH",           method: :cheat_dosh),
      (button id: :btn_giev_loot,  row: 4, col: 22, text: "GIEV LOOT",      method: :cheat_giev_loot),
      (button id: :btn_save_state, row: 5, col: 20, text: "Save state",     method: :cheat_save_state),
      (button id: :btn_injure,     row: 5, col: 22, text: "INJURE SOMEONE", method: :cheat_injure_random_soldier),
      (button id: :btn_kill_all,   row: 6, col: 20, text: "KILL TEAM",      method: :cheat_kill_all_soldiers)
    ]
  end

  def cheat_dosh
    $args.state.company.gain_money(1000)
    $gtk.log_debug "DOSH"
  end

  def cheat_save_state
    $gtk.save_state()
  end

  def cheat_giev_loot
    # Patch the adventure loot, if ongoing adventure
    adventure_loot = $core_fsm.states.corefsm_state_adventure.collected_loot
    if adventure_loot != nil
      adventure_loot << Treasures.get_random_named()
      $gtk.log_info adventure_loot.last
    # Otherwise add to company inventory
    else
      $args.state.company.treasures << Treasures.get_random_named()
      $gtk.log_info $args.state.company.treasures.last
    end
  end

  def cheat_injure_random_soldier
    dmg    = roll_d6
    victim = $args.state.company.team.random_element
    $gtk.log_debug "#{victim.name} takes #{dmg} damage!"
    victim.take_damage(dmg)
    $args.state.company.assign_soldier_to_hospital(victim)
  end

  def cheat_kill_all_soldiers
    $state.company.team.each do |soldier|
      soldier.take_damage(500)
      $gtk.log_debug "#{soldier.name} killed"
    end
  end
end

module Debug
  def Debug.new_frame
    @@state_offset_y = 30
    @@state_offset_x = 10
    @@grid_mode ||= false
    @@speed_multiplier ||= 1.0
    Rendering.set_clear_color(@@grid_mode ? COLOR_BACKGROUND_DEV : COLOR_BACKGROUND_PROD)
  end

  # True in non-prod builds
  def Debug.cheats_enabled?
    return !$gtk.production
  end

  def Debug.assert condition, message
    raise message unless condition
  end

  # Add state text to bottom left of screen
  def Debug.add_state_text text
    if @@grid_mode
      $gtk.args.outputs.labels << { x: @@state_offset_x, y: @@state_offset_y, text: text }.set_color_rgb(COLOR_RED)
      @@state_offset_y += 25
      @@state_offset_x += 5
    end
  end

  def Debug.toggle_layout_grid
    @@grid_mode = !@@grid_mode
  end

  def Debug.visible?
    return @@grid_mode
  end

  def Debug.speed_multiplier
    return @@speed_multiplier
  end

  def Debug.toggle_fast_forward
    if @@speed_multiplier > 1
      @@speed_multiplier = 1
    else
      @@speed_multiplier = 10
    end
  end

  def Debug.render_layout_grid args
    if $dice_logger
      $dice_logger.render(args)
    end

    if @@grid_mode
      Rendering.set_color(COLOR_GRAY)
      Rendering.line_vertical(SCREEN_HALF_W)
      Rendering.line_horizontal(SCREEN_HALF_H)
      Rendering.line_horizontal(100.from_top)
      Rendering.line_horizontal(100.from_bottom)
      Rendering.set_color(COLOR_BLACK)
      Rendering.line_horizontal(0.from_top)
      Rendering.line_horizontal(1.from_bottom)
    end
  end

  # Draw a green/red bar (debug purposes)
  def Debug.render_splitbar value1, value2
    return unless @@grid_mode

    TotalWidth = 64
    total = value1 + value2
    w1 = 32
    w2 = 32
    if total > 0
      w1 = (value1 / total) * TotalWidth
      w2 = TotalWidth - w1
    end
    h = 32
    y = 64.from_top
    x = 128.from_right
    w = 64
    $args.outputs.primitives << [x, y, w1, h, COLOR_GREEN].solid
    $args.outputs.primitives << [x + w1, y, w2, h, COLOR_RED].solid
  end

  def Debug.render_framerate args
    args.outputs.labels << { x:40.from_right, y:20.from_top, text:"#{args.gtk.current_framerate.round}"}.set_color_rgb(COLOR_WHITE)
    if @@speed_multiplier > 1
      args.outputs.labels << { x:40.from_right, y:40.from_top, label:"FF>>"}.set_color_rgb(COLOR_WHITE)
    end

    #args.outputs.debug << args.gtk.framerate_diagnostics_primitives
  end
end
