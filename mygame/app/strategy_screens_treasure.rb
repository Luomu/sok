module Strategy
  # View your collection of loot, and (later) sell them for quick cash
  # Treasures are more valuable at the final evaluation
  class TreasuresScreen < Screen
    def initialize args
      super()
      refresh_list(args)
      Strategy.eventbus.publish(Events::ENTER_LOOT)
      @selected_option = nil
      @quickhelp_text  = nil
    end

    def refresh_list args
      @options = []
      args.state.company.treasures.each do |t|
        @options << { treasure: t }
      end
      @selected_option = nil
    end

    def really_sell_treasure treasure, final_price, args
      Sound.sell()
      args.state.company.gain_money(final_price)
      args.state.company.treasures.delete(treasure)
      refresh_list(args)
    end

    def check_sell_treasure treasure, args
      price = treasure.calculate_sale_price
      ScreenManager.open(ConfirmationDialog.new("We'll take the #{treasure.name} off your hands... for #{price} Cr."))
        .set_on_yes(-> { really_sell_treasure(treasure, price, args) })
    end

    def update_quickhelp text
      @quickhelp_text = text
    end

    Width  = 512
    Height = 400
    Pos_x  = SCREEN_HALF_W - 256
    Pos_y  = 32.from_top
    def on_update args
      # Treasure selection grid
      Gui.set_next_window_pos(Pos_x, Pos_y)
      Gui.set_next_window_size(Width, Height)
      Gui.begin_window("treasures_window")
      Gui.header("Treasures")
      if @options.empty?
        Gui.label("You have no loot right now! Do some missions!")
        @selected_option = nil
      else
        @options.each do |option|
          if Gui.menu_option(option.treasure.name)
            check_sell_treasure(option.treasure, args)
          end
        end
      end

      hl_option = Gui.end_window() #end grid window
      if hl_option != @selected_option
        @selected_option = hl_option
        if @options.size > @selected_option
          update_quickhelp(@options[@selected_option].treasure.description)
        end
      end

      # Context window
      if @quickhelp_text
        Gui.set_next_window_flags(WINDOWFLAG_NO_FOCUS)
        Gui.set_next_window_size(Width, 140)
        Gui.set_next_window_pos(Pos_x, Pos_y - Height)
        Gui.item_preview_window("treasure_details", nil, @quickhelp_text)
      end
    end

    def on_cancel args
      Strategy.eventbus.publish(Events::EXIT_LOOT)
      Sound.menu_cancel()
      close()
    end
  end
end # module Strategy
