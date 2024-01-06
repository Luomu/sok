#Results and ending
# Retirement results
class GameState_Results < FsmState
  def calculate_treasures_value args
    value = 0
    args.state.company.treasures.each do |t|
      value += t.value
    end
    return value
  end

  def calculate_rating credits
    credits = credits.greater(0)
    ratings = [
      [1000000, "Mercenary King", "Big Boss", "CEO"],
      [80000, "Venture capitalist", "Investor", "Company Vice President"],
      [50000, "Career politician", "Director of Operations", "Director of Human Resources"],
      [20000, "Military advisor", "Circus director", "Pleasure cruise operator"],
      [1000, "Artifact smuggler", "Arms dealer", "Mercenary"],
      [500, "Tour guide", "Art critic", "Drill sergeant"],
      [0, "Wage slave", "Sandwich artist", "Office drone"]
    ]
    for rating in ratings
      if credits >= rating[0]
        return rating[1..3].random_element()
      end
    end

    return "Tramp"
  end

  def on_enter args
    company       = args.state.company
    treasures     = company.treasures.length
    starting_cr   = company.money
    treasures_cr  = calculate_treasures_value(args)
    final_credits = starting_cr + treasures_cr
    final_rating  = calculate_rating(final_credits)
    fav_soldier   = company.get_favorite_soldier().fullname
    @timer        = 0

    @model = {
      :turn => company.turn,
      :num_operations => company.num_operations,
      :treasures => company.treasures.length,
      :final_credits => final_credits,
      :favourite_soldier => fav_soldier,
      :final_rating => final_rating
    }

    # Outro already started this
    # Music.play_results_music()
  end

  def on_update args
    @timer += 1

    Gui.begin_window("game_results")
    Gui.header("Your mission is over!")
    Gui.label("")
    Gui.label("You return to the corporate headquarters")
    Gui.label("and deliver your final report to the board.")
    Gui.label("After your financials have been thoroughly")
    Gui.label("scrutinized, the CEO hands over your evaluation")
    Gui.label("and you take on a new lifestyle as #{@model.final_rating.upcase}.")
    Gui.label("")
    Gui.label("Days elapsed: #{@model.turn}")
    Gui.label("Missions: #{@model.num_operations}")
    Gui.label("Treasures gathered: #{@model.treasures}")
    Gui.label("Profit: #{@model.final_credits} Cr")
    Gui.label("Star employee: #{@model.favourite_soldier}")
    Gui.label("")
    Gui.label("See you next time!")
    Gui.end_window()

    if @timer > 120 and Input.pressed_ok(args)
      @parent_fsm.transition_to(:corefsm_state_menu)
    end
  end
end
