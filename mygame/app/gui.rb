# immediate mode menu layout
module Gui
  ERR_NO_CURR_WINDOW = "No current window set - missing begin?"

  class Point
    attr_accessor :x
    attr_accessor :y

    def initialize x_, y_
      @x = x_
      @y = y_
    end
  end

  #Text element
  class Label
    attr_reader :x
    attr_reader :y
    attr_reader :text
    attr_reader :size

    def initialize text_, x_, y_, size_
      @x = x_
      @y = y_
      @text = text_
      @size = size_
    end
  end

  # Image element
  class Image
    attr_reader :x
    attr_reader :y
    attr_reader :w
    attr_reader :h
    attr_reader :path

    def initialize path_, x_, y_, w_, h_
      @x = x_
      @y = y_
      @w = w_
      @h = h_
      @path = path_
    end
  end

  # A Window's draw list for frames, images and labels
  class WindowDrawList
    attr_accessor :labels
    attr_accessor :images
    attr_accessor :primitives
    def initialize
      @labels     = []
      @images     = []
      @primitives = []
    end

    def add_label text, x, y, size = TEXT_SIZE_LABEL
      @labels << Label.new(text, x, y, size)
    end

    def add_image sprite, x, y, w, h
      @images << Image.new(sprite, x, y, w, h)
    end

    def add_primitive prim
      @primitives << prim
    end

    def reset
      @labels.clear()
      @images.clear()
      @primitives.clear()
    end
  end

  # Contains options
  # Has a cursor position for the next element
  # 0,0 is top left for the window frame
  class Window
    attr_reader   :title
    attr_accessor :x
    attr_accessor :y
    attr_accessor :width
    attr_accessor :height
    attr_reader   :draw_list
    attr_accessor :current_selection
    attr_accessor :num_options
    attr_accessor :is_confirmed
    attr_accessor :is_canceled
    attr_accessor :is_alive #otherwise will get deleted
    attr_accessor :flags

    def initialize title_
      @title = title_
      @x = 0
      @y = 0
      @width  = 100
      @height = 60
      @cursor_pos = Point.new(0,0)
      @draw_list  = WindowDrawList.new
      @current_selection = 0
      @num_options  = 0
      @is_confirmed = false
      @is_canceled  = false
      @flags = WINDOWFLAG_DEFAULTS
    end

    # Layout cursor, not the menu cursor!
    def get_cursor_pos
      @cursor_pos
    end

    def set_cursor_pos x, y
      @cursor_pos.x = x
      @cursor_pos.y = y
    end

    def move_up
      if @num_options > 0
        @current_selection -= 1
        @current_selection = 0 if @current_selection < 0
        Sound.menu_up()
      else
        @current_selection = 0
      end
    end

    def move_down
      if @num_options > 0
        @current_selection += 1
        @current_selection = @num_options - 1 if @current_selection >= @num_options
        Sound.menu_down()
      else
        @current_selection = 0
      end
    end

    def move_left
    end

    def move_right
    end

    def confirm_selection
      @is_confirmed = true
    end

    def has_flag? flag
      @flags & flag != 0
    end

    def set_flag flag
      @flags = @flags | flag
    end

    def unset_flag flag
      @flags = @flags & ~flag
    end
  end

  # Stores state
  class Context
    attr_reader   :windows
    attr_accessor :current_window
    attr_accessor :window_stack
    attr_accessor :next_window_flags
    attr_accessor :next_window_pos
    attr_accessor :next_window_size
    attr_accessor :next_window_padding
    attr_accessor :num_columns
    attr_accessor :current_column
    attr_accessor :cursor_before_first_column
    attr_accessor :current_column_width
    attr_accessor :tallest_column
    attr_accessor :padding

    def initialize
      @windows = []
      @window_stack = []
      @current_window = nil
      @next_window_flags   = nil
      @next_window_pos     = nil
      @next_window_size    = nil
      @next_window_padding = nil

      @num_columns    = 0
      @current_column = 0
      @cursor_before_first_column = Point.new(0,0)
      @current_column_width = 0
      @tallest_column       = 0
      @padding              = WINDOW_PADDING
    end

    # New frame reset
    def on_new_frame
      @next_window_flags = nil
      @next_window_pos   = nil
      @next_window_size  = nil
    end

    def find_window title
      @windows.find { |w| w.title == title }
    end

    def create_window title
      wnd = Window.new(title)
      @windows << wnd
      wnd
    end
  end

  def Gui.context
    return @@ctx
  end

  # Begin a menu window - must be matched by end_menu
  def Gui.begin_menu title, x = 0, y = 0
    ctx         = @@ctx
    window      = ctx.find_window(title)
    ctx.padding = ctx.next_window_padding ? ctx.next_window_padding : WINDOW_PADDING
    ctx.next_window_padding = nil

    #create window on first use
    if !window
      window = ctx.create_window(title)
    end
    ctx.window_stack << window
    ctx.current_window = ctx.window_stack.last
    if ctx.next_window_flags != nil
      window.flags = ctx.next_window_flags
      ctx.next_window_flags = nil
    end
    window.is_alive = true
    window.x = x
    window.y = y
    window.num_options = 0
    window.height = ctx.padding * 2

    # Override position
    if ctx.next_window_pos
      if ctx.next_window_pos.x
        window.unset_flag(WINDOWFLAG_CENTER_X)
        window.x = ctx.next_window_pos.x
      end

      if ctx.next_window_pos.y
        window.unset_flag(WINDOWFLAG_CENTER_Y)
        window.y = ctx.next_window_pos.y
      end

      ctx.next_window_pos = nil
    end

    # Override size
    if ctx.next_window_size
      window.set_flag(WINDOWFLAG_FIXED_SIZE)
      window.width  = ctx.next_window_size.x
      window.height = ctx.next_window_size.y
      ctx.next_window_size = nil
    end

    window.set_cursor_pos(ctx.padding, -ctx.padding)
  end

  # End a menu window - must be matched by begin_menu
  # Returns the highlighted option index, if any
  def Gui.end_menu
    raise ERR_NO_CURR_WINDOW unless @@ctx.current_window

    #resize menu to fit contents

    # Auto-center
    w = @@ctx.current_window
    if w.has_flag?(WINDOWFLAG_CENTER_X)
      w.x = SCREEN_HALF_W - w.width/2
    end

    if w.has_flag?(WINDOWFLAG_CENTER_Y)
      w.y = SCREEN_HALF_H + w.height/2
    end

    if w.num_options <= w.current_selection
      w.current_selection = 0
    end

    #@@ctx.current_window = nil
    @@ctx.window_stack.pop
    @@ctx.current_window = @@ctx.window_stack.last

    return w.current_selection
  end

  def Gui.begin_window unique_id
    Gui.begin_menu(unique_id)
  end

  def Gui.end_window
    Gui.end_menu()
  end

  # Define a selectable menu option
  def Gui.menu_option title
    window = @@ctx.current_window
    raise ERR_NO_CURR_WINDOW unless window

    # add a label draw command
    cursor = window.get_cursor_pos
    window.draw_list.add_label(title, cursor.x, cursor.y)

    # decorate with selection cursor
    is_current_selection = window.current_selection == window.num_options
    if is_current_selection
      window.draw_list.add_label(">", cursor.x - WINDOW_CURSOR_WIDTH, cursor.y)
    end
    window.num_options += 1

    #Expand window
    text_size = $gtk.calcstringbox(title, TEXT_SIZE_LABEL, FONT_DEFAULT)
    if !window.has_flag?(WINDOWFLAG_FIXED_SIZE)
      if window.width < (text_size[0] + 32)
        window.width = text_size[0] + 32
      end
      window.height += text_size[1]
    end

    window.set_cursor_pos(cursor.x, cursor.y - text_size[1])

    # Return true (once) if this menu option was confirmed
    if window.is_confirmed && is_current_selection
      window.is_confirmed = false
      return true
    else
      return false
    end
  end

  # Option variant that can call a function if selected, e.g.:
  # Gui.menu_option_call("Attack", method(:do_attack))
  # Gui.menu_option_call("Attack", -> { do_attack })
  def Gui.menu_option_call title, func
    if Gui.menu_option(title)
      Sound.menu_ok()
      func.call()
    end
  end

  def Gui.label title
    window = @@ctx.current_window
    raise ERR_NO_CURR_WINDOW unless window

    cursor = window.get_cursor_pos
    window.draw_list.add_label(title, cursor.x, cursor.y)

    #Expand window
    text_size = $gtk.calcstringbox(title, TEXT_SIZE_LABEL)
    if !window.has_flag?(WINDOWFLAG_FIXED_SIZE)
      window_padding_actual = @@ctx.padding + @@ctx.padding + WINDOW_CURSOR_WIDTH
      if window.width < (text_size[0] + window_padding_actual)
        window.width = text_size[0] + window_padding_actual
      end
      window.height += text_size[1]
    end

    window.set_cursor_pos(cursor.x, cursor.y - text_size[1])
  end

  # A label, but bigger
  def Gui.header title
    window = @@ctx.current_window
    raise ERR_NO_CURR_WINDOW unless window

    cursor = window.get_cursor_pos
    window.draw_list.add_label(title, cursor.x, cursor.y, TEXT_SIZE_HEADER)

    #Expand window
    text_size = $gtk.calcstringbox(title, TEXT_SIZE_HEADER)
    if !window.has_flag?(WINDOWFLAG_FIXED_SIZE)
      window_padding_actual = @@ctx.padding + @@ctx.padding + WINDOW_CURSOR_WIDTH
      if window.width < (text_size[0] + window_padding_actual)
        window.width = text_size[0] + window_padding_actual
      end
      window.height += text_size[1]
    end

    window.set_cursor_pos(cursor.x, cursor.y - text_size[1])
  end

  # Returns true if cancel button was pressed in the currently
  # active menu (must be between menu begin/end)
  #def Gui.menu_canceled
  #  if @@ctx.current_window
  #    return @@ctx.current_window.is_canceled
  #  else
  #    raise "No active window - menu_canceled should be between begin/end"
  #  end
  #end

  def Gui.image image_path, w = 128, h = 128
    window = @@ctx.current_window
    raise ERR_NO_CURR_WINDOW unless window

    cursor = window.get_cursor_pos
    window.draw_list.add_image(image_path, cursor.x, cursor.y - h, w, h)

    if !window.has_flag?(WINDOWFLAG_FIXED_SIZE)
      window.width  = w + 32
      window.height = h + 32
    end

    cursor.y -= h + @@ctx.padding
  end

  # Special character image
  def Gui.portrait character
    window = @@ctx.current_window
    raise ERR_NO_CURR_WINDOW unless window

    cursor = window.get_cursor_pos
    # This adds multiple overlapping prims to the list
    Portrait.render(character, cursor.x, cursor.y - PORTRAIT_HEIGHT, window.draw_list.primitives)

    if !window.has_flag?(WINDOWFLAG_FIXED_SIZE)
      window.width  = PORTRAIT_WIDTH  + 32
      window.height = PORTRAIT_HEIGHT + 32
    end

    cursor.y -= PORTRAIT_HEIGHT + @@ctx.padding
  end

  # Special window with a portrait on left or right side and a text.
  # The text is wrapped to fit.
  # The box is always centered horizontally.
  def Gui.talkbox window_id, portrait, text, ypos = DIALOGUE_DEFAULT_POS
    Gui.set_next_window_flags(WINDOWFLAG_CENTER_X)
    Gui.begin_menu("Talkbox#{window_id}", 240, ypos)
    window = @@ctx.current_window
    cursor = window.get_cursor_pos
    if portrait
      window.draw_list.add_image(portrait, cursor.x, cursor.y-PORTRAIT_HEIGHT, PORTRAIT_WIDTH, PORTRAIT_HEIGHT)
      cursor.x += PORTRAIT_WIDTH + @@ctx.padding
    end
    lines = text.wrapped_lines(DIALOGUE_MAX_LINE_LENGTH)
    text_size = $gtk.calcstringbox(lines.first, TEXT_SIZE_LABEL)
    lines.each_with_index do |l,i|
      window.draw_list.add_label(l, cursor.x, cursor.y)
      cursor.y -= text_size[1]
    end

    padding_x2     = @@ctx.padding * 2
    window.width   = DIALOGUE_WINDOW_WIDTH
    window.height  = padding_x2
    window.height += lines.length * text_size[1]

    min_height = PORTRAIT_HEIGHT + padding_x2
    if window.height < min_height
      window.height = min_height
    end
    Gui.end_menu()
  end

  # Has an image and one multiline text label
  # Bit like talkbox except the size is fixed
  def Gui.item_preview_window window_id, image, text
    Gui.begin_menu("preview#{window_id}", 200, 200)

    window    = @@ctx.current_window
    cursor    = window.get_cursor_pos
    lines     = text.wrapped_lines(DIALOGUE_MAX_LINE_LENGTH)
    text_size = $gtk.calcstringbox(lines.first, TEXT_SIZE_LABEL)
    lines.each_with_index do |l,i|
      window.draw_list.add_label(l, cursor.x, cursor.y)
      cursor.y -= text_size[1]
    end

    Gui.end_menu()
  end

  # Call this before begin/end column pairs to enable column mode
  # last end() unsets the column mode
  def Gui.set_columns num_col
    window = @@ctx.current_window
    raise ERR_NO_CURR_WINDOW unless window
    raise "Already in column mode?" if @@ctx.num_columns > 0
    @@ctx.num_columns    = num_col
    @@ctx.current_column = 0
    @@ctx.current_column_width = 0
    @@ctx.tallest_column = SCREEN_H
  end

  def Gui.begin_column width = 100
    window = @@ctx.current_window
    raise ERR_NO_CURR_WINDOW unless window
    cursor = window.get_cursor_pos
    @@ctx.current_column += 1
    raise "Unexpected column count" if @@ctx.current_column > @@ctx.num_columns
    # First column, save Y
    if @@ctx.current_column == 1
      @@ctx.cursor_before_first_column = cursor.clone
    else
      cursor.x += @@ctx.current_column_width
      cursor.y = @@ctx.cursor_before_first_column.y
    end
    @@ctx.current_column_width = width
  end

  def Gui.end_column
    window = @@ctx.current_window
    raise ERR_NO_CURR_WINDOW unless window
    cursor = window.get_cursor_pos
    raise "No column active" if @@ctx.current_column <= 0
    @@ctx.tallest_column = [@@ctx.tallest_column, cursor.y].min()
    if @@ctx.current_column == @@ctx.num_columns
      # Restore X to pre-column state
      # Set Y to tallest column height
      cursor.x = @@ctx.cursor_before_first_column.x
      cursor.y = @@ctx.tallest_column
      @@ctx.num_columns = 0
    end
  end

  def Gui.set_next_window_flags windowflags
    @@ctx.next_window_flags = windowflags
  end

  # Override the position of the next window
  # (auto-center flag may override this)
  def Gui.set_next_window_pos x, y
    @@ctx.next_window_pos = Point.new(x, y)
  end

  # Override the size of the next window
  def Gui.set_next_window_size w, h
    @@ctx.next_window_size = Point.new(w, h)
  end

  # Override the window padding for the next window
  def Gui.set_next_window_padding x
    @@ctx.next_window_padding = x
  end

  def Gui.highlighted_option_index
    raise ERR_NO_CURR_WINDOW unless @@ctx.current_window
    @@ctx.current_window.current_selection
  end

  # First time setup
  def Gui.initialize args
    @@ctx = Context.new
  end

  # Call when a new frame begins, before any menu code is called
  def Gui.newframe args
    @@ctx.on_new_frame()
  end

  # Returns the topmost focusable window as the input context (or nil)
  def Gui.determine_input_context
    ctx = @@ctx
    active_window = nil
    ctx.windows.each do |w|
      if !w.has_flag?(WINDOWFLAG_NO_FOCUS)
        active_window = w
      end
    end

    return active_window
  end

  def Gui.handle_input_ok input_context
    input_context&.confirm_selection()
  end

  def Gui.handle_input_up input_context
    input_context&.move_up()
  end

  def Gui.handle_input_down input_context
    input_context&.move_down()
  end

  #def Gui.input_handle_left input_context
  #  input_context&.move_left()
  #end

  #def Gui.input_handle_right input_context
  #  input_context&.move_right()
  #end

  # Delete old windows, call before render
  def Gui.update args
    ctx = @@ctx

    if ctx.current_window
      raise "Current window still set - mismatched begin_menu/end_menu?"
    end

    ctx.windows.delete_if {|w| !w.is_alive }
    ctx.windows.each do |w|
      w.is_alive = false #dies next frame unless refreshed on begin_menu
    end
  end

  # At the end of the frame, render the menu structure
  def Gui.render args
    ctx = @@ctx
    ctx.windows.each do |w|
      # Gradient version
      args.outputs.primitives << { x: w.x, y: w.y - w.height, w: w.width, h: w.height, r: 50, g: 60, b: 70, path: "sprites/gradient01.png" }.sprite!
      args.outputs.primitives << { x: w.x, y: w.y - w.height, w: w.width, h: w.height }.set_color_rgb(COLOR_DARK_GREY_P8).border!
      # Non gradient version
      #args.outputs.primitives << [w.x, w.y - w.height, w.width, w.height, COLOR_WHITE].solid
      #args.outputs.primitives << [w.x, w.y - w.height, w.width, w.height, COLOR_WHITE].border

      w.draw_list.images.each do |img|
        args.outputs.primitives << [w.x + img.x, w.y + img.y, img.w, img.h, img.path].sprite
      end
      w.draw_list.labels.each do |l|
        args.outputs.primitives << { x: w.x + l.x, y: w.y + l.y, text: l.text, size_enum: l.size, font: FONT_DEFAULT }.set_color_rgb(COLOR_WHITE).label!
      end
      w.draw_list.primitives.each do |prim|
        prim.x += w.x
        prim.y += w.y
        args.outputs.primitives << prim
      end
      w.draw_list.reset()
    end
  end

  # Draw some help icons. Doesn't necessarily belong here...
  # Hotkey help
  ICON_KEY_Z   = [16, 0]
  ICON_KEY_X   = [32, 0]
  ICON_DEFENSE = [0, 16]
  ICON_ATTACK  = [16, 16]
  def self.draw_icon x, y, icon
    $outputs.primitives << { x: x, y: y, w: 16, h: 16, tile_x: icon.x, tile_y: icon.y, tile_w: 16, tile_h: 16, path: "sprites/icons.png" }.sprite!
  end

  def self.draw_small_label x, y, text
    $outputs.primitives << { x: x, y: y, size_enum: -2, r: 255, g: 255, b: 255, text: text }.label!
  end

  def self.draw_hotkeys
    draw_icon(10, 10, ICON_KEY_Z)
    draw_small_label(30, 25, "OK /")
    draw_icon(70, 10, ICON_KEY_X)
    draw_small_label(90, 25, "CANCEL")
  end
end
