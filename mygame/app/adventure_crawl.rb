module Adventure
  TILE_SCROLL_SPEED = 1
  TILE_RENDER_WIDTH = 32
  TILE_ROW_WIDTH = 32
  HERO_WIDTH  = 16
  HERO_HEIGHT = 16
  BG_WIDTH  = 16
  BG_HEIGHT = 16
  TILE_ORIGIN_X = SCREEN_HALF_W + 6*TILE_RENDER_WIDTH
  TILE_WRAP_X   = SCREEN_HALF_W - 8*TILE_RENDER_WIDTH
  BACKGROUND_WIDTH = 384
  BACKGROUND_HEIGHT = 4 * TILE_RENDER_WIDTH

  # Forms the scrolling background
  class CrawlTile
    attr_sprite

    def initialize x, y, color
      @x = x
      @y = y
      @w    = TILE_RENDER_WIDTH
      @h    = TILE_RENDER_WIDTH
      @path = 'sprites/crawl/dungeon_tile01.png'
      @r = color.r
      @g = color.g
      @b = color.b
    end

    def move
      @x -= TILE_SCROLL_SPEED
      @x = TILE_ORIGIN_X if @x <= TILE_WRAP_X
    end
  end

  class HeroSprite
    attr_sprite
    def initialize x, y
      @x = x
      @y = y
      @w = HERO_WIDTH * 4
      @h = HERO_WIDTH * 4
      @path = 'sprites/characters/soldier.png'
      @tile_x = 0
      @tile_y = 0
      @tile_w = HERO_WIDTH
      @tile_h = HERO_WIDTH
      @flip_horizontally = false
      @starting_frame = rand(40)
    end

    def update
      tile_index = @starting_frame.frame_index(4, 20, true)
      @tile_x = 0 + (tile_index * HERO_WIDTH)
    end
  end

  # Dungeon crawl - play animation until event/encounter occurs
  class State_Crawl < FsmState
    def initialize parent_fsm, adventure_
      super(parent_fsm)
      @adventure = adventure_
      srand($args.state.mission.random_seed) #why no access through Adventure?
      @bg_tint = GOOD_SOLDIER_COLORS.random_element()
    end

    def on_enter args
      @adventure.progress = Cheats::QUICK_CRAWL ? 30 : 400 + rand(200)
      @screen_flash_at = nil
      @do_scroll = true

      @scrolling_tiles = []
      TILE_ROW_WIDTH.times do |i|
        x = TILE_ORIGIN_X - (i % TILE_ROW_WIDTH) * TILE_RENDER_WIDTH
        y = SCREEN_HALF_H - BACKGROUND_HEIGHT/2
        @scrolling_tiles << CrawlTile.new(x, y, @bg_tint)
        @scrolling_tiles << CrawlTile.new(x, y + TILE_RENDER_WIDTH, @bg_tint)
        @scrolling_tiles << CrawlTile.new(x, y + TILE_RENDER_WIDTH * 2, @bg_tint)
        @scrolling_tiles << CrawlTile.new(x, y + TILE_RENDER_WIDTH * 3, @bg_tint)
      end

      # Marching party (for live ones)
      @hero_sprites = []
      xoffs = 20
      @adventure.party.each do |soldier|
        if soldier.alive?
          @hero_sprites << HeroSprite.new(SCREEN_HALF_W + xoffs, 290)
          xoffs -= 40
        end
      end

      # Music etc. can listen to this
      $game_events.publish(Events::ENTER_ADVENTURE_CRAWL)
    end

    def on_update args
      # Render the party walking
      render_animation(args)

      Rendering.set_color(COLOR_WHITE)
      if @do_scroll
        Rendering.text_center(SCREEN_HALF_W, 480, "The expedition continues...")
      else
        Rendering.text_center(SCREEN_HALF_W, 480, "Encounter!")
      end

      if Debug.cheats_enabled?
        Rendering.text_center(SCREEN_HALF_W, SCREEN_HALF_H - 100, "Progress #{@adventure.progress}")
      end

      # Count down
      @adventure.progress -= 1 * Debug.speed_multiplier()

      if @adventure.progress < 50 && !@screen_flash_at
        @screen_flash_at = args.state.tick_count
        @do_scroll = false
        Sound.random_encounter()
      end

      # Play the next encounter
      if @adventure.progress < 0
        @adventure.current_encounter = @adventure.encounters.shift()
        case @adventure.current_encounter
        when Adventure::ENCOUNTER_COMBAT
          @parent_fsm.transition_to(:adventure_state_combat)
        when Adventure::ENCOUNTER_REST
          @parent_fsm.transition_to(:adventure_state_event)
        else
          @parent_fsm.transition_to(:adventure_state_event)
        end
      end
    end

    # Scrolling background (variable theme)
    # 4 heroes walking
    def render_animation args
      # Render some dungeon tiles
      if @do_scroll
        @scrolling_tiles.each {|tile| tile.move }
        @hero_sprites.each { |hero| hero.update }
      end

      args.outputs.primitives << @scrolling_tiles

      #args.outputs.lines << [TILE_ORIGIN_X, 0, TILE_ORIGIN_X, SCREEN_H, 255, 0, 255, 255]
      #args.outputs.lines << [TILE_WRAP_X, 0, TILE_WRAP_X, SCREEN_H, 255, 0, 255, 255]

      # Black bars
      xpos = SCREEN_HALF_W + BACKGROUND_WIDTH / 2
      ypos = 256
      args.outputs.primitives << { x: xpos, y: ypos, w: 64, h: 256 }.solid!
      xpos = SCREEN_HALF_W - BACKGROUND_WIDTH / 2 - 64
      args.outputs.primitives << { x: xpos, y: ypos, w: 64, h: 256 }.solid!

      #vignette & borders
      xpos = SCREEN_HALF_W - BACKGROUND_WIDTH  / 2
      ypos = SCREEN_HALF_H - BACKGROUND_HEIGHT / 2
      args.outputs.primitives << { x: xpos, y: ypos, w: BACKGROUND_WIDTH, h: BACKGROUND_HEIGHT, path: 'sprites/crawl/vignette.png' }.sprite!
      #args.outputs.primitives << { x: xpos, y: ypos, w: BACKGROUND_WIDTH, h: BACKGROUND_HEIGHT, r: 64, g:64, b: 64 }.border!

      args.outputs.primitives << @hero_sprites

      return unless @screen_flash_at
      args.outputs.primitives << {
        r: 255, g: 255, b: 255, a: 255 * @screen_flash_at.ease(10, :flip)
      }
      .merge!($grid.rect).solid!
    end

  end # class State_Crawl
end # module Adventure
