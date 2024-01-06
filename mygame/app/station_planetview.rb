# View showing the planet the station is orbiting
# some moving stars
class StationPlanetView
  SCENE_WIDTH  = 500
  SCENE_HEIGHT = 256

  class Star
    attr_sprite
    def initialize
      intensity = 100 + rand(155)
      @x = rand(500)
      @y = rand(256)
      @w = 2
      @h = 2
      @r = intensity
      @g = intensity
      @b = intensity
      @path = 'sprites/planet_view/star.png'
    end

    def move offs
      @x -= offs
      @x = 500 if @x < -1
    end
  end

  class Traffic
    attr_sprite
    def initialize
      @x = 0
      @y = 0
      @w = 2
      @h = 2
      @r = 255
      @g = 255
      @b = 100
      @path = 'sprites/planet_view/star.png'

      @wait_timer = 10
      @start_x    = 10
      @start_y    = 50
      @end_x      = 500
      @end_y      = 256
      @move_timer = 0
      @moving     = false

      @x = @start_x
      @y = @start_y

      @dir = 1

      @move_speed = 0.001
    end

    def move args
      if @wait_timer > 0
        @wait_timer -= 1
        if @wait_timer <= 0
          @moving = true
        end
      end

      if @moving
        #is there really no simple lerp function?
        @move_timer += @move_speed
        progress = args.easing.ease(0, @move_timer, 1.0, :identity)
        calc_x = @start_x + (@end_x - @start_x) * progress
        progress = args.easing.ease(0, @move_timer, 1.0, :quad)
        calc_y = @start_y + (@end_y - @start_y) * progress
        @x = calc_x
        @y = calc_y
        if progress >= 1.0
          @moving     = false
          @move_timer = 0
          @wait_timer = rand() * 5 * 60
          @dir *= -1
          @move_speed = [0.006, 0.004, 0.002].random_element()

          color = [COLOR_GREEN_P8, COLOR_YELLOW_P8, COLOR_YELLOW_P8].random_element
          @r, @g, @b = color.r, color.g, color.b

          if rand() > 0.5
            oldend = @end_x
            @end_x = @start_x
            @start_x = oldend
          end

          @a = 100 + rand(155)

          @start_y = rand(256)
          @end_y = rand(256)
          @x = @start_x
          @y = @start_y
          #@end_x = 100
          #@end_y = 10#rand(256)
        end
      end
      #@x -= offs
      #@x = 500 if @x < -1
      #args.easing start, tick_count, duration
    end
  end

  def initialize
    @planet_strips = []
    strip_x = 0
    5.times do |i|
      @planet_strips << {
        x: strip_x,
        y: 0,
        w: 32,
        h: 128,
        r: 255,
        g: 255,
        b: 255,
        a: 64,
        path: 'sprites/planet_view/planet_gradient.png',
        blendmode_enum: 2
      }
      strip_x += 32
    end

    @strip_move_timer = 0

    srand(1234) #ensure some stability
    @stars = []
    100.times do |i|
      @stars << Star.new
    end
    srand() #can't restore the previous seed afaik

    # Some simulated traffic
    @traffic = [
      Traffic.new(), Traffic.new()
    ]
  end

  def update args
    #args.outputs[:planet]
    args.outputs[:planet].w = 128
    args.outputs[:planet].h = 128
    args.outputs[:planet].background_color = [199, 240, 216, 0]
    args.outputs[:planet].transient!

    args.outputs[:scene].w = 500
    args.outputs[:scene].h = 256
    args.outputs[:scene].background_color = [0,0,0,255]
    args.outputs[:scene].transient!

    args.outputs[:scene_rotated].w = 500
    args.outputs[:scene_rotated].h = 256
    args.outputs[:scene_rotated].background_color = [255,0,0,255]
    args.outputs[:scene_rotated].transient!

    args.outputs[:planet].primitives << {
      x: 0,
      y: 0,
      w: 128,
      h: 128,
      r: 20,
      g: 100,
      b: 100,
      path: 'sprites/planet_view/planet.png'
    }.sprite!

    offs = 0
    @strip_move_timer += 0.15
    if @strip_move_timer > 1
      offs = 1
      @strip_move_timer = 0
    end

    @planet_strips.each do |strip|
      args.outputs[:planet].primitives << strip.sprite!
      strip.x = -32 if strip.x >= 128
      strip.x += offs
    end

    args.outputs[:planet].primitives << {
      x: 0,
      y: 0,
      w: 128,
      h: 128,
      path: 'sprites/planet_view/planet_shine.png',
      blendmode_enum: 2
    }.sprite!

    # Render scene to target 2
    @stars.each { |star| star.move(offs) }
    @traffic.each { |traffic| traffic.move(args) }
    args.outputs[:scene].primitives << @stars
    args.outputs[:scene].primitives << @traffic[0]
    args.outputs[:scene].primitives << { x:250, y:0, w:256, h:256,path: :planet }.sprite!
    args.outputs[:scene].primitives << @traffic[1]

    # Once more - render the stars + planet slightly rotated

    # Final result, show the (rotated) view
    # offsets are based on the scale and rotation of the scene
    x = -10
    y = -25
    w = 500 * 1.2
    h = 256 * 1.2
    args.outputs[:scene_rotated].primitives << { x:x, y:y, w:w, h:h, path: :scene, angle: -5}.sprite!

    # Final final result - render to screen
    final_w = 500 * 1
    final_h = 256 * 1
    x = SCREEN_HALF_W - final_w/2
    y = SCREEN_HALF_H - final_h/2
    args.outputs.primitives << { x:x, y:y, w:final_w, h:final_h,path: :scene_rotated, angle: 0}.sprite!
  end
end
