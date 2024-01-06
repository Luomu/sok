# Adventure event:
# - Image of the situation and textual explanation
# - Action prompt with 2-3 Choices (sometimes choose a party member)
# - Report outcome in text
# - Return the result to adventure
module Adventure
  class AdventureEvent
    attr_reader :event_result

    STATE_INTRO   = 1
    STATE_CHOICE  = 2
    STATE_OUTCOME = 3
    STATE_EXIT    = 4

    def is_over?
      return @state == STATE_EXIT
    end

    def initialize adventure
      raise "Situation has not been defined" unless @situation_text
      @dialogue  = Dialogue.new
      @adventure = adventure

      @situation_text.each do |line|
        @dialogue.add_message({ text: line, portrait: nil})
      end
      @dialogue.handle_input = false
      @event_result    = nil
      @timer           = 0
      @option_selected = false
      @state           = STATE_INTRO
    end

    # Show the situation, prompt for a choice, set result and return
    def update args
      @timer += 1
      # Image
      Gui.set_next_window_flags(WINDOWFLAG_CENTER_X)
      Gui.begin_menu("situation_image", 0, 100.from_top)
      Gui.image(@situation_image, 256, 256)
      Gui.end_menu()

      # Wait a moment to avoid accidental choice
      return unless @timer > 30

      # Flavor text
      @dialogue.update(args)

      # intro   - play the message(s)
      # choice  - show list of options
      # outcome - show the outcome message(s)
      # return to adventure after the last message has been dismissed
      if @state == STATE_INTRO
        if @dialogue.waiting_for_input?
          if @dialogue.messages_remain? #and Input.pressed_ok(args)
            if Input.pressed_ok(args)
              # Show next message
              Input.consume_event(args)
              @dialogue.forward()
            end
          else
            # Show the choices (on top of the final message)
            # This is the main reason why this logic looks so complicated
            @state = STATE_CHOICE
          end
        end
      elsif @state == STATE_CHOICE
        # Present choices
        Gui.set_next_window_flags(WINDOWFLAG_CENTER_X)
        Gui.begin_menu("choicebox", 640, 300)
        Gui.label(@option_prompt)
        @options.each do |option|
          if Gui.menu_option(option.text)
            @option_selected = true
            if option.result_callback
              option.result_callback.call()
            else
              @dialogue.set_message({ text: option.result_text })
              # Change image
              if option.result_image
                @situation_image = option.result_image
              end
              # Play sound effect
              if option.result_sound
                Sound.play_oneshot(option.result_sound)
              end
              @event_result = option.result
            end
            @state = STATE_OUTCOME
          end
        end
        Gui.end_menu()
      elsif @state == STATE_OUTCOME
        # Play the result text, after that exit the event
        if @dialogue.waiting_for_input?
          if Input.pressed_ok(args)
            Input.consume_event(args)
            if @dialogue.messages_remain?
                # Show next message
                @dialogue.forward()
            else
              # Return to adventure
              @state = STATE_EXIT
            end
          end
        end
      end
    end
  end # class AdventureEvent

  # Checkpoint
  class RestEvent < AdventureEvent
    # has image
    # situation: "You've reached an entrance shaft. You can rest here and continue, or call for extraction."
    # option1: Rest and press on
    ## result: rest, then return
    # option2: Call for extraction
    ## result: event-result-extract
    def initialize adventure
      @situation_image = "sprites/image/image-rest01.png"
      @situation_text = [ "You have reached one of the countless entrance shafts. You could rest here, or call for extraction."]
      @option_prompt = "You decide to..."
      @options = [
        { text: "Rest, and press on", result_callback: method(:perform_rest) },
        {
          text: "Call for extraction",
          result: :event_result_extraction,
          result_text: "Dropship inbound! Returning home.",
          result_image: "sprites/image/image-extraction01.png",
          result_sound: "sounds/event_extraction.wav"
        }
      ]

      super
    end

    def perform_rest
      @adventure.party.each do |soldier|
        soldier.heal_daily() if soldier.alive?
      end
      @dialogue.set_message({ text: "The party rests briefly.", portrait: nil})
      @event_result = :event_result_continue
    end
  end

  class EndEvent < AdventureEvent
    def initialize adventure
      @situation_image = "sprites/image/image-sector-end.png"
      @situation_text  = [ "You have reached the final entrance shaft of the sector."]
      @option_prompt   = "It's time to..."
      @options = [
        {
          text: "Call for extraction",
          result: :event_result_extraction,
          result_text: "Dropship inbound! Returning home.",
          result_image: "sprites/image/image-extraction01.png",
          result_sound: "sounds/event_extraction.wav"
        }
      ]

      super
    end
  end

  # 1. Situation
  # 2. Choice to do it or not
  # 3. (auto-pick the suitable party member) Roll dice
  # 4. Show result
  class SkillCheckEvent < AdventureEvent

    # Kind of builder pattern for scripting events
    class EventData
      attr_reader :title
      attr_reader :skill_type
      attr_reader :situation_messages
      attr_reader :situation_prompt
      attr_reader :option_data

      # Data for a single option
      class OptionData
        attr_reader :title
        attr_reader :activation_messages
        attr_reader :success_messages
        attr_reader :failure_messages

        def initialize title
          @title = title
        end

        def on_activate message1, message2 = nil # "XX steps to the challenge", "I've got this, guys!"
          @activation_messages = [message1]
          if message2
            @activation_messages << message2
          end
          return self
        end

        def on_success message1, message2 # "XX pulls the lever with ease", "You find REWARD_NAME"
          @success_messages = [message1, message2]
          return self
        end

        def on_failure message1, message2 # "Oh no! It's fallen off.", "Nothing we can do about it now."
          @failure_messages = [message1, message2]
          return self
        end
      end # OptionData

      def initialize skill_type
        @skill_type = skill_type
      end

      def situation line1, line2
        @situation_messages = [line1, line2]
        return self
      end

      def options prompt, option1, option2 # "You decide to..."
        @situation_prompt = prompt
        @option_data      = [option1, option2]
        return self
      end
    end #EventData

    def self.make_event skill_type
      return EventData.new(skill_type)
    end

    def self.make_option prompt
      return EventData::OptionData.new(prompt)
    end

    StrEvent = make_event(:str)
      .situation("You come across a big stiff lever.", "A bad enough dude may be able to pull the lever")
      .options("You decide to...",
        make_option("Pull the lever")
          .on_activate("SOLDIER_NAME steps to the challenge.", "I've got this, guys!")
          .on_success("CLICK! SOLDIER_NAME pulls the lever with ease.", "A hidden compartment opens, revealing a REWARD_NAME!")
          .on_failure("SNAP!", "Oh no, it's fallen off. Nothing we can do about it now."),
        make_option("Ignore it and move on")
          .on_activate("You decide to ignore the lever.")
      )

    DexEvent = make_event(:dex)
      .situation("You encounter a lone cargo drone transporting a small container.", "A fast enough dude may be able to snatch the container.")
      .options("You decide to...",
        make_option("Grab the container")
          .on_activate("SOLDIER_NAME eyes the drone.", "I've got this, guys!")
          .on_success("SOLDIER_NAME grabs the container before the drone manages to run away.", "Inside the container is a REWARD_NAME!")
          .on_failure("BEEP BEEP!", "Oh no, it got away. Nothing we can do about it now."),
        make_option("Move on, it's not ours")
          .on_activate("You decide to leave it alone.")
      )

    IntEvent = make_event(:int)
      .situation("You come across an ancient container, sealed by a complex mechanism.", "A smart enough dude may be able to figure out the mechanism.")
      .options("You decide to...",
        make_option("Figure out the lock")
          .on_activate("SOLDIER_NAME steps forward.", "I've got this, guys!")
          .on_success("After less than an hour of investigation, SOLDIER_NAME has figured out the mechanism!", "Inside the ancient container is a REWARD_NAME!")
          .on_failure("KA-CLUNK!", "Oh no, it's completely locked up. Nothing we can do about it now."),
        make_option("Ignore it and move on")
          .on_activate("You decide to leave it untouched.")
      )

    EndEvent = make_event(:end)
      .situation("You see something above you, high up on a perilous ledge.", "A tough enough dude may be able to climb up there.")
      .options("You decide to...",
        make_option("Attempt the climb")
          .on_activate("SOLDIER_NAME jumps forward.", "I've got this, guys!")
          .on_success("After a few failed starts, SOLDIER_NAME has reached the ledge!", "Up on the ledge is a REWARD_NAME!")
          .on_failure("CRASH!", "Oh no, the ledge has collapsed. Nothing we can do about it now."),
        make_option("Ignore it and move on")
          .on_activate("You decide to move on.")
      )

    def initialize adventure
      @data = [StrEvent, DexEvent, IntEvent, EndEvent].random_element()
      @situation_image = "sprites/image/image-encounter-01.png"
      @situation_text  = @data.situation_messages
      @option_prompt   = @data.situation_prompt
      @options = [
        { text: @data.option_data[0].title, result_callback: method(:perform_skillcheck) },
        { text: @data.option_data[1].title, result_callback: method(:skip_event) }
      ]

      super
    end

    def queue_message message
      message = message.gsub('SOLDIER_NAME', @soldier_name)
      message = message.gsub('REWARD_NAME', @reward_name)
      if @dialogue.waiting_for_input?
        @dialogue.set_message({ text: message, portrait: nil})
      else
        @dialogue.add_message({ text: message, portrait: nil})
      end
    end

    def queue_dialogue message_list
      queue_message(message_list[0])
      queue_message(message_list[1])
    end

    def choose_soldier
      skill_accessor = ->(soldier) {
        case @data.skill_type
        when :str
          soldier.strength.current
        when :dex
          soldier.dexterity.current
        when :int
          soldier.intellect.current
        else
          soldier.endurance.current
        end
      }
      alive_soldiers = @adventure.party.select { |x| x.alive? }
      max_skill = alive_soldiers.max_by(&skill_accessor)
      return max_skill
    end

    def roll_check soldier
      mod = 0
      case @data.skill_type
      when :str
        mod = soldier.strength.dm
      when :dex
        mod = soldier.dexterity.dm
      when :int
        mod = soldier.intellect.dm
      when :end
        mod = soldier.endurance.dm
      end
      return (roll_2d6() + mod) >= ADVENTURE_EVENT_DIFFICULTY
    end

    def perform_skillcheck
      # Pick the best candidate
      # Roll dice
      # Decide results accordingly
      candidate = choose_soldier()
      success   = roll_check(candidate)
      reward    = Treasures.get_random_named()

      @soldier_name = candidate.firstname.upcase
      @reward_name  = reward.name.upcase
      option        = @data.option_data[0]
      queue_dialogue(option.activation_messages)
      if success
        queue_dialogue(option.success_messages)
        @adventure.collected_loot << reward
      else
        queue_dialogue(option.failure_messages)
      end
      @event_result = :event_result_continue
    end

    def skip_event
      # junk... dialogue bugs out unless the first message is set_message
      # should really fix this!
      @data.option_data[1].activation_messages.each_with_index do |msg, idx|
        if idx == 0
          @dialogue.set_message({ text: msg, portrait: nil})
        else
          @dialogue.add_message({ text: msg, portrait: nil})
        end
      end
      @event_result = :event_result_continue
    end
  end

  module EventFactory
    def EventFactory.make_random_event adventure
      return SkillCheckEvent.new(adventure)
    end
  end
end #module Adventure
