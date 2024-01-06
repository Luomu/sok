# Various screens related to Strategy mode
module Strategy
  # Show name & portrait & statblock
  def Strategy.render_soldier_preview soldier
    Gui.set_next_window_flags(WINDOWFLAG_NO_FOCUS)
    Gui.set_next_window_size(400, 200)
    Gui.set_next_window_pos(500, 40.from_top)
    Gui.begin_window("soldier_preview")
    Gui.header(soldier.firstname + " " + soldier.lastname)

    Gui.set_columns(3)

    Gui.begin_column()
    Gui.portrait(soldier)
    Gui.end_column()

    Gui.begin_column()
    Gui.label("STR #{soldier.strength.current}/#{soldier.strength.max}")
    Gui.label("END #{soldier.endurance.current}/#{soldier.endurance.max}")
    Gui.end_column()

    Gui.begin_column()
    Gui.label("DEX #{soldier.dexterity.current}/#{soldier.dexterity.max}")
    Gui.label("INT #{soldier.intellect.current}/#{soldier.intellect.max}")
    Gui.end_column()

    Gui.label(soldier.upp)
    Gui.label("Salary #{soldier.salary}Cr/day")

    Gui.end_window()
  end

  # Review & manage the team members
  class TeamScreen < Screen
    def initialize
      super()
    end

    def on_update args
      Gui.set_next_window_pos(500, 250.from_top)
      Gui.begin_window("team_window")
      Gui.header("Team")
      if args.state.company.team.length == 0
        Gui.label("You have no employees!")
        Gui.end_window()
      else
        args.state.company.team.each do |member|
          if Gui.menu_option(member.firstname + " " + member.lastname)
            Sound.menu_ok()
            open_action_menu(member)
          end
        end
        selected_soldier_index = Gui.end_window()

        selected_soldier = args.state.company.team[selected_soldier_index]
        Strategy.eventbus.publish(Strategy::EVENT_HIGHLIGHT_CHARACTER, selected_soldier)
        Strategy.render_soldier_preview(selected_soldier)
      end
    end

    def on_cancel args
      Strategy.eventbus.publish(Strategy::EVENT_HIGHLIGHT_CHARACTER, nil)
      Sound.menu_cancel()
      close()
    end

    def open_action_menu soldier
      if soldier.assignment == ASSIGNMENT_HOSPITAL
          ScreenManager.open(MessageScreen.new("You cannot reassign an injured soldier!"))
        return
      end

      @assign_menu = ScreenManager.open(MenuScreen.new("Assign #{soldier.firstname} to"))
        .add_option({text: "Active Squad (Slot 1)", callback: -> { move_to_squad(soldier, 0) }})
        .add_option({text: "Active Squad (Slot 2)", callback: -> { move_to_squad(soldier, 1) }})
        .add_option({text: "Active Squad (Slot 3)", callback: -> { move_to_squad(soldier, 2) }})
        .add_option({text: "Active Squad (Slot 4)", callback: -> { move_to_squad(soldier, 3) }})
        .add_option({text: "Reserve", callback: -> { move_to_reserve(soldier) }})
        .add_option({text: "End contract", callback: -> { check_fire_soldier(soldier) }})
    end

    def move_to_squad soldier, slot_index
      $state.company.assign_soldier_to_squad(soldier, slot_index)
      ScreenManager.close(@assign_menu)
    end

    def move_to_reserve soldier
      $state.company.assign_soldier_to_reserve(soldier)
      ScreenManager.close(@assign_menu)
    end

    def check_fire_soldier soldier
      if soldier.injured?
        # Perhaps allow it anyway and cause them to leave for good
        ScreenManager.open(MessageScreen.new("You cannot fire an injured soldier!"))
      else
        ScreenManager.open(ConfirmationDialog.new("Fire #{soldier.firstname} #{soldier.lastname}?"))
          .set_on_yes(-> {
            $state.company.fire_soldier(soldier)
            Strategy.eventbus.publish(:strategy_soldier_fired, soldier)
            ScreenManager.close(@assign_menu)
          })
      end
    end
  end

  # Hiring a soldier
  class RecruitScreen < Screen
    def initialize
      super
    end

    def update_list
      @selected_option = -1
    end

    def refresh_selection
    end

    def show_hire_confirmation soldier
      if $state.company.money < RECRUITMENT_DEBT_LIMIT
        ScreenManager.open(MessageScreen.new("You are too much in debt to recruit!"))
      else
        ScreenManager.open(ConfirmationDialog.new("Hire #{soldier.firstname} #{soldier.lastname}?"))
          .set_on_yes(-> { hire_soldier(soldier) })
      end
    end

    def hire_soldier soldier
      $state.company.hire_soldier(soldier)
      update_list()
      Sound.buy()
      Strategy.eventbus.publish(:strategy_soldier_hired, soldier)
    end

    Pos_y = 128.from_top
    def on_update args
      Gui.set_next_window_size(256, 256)
      Gui.set_next_window_pos(256, Pos_y)
      Gui.begin_window("recruit_window")
      Gui.header("Recruit Soldiers")

      # Soldier selector
      args.state.available_soldiers.each do |soldier|
        if Gui.menu_option(soldier.firstname)
          Sound.menu_ok()
          show_hire_confirmation(soldier)
        end
      end

      if Gui.highlighted_option_index != @selected_option
        @selected_option = Gui.highlighted_option_index
        refresh_selection()
      end
      Gui.end_window()

      return if args.state.available_soldiers.length <= @selected_option

      # Soldier details
      soldier = args.state.available_soldiers[@selected_option]
      Gui.set_next_window_flags(WINDOWFLAG_NO_FOCUS)
      Gui.set_next_window_size(400, 256)
      Gui.set_next_window_pos(512, Pos_y)
      Gui.begin_window("recruit_preview")
      Gui.header(soldier.firstname + " " + soldier.lastname)

      Gui.set_columns(3)

      Gui.begin_column()
      Gui.portrait(soldier)
      Gui.end_column()

      Gui.begin_column()
      Gui.label("STR #{soldier.strength.max}")
      Gui.label("END #{soldier.endurance.max}")
      Gui.end_column()

      Gui.begin_column()
      Gui.label("DEX #{soldier.dexterity.max}")
      Gui.label("INT #{soldier.intellect.max}")
      Gui.end_column()

      Gui.label(soldier.upp)
      Gui.label("Background: #{soldier.background}")
      Gui.label("Salary #{soldier.salary}Cr/day")
      hiring_fee = Rules.calculate_sign_in_bonus(soldier)
      Gui.label("Hiring fee #{hiring_fee}Cr")

      Gui.end_window()
    end

    def on_cancel args
      Sound.menu_cancel()
      close()
    end
  end

  # Pick one of the missions available this turn
  # Names are shown as sector coordinates
  class MissionsScreen < Screen
    def on_update args
      Gui.begin_window("mission_window")
      Gui.header("Available missions")
      if args.state.missions.length == 0
        Gui.label("No missions right now - check back tomorrow")
      else
        args.state.missions.each do |mission|
          Gui.set_columns(2)

          Gui.begin_column(200)
          if Gui.menu_option(mission.name)
            Sound.menu_ok()
            check_begin_mission(mission)
          end
          Gui.end_column()

          Gui.begin_column()
          Gui.label("LVL #{mission.challenge}")
          Gui.end_column()
        end
      end
      Gui.end_window()
    end

    def check_begin_mission mission
      if $state.company.squad_empty?
        ScreenManager.open(MessageScreen.new("Nobody has been assigned to the squad!"))
      else
        drop_cost = Rules.calculate_drop_cost(mission, $state.company)
        ScreenManager.open(ConfirmationDialog.new("Begin #{mission.name} with the current squad?\nDrop cost: #{drop_cost} Cr"))
          .set_on_yes(-> { really_begin_mission($state, mission, drop_cost) })
      end
    end

    def really_begin_mission state, mission, drop_cost
      state.company.spend_money(drop_cost) #bypasses debt limit on purpose
      state.mission = mission
      # Give everyone drop credit
      state.company.team_squad.each do |soldier|
        soldier.missions += 1 if soldier
      end
      close($core_fsm.begin_mission)
    end
  end

  # HOW TO PLAY :)
  class HelpScreen < Screen
    def on_update args
      Gui.set_next_window_size(800, 500)
      Gui.begin_window("help_screen")
      Gui.header("Quick instructions")
      Gui.label("Hire mercs, send them on missions, sell treasures to raise funds.")
      Gui.label("Retire whenever you choose to receive a final rating.")
      Gui.label("Negative Credits isn't the end, but should be avoided.")
      Gui.label("")
      Gui.label("Overview on stats:")
      Gui.label("Mercenaries have four stats: Strength, Dexterity, Endurance and Intelligence.")
      Gui.label("STR - brawn, affects melee weapons.")
      Gui.label("DEX - quickness, affects firearms and combat initiative.")
      Gui.label("END - toughness and resilience.")
      Gui.label("INT - brain power.")
      Gui.label("")
      Gui.label("The three physical stats combined form a merc's overall health pool.")
      Gui.label("Endurance is usually the first to take damage.")
      Gui.label("Losing two physical stats leads to unconsciousness.")
      Gui.label("Losing three physical stats is fatal.")
      Gui.label("")
      Gui.label("Armor reduces physical damage.")
      Gui.end_window()
    end
  end
end
