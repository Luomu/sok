# Test code for visualizing dice roll results
class GameState_CurveTest < FsmState
  def on_enter args
  end

  Mode_Index = 0
  Mode = :quadratic
  Modes = [
    :linear, :smoothstep, :quadratic
  ]
  def on_update args
    if Input.pressed_right(args)
      Mode_Index = (Mode_Index + 1) % 3
    elsif Input.pressed_left(args)
      Mode_Index = (Mode_Index - 1) % 3
    end
    Mode = Modes[Mode_Index]
    Rendering.text_left( 20, 30.from_top, Mode)

    curve_a = Curve.new(:linear,
      [
        [0.0, 0 ],
        [1.0, 255],
      ]
    )

    curve_b = Curve.new(Mode,
      [
        [0.0, 0 ],
        [1.0, 255],
      ]
    )

    curve_c = Curve.new(Mode,
      [
        [0.0, 0 ],
        [0.5, 255],
        [1.0, 0],
      ]
    )

    curve_d = Curve.new(Mode,
      [
        [0.0,  0.0],
        [0.25, 0.5],
        [0.75, 0.5],
        [1.0,  1.0]
      ]
    )

    xpos, ypos = 120, 120#args.inputs.mouse.x, args.inputs.mouse.y
    draw_curve(args, curve_a, xpos, ypos)
    draw_curve(args, curve_b, xpos += 128, ypos)
    draw_curve(args, curve_c, xpos += 128, ypos)
    draw_curve(args, curve_d, xpos += 128, ypos)
  end

  # Evaluate the curve and draw it
  def draw_curve args, curve, x_offs, y_offs
    NumPoints = 20
    Size      = 120
    pts = []
    s = curve.start_time
    e = curve.end_time
    incr = (e - s) / NumPoints
    time = s
    y_scale = Size / curve.calculate_max
    x_scale = Size / (NumPoints * incr)
    (0..NumPoints).each do |i|
      time = i * incr
      pts << [
        time * x_scale + x_offs,
        curve.evaluate(time) * y_scale + y_offs
      ]
    end

    Rendering.set_color COLOR_LAVENDER_P8
    Rendering.rectangle(x_offs-2,y_offs-2,Size+4,Size+4)
    Rendering.set_color COLOR_WHITE
    Rendering.line_strip(pts)
  end
end
