module StatusEffects
  TAG_DEFENDING = :tag_defending

  # Usually combat related status effect, has a duration
  # and may modify incoming attacks/damage
  # Effects determine the stacking rules for tags
  class Effect
    def initialize
      @expired = false
      @owner   = nil
    end

    def expired?
      return @expired
    end

    # May fail to apply depending on immunities/conditions
    # Usage: StatusEffects::SomeEffect.new.apply(character)
    def apply character
      raise "Override apply method"
    end

    def remove
      if not @expired
        @owner   = nil
        @expired = true
      end
    end

    def update
      raise 'Update method not overridden'
    end
  end

  # Adds a tag for a fixed duration of turns.
  class SimpleTagEffect < Effect
    def initialize
      @duration = 1
      @elapsed  = 1
    end

    def tag
      raise 'Tag method not overridden'
    end

    def apply character
      character.add_tag(tag())
      character.status_effects << self
      @owner = character
    end

    def remove
      if not expired?
        @owner.remove_tag(tag())
        super()
      end
    end

    # Tick duration, remove if needed
    def update
      if not expired?
        @elapsed += 1
        if @elapsed >= @duration
          remove()
        end
      end
    end
  end

  # Apply penalty to enemy hit chance
  class Defending < SimpleTagEffect
    def tag
      return :tag_defending
    end
  end
end
