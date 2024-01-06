# Wrap controller and gamepad inputs.
module Input
  def Input.keyname_ok
    'Z'
  end

  def Input.keyname_cancel
    'X'
  end

  def Input.pressed_up args
    args.inputs.controller_one.key_down.up ||
    args.inputs.keyboard.key_down.up
  end

  def Input.pressed_down args
    args.inputs.controller_one.key_down.down ||
    args.inputs.keyboard.key_down.down
  end

  def Input.pressed_left args
    args.inputs.controller_one.key_down.left ||
    args.inputs.keyboard.key_down.left
  end

  def Input.pressed_right args
    args.inputs.controller_one.key_down.right ||
    args.inputs.keyboard.key_down.right
  end

  def Input.pressed_ok args
    args.inputs.controller_one.key_down.a ||
    args.inputs.keyboard.key_down.z
  end

  def Input.held_ok args
    args.inputs.controller_one.key_held.a ||
    args.inputs.keyboard.key_held.z
  end

  def Input.pressed_cancel args
    args.inputs.controller_one.key_down.b ||
    args.inputs.keyboard.key_down.x
  end

  def Input.pressed_debug_restart args
    args.inputs.keyboard.key_down.r
  end

  def Input.last_handled_tick
    @@handled_tick
  end

  def Input.initialize args
    @@handled_tick = args.state.tick_count
  end

  # Handle no more input events this tick
  def Input.consume_event args
    @@handled_tick = args.state.tick_count
  end
end
