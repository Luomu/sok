# Provides character or event text with
# a typewriter effect
class Dialogue
  attr_accessor :handle_input #dialogue handles keypresses

  def initialize
    @window_id        = rand(10000)
    @messages         = []
    @current_char     = 0
    @message_buffer   = ""
    @handle_input     = true
    @message_finished = false
    @ypos = DIALOGUE_DEFAULT_POS
  end

  # Add a message to the queue
  def add_message msg
    raise "Message must be a hash" unless msg.kind_of?(Hash)
    @messages << msg
    return self
  end

  # Final message has been dismissed
  def finished?
    @messages.empty?
  end

  # Messages in queue after the current one?
  def messages_remain?
    return @messages.length > 1
  end

  def waiting_for_input?
    return @message_finished
  end

  def forward
    @messages.shift()
    @current_char = 0
    @message_buffer = ""
  end

  # Replaces the current message, typing animation restarts
  def set_message msg
    raise "Message must be a hash" unless msg.kind_of?(Hash)
    @messages         = [ msg ]
    @current_char     = 0
    @message_buffer   = ""
    @message_finished = false
  end

  def set_ypos ypos
    @ypos = ypos
    return self
  end

  # Update animation, handle keypress to forward messages
  def update args
    # Messages remain, keep printing
    if @messages.length > 0
      current_message = @messages.first
      if @message_buffer.length < current_message.text.length
        @message_buffer << current_message.text[@current_char]
        @current_char += 1
        @message_finished = false

        # Fast forward!
        if Cheats::QUICK_MESSAGES
          @message_buffer = current_message.text
        end
      end

      #message has finished
      if @message_buffer.length == current_message.text.length
        @message_finished = true
      end
    end

    # Draw the textbox
    if current_message
      Gui.talkbox(@window_id, current_message.portrait, @message_buffer, @ypos)
    end

    # Consume keypress
    if @message_finished and @handle_input and Input.pressed_ok(args)
      Input.consume_event(args)
      forward()
    end
  end
end
