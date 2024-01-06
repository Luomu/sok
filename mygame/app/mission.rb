# Current mission, accessible from args.state.mission
class Mission
  attr_accessor :name
  attr_accessor :challenge #1-5
  attr_reader   :random_seed

  def initialize seed
    @random_seed = seed
    srand(@random_seed)
    @name      = Names::Mission.generate()
    @challenge = [1,2,3].random_element() #should feed into compensation
  end

  def Mission.generate
    return Mission.new(rand(100000))
  end

  def serialize
    {
      name: @name,
      lvl:  @challenge,
      seed: @random_seed
    }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end

# May be use in the BBS display
#class MissionDefinition
#  name
#  difficulty
#  reward
#end
