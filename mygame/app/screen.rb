# popup screen
class Screen
  def initialize
  end

  # Layout using imgui (override on_update instead of this)
  def update args
    on_update(args)
  end

  # Close the screen, callback will be invoked at end
  def close close_callback = nil
    close_callback&.call()
    ScreenManager.close(self)
  end

  # Override this to do layout
  def on_update args
  end

  #override this to handle cancel (default is autoclose)
  def on_cancel args
    Sound.menu_cancel()
    close()
  end
end

# Holds a stack of screens
class ScreenManager
  def ScreenManager.initialize args
    @@stack = []
  end

  # Push a screen on top of the stack
  def ScreenManager.open screen
    @@stack.push(screen)
    return screen
  end

  # Update the screen stack
  def ScreenManager.update args
    @@stack.each do |screen|
      screen.update(args)
    end

    # Inputs
    input_context = Gui.determine_input_context()
    if Input.pressed_cancel(args)
      if @@stack.length > 1
        @@stack.last.on_cancel(args)
      end
    elsif Input.pressed_ok(args)
      Gui.handle_input_ok(input_context)
    elsif Input.pressed_up(args)
      Gui.handle_input_up(input_context)
    elsif Input.pressed_down(args)
      Gui.handle_input_down(input_context)
    end
  end

  def ScreenManager.close screen
    @@stack.delete(screen)
  end

  # Delete all screens, does not invoke close()
  def ScreenManager.delete_all
    @@stack.clear()
  end

  def ScreenManager.num_screens
    return @@stack.length
  end
end

# Simple yes/no message dialog
# - Always centered to screen
# - Closes when either option is selected
# - Callback can be set for both options during initialize or using set_on_ methods
# Multiline strings are split by newline (\n)
class ConfirmationDialog < Screen
  def initialize lines, on_yes = nil, on_no = nil
    @lines = lines.split("\n")
    @on_yes = on_yes
    @on_no = on_no
  end

  def on_cancel args
    #require explicit select
    Sound.menu_blocked()
  end

  def set_on_yes callback
    @on_yes = callback
    return self
  end

  def set_on_no callback
    @on_no = callback
    return self
  end

  def on_update args
    Gui.begin_window(@lines[0])
    @lines.each do |l|
      Gui.label(l)
    end
    if Gui.menu_option("Yes")
      Sound.menu_ok()
      close(@on_yes)
    end
    if Gui.menu_option("No")
      Sound.menu_cancel()
      close(@on_no)
    end
    Gui.end_window()
  end
end

# Not implemented, yo
class PlaceholderScreen < Screen
  def on_update args
    Gui.begin_window(@title)
    Gui.label("Not implemented!")
    Gui.end_window()
  end

  def initialize title
    @title = title
  end
end

# Generic message box with one option
class MessageScreen < Screen
  def initialize message
    @message       = message
    @ypos_override = nil
  end

  # Override Y position (default is auto-center)
  def set_ypos ypos
    @ypos_override = ypos
    return self
  end

  def on_update args
    Gui.begin_window(@message)
    Gui.header(@message)
    if Gui.menu_option("OK")
      close(@on_close)
    end
    Gui.end_window()
  end

  def on_cancel args
    Sound.menu_cancel()
    close(@on_close)
  end

  def set_on_close callback
    @on_close = callback
    return self
  end
end

# Multi-choice generic menu screen
# A title starting with '#' won't be rendered,
# but a title must be specified regardless
class MenuScreen < Screen
  def initialize title
    super()
    @title   = title
    @options = []
    @labels  = []
    @ypos_override = nil
  end

  # Use hashes as options
  # { text: "A", callback: call, close: true }
  # Options don't close the screen unless close: true is specified
  def add_option option
    @options << option
    return self
  end

  # Additional lines of text before the options
  def add_label label
    @labels << label
    return self
  end

  # Override Y position (default is auto-center)
  def set_ypos ypos
    @ypos_override = ypos
    return self
  end

  def on_update args
    if @ypos_override
      Gui.set_next_window_pos(nil, @ypos_override)
    end
    Gui.begin_window(@title)
    if not @title.start_with?('#')
      Gui.header(@title)
    end
    # Optional extra labels
    @labels.each { |l| Gui.label(l) }
    # Selectable options
    @options.each do |option|
      if Gui.menu_option(option.text)
        Sound.menu_ok()
        option.callback&.call()
        close() if option.close
      end
    end
    Gui.end_window()
  end
end

# Wraps a Dialogue box. Why this is handy:
# 1. Can delete itself upon closing without having to assign nil to it
# 2. Handles input
class DialogueScreen < Screen
  attr_reader :dialogue

  def initialize
    @dialogue = Dialogue.new
  end

  def on_cancel args
  end

  def on_update args
    @dialogue.update(args)
    if @dialogue.finished?
      close()
    end
  end

  def add_message msg
    @dialogue.add_message(msg)
    return self
  end
end
