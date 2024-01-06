# Save options
module Strategy
  class SystemScreen < Screen
    def initialize
      super
      @save_screen = nil
    end

    def on_update args
      #Gui.set_next_window_size(512, 320)
      Gui.begin_window("save_window")
      Gui.menu_option_call("Save", method(:open_save_screen))
      Gui.menu_option_call("Quit", method(:open_quit_screen))
      Gui.label("")
      Gui.end_window()
    end

    def quit_game
      Music.stop() # TODO clean this :)
      $game_events.publish(Events::AUTOSAVE, nil)
      $core_fsm.transition_to(:corefsm_state_menu)
    end

    def open_quit_screen
      @save_screen = ScreenManager.open(MenuScreen.new("Quit to main menu?"))
        .add_option({text: "Yes", callback: -> { quit_game() }})
        .add_option({text: "No",  callback: -> { }, close: true})

      if $args.state.save_slot_idx
        @save_screen.add_label("Game will be saved to Slot #{$args.state.save_slot_idx}")
      else
        @save_screen.add_label("Game will not be saved.")
      end
    end

    def open_save_screen
      @save_screen = ScreenManager.open(MenuScreen.new("Select save slot:"))
      .add_option({text: "Slot 1", callback: -> { confirm_save_to(1) }})
      .add_option({text: "Slot 2", callback: -> { confirm_save_to(2) }})
      .add_option({text: "Slot 3", callback: -> { confirm_save_to(3) }})
    end

    def confirm_save_to slot_no
      # Show confirmation
      # If slot is occupied, show message with extra confirm
      ScreenManager.open(ConfirmationDialog.new("Save and enable autosaving to Slot #{slot_no}?"))
        .set_on_yes(-> {
          $game_events.publish(Events::ENABLE_AUTOSAVE, slot_no)
          ScreenManager.close(@save_screen)
          ScreenManager.close(self)
        })
    end
  end # class ShopScreen
end
