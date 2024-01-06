module Rendering
  @@draw_color = COLOR_WHITE

  def Rendering.text_center x,y,text
    $gtk.args.outputs.primitives << {
      x:x, y:y, text:text, size_enum:0, alignment_enum:ALIGN_CENTER,
      r:@@draw_color.r, g:@@draw_color.g, b:@@draw_color.b
    }.label!
  end

  def Rendering.text_left x,y,text
    $gtk.args.outputs.primitives << {
      x:x, y:y, text:text, size_enum:0, alignment_enum:ALIGN_LEFT,
      r:@@draw_color.r, g:@@draw_color.g, b:@@draw_color.b
    }.label!
  end

  def Rendering.text_right x,y,text
    $gtk.args.outputs.primitives << {
      x:x, y:y, text:text, size_enum:0, alignment_enum:ALIGN_RIGHT,
      r:@@draw_color.r, g:@@draw_color.g, b:@@draw_color.b
    }.label!
  end

  def Rendering.line_vertical x
    $gtk.args.outputs.lines << { x: x, y: 0, x2: x, y2: SCREEN_H }.set_color_rgb(@@draw_color)
  end

  def Rendering.line_horizontal y
    $gtk.args.outputs.lines << { x: 0, y: y, x2: SCREEN_W, y2: y }.set_color_rgb(@@draw_color)
  end

  # Render a continuous line from an array of points [[x,y],[x,y]...]
  def Rendering.line_strip point_array
    return if !point_array.is_a? Array || point_array.length < 2

    (1..point_array.length-1).each do |idx|
      e_x = point_array[idx][0]
      e_y = point_array[idx][1]
      s_x = point_array[idx-1][0]
      s_y = point_array[idx-1][1]
      $gtk.args.outputs.lines << [s_x, s_y, e_x, e_y, *@@draw_color]
    end
  end

  def Rendering.rectangle x,y,w,h
    $gtk.args.outputs.primitives << { x: x, y: y, w: w, h: h }.set_color_rgb(@@draw_color).border!
  end

  def Rendering.set_color color
    @@draw_color = color
  end

  def Rendering.set_clear_color color
    $args.outputs.background_color = color
  end
end
