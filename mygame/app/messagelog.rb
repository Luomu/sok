# Stores X lines of log
# Call update to keep showing messages until done
# Does not handle input
class MessageLog
  MAX_LOG_LINES = 4

  def initialize
    @message_queue          = []
    @lines                  = []
    @current_message        = nil
    @current_char           = 0
    @countdown              = 0
    @ypos_override          = nil
    @all_done               = false
  end

  def queue_message message
    @message_queue << message
    @all_done = false
    return self
  end

  def done?
    return @all_done
  end

  # Override Y position (default is auto-center)
  def set_ypos ypos
    @ypos_override = ypos
    return self
  end

  def render
    Gui.set_next_window_flags(0)
    if @ypos_override
      Gui.set_next_window_pos(40, @ypos_override)
    else
      Gui.set_next_window_pos(40, 135)
    end
    Gui.set_next_window_size(1200, 134)
    Gui.begin_window("#log_window")
    # render all lines
    y = 200
    @lines.each do |line|
      Gui.label(line)
      y -= LABEL_HEIGHT
    end
    Gui.end_window()
  end

  def update args
    # if current message, keep typing it until fully visible
    if @current_message
      if Cheats::QUICK_MESSAGES
        @lines.last << @current_message
        @current_char = @current_message.length
      else
        @lines.last << @current_message[@current_char]
        @current_char += 1
      end

      # Finished, ready for next message (or end)
      if @current_char >= @current_message.length
        @current_message = nil
        @countdown = 30
      end
    else
      # Countdown to next event
      if @countdown > 0
        @countdown -= 1 * Debug.speed_multiplier()
      end

      #Queue a new message or end
      if @countdown <= 0
        if @message_queue.empty?
          @all_done = true
        else
          @current_message = @message_queue.shift()
          @current_char    = 0
          @lines.push("") #allocate empty line
          if @lines.length > MAX_LOG_LINES
            @lines.shift()
          end
        end
      end
    end

    render()
  end #update

  # Immediately display all messages
  def flush
    while not @message_queue.empty?
      @lines << @message_queue.shift()
      if @lines.length > MAX_LOG_LINES
        @lines.shift()
      end
    end

    @current_message        = nil
    @current_char           = 0
    @countdown              = 0
    @all_done               = true

    render()
  end
end
