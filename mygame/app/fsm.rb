# Finite State Machine

# States have an entry, update and exit methods
class FsmState
  attr_reader :parent_fsm

  def initialize parent_fsm
    @parent_fsm = parent_fsm
  end

  def on_enter args
  end

  def on_update args
    raise "FsmState::on_update must be implemented"
  end

  def on_exit args
  end
end

# Holds states
# State transitions are 'loose' (can transition to any state)
class Fsm
  attr_accessor :states
  attr_reader   :current_state

  def initialize
    @current_state = nil
    @next_state    = nil
    @states        = {}
  end

  def current_state_name
    return @current_state.to_s
  end

  def update args
    if @next_state
      if @current_state
        @current_state.on_exit args
      end
      @current_state = @next_state
      @current_state.on_enter args
      @next_state = nil
    end
    return unless @current_state
    @current_state.on_update args
  end

  def transition_to state
    if state.is_a?(FsmState)
      @next_state = states
    else
      @next_state = states[state]
    end

    raise ArgumentError, "State #{state} not found" unless @next_state
  end
end

# FSM state that can be bound to methods, which is sometimes
# simpler than subclassing FsmState:
# FsmStateFunctional.new(fsm, method(:enter_foo), method(:update_foo), method(:exit_foo))
class FsmStateFunctional < FsmState
  def initialize parent_fsm, enter_, update_, exit_, state_name_ = nil
    super(parent_fsm)
    @func_enter  = enter_
    @func_update = update_
    @func_exit   = exit_
    @state_name  = state_name_
  end

  def to_s
    return @state_name
  end

  def on_enter args
    @func_enter.call(args) unless @func_enter.nil?
  end

  def on_update args
    @func_update.call(args) unless @func_update.nil?
  end

  def on_exit args
    @func_exit.call(args) unless @func_exit.nil?
  end
end

# Helper method to build functional states quickly
# fsm
#   .add_func_state(:state_foo, method(:update_foo))
#   .add_funct_state(:state_bar, method(:update_bar), method(:enter_bar))
#   .transition_to(:state_foo)
#
class Fsm
  def add_func_state state_name, update_func, enter_func = nil, exit_func = nil
    self.states[state_name] = FsmStateFunctional.new(self, enter_func, update_func, exit_func, state_name)
    return self
  end
end
