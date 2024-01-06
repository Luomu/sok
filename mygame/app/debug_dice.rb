module Debug
  # Listens for:
  # :roll_damage
  class DiceLogger
    class Stat
      def initialize
        @values = []
        @avg    = 0
      end

      def accumulate value
        @values << value
        @avg = @values.sum / @values.size
      end

      def average
        return @avg.round(1)
      end

      def hit_rate
        return 0 if @values.empty?
        hit_count = @values.map { |x| x >= 0 }.tally[true]
        hit_count = 0 unless hit_count
        return (hit_count / @values.size * 100).round(1)
      end
    end

    def initialize
      @stat_hit_soldiers = Stat.new
      @stat_hit_enemies  = Stat.new

      @stat_dmg_soldiers = Stat.new
      @stat_dmg_enemies  = Stat.new
    end

    def hook
      $game_events.subscribe(:roll_attack, method(:on_roll_attack))
      $game_events.subscribe(:roll_damage, method(:on_roll_damage))
    end

    def unhook
      $game_events.unsubscribe(:roll_attack, method(:on_roll_attack))
      $game_events.unsubscribe(:roll_damage, method(:on_roll_damage))
    end

    def on_roll_attack payload
      if payload.source.class == Creature
        @stat_hit_enemies.accumulate(payload.roll)
      else
        @stat_hit_soldiers.accumulate(payload.roll)
      end
    end

    def on_roll_damage payload
      if payload.source.class == Creature
        @stat_dmg_enemies.accumulate(payload.roll)
      else
        @stat_dmg_soldiers.accumulate(payload.roll)
      end
    end

    def render args
      ypos = 40.from_top
      Rendering.set_color(COLOR_WHITE)
      Rendering.text_right(20.from_right, ypos-=20, "Avg Sol Hit: #{@stat_hit_soldiers.average}")
      Rendering.text_right(20.from_right, ypos-=20, "Avg Enm Hit: #{@stat_hit_enemies.average}")
      Rendering.text_right(20.from_right, ypos-=20, "Avg Sol Dmg: #{@stat_dmg_soldiers.average}")
      Rendering.text_right(20.from_right, ypos-=20, "Avg Enm Dmg: #{@stat_dmg_enemies.average}")
      Rendering.text_right(20.from_right, ypos-=20, "Sol Hit %: #{@stat_hit_soldiers.hit_rate}")
      Rendering.text_right(20.from_right, ypos-=20, "Enm Hit %: #{@stat_hit_enemies.hit_rate}")
    end
  end
end
