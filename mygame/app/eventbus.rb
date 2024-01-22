# Simple publish/subscribe event model
class EventBus
  def initialize
    @listeners = []
  end

  # Emit an event to all listeners with variable payload
  def publish event_name, payload = nil
    @listeners.each do |l|
      if l.name == event_name
        l.callback.call(payload)
      end
    end
  end

  # Subscribe function to an event
  def subscribe event_name, listener_function
    @listeners << { name: event_name, callback: listener_function }
    $gtk.log_debug "Subscribed #{event_name} -> #{listener_function}"
  end

  # Remove all subscriptions of listener_function
  def unsubscribe listener_function
    count_before = @listeners.length
    @listeners.delete_if {|l| l.callback == listener_function }
    count_after = @listeners.length
    $gtk.log_debug "Unsubscribed #{listener_function} #{count_before - count_after} times"
  end

  # Clear all subscriptions
  def clear
    @listeners.clear()
  end
end
