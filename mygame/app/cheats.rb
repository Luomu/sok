# Several cheat values useful for testing
# In one place to reduce temporary edits in many files
# Don't edit the defaults below
module Cheats
  DISABLE_MUSIC         = false # not a cheat, just a common toggle
  DISABLE_SFX           = false # as above
  QUICK_ADVENTURE_INTRO = false # mission intro fast forward
  QUICK_COMBAT          = false # make combat mega fast
  QUICK_CRAWL           = false # adventure proceeds quickly
  QUICK_MESSAGES        = false # show messages as fast as possible
  ULTRA_RICH            = false # loadsamoney at start
  WEAK_FOES             = false # one hit kills
end

# Edit these if testing
if !$gtk.production
Cheats::DISABLE_MUSIC         = false
Cheats::DISABLE_SFX           = false
Cheats::QUICK_ADVENTURE_INTRO = false
Cheats::QUICK_COMBAT          = false
Cheats::QUICK_CRAWL           = false
Cheats::QUICK_MESSAGES        = false
Cheats::ULTRA_RICH            = false
Cheats::WEAK_FOES             = false
end
