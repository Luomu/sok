SAVEGAME_VERSION = 1

COLOR_BLACK = [0, 0, 0]
COLOR_RED   = [255, 0, 0]
COLOR_WHITE = [255, 255, 255]
COLOR_GRAY  = [128, 128, 128]
COLOR_GREEN = [0, 255, 0]

COLOR_BACKGROUND_PROD  = [0, 0, 0]
COLOR_BACKGROUND_DEV   = [32,32,64]
COLOR_TEXT_NORMAL      = [255, 255, 255]

ALIGN_LEFT   = 0
ALIGN_CENTER = 1
ALIGN_RIGHT  = 2

TEXT_SIZE_LABEL  = 1
TEXT_SIZE_HEADER = 4

SCREEN_W      = 1280
SCREEN_H      = 720
SCREEN_HALF_W = 640
SCREEN_HALF_H = 360

FONT_DEFAULT = 'fonts/Gewtymol.ttf'

LABEL_HEIGHT = $gtk.calcstringbox("X", TEXT_SIZE_LABEL, FONT_DEFAULT)[1]

WINDOW_PADDING      = 16
WINDOW_CURSOR_WIDTH = 12 # width of '>'

PORTRAIT_WIDTH  = 48
PORTRAIT_HEIGHT = 64

PORTRAITS_OTHER  = 0
PORTRAITS_FEMALE = 1
PORTRAITS_MALE   = 2

GENDER_UNIVERSAL = 0
GENDER_FEMININE  = 1
GENDER_MASCULINE = 2

DIALOGUE_WINDOW_WIDTH    = 800
DIALOGUE_MAX_LINE_LENGTH = 50
DIALOGUE_DEFAULT_POS     = 360

WINDOWFLAG_CENTER_X   = 0b1000
WINDOWFLAG_CENTER_Y   = 0b0100
WINDOWFLAG_FIXED_SIZE = 0b0010
WINDOWFLAG_NO_FOCUS   = 0b0001
WINDOWFLAG_DEFAULTS   = WINDOWFLAG_CENTER_X | WINDOWFLAG_CENTER_Y

ASSIGNMENT_NONE     = :assignment_none #used as a null state - normally everyone is at least in Reserve
ASSIGNMENT_SQUAD    = :assignment_squad
ASSIGNMENT_RESERVE  = :assignment_reserve
ASSIGNMENT_HOSPITAL = :assignment_hospital

=begin
1 		#1D2B53 	29, 43, 83 	dark-blue
2 		#7E2553 	126, 37, 83 	dark-purple
3 		#008751 	0, 135, 81 	dark-green
4 		#AB5236 	171, 82, 54 	brown
5 		#5F574F 	95, 87, 79 	dark-grey
6 		#C2C3C7 	194, 195, 199 	light-grey
7 		#FFF1E8 	255, 241, 232 	white
8 		#FF004D 	255, 0, 77 	red
9 		#FFA300 	255, 163, 0 	orange
10 		#FFEC27 	255, 236, 39 	yellow
11 		#00E436 	0, 228, 54 	green
12 		#29ADFF 	41, 173, 255 	blue
13 		#83769C 	131, 118, 156 	lavender
14 		#FF77A8 	255, 119, 168 	pink
15 		#FFCCAA 	255, 204, 170 	light-peach
=end
# Pico-8 color palette
COLOR_DARK_BLUE_P8   = [29, 43, 83]
COLOR_DARK_PURPLE_P8 = [126, 37, 83]
COLOR_DARK_GREEN_P8  = [0, 135, 81]
COLOR_BROWN_P8       = [171, 82, 54]
COLOR_DARK_GREY_P8   = [95, 87, 54]
COLOR_LIGHT_GREY_P8  = [194, 195, 199]
COLOR_WHITE_P8       = [255, 241, 232]
COLOR_RED_P8         = [255, 0, 77]
COLOR_ORANGE_P8      = [255, 163, 0]
COLOR_YELLOW_P8      = [255, 236, 39]
COLOR_GREEN_P8       = [0, 228, 54]
COLOR_BLUE_P8        = [41, 173, 255]
COLOR_LAVENDER_P8    = [131, 118, 156]
COLOR_PINK_P8        = [255, 119, 168]
COLOR_LIGHT_PEACH_P8 = [255, 204, 170]

GOOD_SOLDIER_COLORS = [
  #COLOR_DARK_BLUE_P8,
  COLOR_DARK_PURPLE_P8,  #meh
  COLOR_DARK_GREEN_P8,
  COLOR_BROWN_P8,
  COLOR_DARK_GREY_P8,
  COLOR_LIGHT_GREY_P8,
  COLOR_WHITE_P8,
  COLOR_RED_P8,
  COLOR_ORANGE_P8,
  COLOR_YELLOW_P8,
  COLOR_GREEN_P8,
  COLOR_BLUE_P8,
  COLOR_LAVENDER_P8,
  COLOR_PINK_P8,
  COLOR_LIGHT_PEACH_P8
]

COLOR_ATTACK  = COLOR_RED_P8
COLOR_DEFENSE = COLOR_BLUE_P8

# Known event symbols
module Events
  TURN_ENDED            = :event_turn_ended

  ENABLE_AUTOSAVE       = :event_enable_autosave
  AUTOSAVE              = :event_autosave
  ENTER_STRATEGY        = :event_enter_strategy
  ENTER_ADVENTURE       = :event_enter_adventure
  EXIT_ADVENTURE        = :event_exit_adventure
  ENTER_ADVENTURE_CRAWL = :event_enter_adventure_crawl
  ENTER_COMBAT          = :event_enter_combat

  ENTER_SHOP = :event_enter_shop
  EXIT_SHOP  = :event_exit_shop
  ENTER_LOOT = :event_enter_loot
  EXIT_LOOT  = :event_exit_loot

  MESSAGE    = :event_message

  SPEND_MONEY     = :event_spend_money
  GAIN_MONEY      = :event_gain_money
  GAIN_REPUTATION = :event_gain_reputation
  LOSE_REPUTATION = :event_lose_reputation
end

# Balancing data
STARTING_MONEY         = 8000
DEBT_LIMIT             = -10000
RECRUITMENT_DEBT_LIMIT = 0
RENT_PERIOD_DAYS       = 30
ADVENTURE_EVENT_DIFFICULTY = 6
STARTING_ARMOR_LEVEL   = 1
STARTING_WEAPON_LEVEL  = 1
TEST_MISSION_CHALLENGE = 1
MAX_REPUTATION         = 1000000

#drop cost by rank (1-5)
MISSION_DROP_COST = [
  0,
  50,
  100,
  150,
  200,
  250
]
