# Weekly evaluation
# Tracks stats for the period
module Strategy
  # saved in args.state.weekly_data
  def self.init_weekly_stats
    {
      current_week:      1,
      days_until_eval:   7,
      money_spent:       0,
      money_gained:      0,
      reputation_gained: 0,
      reputation_lost:   0,
      income_history:    [], # tracks 30 days of daily income
      expense_history:   [], # tracks 30 days of daily spend
    }
  end

  def self.reset_weekly_stats stats
    stats.merge!({
      days_until_eval:   7,
      money_spent:       0,
      money_gained:      0,
      reputation_gained: 0,
      reputation_lost:   0
    })
  end

  class CompanyStatsTracker
    # money spend/gain
    # new hires
    # count down days
    def initialize
      Strategy.eventbus.subscribe(Events::TURN_ENDED,      method(:on_end_turn))
      Strategy.eventbus.subscribe(Events::SPEND_MONEY,     method(:on_spend_money))
      Strategy.eventbus.subscribe(Events::GAIN_MONEY,      method(:on_gain_money))
      Strategy.eventbus.subscribe(Events::GAIN_REPUTATION, method(:on_gain_rep))
      Strategy.eventbus.subscribe(Events::LOSE_REPUTATION, method(:on_lose_rep))
    end

    def stats
      return $gtk.args.state.weekly_data
    end

    def on_end_turn payload
      stats.days_until_eval -= 1
    end

    def on_spend_money amount
      stats.money_spent += amount
    end

    def on_gain_money amount
      stats.money_gained += amount
    end

    def on_gain_rep amount
      stats.reputation_gained += amount
    end

    def on_lose_rep amount
      stats.reputation_lost += amount
    end

    # End of Week Eval
    def trigger_evaluation
      # We know this is called at the end of a day,
      # Add daily inc/exp to 30 days data
      stats.income_history  << stats.money_gained
      stats.expense_history << stats.money_spent
      stats.income_history.shift  while stats.income_history.length  > 30
      stats.expense_history.shift while stats.expense_history.length > 30
      stats.money_gained = stats.money_spent = 0

      return unless stats.days_until_eval <= 0
      stats.days_until_eval = 7
      ScreenManager.open(WeeklyEvaluationScreen.new(stats))

      # Reset stats
      Strategy::reset_weekly_stats(stats)
      stats.current_week += 1
    end
  end # class CompanyStatsTracker

  # Show:
  # Finances (profit/loss)
  # Missions performed
  # Rank gain and loss
  class WeeklyEvaluationScreen < Screen
    def initialize stats
      super()
      # Sum the last 7 days to get the weekly spend/gain
      weekly_spend = 0
      weekly_gain  = 0
      if stats.income_history.length > 6
        weekly_spend = stats.expense_history[-7..-1].sum
        weekly_gain  = stats.income_history[-7..-1].sum
      end
      @model = {
        week:        stats.current_week,
        money_gain:  weekly_gain,
        money_spend: weekly_spend,
        profit:      stats.money_gained - stats.money_spent,
      }

      # Build 2 graphs: income and expenses for the last 30 days
      raise "Financial history data mismatch" unless stats.income_history.length == stats.expense_history.length
      max_value = stats.income_history.max.greater(stats.expense_history.max)
      @model.graph_data = { income: [], expense: [], scaled: false }
      num_pts = stats.income_history.length
      xscale  = 1.0 / (num_pts-1)
      if num_pts > 1
        (1..num_pts-1).each { |idx|
          # Income graph
          x1  = (idx-1) * xscale
          x2  = idx     * xscale
          pt1 = stats.income_history[idx-1]
          pt2 = stats.income_history[idx]
          @model.graph_data.income << {
            x:  x1,
            y:  pt1.fdiv(max_value),
            x2: x2,
            y2: pt2.fdiv(max_value),
            g:  255
          }

          # Expense graph (same number of pts/x coords as income)
          pt1 = stats.expense_history[idx-1]
          pt2 = stats.expense_history[idx]
          @model.graph_data.expense << {
            x:  x1,
            y:  pt1.fdiv(max_value),
            x2: x2,
            y2: pt2.fdiv(max_value),
            r:  255
          }
        }
      end

    end

    def draw_graph args, x, y, w, h, data = nil
      return if !data.expense or !data.income
      # Offset & scale the data once, now that we know x/y/w/h
      if !data.scaled
        xscale = w - 3
        yscale = h - 3
        xoffs  = x + 1
        yoffs  = y + 2
        data.scaled = true
        data.expense.each do |line|
          line.x  = line.x  * xscale + xoffs
          line.x2 = line.x2 * xscale + xoffs
          line.y  = line.y  * yscale + yoffs
          line.y2 = line.y2 * yscale + yoffs
        end
        data.income.each do |line|
          line.x  = line.x  * xscale + xoffs
          line.x2 = line.x2 * xscale + xoffs
          line.y  = line.y  * yscale + yoffs
          line.y2 = line.y2 * yscale + yoffs
        end
      end
      args.outputs.lines << data.expense # red graph
      args.outputs.lines << data.income  # green graph
      Rendering.set_color(COLOR_ORANGE_P8)
      Rendering.text_left(x + 30, y + h, "Income/Expenses")
      Rendering.rectangle(x, y, w, h)
    end

    def on_update args
      Gui.set_next_window_size(800, 500)
      Gui.begin_window("weekly_screen")
      Gui.header("Week #{@model.week} results")
      Gui.label("Cr gained: #{@model.money_gain}")
      Gui.label("Cr spent: #{@model.money_spend}")
      Gui.label("Revenue: #{@model.profit}")
      Gui.label("You did good.")
      Gui.draw_custom(200, 100, method(:draw_graph), @model.graph_data)
      Gui.label("Employees love you.")
      Gui.end_window()
    end
  end
end # module Strategy
