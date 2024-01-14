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
  cfg = $gtk.parse_json_file "cheat.json"
  if cfg
    Cheats::DISABLE_MUSIC         = cfg.fetch('disable_music', false)
    Cheats::DISABLE_SFX           = cfg.fetch('disable_sfx', false)
    Cheats::QUICK_ADVENTURE_INTRO = cfg.fetch('quick_adventure_intro', false)
    Cheats::QUICK_COMBAT          = cfg.fetch('quick_combat', false)
    Cheats::QUICK_CRAWL           = cfg.fetch('quick_crawl', false)
    Cheats::QUICK_MESSAGES        = cfg.fetch('quick_messages', false)
    Cheats::ULTRA_RICH            = cfg.fetch('ultra_rich', false)
    Cheats::WEAK_FOES             = cfg.fetch('weak_foes', false)
  end
end
