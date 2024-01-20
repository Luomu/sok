# Company state
# accessible from args.state.company
class Company
  #attr_accessor :name
  attr_accessor :level          # determines rent
  attr_accessor :reputation     # company 'XP', hidden stat
  attr_accessor :turn           # game turns (days)
  attr_accessor :money          # could be negative (debt) at start
  attr_accessor :num_operations # how many combat drops
  attr_accessor :treasures      # loot vault
  attr_accessor :team           # all soldiers
  attr_accessor :team_squad     # soldiers assigned to squad (4, can have nil slots)
  attr_accessor :team_reserve   # soldiers in reserve pool
  attr_accessor :team_hospital  # soldiers being treated in hospital
  attr_accessor :daily_fees     # salaries mostly
  attr_accessor :monthly_fees   # rent
  attr_accessor :monthly_fees_due_days # countdown to rent payment
  attr_accessor :armor_level    # persistent upgrades
  attr_accessor :weapon_level   # persistent upgrades

  def initialize
    @level = 1
    @reputation = 0
    @turn  = 0
    @money = Cheats::ULTRA_RICH ? 1000*1000 : STARTING_MONEY
    @num_operations = 0
    @treasures      = []
    @daily_fees     = 0
    @monthly_fees   = 0
    @monthly_fees_due_days = RENT_PERIOD_DAYS
    @armor_level  = STARTING_ARMOR_LEVEL
    @weapon_level = STARTING_WEAPON_LEVEL

    # Empty by default
    @team          = []
    @team_squad    = [nil, nil, nil, nil]
    @team_reserve  = []
    @team_hospital = []
  end

  def rank
    return @level
  end

  def rank= rank
    @level = rank
  end

  def setup_initial_team!
    @team = generate_team()
    @team_reserve  = []
    @team_hospital = []
    @team_squad    = [nil, nil, nil, nil]
    @team.each_with_index do |member, idx|
      assign_soldier_to_squad(member, idx)
    end
  end

  def from_hash hash
    @level          = hash.level
    @reputation     = hash.reputation
    @turn           = hash.turn
    @money          = hash.money
    @num_operations = hash.num_operations
    @monthly_fees_due_days = hash.monthly_fees_due_days
    @armor_level    = hash.armor_level
    @weapon_level   = hash.weapon_level

    @treasures = []
    hash.treasures.each do |t|
      treasures << Treasures::Treasure.from_hash(t)
    end

    @team = []
    hash.team.each do |t|
      soldier = Character.new
      soldier.from_hash(t)
      @team << soldier
      case soldier.assignment
      when ASSIGNMENT_RESERVE
        assign_soldier_to_reserve(soldier)
      when ASSIGNMENT_HOSPITAL
        assign_soldier_to_hospital(soldier)
      when ASSIGNMENT_SQUAD
        assign_soldier_to_squad(soldier, soldier.assignment_index)
      end
    end

    # Can be calculated from team
    @daily_fees   = Rules.calculate_daily_fees(self)
    @monthly_fees = Rules.calculate_monthly_fees(self)
  end

  def Company.deserialize hash
    company = Company.new
    company.from_hash(hash)
    return company
  end

  def serialize
    {
      class:          self.class.name,
      level:          @level,
      reputation:     @reputation,
      turn:           @turn,
      money:          @money,
      team:           @team,
      num_operations: @num_operations,
      treasures:      @treasures,
      monthly_fees_due_days: @monthly_fees_due_days,
      armor_level:    @armor_level,
      weapon_level:   @weapon_level
    }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end

  def gain_money sum
    @money += sum
    Strategy.eventbus.publish(Events::GAIN_MONEY, sum)
  end

  def spend_money sum
    @money -= sum
    Strategy.eventbus.publish(Events::SPEND_MONEY, sum)
  end

  def gain_reputation amount
    rep_before = @reputation
    @reputation = (@reputation + amount).clamp(0, MAX_REPUTATION)
    if @reputation != rep_before
      Strategy.eventbus.publish(Events::GAIN_REPUTATION, amount)
    end
  end

  def lose_reputation amount
    rep_before = @reputation
    @reputation = (@reputation - amount).clamp(0, MAX_REPUTATION)
    if @reputation != rep_before
      Strategy.eventbus.publish(Events::LOSE_REPUTATION, amount)
    end
  end

  def squad_empty?
    return @team_squad[0] == nil &&
      @team_squad[1] == nil &&
      @team_squad[2] == nil &&
      @team_squad[3] == nil
  end

  def count_squad_size
    return 4 - @team_squad.count(nil)
  end

  def get_first_empty_squad_slot
    return 0 if @team_squad[0] == nil
    return 1 if @team_squad[1] == nil
    return 2 if @team_squad[2] == nil
    return 3 if @team_squad[3] == nil
    return -1
  end

  # Generate an initial team... mostly for testing
  # Should reject duplicate names
  def generate_team
    soldiers = []
    4.times do
      soldiers << Character.generate()
    end
    return soldiers
  end

  def hire_soldier soldier
    $state.available_soldiers.delete(soldier)
    @team << soldier
    # For convenience, put new hires into the squad
    squad_slot = get_first_empty_squad_slot()
    if squad_slot == -1
      assign_soldier_to_reserve(soldier)
    else
      assign_soldier_to_squad(soldier, squad_slot)
    end
    spend_money(Rules.calculate_sign_in_bonus(soldier))
    @daily_fees = Rules.calculate_daily_fees(self)
  end

  def fire_soldier soldier
    unassign_soldier(soldier)
    @team.delete(soldier)
    @daily_fees = Rules.calculate_daily_fees(self)
  end

  def kill_soldier soldier
    unassign_soldier(soldier)
    @team.delete(soldier)
    @daily_fees = Rules.calculate_daily_fees(self)
  end

  def assign_soldier_to_reserve soldier
    unassign_soldier(soldier)
    soldier.assignment = ASSIGNMENT_RESERVE
    @team_reserve << soldier
  end

  def assign_soldier_to_hospital soldier
    unassign_soldier(soldier)
    soldier.assignment = ASSIGNMENT_HOSPITAL
    @team_hospital << soldier
  end

  def assign_soldier_to_squad soldier, slot_number
    raise "No soldier to assign" unless soldier
    prev_assignment = soldier.assignment
    prev_index      = soldier.assignment_index
    unassign_soldier(soldier)
    raise "Slot index must be 0-3" if slot_number < 0 or slot_number > 3
    slot_index = slot_number

    # Move current squad slot occupant to reserve
    old_soldier = @team_squad[slot_index]
    if old_soldier
      assign_soldier_to_reserve(old_soldier)
    end

    soldier.assignment       = ASSIGNMENT_SQUAD
    soldier.assignment_index = slot_index
    @team_squad[slot_index]  = soldier

    # If both soldiers were in squad, swap places for convenience
    if old_soldier and prev_assignment == ASSIGNMENT_SQUAD
      assign_soldier_to_squad(old_soldier, prev_index)
    end
  end

  # Clear a current assignment (for internal use)
  def unassign_soldier soldier
    # Remove from previous
    case soldier.assignment
    when ASSIGNMENT_RESERVE
      @team_reserve.delete(soldier)
    when ASSIGNMENT_SQUAD
      slot = soldier.assignment_index
      @team_squad[slot] = nil #not deleting to keep the empty slots
    when ASSIGNMENT_HOSPITAL
      @team_hospital.delete(soldier)
    end
    soldier.assignment = ASSIGNMENT_NONE
  end

  def get_favorite_soldier
    return nil if team.empty?
    # Determine highest drop count
    max_missions = team.max_by {|soldier| soldier.missions }.missions

    # Get everyone with that count
    favorites = team.select {|soldier| soldier.missions == max_missions }
    return favorites.random_element()
  end
end
