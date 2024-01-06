# Turn based battlin'
module Adventure
  ENEMY_WIDTH  = 48 * 3
  ENEMY_HEIGHT = 64 * 3

  # combat event is a hash
  # { type, instigator, targets, payload }
  # types:
  ACTION_ATTACK = 1
  ACTION_DEFEND = 2
  ACTION_ESCAPE = 3

  class SoldierAttack
    def use_weapon?
      true
    end
  end

  # Visual representation of an enemy
  class EnemySprite
    attr_sprite
    attr_accessor :x
    attr_accessor :y
    attr_accessor :w
    attr_accessor :h
    attr_accessor :color
    attr_accessor :alpha
    attr_accessor :path
    attr_accessor :character #character this sprite represents

    def initialize path, x, y, w, h
      @path = path

      @x = x
      @y = y
      @w = w
      @h = h
      @r = 255
      @g = 255
      @b = 255
      @a = 255
    end
  end

  # Dummy wrapper for the character location on screen
  SoldierSprite  = Struct.new(:x, :y, :w, :h)

  # 90% obsolete - wraps effect info for the animation queue.
  # Actual animations are played by AnimationManager now
  module Fx
    def Fx.make_death_animation target
      if target.has_stats?
        return { duration: 0 }
      else
        return {
          target:   target,
          frame:    0,
          duration: 60,
          sound:    'sounds/enemy_defeated.wav',
          flash: method(:death_fade)
        }
      end
    end

    def Fx.make_hit_animation target
      return {
        target:   target,
        frame:    0,
        duration: 20,
        flash:    method(:hit_flash),
        anim_id:  Animations::HIT_1
      }
    end

    def Fx.make_animation target, animation_id
      return {
        target:   target,
        frame:    0,
        duration: 15,
        anim_id:  animation_id
      }
    end

    # Flash the sprite
    def Fx.hit_flash target, frame, duration
      #return if target.has_stats? #only enemies supported
      #gfx = target.combat_graphic
      #easing_progress = $args.easing.ease(0, frame, duration, :identity)
      #gfx.r, gfx.g, gfx.b = 255, easing_progress * 255, 255
    end

    # Turn red and fade out
    def Fx.death_fade target, frame, duration
      return if target.has_stats? #only enemies supported
      gfx = target.combat_graphic
      easing_progress = $args.easing.ease(0, frame, duration, :identity)
      gfx.r, gfx.g, gfx.b = 255, 0, 0
      gfx.a = 255 - (easing_progress * 255)
    end
  end

  # Uses MenuScreens to show classic attack/defend/item options
  class CombatMenu
    attr_reader :result_action

    def initialize instigator, alive_enemies
      @instigator    = instigator
      @finished      = false
      @result_action = { instigator: instigator }
      @action_menu   = nil
      @alive_enemies = alive_enemies
      @target_menu   = nil
    end

    def build
      @action_menu = ScreenManager.open(MenuScreen.new("#{@instigator.firstname} acts!")
        .add_option({text: "Attack", callback: -> { do_attack() }})
        .add_option({text: "Defend", callback: -> { do_defend() }})
        .add_option({text: "Autobattle", callback: -> { do_autobattle() }})
        .set_ypos(350)
      )
    end

    def commit_attack target
      @target_menu.close()
      @action_menu.close()
      @finished = true
      @result_action.targets = [target]
      @result_action.payload = SoldierAttack.new()
    end

    def do_target_selection
      @target_menu = ScreenManager.open(MenuScreen.new("Choose target"))
      @alive_enemies.each do |enemy|
        @target_menu.add_option({ text: enemy.name, callback: -> { commit_attack(enemy) } })
      end
    end

    def do_attack
      @result_action.type = ACTION_ATTACK
      do_target_selection()
    end

    def do_defend
      @result_action.type = ACTION_DEFEND
      @action_menu.close()
      @finished = true
    end

    def do_autobattle
      @result_action = nil # set by auto attack
      $do_autobattle = true
      @action_menu.close()
      @finished = true
    end

    def finished?
      return @finished
    end
  end #CombatMenu

  # Combat root class
  class State_Combat < FsmState
    include CombatRules

    def initialize parent_fsm, adventure_
      super(parent_fsm)
      @adventure         = adventure_
      $do_autobattle     = false
      @combat_events     = []
      @combat_animations = []
      @animation_manager = AnimationManager.new
    end

    def on_enter args
      $game_events.publish(Events::ENTER_COMBAT)

      @messages          = MessageLog.new()
      @messages.set_ypos(300)
      @combat_events     = []
      @combat_animations = []
      @fx_sprites        = []
      $do_autobattle     = false

      # Combat sub state machine
      @combat_fsm = Fsm.new
      @combat_fsm
        .add_func_state(:combatstate_begins, method(:state_combat_begins_update))
        .add_func_state(:combatstate_new_character_turn, method(:state_combat_new_turn_update), method(:state_combat_new_turn_enter))
        .add_func_state(:combatstate_input, method(:state_combat_input_update), method(:state_combat_input_enter))
        .add_func_state(:combatstate_execute, method(:state_combat_execute_update))
        .add_func_state(:combatstate_check_end, method(:state_check_end_update))
        .add_func_state(:combatstate_victory, method(:state_victory_update), method(:state_victory_enter))
        .add_func_state(:combatstate_loss, method(:state_loss_update), method(:state_loss_enter))
        .transition_to(:combatstate_begins)

      Adventure.eventbus.subscribe(Adventure::EVENT_CHEAT_KILL_ENEMIES, method(:on_cheat_kill_enemies))
    end

    def on_exit args
      @combat_fsm    = nil
      @combat_events = nil

      Adventure.eventbus.unsubscribe(method(:on_cheat_kill_enemies))
    end

    # -- SUBSTATES BEGIN
    def state_combat_begins_update args
      @enemies     = Encounter.build(args.state.mission.challenge)
      @round       = 1
      @order_index = -1 #increments on turn start

      # Clean up old effects (if we used debug cheats)
      @adventure.party.each { |soldier| soldier.remove_status_effects() }

      # Set up enemy graphics
      num_enemies  = @enemies.length
      spacing      = 40
      box_width    = num_enemies * ENEMY_WIDTH + (num_enemies - 1) * spacing
      xpos         = SCREEN_HALF_W - box_width / 2
      @enemies.each do |e|
        ypos = 400
        e.combat_graphic = EnemySprite.new(e.sprite, xpos, ypos, e.sprite_width * 3, ENEMY_HEIGHT)
        xpos += ENEMY_WIDTH + spacing
      end

      queue_message("#{@enemies[0].name} and friends emerge from the shadows!")

      # Initiative
      @turn_order = []
      @adventure.party.each do |soldier|
        @turn_order << { initiative: soldier.roll_initiative(), character: soldier }
      end
      @enemies.each do |enemy|
        @turn_order << { initiative: enemy.roll_initiative(), character: enemy }
      end
      @turn_order = @turn_order.sort_by { |x| x.initiative }
      @turn_order.reverse!

      @combat_fsm.transition_to(:combatstate_execute)
    end

    # An individual combatant's turn starts: this will tick status effects such
    # as defending and remove expired ones. It may trigger messages/fx.
    def state_combat_new_turn_enter args
      @active_character = @turn_order[@order_index].character
      raise "No active char??" unless @active_character
      @active_character.status_effects.each do |effect|
        effect.update()
      end
      @active_character.status_effects.delete_if {|eff| eff.expired? }
    end

    def state_combat_new_turn_update args
      @combat_fsm.transition_to(:combatstate_input)
    end

    def state_combat_input_enter args
      raise "No active char" unless @active_character
      @combat_menu = nil
      Adventure.eventbus.publish(:event_highlight_character, @active_character)
      if @active_character.unconscious?
        queue_message("#{@active_character.name} remains unconscious!")
      else
        # Players only
        if @active_character.class != Creature
          if !$do_autobattle
            @combat_menu = CombatMenu.new(@active_character, @enemies.select { |x| x.alive? })
            @combat_menu.build()
          end
        end
      end
    end

    # Punch a random enemy
    def perform_random_player_attack char
      attack = SoldierAttack.new()
      @combat_events << {
        type: ACTION_ATTACK,
        instigator: char,
        targets: [get_random_enemy()],
        payload: attack
      }
    end

    # Someone makes a move
    # May be best if we rolled attack here already?
    def state_combat_input_update args
      Debug.assert(@active_character, "No active character")

      if @active_character.class == Creature
        chance = roll_2d6
        if chance < 4
          @combat_events << { type: ACTION_DEFEND, instigator: @active_character }
        else
          #attack random soldier
          @combat_events << {
            type: ACTION_ATTACK,
            instigator: @active_character,
            targets: [get_random_soldier()],
            payload: @active_character.attacks.random_element()
          }
        end
        @combat_fsm.transition_to(:combatstate_execute)
      else #player input
        if $do_autobattle
          perform_random_player_attack(@active_character)
        end

        if !@combat_menu
          @combat_fsm.transition_to(:combatstate_execute)
        else
          if @combat_menu.finished?
            @combat_events << @combat_menu.result_action
            @combat_fsm.transition_to(:combatstate_execute)
          end
        end
      end
    end

    # Execute results of the input
    def state_combat_execute_update args
      # Play events until done
      active_event = @combat_events.shift()
      if active_event
        case active_event.type
        when ACTION_DEFEND
          StatusEffects::Defending.new.apply(active_event.instigator)
          queue_message("#{active_event.instigator.name} is defending...")
        when ACTION_ATTACK
          raise "No attacker set" unless active_event.instigator
          raise "No target set" unless active_event.targets
          attacker = active_event.instigator
          target   = active_event.targets[0]
          attack   = active_event.payload
          raise "No target set" unless target

          effect = roll_attack(attacker, target, attack)
          if effect >= 0
            # roll and apply damage
            damage = roll_damage(effect, active_event, target)
            queue_message("#{attacker.name} attacks #{target.name} for #{damage} damage!", Fx.make_hit_animation(target))
            target.take_damage(damage)
            if not target.alive?
              queue_message("#{target.name} is defeated!", Fx.make_death_animation(target))
            elsif target.should_fall_unconscious?
              queue_message("#{target.name} falls unconscious!")
            end
          else
            #miss
            queue_message("#{attacker.name} attacks #{target.name} but misses!", Fx.make_animation(target, Animations::MISS))
          end
        end
      end

      if update_animations(args)
        @combat_fsm.transition_to(:combatstate_check_end)
      end
    end

    # Check if we win, lose or continue
    def state_check_end_update args
      # Un-highlight active character
      Adventure.eventbus.publish(Adventure::EVENT_HIGHLIGHT_CHARACTER, nil)

      # Players are dead/all KOd or enemies are dead
      if @enemies.none? { |enemy| enemy.alive? }
        @combat_fsm.transition_to(:combatstate_victory)
      elsif @adventure.party_dead?
        @combat_fsm.transition_to(:combatstate_loss)
      else
        # Find out who's next. We already checked we aren't
        # in win/loss state, so infinite loop is impossible
        next_character = nil
        while !next_character do
          @order_index += 1
          # Advance round if at the end
          if @order_index > @turn_order.length - 1
            @round += 1
            @order_index = 0
          end
          next_character = @turn_order[@order_index] if @turn_order[@order_index].character.alive?
        end

        # Remove dead chars, then find updated index of new character
        @turn_order.reject! { |o| not o.character.alive? }
        @order_index = @turn_order.find_index(next_character)

        @combat_fsm.transition_to(:combatstate_new_character_turn)
      end
    end

    def state_victory_enter args
      @adventure.stat_enemies_killed += @enemies.count() # all defeated, by definition

      Music.play_combat_win_jingle()
      queue_message("You have won!")
      perform_first_aid()
      @victory_wait_timer = Cheats::QUICK_COMBAT ? 5 : 120
    end

    def state_victory_update args
      #menu will handle
      if update_animations(args)
        @victory_wait_timer -= 1
        if @victory_wait_timer <= 0
          @parent_fsm.transition_to(:adventure_state_crawl)
        end
      end
    end

    def state_loss_enter args
      @adventure.stat_enemies_killed += @enemies.count {|enemy| enemy.alive? }

      Music.play_combat_lose_jingle()
      ScreenManager.open(MessageScreen.new("You have lost!"))
        .set_on_close(-> { @parent_fsm.transition_to(:adventure_state_results) })
    end

    def state_loss_update args
      #menu will handle
    end
    # -- SUBSTATES END

    def update_animations args
      # Render active FX
      @animation_manager.update(args)

      # Queue new FX + update Messages, flashes and fades
      active_event   = @combat_animations.first
      event_finished = true
      if active_event
        if active_event.message
          @messages.queue_message(active_event.message)
          active_event.message = nil
        end

        # Start the effect
        if active_event.duration > 0
          if active_event.frame == 0
            if active_event.sound
              Sound.play_oneshot(active_event.sound)
            end

            if active_event.anim_id
              gfx   = active_event.target.combat_graphic
              xoffs = gfx.w * 0.5
              yoffs = gfx.h * 0.5
              @animation_manager.play(active_event.anim_id, [gfx.x + xoffs, gfx.y + yoffs])
            end
          end
          # Flash/fade fx
          if active_event.flash
            active_event.flash.call(active_event.target, active_event.frame, active_event.duration)
          end
          active_event.frame += 1
          if active_event.frame < active_event.duration
            event_finished = false
          end
        end
      end

      if Cheats::QUICK_COMBAT
        @messages.flush()
        @animation_manager.clear()
        if active_event
          @combat_animations.shift()
        end
      end

      @messages.update(args)
      if @messages.done? and event_finished
        @combat_animations.shift()
        if @combat_animations.empty?
          return true
        end
      end

      return false
    end

    def on_update args
      @combat_fsm.update(args)

