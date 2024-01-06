# "3D6 + 2"
DamageDice = Struct.new(:num_dice, :dice_size, :modifier)

def roll_d6
  return rand(6) + 1
end

def roll_2d6
  return roll_d6 + roll_d6
end

def roll_d3
  return rand(3) + 1
end

def roll_d6_times(t)
  total = 0
  t.times do
    total += roll_d6
  end
  return total
end

# Roll n-sided die t times, adding mod to the total
def roll_dice(t, n, mod = 0)
  total = mod
  t.times { total += rand(n) + 1 }
  return total
end

def rand_between(min, max)
  return rand(max - min + 1) + min
end

# small testing func - example: tally_helper { roll_d6 + 3 }
def tally_helper
  raise "No block passed to tally_helper" unless block_given?
  garr = []
  100000.times { garr << yield }
  garr.sort.tally
end

def average_helper
  raise "No block passed to average_helper" unless block_given?
  garr = []
  100000.times { garr << yield }
  garr.average
end

DM_TABLE = [
  -3,         #0
  -2, -2,     #1,2
  -1, -1, -1, #3, 4, 5
  0, 0, 0,    #6, 7, 8
  1, 1, 1,    #9, 10, 11
  2, 2, 2,    #12, 13, 14
  3           #15
]
