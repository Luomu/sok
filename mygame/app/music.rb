# Music:
# - station background music
# - dungeon crawl music
# - combat music
# Listens to game events to play/stop/fade audio
ENABLE_MUSIC = !Cheats::DISABLE_MUSIC

module Music
  def Music.initialize args
    #connect to game events
    if ENABLE_MUSIC
      $game_events.subscribe(Events::ENTER_STRATEGY,  method(:play_station_music))
      $game_events.subscribe(Events::ENTER_ADVENTURE, method(:on_enter_adventure))
      $game_events.subscribe(Events::EXIT_ADVENTURE,  method(:on_exit_adventure))
      $game_events.subscribe(Events::ENTER_ADVENTURE_CRAWL, method(:play_adventure_music))
      $game_events.subscribe(Events::ENTER_COMBAT, method(:play_combat_music))
    end
  end

  def Music.stop
    $args.audio[:music_strategy_main]       = nil
    $args.audio[:music_strategy_secondary]  = nil
    $args.audio[:music_adventure_main]      = nil
    $args.audio[:music_adventure_secondary] = nil
  end

  def Music.play_intro
    return unless ENABLE_MUSIC
    $args.audio[:music_strategy_main] = {
      input: 'music/intro.ogg',
      looping: true
    }
  end

  def Music.play_station_music payload
    return unless ENABLE_MUSIC

    # The station music gets repetitive if it starts from over constantly.
    # Play the sub-scene music using another stream.
    #$args.audio[:music_strategy_main] ||= {
    #  input: 'music/station01.ogg',
    #  looping: true,
    #  paused: false
    #}
    if $args.audio[:music_strategy_main]&.paused
      $args.audio[:music_strategy_main].paused = false
    else
      $args.audio[:music_strategy_main] = {
        input: 'music/station01.ogg',
        looping: true,
        paused: false
      }
    end
    $args.audio[:music_strategy_main].paused = false
    $args.audio[:music_strategy_secondary]   = nil

    # In case we did any cheat skipping
    $args.audio[:music_adventure_main]      = nil
    $args.audio[:music_adventure_secondary] = nil
  end

  def Music.play_shop_music
    return unless ENABLE_MUSIC

    # The station music gets repetitive if it starts from over constantly.
    # Play the sub-scene music using another stream.
    $args.audio[:music_strategy_main].paused = true
    $args.audio[:music_strategy_secondary]   = {
      input: 'music/garage01.ogg',
      looping: true,
      paused: false
    }
  end

  def Music.play_treasure_music
    return unless ENABLE_MUSIC

    $args.audio[:music_strategy_main].paused = true
    $args.audio[:music_strategy_secondary]   = {
      input: 'music/treasureroom.ogg',
      looping: true,
      paused: false
    }
  end

  def Music.play_results_music
    return unless ENABLE_MUSIC

    $args.audio[:music_strategy_main] = {
      input: 'music/final_results.ogg',
      looping: false
    }
    $args.audio[:music_strategy_secondary]  = nil
    $args.audio[:music_adventure_main]      = nil
    $args.audio[:music_adventure_secondary] = nil
  end

  def Music.on_enter_adventure payload
    # Mostly needed because of cheat keys
    $args.audio[:music_strategy_main]        = nil
    $args.audio[:music_strategy_secondary]   = nil
    $args.audio[:music_adventure_main]       = nil
    $args.audio[:music_adventure_secondary]  = nil
  end

  def Music.on_exit_adventure payload
    $args.audio[:music_strategy_main]        = nil
    $args.audio[:music_strategy_secondary]   = nil
    $args.audio[:music_adventure_main]       = nil
    $args.audio[:music_adventure_secondary]  = nil
  end

  def Music.play_adventure_music payload
    return unless ENABLE_MUSIC

    $args.audio[:music_strategy_main]      = nil
    $args.audio[:music_strategy_secondary] = nil
    $args.audio[:music_adventure_main] ||= {
      input: 'music/dungeoncrawl01.ogg',
      looping: true
    }
    $args.audio[:music_adventure_main].paused = false
    $args.audio[:music_adventure_secondary]   = nil
  end

  def Music.play_combat_music payload
    return unless ENABLE_MUSIC

    $args.audio[:music_adventure_main]&.paused = true
    $args.audio[:music_adventure_secondary]   = {
      input: 'music/fight01.ogg',
      looping: true
    }
  end

  def Music.play_combat_win_jingle
    return unless ENABLE_MUSIC

    $args.audio[:music_adventure_main]&.paused = true
    $args.audio[:music_adventure_secondary]    = {
      input: 'music/win-jingle.ogg',
      looping: false
    }
  end

  def Music.play_combat_lose_jingle
    return unless ENABLE_MUSIC

    $args.audio[:music_adventure_main]&.paused = true
    $args.audio[:music_adventure_secondary]   = {
      input: 'music/lose-jingle.ogg',
      looping: false
    }
  end
end
