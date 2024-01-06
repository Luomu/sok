# Status effects: holds list of active effects,
# and a list of gameplay tags. Tags are used to quickly
# check for statuses and there can be multiple instances of a tag
module CharacterStatuses
  attr_accessor :status_tags
  attr_accessor :status_effects

  def initialize(*args)
    super
    @status_tags    = []
    @status_effects = []
  end

  def has_tag? tag
    @status_tags.include?(tag)
  end

  def count_tags tag
    @status_tags.count(tag)
  end

  # Add one instance of tag
  def add_tag tag
    @status_tags << tag
  end

  def add_tag_unique tag
    add_tag(tag) unless has_tag?(tag)
  end

  # Remove one instance of tag
  def remove_tag tag
    idx = @status_tags.find_index(tag)
    @status_tags.delete_at(idx) if idx
  end

  # Remove all instances of tag
  def remove_tags tag
    @status_tags.delete(tag)
  end

  # Remove all status effects + their applied tags
  def remove_status_effects
    # Removes tags
    @status_effects.each { |e| e.remove() }
    # Deletes effect
    @status_effects.delete_if {|e| e.expired? }
  end
end

module CharacterEquipment
  def initialize(*args)
    super
    #@weapon = set during missions
    @armor  = Character::Attribute.new(1)
  end

  attr_accessor :weapon # equipped weapon (during missions)
  attr_accessor :armor  # just a number for now
end

