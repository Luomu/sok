# Bit like $gtk.notify, but can be used in production
module Notify
  def self.send message, duration = 300
    $gtk.log_info(message)
    @time      = Kernel.global_tick_count
    @duration  = duration
    @message   = message
    @box_width = $gtk.calcstringbox(message, TEXT_SIZE_LABEL, FONT_DEFAULT)[0]
  end

  def self.update args
    if @message && @time.elapsed_time(Kernel.global_tick_count) < @duration
      # math from GTK::Notify
      diff  = @duration - @time.elapsed_time(Kernel.global_tick_count)
      alpha = @time.global_ease(15, :identity) * 255
      if diff < 15
        alpha = @time.+(@duration - 15).global_ease(15, :flip) * 255
      end

      # Render a little toast widget
      args.outputs.primitives << { x: @box_width.from_right - 25, y: args.grid.bottom, w: @box_width, h: 40, a: alpha }.solid!
      args.outputs.primitives << { x: args.grid.right - 10, y: args.grid.bottom, w: 40, h: 40, r: 128, g: 200, b: 200, a: alpha }.solid!
      args.outputs.primitives << { x: @box_width.from_right - 15, y: args.grid.bottom + 30, text: @message, r: 255, g: 255, b: 255, a: alpha }
    else
      @message = nil
    end
  end
end
