# Test code for visualizing dice roll results
class GameState_DiceTest < FsmState
  def on_enter args
    @log = Array.new(12, 0)
    @max = 100
    @hits   = 0
    @misses = 0
    @target = 8

    srand()
  end

  def roll_die
    # Roll dice
    roll = roll_2d6()
    idx  = roll - 1
    @log[idx] += 1
    if @log[idx] > @max
      @max = @log[idx]
    end
    if roll >= @target
      @hits += 1
    else
      @misses += 1
    end
  end

  def on_update args
    total = @hits + @misses
    if total < 1e6
      1000.times { roll_die() }
    end

    # Draw graph
    Rendering.set_color COLOR_WHITE
    x = 20
    @log.each_with_index do |e,i|
      x += 40
      height = e / @max * 400
      args.outputs.solids << [x, 100, 30, height, 170, 128, 60]
      Rendering.text_left x, 100, i+1
    end

    Rendering.set_color COLOR_WHITE
    12.times do |i|
      count = @log[i]
      Rendering.text_left 40, 40.from_top - i * 30, "#{i+1}: #{count}"
    end

    if total > 1
      hitrate = (@hits/total).round(3)
      Rendering.text_left(400, 100.from_top, "Hit rate #{hitrate}, total rolls #{total}")
    end
  end
end