# The titular Soldier
class Character
  include CharacterStatuses
  include CharacterEquipment

  # V1: For flavour, picked at random
  BACKGROUNDS = [
    "Admin",
    "Advisor",
    "Agent",
    "Assassin",
    "Athlete",
    "Black ops",
    "Bodyguard",
    "Cavalry",
    "Colonist",
    "Convict",
    "Corporate",
    "Cyberwarrior",
    "Demolitionist",
    "Diplomat",
    "Duelist",
    "Enforcer",
    "Engineer",
    "Entertainer",
    "Explorer",
    "Farmer",
    "Infantry",
    "Investigator",
    "Marine",
    "Mech Infantry",
    "Mechanic",
    "Merchant",
    "Navy",
    "Nomad",
    "Pilot",
    "Pirate",
    "Police",
    "Programmer",
    "Ranger",
    "Reclaimer",
    "Recon",
    "Sapper",
    "Scavenger",
    "Scientist",
    "Shock Troop",
    "Spec ops",
    "Surveyor",
    "Wanderer",
    "Worker",
    "Xeno Hunter",
  ]

  class Attribute
    attr_accessor :current
    attr_accessor :max

    def initialize value
      @max     = value
      @current = value
    end

    # Initialize an attrib from save data
    def self.from_hash hash
      attrib         = new(0)
      attrib.current = hash.fetch(:current)
      attrib.max     = hash.fetch(:max)
      return attrib
    end

    def serialize
      {
        current: @current,
        max: @max
      }
    end

    def inspect
      serialize.to_s
    end

    def to_s
      serialize.to_s
    end

    def to_upp_s
      return @max.to_s(16).upcase
    end

    def dm
      return DM_TABLE[@current]
    end

    def damaged?
      return @current < @max
    end

    # Takes the damage if possible, and returns the remaining amount
    def take_damage amount
      before = @current
      @current -= amount
      if @current >= 0
        return 0
      else
        @current = 0
        return -(before - amount)
      end
    end

    # Utility function used in healing - reduces amount
    # and returns new amount
    def heal_one_if_damaged amount
      if amount > 0 and damaged?
        @current += 1
        return amount - 1
      else
        return amount
      end
    end

    def heal_all
      @current = @max
    end
  end

  # Skills table
  class Skills
    #athletics, electronics, engineer, explosives
    #guns/archaic, guns/energy, guns/slug
    #heavy
    #investigate
    #jack-of-all-trades (versatile)
    #leadership
    #mechanic
    #medic
    #melee
    #navigation
    #recon
    #science
    #stealth
    #survival
    #tactics
    #vacc suit
  end

  attr_accessor :firstname # or shortname
  attr_accessor :lastname
  attr_accessor :random_seed

  # Visuals & flavor
  attr_accessor :background
  attr_accessor :portrait_category
  attr_accessor :portrait_id
  attr_accessor :color

  # Career
  # :morale
  attr_accessor :salary   # credits per turn
  attr_accessor :missions # drops with this company
  attr_accessor :assignment
  attr_accessor :assignment_index

  # Stats
  # skill level cap is int+edu
  attr_accessor :strength
  attr_accessor :dexterity
  attr_accessor :endurance
  attr_accessor :intellect
  attr_accessor :education
  attr_accessor :social

  # Transient data
  # Sprite during combat
  attr_accessor :combat_graphic

  def from_hash hash
    # Fetch has the advantage of raising KeyError
    @firstname        = hash.fetch(:firstname)
    @lastname         = hash.fetch(:lastname)
    @salary           = hash.fetch(:salary)
    @random_seed      = hash.fetch(:seed)
    @assignment       = hash.fetch(:assignment)
    @assignment_index = hash.fetch(:assignment_index)
    @missions         = hash.fetch(:missions)

    @strength  = Attribute::from_hash(hash.fetch(:str))
    @dexterity = Attribute::from_hash(hash.fetch(:dex))
    @endurance = Attribute::from_hash(hash.fetch(:end))
    @intellect = Attribute::from_hash(hash.fetch(:int))
    @education = Attribute::from_hash(hash.fetch(:edu))
    @social    = Attribute::from_hash(hash.fetch(:soc))

    raise "Hell" unless @status_tags

    # Regen from seed
    generate_visuals(@random_seed)
  end

  # Only the non-procedural data needs to be serialized (name for readability in data)
  def serialize
    {
      firstname:        @firstname,
      lastname:         @lastname,
      seed:             @random_seed,
      salary:           @salary,
      assignment:       @assignment,
      assignment_index: @assignment_index,

      str: @strength,
      dex: @dexterity,
      end: @endurance,
      int: @intellect,
      edu: @education,
      soc: @social,

      missions:   @missions
    }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end

  # has STR, DEX etc. (Creatures don't)
  def has_stats?
    return true
  end

  def name
    return @firstname
  end

  def fullname
    return "#{@firstname} #{@lastname}"
  end

  def upp
    return strength.to_upp_s + dexterity.to_upp_s + endurance.to_upp_s + intellect.to_upp_s + education.to_upp_s + social.to_upp_s
  end

  def hits_current
    return @strength.current + @dexterity.current + @endurance.current
  end

  def hits_max
    return @strength.max + @dexterity.max + @endurance.max
  end

  def injured?
    return strength.damaged? || @dexterity.damaged? || @endurance.damaged?
  end

  def healthy?
    return !injured?
  end

  def alive?
    return hits_current > 0
  end

  # Could also be dead
  def should_fall_unconscious?
    return @endurance.current == 0 && (@strength.current == 0 || @dexterity.current == 0)
  end

  def unconscious?
    #todo replace with a status tag
    return @endurance.current == 0 && (@strength.current == 0 || @dexterity.current == 0)
  end

  def distribute_healing healing
    #distribute healing
    while healing > 0
      healing = @strength.heal_one_if_damaged(healing)
      healing = @dexterity.heal_one_if_damaged(healing)
      healing = @endurance.heal_one_if_damaged(healing)

      if healthy?
        healing = 0
      end
    end
  end

  def heal_amount healing
    distribute_healing(healing)
  end

  # Heal while in hospital (note no doctors yet)
  def heal_daily
    # natural healing: 1d + END DM per day
    healing = roll_d6 + @endurance.dm()
    # medical care: 3 + END DM + doctor's medic skill per day
    healing += 3 + @endurance.dm()

    distribute_healing(healing)
  end

  def heal_all
    @strength.heal_all()
    @dexterity.heal_all()
    @endurance.heal_all()
  end

  # Distribute damage to END first then STR or INT
  def take_damage amount
    amount = @endurance.take_damage(amount)
    if @strength.current > @dexterity.current
      amount = @strength.take_damage(amount)
      amount = @dexterity.take_damage(amount)
    else
      amount = @dexterity.take_damage(amount)
      amount = @strength.take_damage(amount)
    end
  end

  def roll_initiative
    if @dexterity.max > @intellect.max
      roll_2d6() + @dexterity.dm()
    else
      roll_2d6() + @intellect.dm()
    end
  end

  # Create a new soldier
  def Character.generate
    char = Character.new
    char.random_seed = rand(100000)
    srand(char.random_seed)
    gender = [GENDER_UNIVERSAL, GENDER_FEMININE, GENDER_MASCULINE].random_element()

    char.firstname, char.lastname = Names::Human.generate(gender)
    char.assignment       = ASSIGNMENT_NONE
    char.assignment_index = 0

    # Might evolve
    char.salary = [230, 260, 300].random_element() #should correlate with stats...

    # Generated, but may change during gameplay
    char.strength  = Attribute.new(roll_2d6)
    char.dexterity = Attribute.new(roll_2d6)
    char.endurance = Attribute.new(roll_2d6)
    char.intellect = Attribute.new(roll_2d6)
    char.education = Attribute.new(roll_2d6)
    char.social    = Attribute.new(roll_2d6)

    char.armor     = Attribute.new(STARTING_ARMOR_LEVEL)
    char.weapon    = nil
    char.missions  = 0

    char.generate_visuals(char.random_seed)

    return char
  end

  # Can be regen'd from seed
  def generate_visuals seed
    srand(seed)
    gender = [GENDER_UNIVERSAL, GENDER_FEMININE, GENDER_MASCULINE].random_element()
    @portrait_category = Portrait.get_sheet_for_gender(gender)
    @portrait_id       = rand(Portrait.get_num_portraits_for_gender(gender))
    @color             = GOOD_SOLDIER_COLORS.random_element()
    @background        = BACKGROUNDS.random_element()
  end
