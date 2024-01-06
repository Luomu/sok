# Cheat screen for adventure mode
class AdventureDebugScreen < Screen
  def initialize adventure
    @adventure = adventure
  end

  def on_update args
    Gui.begin_window("#AdventureDebug")
    Gui.header("AdventureDebug")

    Gui.label("Encounters left: #{@adventure.encounters.length}")
    #for enc in @adventure.encounters
    #  Gui.label(enc.to_s)
    #end

    if Gui.menu_option("Kill enemies")
      Adventure.eventbus.publish(Adventure::EVENT_CHEAT_KILL_ENEMIES)
      close()
    end

    if Gui.menu_option("Kill party")
      Adventure.eventbus.publish(Adventure::EVENT_CHEAT_KILL_PARTY)
      close()
    end

    if Gui.menu_option("Heal party")
      Adventure.eventbus.publish(Adventure::EVENT_CHEAT_HEAL_PARTY)
      close()
    end

    if Gui.menu_option("End mission")
      Adventure.eventbus.publish(Adventure::EVENT_CHEAT_END_MISSION)
      ScreenManager.delete_all() #may have some adventure menus open
    end

    Gui.end_window()
  end
end

# Some misc debug viz stuff
module Adventure
  def self.render_debug_info args, adventure
    return unless Debug.cheats_enabled?

    return unless Debug.visible?
    #Debug.add_state_text(adventure.fsm.current_state_name)
    # List upcoming encounters
    Rendering.set_color(COLOR_YELLOW_P8)
    ypos  = 100.from_top()
    xpos  = 300.from_right()
    yoffs = 25
    Rendering.text_left(xpos, ypos, "Encs (lvl #{adventure.mission.challenge})")
    adventure.encounters.each do |enc|
      case enc
      when Adventure::ENCOUNTER_REST
        Rendering.set_color(COLOR_GREEN_P8)
      when Adventure::ENCOUNTER_EVENT
        Rendering.set_color(COLOR_BLUE_P8)
      else
        Rendering.set_color(COLOR_YELLOW_P8)
      end
      Rendering.text_left(xpos, ypos-=yoffs, enc)
    end
  end
end
