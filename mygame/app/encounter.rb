# Enemy party
# Default sprite size is: 64x64
module Encounter
  def self.dice num, size, mod = 0
    return DamageDice.new(num, size, mod)
  end

  def Encounter.make_foe foe_list, foe_rank
    data = foe_list.select{ |x| x.rank == foe_rank }.random_element()

    sprite_path   = "sprites/enemies/" + data.image
    sprite_width  = data.w ? data.w : 64
    sprite_height = data.h ? data.h : 64
    hits = data.hits ? data.hits : 30
    hits = 1 if Cheats::WEAK_FOES

    foe_one         = Creature.new(data.name, sprite_path, sprite_width, sprite_height)
    foe_one.hits    = Character::Attribute.new(hits)
    foe_one.attacks = [
      CreatureAttack.new(name: "Poke", damage: data.ddie)
    ]
    return foe_one
  end

  #Enemy data
  Foes = [
    { rank: 1, name: 'Alien Android', image: 'robot03.png',  hits: 8,  ddie: dice(1,3),    w: 48 },
    { rank: 1, name: 'Bad Robot',     image: 'robot01.png',  hits: 12, ddie: dice(1,3),    w: 48 },
    { rank: 1, name: 'Competitor',    image: 'human01.png',  hits: 15, ddie: dice(1,3,+1), w: 64 },
    { rank: 1, name: 'Lanky Alien',   image: 'alien01.png',  hits: 12, ddie: dice(1,3),    w: 48 },
    { rank: 1, name: 'Plantasm',      image: 'mutant02.png', hits: 18, ddie: dice(1,3),          },
    { rank: 1, name: 'Tombot',        image: 'robot02.png',  hits: 20, ddie: dice(1,3),    w: 64 },
    { rank: 2, name: 'Alien Horror',  image: 'alien03.png',  hits: 20, ddie: dice(2,3),    w: 48 },
    { rank: 2, name: 'Buff Ursoid',   image: 'mutant01.png', hits: 28, ddie: dice(2,3,+1),       },
    { rank: 2, name: 'Cacodemon',     image: 'demon02.png',  hits: 22, ddie: dice(2,3),    w: 64 },
    { rank: 2, name: 'Lemon Demon',   image: 'demon01.png',  hits: 25, ddie: dice(2,3),    w: 64 },
    { rank: 2, name: 'Morbin',        image: 'alien02.png',  hits: 24, ddie: dice(2,3),    w: 64 },
    { rank: 2, name: 'Warrior',       image: 'alien04.png',  hits: 30, ddie: dice(2,3),    w: 64 },
    { rank: 3, name: 'Bearhemoth',    image: 'mutant03.png', hits: 44, ddie: dice(3,3,+1), w: 64 },
    { rank: 3, name: 'Melty Horror',  image: 'demon03.png',  hits: 50, ddie: dice(3,3),    w: 48 },
  ]

  # Validate once
  Foes.each do |data|
    Debug.assert(data.rank, "Foe #{data.name} does not define rank")
    Debug.assert(data.hits, "Foe #{data.name} does not define hitpoints")
    Debug.assert(data.ddie, "Foe #{data.name} does not define damage dice")
  end

  # Challenge level 1, 2, 3
  # c = enemy composition
  # t = number of times the item appears in selection
  EnemyParties = [
    {
      challenge: 0, #dummy
      parties: [
        { c: [3,3,3,3], t: 1 }
      ]
    },
    {
      challenge: 1,
      parties: [
        { c: [1,1],   t: 6 },
        { c: [1,1,1], t: 3 },
        { c: [2],     t: 1 },
      ]
    },
    {
      challenge: 2,
      parties: [
        { c: [1,2],   t: 2 },
        { c: [2,2],   t: 6 },
        { c: [2,2,2], t: 4 },
        { c: [1,3],   t: 1 },
      ]
    },
    {
      challenge: 2,
      parties: [
        { c: [2,2,2], t: 6 },
        { c: [2,3],   t: 4 },
        { c: [3,3],   t: 1 },
        { c: [3,3,3], t: 1 },
        { c: [1,3,1], t: 1 }
      ]
    },
  ]

  def Encounter.build challenge
    challenge   = challenge.greater(0).lesser(3)
    source_deck = EnemyParties[challenge].parties
    deck        = []
    source_deck.each do |party|
      party.t.times do
        deck << party.c
      end
    end

    party = deck.random_element()
    # Effectively: [make_foe(Foes, lvl), make_foe(Foes, lvl), make_foe(Foes, lvl)]
    return party.map { |enemy_lvl| make_foe(Foes, enemy_lvl) }
  end

  # Randomize the adventure contents
  # Varying number of combat encounters and occasional events
  # before reaching a checkpoint
  def Encounter.build_encounter_list mission
    raise "Mission challenge wrong" if mission.challenge < 1 or mission.challenge > 3
    # Number of possible sections (checkpoints) per mission challenge level:
    # Mission length increases with rank
    MissionLength = [
      [1,1,1],       # dummy
      [3,3,3,4],     # lvl 1
      [3,3,4,4,5],   # lvl 2
      [4,4,4,5,5,6]  # lvl 3
    ]

    # Number of encounters per section
    SectionLength = [
      [2,2,2],         # dummy
      [3,3,3,3,4],     # lvl 1
      [3,3,3,4,4,4,5], # lvl 2
      [3,4,4,4,4,5,5]  # lvl 3
    ]

    encounters   = []
    num_sections = MissionLength[mission.challenge].random_element()
    num_sections.times do
      encounter_deck = [
        Adventure::ENCOUNTER_COMBAT,
        Adventure::ENCOUNTER_COMBAT,
        Adventure::ENCOUNTER_COMBAT,
        Adventure::ENCOUNTER_COMBAT,
        Adventure::ENCOUNTER_EVENT
      ]
      # N encounters before a checkpoint
      num_encounters = SectionLength[mission.challenge].random_element()
      num_encounters.times do
        encounters << encounter_deck.draw_random_element!
      end

      #checkpoint
      encounters << Adventure::ENCOUNTER_REST
    end

    # Replace the last rest with an end
    encounters[-1] = Adventure::ENCOUNTER_END
    return encounters
  end
end
