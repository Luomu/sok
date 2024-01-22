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
      reputation_lost:   0
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
      @model = {
        week:        stats.current_week,
        money_gain:  stats.money_gained,
        money_spend: stats.money_spent,
        profit:      stats.money_gained - stats.money_spent,
      }
      Strategy.eventbus.publish(Events::ENTER_SHOP)
    end

    def draw_func args, x, y, w, h, data = nil
      Rendering.set_color(COLOR_ORANGE_P8)
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
      Gui.draw_custom(200, 100, method(:draw_func))
      Gui.label("Employees love you.")
      Gui.end_window()
    end
  end
end # module Strategy
