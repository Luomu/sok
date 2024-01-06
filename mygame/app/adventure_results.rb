# Show the loot and other such ceremonies
module Adventure
  class ResultScreen < Screen
    def initialize model
      super()
      @model = model
    end

    def on_update args
      Gui.begin_window("adventure_results")
      if @model.is_failed
        Gui.label("The team has been KIA")
        Gui.label("Science Bonus: #{@model.science_bonus} Cr")
        Gui.label("Security Bonus: #{@model.security_bonus} Cr")
        Gui.label("Artifacts Recovered: None")
        Gui.label("Another team may be sent to recover the lost equipment and items.")
      else
        Gui.label("Mission Accomplished!")
        Gui.label("Science Bonus: #{@model.science_bonus} Cr")
        Gui.label("Security Bonus: #{@model.security_bonus} Cr")
        if @model.loot.empty?
          Gui.label("Artifacts Recovered: None")
        else
          Gui.label("Artifacts Recovered:")
          @model.loot.each {|treasure_name| Gui.label(treasure_name) }
        end
      end
      Gui.end_window()
    end
  end

  # Determine mission results and show a screen
  class State_Results < FsmState
    def initialize parent_fsm, adventure_
      super(parent_fsm)
      @adventure = adventure_
    end

    def on_enter args
      # If everyone's dead, this is a loss
      is_failed = @adventure.party_dead?
      # Money is gained regardless of win/loss
      science_bonus, security_bonus = Rules.calculate_mission_bonus(@adventure)
      args.state.company.gain_money(science_bonus + security_bonus)
      args.state.company.num_operations += 1
      # only keep treasures if party survived
      kept_loot_display = []
      if !is_failed
        @adventure.collected_loot.each do |treasure|
          args.state.company.treasures << treasure
          kept_loot_display << treasure.name
        end
      end
      #todo: upon loss, move loot to state.recovery_pile

      # Data for the result screen
      screen_model = {
        science_bonus:  science_bonus,
        security_bonus: security_bonus,
        is_failed:      is_failed,
        loot:           kept_loot_display
      }

      @timer = 0
      @result_screen = ScreenManager.open(Adventure::ResultScreen.new(screen_model))
    end

    def on_update args
      @timer += 1

      # manual close since the screen has no inputs
      if @timer > 20 and Input.pressed_ok(args)
        @result_screen.close(-> { @adventure.is_over = true })
      end
    end
  end
end
