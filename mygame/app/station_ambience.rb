# Plays occasional sound effects (bleeps, muffled announcements)
class StationAmbience
  Announcements = [
    'announce01',
    'announce02',
    'announce03',
    'announce04',
    'announce05',
    'announce06',
    'announce07',
    'announce08'
  ]

  Effects = [
    'effect01',
    'effect02',
    'effect03',
    'effect04',
    'effect05',
    'effect06',
    'effect07',
    'effect08',
    'effect09'
  ]

  def initialize
    @cooldown_ann = get_cooldown()
    @cooldown_eff = get_cooldown()

    @eff_queue = Effects.shuffle
    @ann_queue = Announcements.shuffle
  end

  def get_announcement
    if @ann_queue.empty?
      @ann_queue = Announcements.shuffle
    end
    "sounds/amb_station/" + @ann_queue.draw_random_element! + ".ogg"
  end

  def get_effect
    if @eff_queue.empty?
      @eff_queue = Effects.shuffle
    end
    "sounds/amb_station/" + @eff_queue.draw_random_element! + ".ogg"
  end

  def get_pitch()
    return [0.8, 0.9, 1.0, 1.1, 1.2].random_element()
  end

  def get_cooldown()
    return rand_between(9*60, 15*60)
  end

  def get_gain()
    return [0.6, 0.7, 0.8, 0.9].random_element()
  end

  def update args
    @cooldown_ann -= 1
    if @cooldown_ann <= 0
      args.audio[:amb_announcement] = { input: get_announcement(), pitch: get_pitch(), gain: get_gain() }
      @cooldown_ann = get_cooldown()
    end

    @cooldown_eff -= 1
    if @cooldown_eff <= 0
      args.audio[:amb_effect] = { input: get_effect(), pitch: get_pitch(), gain: get_gain() }
      @cooldown_eff = get_cooldown()
    end
  end
end
