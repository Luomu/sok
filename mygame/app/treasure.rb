# 1. Premade treasures
# 2. Infinitely generated treasures
module Treasures
  # A treasure. May be fixed or generated.
  class Treasure
    attr_reader :name
    attr_reader :description
    attr_reader :rarity
    attr_reader :value
    #attr_reader :type

    RARITY_TO_VALUE = [
      200,
      2000,
      4000,
      6000,
      8000,
      10000
    ]
    def Treasure.calculate_value rarity
      return RARITY_TO_VALUE[rarity.clamp(0,5)]
    end

    def initialize name, rarity, description
      @name  = name
      @description = description
      @rarity = rarity.clamp(0,5)
      @value  = Treasure.calculate_value(rarity)
    end

    def calculate_sale_price
      price = value / 2
      # round down to 50
      return (price - price % 50).floor
    end

    def Treasure.from_hash hash
      return Treasures::Treasure.new(hash.fetch(:name), hash.fetch(:rarity), hash.fetch(:descr))
    end

    def serialize
      {
        name:   @name,
        descr:  @description,
        rarity: @rarity,
        value:  @value
      }
    end

    def inspect
      serialize.to_s
    end

    def to_s
      serialize.to_s
    end
  end

  # Rarity, name, description
  Named = [
    [1, "Ectoplasm", "Ghostly residue, it shivers and twitches"],
    [1, "Garf Crystal", "Valuable to collectors of obscure crystals"],
    [1, "Racobal", "It stinks real bad, but is still valuable"],
    [1, "Spinel", "A fairly valuable purple spinel"],
    [1, "Twisted Coil", "Tangled alien metal, has industrial value"],
    [2, "Alien Statue", "Represents an alien god... or a celebrity?"],
    [2, "Ceremonial Blade", "Ancient decorative weapon, not suitable for human hands"],
    [2, "Dormant Egg", "Ancient ovoid, dormant but faintly humming"],
    [2, "Jam Eye", "Directly under the lid"],
    [2, "X-Plasma Battery", "Old energy cell, still active. Cannot be built by human technology"],
    [3, "Binted Bogos", "A set of bogos, tastefully binted"],
    [3, "DATA DISK", "An old DATA DISK, remnant of the original scientific expedition"],
    [3, "Kinf Cube", "Has considerable military applications, if only we could understand it"],
    [3, "Timeless Bauble", "Not of this world, phasing in and out of existence"],
  ]

  def Treasures.get_random_named
    params = Named.random_element()
    return Treasure.new(params[1], params[0], params[2])
  end
end
