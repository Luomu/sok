# Combat RULES!
# Moving some of the rules/logic here for easier overview & balancing
module CombatRules
  # Returns the attack effect, taking into account
  # the weapon and appropriate skills
  # The effect can be negative, if the roll is especially poor
  def roll_attack attacker, target, attack
    if attacker.has_stats? #soldiers
      # Roll to hit (8+)
      # 2d + melee specialty + str or dex dm
      # 2d + gun specialty + dex dm
      effect = roll_2d6() - 8
      str_dm = attacker.strength.dm()
      dex_dm = attacker.dexterity.dm()
      if attack.use_weapon?
        raise "Attacker has no weapon" unless attacker.weapon
        weapon = attacker.weapon
        if weapon.has_trait?(Equipment::Trait::Ranged)
          dm = dex_dm
        else #melee - strength or dex
          dm = str_dm > dex_dm ? str_dm : dex_dm
        end
        # To simulate gaining skills, better wpns hit easier
        dm += weapon.hit_bonus
      else
        # deprecated... just pick bigger bonus
        dm = str_dm > dex_dm ? str_dm : dex_dm
      end
      dm += 1 # assume more skill for soldiers
      effect += dm
    else # Enemies
      # Roll to hit (8+)
      # No bonuses so far
      effect = roll_2d6() - 8
      effect += 1 # assume natural melee proficiency
    end

    # Check for defense
    # Give a flat -2 penalty to hit rolls
    if target.has_tag? StatusEffects::TAG_DEFENDING
      effect -= 2
    end

    $game_events.publish(:roll_attack, { roll: effect, source: attacker })

    # Effect < 0 wil be a miss
    return effect
  end

  # Returns the final damage, taking into account
  # the weapon and target's defenses
  def roll_damage effect, attack_event, target
    return 0 if effect < 0
    attacker = attack_event.instigator
    attack   = attack_event.payload

    # Soldiers are equipped with weapons
    if attack.use_weapon?
      raise "Attacker has no weapon" unless attacker.weapon
      weapon = attacker.weapon
      dmg    = roll_dice(weapon.damage.num_dice, weapon.damage.dice_size, weapon.damage.modifier)

      # melee: add strength bonus
      if weapon.has_trait?(Equipment::Trait::Melee)
        dmg += attacker.strength.dm
      end
    else
      # Non-armed (enemies): Roll the attack's inherent values
      dmg = roll_dice(attack.damage.num_dice, attack.damage.dice_size, attack.damage.modifier)
    end

    dmg += effect

    # Armour: reduces damage by its protection score
    # To do: AP ignores protection value by the AP score
    # To do: kinetic/laser etc resistance?
    dmg -= target.armor.current

    # No negative dmg
    dmg = dmg.greater(0)

    # always at least 1 damage if effect 6+
    if effect >= 6
      dmg = dmg.greater(1)
    end

    $game_events.publish(:roll_damage, { roll: dmg, source: attacker })

    return dmg
  end
end
