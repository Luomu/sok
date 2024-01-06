# Main menu: Start or Load a game
class GameState_MainMenu < FsmState
  def on_enter args
    @assign_menu = ScreenManager.open(MenuScreen.new("#mainmenu"))
      .add_option({ text: "New game", callback: -> { start_game } })
      .add_option({ text: "New game (skip intro)", callback: -> { start_game_quick } })
      .add_option({ text: "Load game", callback:  -> { show_load_menu }  })
      .set_ypos(300)
  end

  def on_exit args
    ScreenManager.delete_all()
  end

  def start_game
    $state.quickstart   = false
    $state.intro_viewed = false
    initialize_new_game($args, quickstart = false)
    @parent_fsm.transition_to(:corefsm_state_intro)
  end

  def start_game_quick
    $state.quickstart   = true
    $state.intro_viewed = true
    initialize_new_game($args, quickstart = true)
    @parent_fsm.transition_to(:corefsm_state_strategy)
  end

  def show_load_menu
    ScreenManager.open(LoadGameScreen.new)
  end

  def on_update args
    # Logo + sub-heading
    args.outputs.primitives << { x: SCREEN_HALF_W-420/2, y: 300.from_top, w: 420, h: 110, path: "sprites/logo.png" }.sprite!
    args.outputs.primitives << { x: SCREEN_HALF_W-200, y: 320.from_top, text: "A computer role-playing game", size_enum: 1, font: FONT_DEFAULT }.set_color_rgb(COLOR_WHITE).label!

    ScreenManager.update(args)

    # Hotkey help
    Gui.draw_hotkeys()
  end

  class LoadGameScreen < Screen
    def initialize
      super
      @save_slots = $core_fsm.enumerate_saves()
    end

    def try_load slot_name
      if slot_name
        Sound.buy()
        close()
        $core_fsm.load_game(slot_name)
      else
        Sound.menu_blocked()
      end
    end

    def on_update args
      Gui.begin_window("load_game")
      Gui.header("Load game")
      @save_slots.each_with_index do |e,i|
        txt = "Slot #{i+1}"
        txt += " (EMPTY)" unless e
        Gui.menu_option_call(txt, -> { try_load(e) })
      end
      Gui.end_window()
    end
  end
end
