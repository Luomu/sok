# Weapons & Armor & Misc
module Equipment
  module Trait
    Melee  = 0b1000
    Ranged = 0b0100
  end

  module Traits
    def has_trait? trait
      @traits & trait != 0
    end

    def set_trait trait
      @traits = @traits | trait
    end

    def unset_trait trait
      @traits = @traits & ~trait
    end
  end

  class Weapon
    include Traits
    attr_reader   :name
    attr_reader   :damage
    attr_accessor :hit_bonus # flat attack bonus, to simulate leveling up

    def initialize name, damage_dice, hit_bonus
      super
      @name      = name
      @traits    = 0
      @damage    = damage_dice
      @hit_bonus = hit_bonus
    end
  end

  class MeleeWeapon < Weapon
    def initialize name, damage_range, hit_bonus
      super
      set_trait(Trait::Melee)
    end
  end

  class RangedWeapon < Weapon
    def initialize name, damage_range, hit_bonus
      super
      set_trait(Trait::Ranged)
    end
  end

  #Weapons are accessible as: WeaponDatabase.gravityhammer or WeaponDatabase[:gravityhammer]
  WeaponDatabase = {}
  def self.dice num, size, mod = 0
    return DamageDice.new(num, size, mod)
  end

  def self.melee_weapon name, damage_range, hit_bonus, price, armor_piercing = 0
    WeaponDatabase[name.downcase.gsub(' ', '_').to_sym] = MeleeWeapon.new(name, damage_range, hit_bonus)
  end

  def self.ranged_weapon name, damage_range, hit_bonus, price, armor_piercing = 0
    WeaponDatabase[name.downcase.gsub(' ', '_').to_sym] = RangedWeapon.new(name, damage_range, hit_bonus)
  end

  def self.setup_weapon_database
    melee_weapon("StaticBlade 1",   dice(2,6,+1), 1, 700,   5)
    melee_weapon("Chainsword 2",    dice(3,6,+2), 2, 500,   2)
    melee_weapon("GravityHammer 3", dice(4,6,+2), 3, 10000, 50)

    ranged_weapon("SMG 1",     dice(2,6,-2), 1, 400)  # auto 3
    ranged_weapon("AR 2",      dice(3,6,+1), 2, 500)  # auto 2
    ranged_weapon("MagRail 3", dice(4,6,+1), 2, 2500) # auto 6
  end

  setup_weapon_database()
end