=begin
      # Animation test keys
      if args.inputs.keyboard.key_down.j
        gfx = @enemies.first.combat_graphic
        @animation_manager.play(Animations::HIT_1, [gfx.x + gfx.w/2, gfx.y + gfx.h/2])
      end

      if args.inputs.keyboard.key_down.k
        gfx = @adventure.party.first.combat_graphic
        @animation_manager.play(Animations::HIT_1, [gfx.x + gfx.w/2, gfx.y + gfx.h/2])
      end
=end

      @messages.update(args)

      render_turn_order(args)
      # Render enemy party
      render_enemies(args)
      render_fx(args)
      # Player party already shown
      # Render combat log
      Debug.add_state_text(@combat_fsm.current_state_name)
      Debug.add_state_text(@active_character&.name)
    end

    def queue_message message, effect = nil
      if !effect
        effect = { duration: 0 }
      end
      effect.message = message
      @combat_animations << effect
    end

    def get_random_soldier
      return @adventure.party.select { |x| x.alive? }.random_element()
    end

    def get_random_enemy
      # Only when cheating we may not have alive enemies
      enemy = @enemies.select { |x| x.alive? }.random_element()
      if !enemy
        enemy = @enemies.random_element()
      end
      return enemy
    end

    def perform_first_aid
      alive_and_wounded = @adventure.party.select { |x| x.alive? and x.injured? }
      alive_and_wounded.each do |x|
        queue_first_aid(x)
      end
    end

    def queue_first_aid patient
      # Get the alive, conscious soldier (with the best medic skill), can be self
      healers = @adventure.party.select { |x| x.alive? and not x.unconscious? }
      healer = healers.first() # no medics yet
      medic_check_effect = [roll_2d6() - 8, 1].max # at least 1 pity heal
      patient_damage     = patient.hits_max - patient.hits_current
      medic_check_effect = [patient_damage, medic_check_effect].min # no overheal
      queue_message("#{healer.name} performs first aid on #{patient.name}")
      queue_message("#{medic_check_effect} damage healed!")
      patient.heal_amount(medic_check_effect)
    end

    def render_turn_order args
      Rendering.set_color(COLOR_WHITE)
      ypos = 100.from_top()
      Rendering.text_left(30, ypos, "Round #{@round}")
      ypos -= 20
      @turn_order.each_with_index do |entry, index|
        if index == @order_index
          Rendering.text_left(30, ypos, ">")
        end
        Rendering.text_left(45, ypos, entry.character.name)

        #health is for debug
        if Debug.cheats_enabled?
          Rendering.text_left(200, ypos, "#{entry.character.hits_current}/#{entry.character.hits_max}")
        end

        ypos -= 20
      end
    end

    def render_enemies args
      num_enemies  = @enemies.length
      spacing      = 40
      box_width    = num_enemies * ENEMY_WIDTH + (num_enemies - 1) * spacing

      xpos = SCREEN_HALF_W - box_width / 2
      @enemies.each do |enemy|
        args.outputs.primitives << enemy.combat_graphic
        xpos += ENEMY_WIDTH + spacing
      end
    end

    def render_fx args
      @animation_manager.update(args)

      @fx_sprites.each do |s|
        s.render(args)
      end
      @fx_sprites.delete_if {|s| s.finished? }
    end

    def on_cheat_kill_enemies args
      @enemies.each do |enemy|
        enemy.take_damage(9999)
      end
    end
  end # class State_Combat
end # module Adventure
