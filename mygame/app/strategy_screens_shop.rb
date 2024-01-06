module Strategy
  # Buy equipment
  class ShopScreen < Screen
    def initialize
      super
      update_model()
      Strategy.eventbus.publish(Events::ENTER_SHOP)
    end

    def update_model
      @next_armor_tier  = Rules.get_next_armor_upgrade_tier($state.company)
      @next_weapon_tier = Rules.get_next_weapon_upgrade_tier($state.company)
    end

    def on_update args
      Gui.set_next_window_size(512, 320)
      Gui.begin_window("shop_window")
      Gui.header("Shop shop shop")
      Gui.label("Individual equipment not implemented yet.")
      Gui.label("Spend credits to unlock overall upgrades instead.")
      Gui.label("")
      Gui.set_columns(2)
      Gui.begin_column(300)
      if @next_armor_tier
        Gui.menu_option_call("Upgrade Armor", -> { check_upgrade(:armor, @next_armor_tier) })
      else
        Gui.label("Armor maxed")
      end
      if @next_weapon_tier
        Gui.menu_option_call("Upgrade Weapons", -> { check_upgrade(:weapons, @next_weapon_tier) })
      else
        Gui.label("Weapons maxed")
      end
      Gui.end_column()
      Gui.begin_column()
      if @next_armor_tier
        Gui.label("Lvl #{@next_armor_tier.level}, #{@next_armor_tier.cost} Cr")
      else
        Gui.label("MAX")
      end
      if @next_weapon_tier
        Gui.label("Lvl #{@next_weapon_tier.level}, #{@next_weapon_tier.cost} Cr")
      else
        Gui.label("MAX")
      end
      Gui.end_column()
      Gui.end_window()
    end

    def on_cancel args
      Strategy.eventbus.publish(Events::EXIT_SHOP)
      Sound.menu_cancel()
      close()
    end

    def check_upgrade category, tier_data
      company = $state.company
      if company.money <= 0
        ScreenManager.open(MessageScreen.new("You don't have the funds!"))
      else
        msg = sprintf("Spend %d Cr to upgrade %s to Lvl %d?",
          tier_data.cost,
          category == :armor ? "Armor" : "Weapons",
          tier_data.level
        )
        ScreenManager.open(ConfirmationDialog.new(msg))
          .set_on_yes(-> { really_buy_upgrade(category, tier_data, company) })
      end
    end

    def really_buy_upgrade category, tier_data, company
      company.spend_money(tier_data.cost)
      Sound.buy()
      if category == :armor
        company.armor_level = tier_data.level
        Strategy.eventbus.publish(Events::MESSAGE, "Armor has been upgraded to level #{tier_data.level}")
      elsif category == :weapons
        company.weapon_level = tier_data.level
        Strategy.eventbus.publish(Events::MESSAGE, "Weapons have been upgraded to level #{tier_data.level}")
      end
      update_model() #refresh screen
    end
  end
end
