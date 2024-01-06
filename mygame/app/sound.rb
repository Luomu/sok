#sfx, yo
module Sound
  def Sound.play_oneshot name
    return if Cheats::DISABLE_SFX
    $args.audio[:sound1] = { input: name }
  end

  def Sound.menu_blocked
    Sound.play_oneshot("sounds/menu_blocked02.wav")
  end

  def Sound.menu_up
    Sound.play_oneshot("sounds/menu_up.wav")
  end

  def Sound.menu_down
    Sound.play_oneshot("sounds/menu_down.wav")
  end

  def Sound.menu_ok
    Sound.play_oneshot("sounds/menu_ok.wav")
  end

  def Sound.menu_cancel
    Sound.play_oneshot("sounds/menu_cancel.wav")
  end

  def Sound.random_encounter
    Sound.play_oneshot("sounds/encounter.wav")
  end

  def Sound.buy
    Sound.play_oneshot("sounds/buy.wav")
  end

  def Sound.sell
    Sound.play_oneshot("sounds/sell.wav")
  end
end
