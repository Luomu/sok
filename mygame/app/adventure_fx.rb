# Combat effects/animations
module Adventure
  TICKS_PER_FRAME  = 4 # 60 / 15
  Point            = Struct.new(:x, :y)
  EventTrackFrame  = Struct.new(:frame, :sound)
  SpriteTrackFrame = Struct.new(:frame, :frame_idx, :offset, :scale, :opacity)
  AnimSpriteSheet  = Struct.new(:path, :width, :height, :columns, :rows)

  # Sprite sheet registry
  SHEET_FRAG  = AnimSpriteSheet.new('sprites/combat/fx_frag.png', 256, 256, 4, 4)
  SHEET_DEMO  = AnimSpriteSheet.new('sprites/combat/fx_temp.png', 256, 256, 4, 4)
  SHEET_ICONS = AnimSpriteSheet.new('sprites/combat/fx_icons.png', 256, 256, 4, 4)

  # Animation IDs
  module Animations
    MISS  = 0
    HIT_1 = 1
  end

  # Event track  (sound, frame_idx, volume)
  class EventTrack
    attr_accessor :frames

    def initialize
      @frames = []
    end
  end

  # Sprite track (sheet, frame_idx, offset, scale, opacity)
  class SpriteTrack
    attr_accessor :frames
    attr_reader   :sprite_sheet

    def initialize sheet_name
      @frames = []
      @sprite_sheet = sheet_name
    end
  end

  # Combat hit effect
  # Holds animation data
  class Animation
    attr_reader :event_track
    attr_reader :sprite_track
    attr_reader :duration

    def initialize duration, sprite_track, event_track
      raise "No animation tracks specified" if (sprite_track == nil && event_track == nil)
      @event_track  = event_track
      @sprite_track = sprite_track
      @duration     = duration
    end

    def draw args, position, tile_idx
      sheet = @sprite_track.sprite_sheet
      w = sheet.width  / sheet.columns
      h = sheet.height / sheet.rows
      left = w * (tile_idx % sheet.columns)
      top  = h * (tile_idx.idiv(sheet.columns))

      xoffs = w * 0.5
      yoffs = h * 0.5

      #debugstuff
      #Rendering.set_color(COLOR_PINK_P8)
      #Rendering.text_left(position.x - w, position.y + h, tile_idx)
      #Rendering.rectangle(position.x - xoffs, position.y - yoffs, w, h)

      args.outputs.primitives <<
      {
        x: position.x - xoffs,
        y: position.y - yoffs,
        w: w,
        h: h,
        path: sheet.path,
        tile_x: left,
        tile_y: top,
        tile_w: w,
        tile_h: h,
        flip_horizontally: false,
      }.sprite!
    end
  end

  # Playing instance of an animation
  class AnimationInstance
    attr_reader :animation
    attr_reader :curr_frame
    attr_reader :position

    def initialize animation_, position_
      @animation  = animation_
      @curr_frame = 0
      @curr_tick  = 0
      @position   = position_
    end

    def finished?
      @curr_frame >= @animation.duration
    end

    # Increment internal frame count
    # Draw all frames equal to current internal frame
    # Play all sounds equal to current frame
    def update args
      @curr_tick += 1
      if @curr_tick > TICKS_PER_FRAME
        @curr_frame += 1
        @curr_tick  = 1
      end

      # Play sounds + misc fx
      # Sounds trigger once per frame
      @animation.event_track.frames.each do |f|
        if f.sound && f.frame == @curr_frame && @curr_tick == 1
          Sound.play_oneshot(f.sound)
        end
      end

      # Update sprites
      #Rendering.set_color COLOR_WHITE
      #Rendering.text_left(@position.x, @position.y+64, @curr_frame)
      @animation.sprite_track.frames.each do |f|
        next unless f.frame == @curr_frame
        @animation.draw(args, [@position.x + f.offset.x, @position.y + f.offset.y], f.frame_idx)
      end
    end
  end

  # Plays animations
  class AnimationManager
    attr_reader :anim_instances

    def prepare_animation data
      sprite_track = SpriteTrack.new(data.sprite1_sheet)
      event_track  = EventTrack.new()
      if data.sprite1_frames
        sprite_track.frames = data.sprite1_frames.map do |frame|
          # frame, tile, location
          SpriteTrackFrame.new(frame.frame, frame.tile, [frame.x.to_i, frame.y.to_i])
        end
      end
      if data.events
        event_track  = EventTrack.new()
        event_track.frames = data.events.map {|frame| EventTrackFrame.new(frame.frame, frame.sound) }
      end
      return Animation.new(data.duration, sprite_track, event_track)
    end

    def initialize
      @animation_data = []
      @anim_instances = []

      miss_data = {
        "duration": 16,
        "sprite1_sheet": SHEET_ICONS,
        "sprite1_frames": [
          { "frame": 0, "tile": 0 },
          { "frame": 1, "tile": 0, "y": 10 },
          { "frame": 2, "tile": 0, "y": 15 },
          { "frame": 3, "tile": 0, "y": 20 },
          { "frame": 4, "tile": 0, "y": 25 },
          { "frame": 5, "tile": 0, "y": 30 }
        ],
        "events": [
          { "frame": 0, "sound": 'sounds/attack_miss.wav' }
        ]
      }

      hit1_data = {
        "duration": 16,
        "sprite1_sheet": SHEET_FRAG,
        "sprite1_frames": [
          { "frame": 0, "tile": 1 },
          { "frame": 1, "tile": 2 },
          { "frame": 2, "tile": 3 },
          { "frame": 3, "tile": 4 },
          { "frame": 4, "tile": 5 },
          { "frame": 5, "tile": 6 },
          { "frame": 6, "tile": 7 },
        ],
        "events": [
          { "frame": 0, "sound": 'sounds/attack_hit.wav' }
        ]
      }

      @animation_data[Animations::MISS]  = prepare_animation(miss_data)
      @animation_data[Animations::HIT_1] = prepare_animation(hit1_data)
    end

    # Play active animations, kill outdated animations
    def update args
      @anim_instances.each do |anim|
        anim.update(args)
      end
      @anim_instances.reject! { |anim| anim.finished? }
    end

    def play animation_id, location
      @anim_instances << AnimationInstance.new(@animation_data.fetch(animation_id), location)
    end

    def clear
      @anim_instances.clear()
    end
  end
end # module Adventure
