module Portrait
  PORTRAIT_SHEETS = [
    "sprites/portraits/portraits-u.png",
    "sprites/portraits/portraits-f.png",
    "sprites/portraits/portraits-m.png"
  ]

  PORTRAIT_COUNT_PER_GENDER = [
    60,
    50,
    50
  ]

  def Portrait.get_sheet_for_gender gender
    case gender
    when GENDER_UNIVERSAL
      return PORTRAITS_OTHER
    when GENDER_FEMININE
      return PORTRAITS_FEMALE
    when GENDER_MASCULINE
      return PORTRAITS_MALE
    end
  end

  def Portrait.get_num_portraits_for_gender gender
    return PORTRAIT_COUNT_PER_GENDER[gender]
  end

  def Portrait.get_sheet soldier
    return PORTRAIT_SHEETS[soldier.portrait_category]
  end

  # Render a soldier's portrait
  # Also: background, scanline overlay, all tinted to soldier's color
  def Portrait.render soldier, xpos, ypos, primitive_list
    primitive_list << {x: xpos, y: ypos, w: PORTRAIT_WIDTH, h: PORTRAIT_HEIGHT, r: soldier.color[0], g: soldier.color[1], b: soldier.color[2], path: "sprites/gradient01.png"}.sprite!
    primitive_list << {x: xpos, y: ypos, w: PORTRAIT_WIDTH, h: PORTRAIT_HEIGHT, r: soldier.color[0], g: soldier.color[1], b: soldier.color[2], source_x: soldier.portrait_id * PORTRAIT_WIDTH, source_y: 0, source_w: PORTRAIT_WIDTH, source_h: PORTRAIT_HEIGHT, path: get_sheet(soldier)}.sprite!
    primitive_list << {x: xpos, y: ypos, w: PORTRAIT_WIDTH, h: PORTRAIT_HEIGHT, r: 0, g: 0, b: 0, a: 255, path: "sprites/portraits/scanline.png"}.sprite!
  end

end