end

# Simpler than player weapons
class CreatureAttack
  attr_reader :name
  attr_reader :traits
  attr_reader :damage #DamageDice struct (count,size,mod)

  def use_weapon?
    false
  end

  def initialize params
    @name   = params.fetch(:name, "Bite")
    @traits = params.fetch(:traits, [])
    @damage = params.fetch(:damage, DamageDice.new(1,3,0))
  end
end

# Animal, robot, other simplified threat
class Creature
  include CharacterStatuses

  attr_reader   :name
  attr_reader   :sprite
  attr_accessor :hits
  attr_accessor :skills
  attr_accessor :attacks
  attr_reader   :sprite_width
  attr_reader   :sprite_height
  attr_accessor :combat_graphic
  attr_accessor :armor

  def initialize name, sprite, sprite_width = 64, sprite_height = 64
    @name = name
    @name.freeze()
    @sprite = sprite
    @sprite.freeze()
    @sprite_width  = sprite_width
    @sprite_height = sprite_height
    @attacks = [ CreatureAttack.new({}) ]
    @combat_graphic = nil
    @armor = Character::Attribute.new(0)
    super
  end

  # Creatures don't have STR, DEX, etc, only Hits
  def has_stats?
    return false
  end

  def hits_current
    return @hits.current
  end

  def hits_max
    return @hits.max
  end

  def alive?
    return hits_current() > 0
  end

  # Only death
  def should_fall_unconscious?
    return false
  end

  # Impossible
  def unconscious?
    return false
  end

  def take_damage amount
    @hits.current -= amount
    @hits.current = 0 if @hits.current < 0
  end

  def roll_initiative
    return roll_2d6()
  end
end
