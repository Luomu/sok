# Game rules
# Trying to keep some calculations here for easier balancing
module Rules
  def Rules.calculate_drop_cost mission, company
    # mission danger level * number of soldiers
    return MISSION_DROP_COST[mission.challenge] * company.count_squad_size()
  end

  def Rules.calculate_mission_bonus adventure
    science_bonus  = adventure.stat_checkpoints_reached * 300
    security_bonus = adventure.stat_enemies_killed * 40
    return science_bonus, security_bonus
  end

  # Calculate daily expenses (salaries)
  def Rules.calculate_daily_fees company
    expenses = 0
    company.team.each do |soldier|
      expenses += soldier.salary
    end
    return expenses
  end

  def Rules.calculate_monthly_fees company
    RENT_PER_RANK = [
      1000,
      1600,
      2200,
      2800,
      3400,
      4000
    ]
    if company.level >= RENT_PER_RANK.size
      return RENT_PER_RANK.last
    else
      return RENT_PER_RANK[company.level]
    end
  end

  def Rules.calculate_sign_in_bonus soldier
    return soldier.salary
  end

  # Armor, weapon upgrade tiers
  UpgradeTiers = [
    [
      { level: 2, cost: 10000 },
      { level: 3, cost: 15000 },
      { level: 4, cost: 25000 },
    ],
    [
      { level: 2, cost: 15000 },
      { level: 3, cost: 30000 },
    ]
  ]

  # Returns the next upgrade tier for armor, or nil if at max level
  def Rules.get_next_armor_upgrade_tier company
    UpgradeTiers[0].each do |tier|
      return tier if tier.level > company.armor_level
    end
    return nil
  end

  # Returns the next upgrade tier for weapons, or nil if at max level
  def Rules.get_next_weapon_upgrade_tier company
    UpgradeTiers[1].each do |tier|
      return tier if tier.level > company.weapon_level
    end
    return nil
  end

  def Rules.get_melee_weapon_for_level level
    case level
    when 1
      return Equipment::WeaponDatabase.staticblade_1
    when 2
      return Equipment::WeaponDatabase.chainsword_2
    when 3
      return Equipment::WeaponDatabase.gravityhammer_3
    else
      return Equipment::WeaponDatabase.staticblade_1
    end
  end

  def Rules.get_ranged_weapon_for_level level
    case level
    when 1
      return Equipment::WeaponDatabase.smg_1
    when 2
      return Equipment::WeaponDatabase.ar_2
    when 3
      return Equipment::WeaponDatabase.magrail_3
    else
      return Equipment::WeaponDatabase.smg_1
    end
  end
end
