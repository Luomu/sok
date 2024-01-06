# Intro "cinematic"
class GameState_Intro < FsmState
  def on_enter args
    @dialogue = Dialogue.new()
    @dialogue.handle_input = false #running on timer

    IMAGE_ONE = "sprites/image/image-intro-01a.png"
    IMAGE_TWO = "sprites/image/image-intro-01.png"

    # Defines text lines and how long they stay on screen
    @text_lines = [
      { text: "Planet Kolumbo is haunted, it is said.", timeout: 250, image: IMAGE_ONE},
      { text: "It is also a source of great riches, with vast alien ruins reaching deep within the planet.", timeout: 300 },
      { text: "Fortune-seekers and mercenaries plunder this dangerous world, launching down from an orbital station.", timeout: 300 },
      { text: "The Corporation sends you here, to manage the local franchise and recover priceless artifacts.", timeout: 250, image: IMAGE_TWO},
      { text: "The journey has been long, but you are finally docking with the station.", timeout: 250 },
      { text: "The race for riches will soon begin! Make The Corporation proud!", timeout: 250 }
    ]

    @countdown = -1
    @stage     = 0
    @img_ypos  = 0
    @img_fade  = 0
    @img_state = :fading_in
    @img_path  = nil

    @skip_counter = 0

    Music.play_intro()
  end

  def on_exit args
    @dialogue = nil
  end

  # Show the intro text, pan an image
  IMAGE_WIDTH  = 384
  IMAGE_HEIGHT = 384
  IMAGE_XPOS = SCREEN_HALF_W - IMAGE_WIDTH/2
  IMAGE_YPOS = SCREEN_HALF_H - IMAGE_HEIGHT/2 + 80
  def on_update args
    @countdown -= 1 * Debug.speed_multiplier()

    # Play the next line
    if @countdown < 0
      if @text_lines.size > 0
        next_line = @text_lines.shift
        @dialogue.set_message(next_line)
        @countdown = next_line.timeout

        # Swap the image
        if next_line.image
          @img_path = next_line.image
          @img_ypos = 0
        end
      else
        @stage = :end
      end
    end

    @dialogue.set_ypos(140)
    @dialogue.update(args)
    @img_ypos += 0.15

    # Fade in the image
    if @img_state == :fading_in
      @img_fade += 1
      if @img_fade >= 255
        @img_fade = 255
        @img_state = :stable
      end
    end

    # Image, showing a scrolling sub-region
    args.outputs.primitives << { x: IMAGE_XPOS, y: IMAGE_YPOS,
      w: IMAGE_WIDTH, h: IMAGE_HEIGHT, r: @img_fade, g: @img_fade, b: @img_fade,
      source_x: 0, source_y: @img_ypos, source_w: 384, source_h: 384, path: @img_path}.sprite!

    if @stage == :end
      @parent_fsm.transition_to(:corefsm_state_strategy)
    end

    if Input.held_ok(args)
      @skip_counter += 1
      Rendering.text_left(40, 40, "Hold OK to skip...")
      if @skip_counter > 60
        @stage = :end
      end
    elsif @skip_counter > 0
      @skip_counter -= 1
    end
    Debug.add_state_text("#{@text_lines.size} #{@stage}")
  end
end

# Ceremony before results
class GameState_Outro < FsmState
  def on_enter args
    @counter  = 0
    @dialogue = Dialogue.new()
    @dialogue.handle_input = false #running on timer

    Music.play_results_music()

    # Image fade in/out animation
    @fade_curve = Curve.new
    @fade_curve.add_frame!(0, 0)
    @fade_curve.add_frame!(80, 255)
    @fade_curve.add_frame!(300, 255)
    @fade_curve.add_frame!(480, 0)

    @img_curve = Curve.new
    @img_curve.add_frame!(0,   0)
    @img_curve.add_frame!(500, 100)

    @dialogue.set_message({ text: "Now departing the Kolumbo System!", timeout: 250, image: "sprites/image/image-outro-01.png"})
    Sound.play_oneshot("sounds/outro_airbike.wav")
  end

  # Show the outro text, pan an image
  IMAGE_WIDTH  = 384
  IMAGE_HEIGHT = 384
  IMAGE_XPOS = SCREEN_HALF_W - IMAGE_WIDTH/2
  IMAGE_YPOS = SCREEN_HALF_H - IMAGE_HEIGHT/2 + 80
  IMG_PATH   = "sprites/image/image-outro-01.png"
  def on_update args
    @counter += 1 * Debug.speed_multiplier()
    Rendering.set_color(COLOR_WHITE)
    Rendering.text_center(640, 500, "Playing outro... #{@counter}")

    @dialogue.set_ypos(140)
    @dialogue.update(args)

    img_fade = @fade_curve.evaluate(@counter)
    img_ypos = @img_curve.evaluate(@counter)

    # Image, showing a scrolling sub-region
    args.outputs.primitives << { x: IMAGE_XPOS, y: IMAGE_YPOS,
      w: IMAGE_WIDTH, h: IMAGE_HEIGHT, r: img_fade, g: img_fade, b: img_fade,
      source_x: img_ypos/2, source_y: img_ypos, source_w: 256, source_h: 256, path: IMG_PATH}.sprite!

    if @counter > 500 or Input.pressed_ok(args)
      @parent_fsm.transition_to(:corefsm_state_results)
    end
  end
end
