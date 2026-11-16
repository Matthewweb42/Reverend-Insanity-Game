extends Control
## Deckbuilder battle screen. Reads Game.combat state, plays cards on click, and turns the
## combat log's fx list into floating numbers, shakes, flashes and sounds.

var main
var c: Combat
var target := -1
var enemy_box: HBoxContainer
var enemy_views := {}      # id -> panel
var player_panel: PanelContainer
var hand_box: HBoxContainer
var killer_box: HFlowContainer
var log_rich: RichTextLabel
var p_hp: ProgressBar
var p_ess: ProgressBar
var p_shield: Label
var p_status: HFlowContainer
var summon_box: HBoxContainer
var pile_lbl: Label
var turn_lbl: Label
var end_btn: Button
var flee_btn: Button
var auto_btn: Button
var fx_layer: Control
var result_shown := false
var busy := false
var _fx_i := 0
var _log_i := 0
var setup := {}


func _ready() -> void:
	c = Game.combat
	setup = Game.combat_setup
	_fx_i = 0
	var bgp := ColorRect.new()
	bgp.color = Color(0, 0, 0, 0.35)
	bgp.set_anchors_preset(Control.PRESET_FULL_RECT)
	bgp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bgp)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + k, 18)
	add_child(m)
	var root := UI.hbox(14)
	m.add_child(root)
	var main_col := UI.vbox(10)
	UI.expand(main_col, true, true)
	root.add_child(main_col)
	# header
	var hd := UI.hbox()
	var title: String = setup.get("title", "")
	if title == "":
		title = "Tribulation" if setup.get("tribulation", false) else ("Breakthrough Trial" if setup.get("trial", false) else "Battle")
	hd.add_child(UI.heading(title, 28))
	turn_lbl = UI.lbl("", 16, UI.TEXT_DIM)
	hd.add_child(turn_lbl)
	hd.add_child(UI.expand(UI.spacer()))
	for e in c.env:
		var chip := UI.panel(Color(UI.SKY, 0.15), UI.SKY, 6, 4)
		chip.add_child(UI.lbl(e.name, 13, UI.SKY))
		chip.tooltip_text = e.desc
		hd.add_child(chip)
	if c.night:
		var nchip := UI.panel(Color(UI.VIOLET, 0.15), UI.VIOLET, 6, 4)
		nchip.add_child(UI.lbl("Night", 13, UI.VIOLET))
		hd.add_child(nchip)
	main_col.add_child(hd)
	# enemies
	enemy_box = UI.hbox(18)
	enemy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_box.custom_minimum_size.y = 290
	main_col.add_child(enemy_box)
	main_col.add_child(UI.expand(UI.spacer(), true, true))
	# player strip
	player_panel = UI.panel(Color(UI.PANEL, 0.95), UI.GOLD_DIM, 10)
	var pv := UI.hbox(14)
	player_panel.add_child(pv)
	var pic := UI.icon("meditation", 56, UI.GOLD)
	pv.add_child(pic)
	var stats := UI.vbox(4)
	stats.custom_minimum_size.x = 280
	stats.add_child(UI.lbl(Game.p().name, 17, UI.GOLD, true))
	p_hp = UI.bar(1, 1, UI.CRIMSON, 18)
	p_ess = UI.bar(1, 1, Color("4f8fd6"), 18)
	stats.add_child(p_hp)
	stats.add_child(p_ess)
	pv.add_child(stats)
	var mid := UI.vbox(4)
	UI.expand(mid)
	p_shield = UI.lbl("", 15, Color("9fd3ff"))
	mid.add_child(p_shield)
	p_status = HFlowContainer.new()
	mid.add_child(p_status)
	summon_box = UI.hbox(6)
	mid.add_child(summon_box)
	pv.add_child(mid)
	var btns := UI.vbox(6)
	end_btn = UI.btn("End Turn", _end_turn, "Space / E")
	end_btn.custom_minimum_size = Vector2(170, 46)
	end_btn.add_theme_font_override("font", UI.font_head_bold)
	btns.add_child(end_btn)
	var bh := UI.hbox(6)
	flee_btn = UI.btn("Flee", _flee)
	auto_btn = UI.btn("Auto turn", _auto, "Let your instincts play this turn")
	bh.add_child(flee_btn)
	bh.add_child(auto_btn)
	btns.add_child(bh)
	pile_lbl = UI.lbl("", 13, UI.TEXT_DIM)
	btns.add_child(pile_lbl)
	pv.add_child(btns)
	main_col.add_child(player_panel)
	killer_box = HFlowContainer.new()
	killer_box.add_theme_constant_override("h_separation", 8)
	main_col.add_child(killer_box)
	hand_box = UI.hbox(10)
	hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_box.custom_minimum_size.y = 236
	main_col.add_child(hand_box)
	# log
	var lp := UI.panel(Color(UI.PANEL, 0.9), UI.GOLD_DIM, 10)
	lp.custom_minimum_size.x = 360
	var lv := UI.vbox(4)
	lp.add_child(lv)
	lv.add_child(UI.lbl("Battle log", 15, UI.GOLD, true))
	log_rich = UI.rich("", false)
	log_rich.scroll_following = true
	UI.expand(log_rich, true, true)
	lv.add_child(log_rich)
	var tip := UI.wrap("Click an enemy to target it. Click a card to activate that Gu. Essence refills a little each turn; each path allows a limited number of plays per turn by attainment.", 12, UI.TEXT_DIM)
	lv.add_child(tip)
	root.add_child(lp)
	fx_layer = Control.new()
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx_layer)
	_build_enemies()
	_refresh()
	_drain_fx(false)


func hotkey(ev: InputEventKey) -> void:
	if result_shown:
		if ev.keycode in [KEY_SPACE, KEY_ENTER]:
			_close()
		return
	match ev.keycode:
		KEY_SPACE, KEY_E:
			_end_turn()
		KEY_F:
			_flee()
		KEY_TAB:
			_cycle_target()
		_:
			var n: int = ev.keycode - KEY_1
			if n >= 0 and n < 9:
				_play(n)


func _cycle_target() -> void:
	var living := []
	for i in c.enemies.size():
		if c.enemies[i].alive:
			living.append(i)
	if living.is_empty():
		return
	var k := living.find(target)
	target = living[(k + 1) % living.size()]
	_refresh()


# --------------------------------------------------------------- enemies --
func _build_enemies() -> void:
	UI.clear(enemy_box)
	enemy_views.clear()
	for i in c.enemies.size():
		var e: Dictionary = c.enemies[i]
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(220, 270)
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var v := UI.vbox(4)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(v)
		var intent := UI.lbl("", 15, UI.AMBER, true)
		intent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		intent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		intent.name = "Intent"
		v.add_child(intent)
		var tint := Data.path_color(e.path).lightened(0.25)
		if e.tier == "boss":
			tint = UI.CRIMSON.lightened(0.2)
		var ic := UI.icon(e.icon, 110, tint)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.name = "Icon"
		v.add_child(ic)
		var nm := UI.lbl(e.name, 17, UI.TEXT, true)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		var sub := UI.lbl("Rank %d %s · %s" % [int(e.rank), e.tier, Data.path_name(e.path)], 12, UI.TEXT_DIM)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(sub)
		var hp := UI.bar(e.hp, e.max_hp, UI.CRIMSON, 16)
		hp.name = "HP"
		v.add_child(hp)
		var sh := UI.lbl("", 13, Color("9fd3ff"))
		sh.name = "Shield"
		sh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(sh)
		var st := HFlowContainer.new()
		st.name = "Status"
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(st)
		p.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and e.alive:
				target = i
				Sfx.play("click")
				_refresh())
		var abil := []
		for a in e.abilities:
			abil.append(a.name)
		p.tooltip_text = "%s\nAbilities: %s%s" % [e.name, ", ".join(abil), ("\nKiller move: " + e.killer.name) if e.killer != null else ""]
		enemy_box.add_child(p)
		enemy_views[e.id] = p


func _status_chips(box: HFlowContainer, ent: Dictionary) -> void:
	UI.clear(box)
	for sid in ent.get("statuses", {}).keys():
		var st: Dictionary = ent.statuses[sid]
		if int(st.stacks) <= 0 or int(st.turns) <= 0:
			continue
		var sd: Dictionary = Data.statuses.get(sid, {"name": sid, "debuff": false, "desc": ""})
		var col := UI.CRIMSON if sd.get("debuff", false) else UI.JADE
		var chip := UI.hbox(2)
		chip.add_child(UI.icon(sd.get("icon", "circle"), 20, col.lightened(0.2)))
		chip.add_child(UI.lbl(str(int(st.stacks)), 13, col.lightened(0.3)))
		chip.tooltip_text = "%s ×%d (%d turns): %s" % [sd.name, int(st.stacks), int(st.turns), sd.get("desc", "")]
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		box.add_child(chip)
	for f in ent.get("forms", {}).keys():
		if int(ent.forms[f]) > 0 and Data.forms.has(f):
			var l := UI.lbl("◇ " + Data.forms[f].name, 13, UI.GOLD)
			l.tooltip_text = Data.forms[f].get("desc", "")
			l.mouse_filter = Control.MOUSE_FILTER_PASS
			box.add_child(l)


# ---------------------------------------------------------------- refresh --
func _refresh() -> void:
	if c == null:
		return
	if target < 0 or target >= c.enemies.size() or not c.enemies[target].alive:
		target = -1
		for i in c.enemies.size():
			if c.enemies[i].alive:
				target = i
				break
	turn_lbl.text = "Turn %d" % c.turn
	for i in c.enemies.size():
		var e: Dictionary = c.enemies[i]
		var p: PanelContainer = enemy_views[e.id]
		var sel := i == target
		var border := UI.GOLD if sel else (UI.CRIMSON if e.tier == "boss" else UI.GOLD_DIM)
		p.add_theme_stylebox_override("panel", UI.box(Color(0.12, 0.09, 0.08, 0.95) if e.alive else Color(0.06, 0.05, 0.05, 0.7), border, 3 if sel else 1, 10, 10))
		var v := p.get_child(0)
		var intent: Label = v.get_node("Intent")
		intent.text = ("⚔ " if e.intent.get("kind", "") in ["attack", "killer"] else "◆ ") + c.intent_text(e) if e.alive else ("Fled" if e.get("fled", false) else "Defeated")
		intent.add_theme_color_override("font_color", UI.CRIMSON if e.intent.get("kind", "") == "killer" else UI.AMBER)
		UI.set_bar(v.get_node("HP"), maxi(0, int(e.hp)), int(e.max_hp))
		var sh: Label = v.get_node("Shield")
		sh.text = "Shield %d" % int(e.shield) if int(e.shield) > 0 else ""
		_status_chips(v.get_node("Status"), e)
		p.modulate = Color(1, 1, 1, 1) if e.alive else Color(1, 1, 1, 0.35)
	var pl: Dictionary = c.player
	UI.set_bar(p_hp, maxi(0, int(pl.hp)), int(pl.max_hp), "HP %d / %d" % [maxi(0, int(pl.hp)), int(pl.max_hp)])
	UI.set_bar(p_ess, int(pl.essence), int(pl.max_essence), "Essence %d / %d  (+%d/turn)" % [int(pl.essence), int(pl.max_essence), int(pl.regen)])
	var extra := []
	if int(pl.shield) > 0:
		extra.append("Shield %d" % int(pl.shield))
	if int(pl.combo) > 0:
		extra.append("Combo %d" % int(pl.combo))
	if int(pl.cheapen) > 0:
		extra.append("Next %d Gu half cost" % int(pl.cheapen))
	if int(pl.reveal) > 0:
		extra.append("Intents revealed")
	var plays := []
	for path in pl.path_plays.keys():
		plays.append("%s %d/%d" % [Data.path_symbol(path), int(pl.path_plays[path]), c.path_limit(path)])
	if plays.size() > 0:
		extra.append("Plays: " + " ".join(plays))
	p_shield.text = "   ".join(extra)
	_status_chips(p_status, pl)
	UI.clear(summon_box)
	for s in pl.summons:
		var chip := UI.panel(UI.PANEL_2, UI.JADE, 4, 4)
		var h := UI.hbox(4)
		h.add_child(UI.icon(s.get("icon", "wolf-head"), 22, UI.JADE))
		h.add_child(UI.lbl("%s %d/%d (%dt)" % [s.name, int(s.hp), int(s.max_hp), int(s.turns)], 13, UI.JADE))
		chip.add_child(h)
		summon_box.add_child(chip)
	pile_lbl.text = "Draw %d · Discard %d · Exhausted %d" % [pl.draw.size(), pl.discard.size(), pl.exhaust.size()]
	var fr: String = c.can_flee()
	flee_btn.disabled = fr != ""
	flee_btn.text = "Flee (%d%%)" % int(c.flee_chance() * 100) if fr == "" else "Flee"
	flee_btn.tooltip_text = fr if fr != "" else "Escape the battle. Key: F"
	var over := c.result != ""
	end_btn.disabled = over or busy
	auto_btn.disabled = over or busy
	_build_hand()
	_build_killers()
	_update_log()


func _build_hand() -> void:
	UI.clear(hand_box)
	var hand: Array = c.player.hand
	var w := 150 if hand.size() <= 6 else 128
	for i in hand.size():
		var card: Dictionary = hand[i]
		var why: String = c.can_play(i)
		var gd := {"name": card.name, "path": card.path, "rank": card.rank, "rarity": card.get("rarity", "common"),
				"cost": card.cost, "effects": card.effects, "flags": card.flags, "icon": card.get("icon", "circle"), "flavor": ""}
		var power: float = float(card.get("power", 1.0)) * (1.0 + float(card.get("upgrade", 0.0)))
		var cv := UI.gu_card(gd, power, w, 214, c.card_cost(card), why != "")
		cv.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if why == "" else Control.CURSOR_FORBIDDEN
		if why != "":
			cv.tooltip_text = why + "\n\n" + cv.tooltip_text
		else:
			var sb: StyleBoxFlat = cv.get_theme_stylebox("panel").duplicate()
			sb.shadow_color = Color(UI.GOLD, 0.35)
			sb.shadow_size = 8
			cv.add_theme_stylebox_override("panel", sb)
		var key := UI.lbl(str(i + 1), 11, UI.TEXT_DIM)
		key.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		key.position -= Vector2(6, 2)
		cv.add_child(key)
		cv.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_play(i))
		cv.mouse_entered.connect(func():
			cv.pivot_offset = cv.size / 2.0
			create_tween().tween_property(cv, "scale", Vector2(1.08, 1.08), 0.08))
		cv.mouse_exited.connect(func(): create_tween().tween_property(cv, "scale", Vector2.ONE, 0.08))
		hand_box.add_child(cv)
	if hand.is_empty():
		hand_box.add_child(UI.lbl("Your hand is empty. End the turn to draw.", 16, UI.TEXT_DIM))


func _build_killers() -> void:
	UI.clear(killer_box)
	for k in c.available_killers():
		var km: Dictionary = k.km
		var b := UI.btn("☯ %s  (%d)" % [km.name, int(k.cost)], func(): _killer(km.id), "%s\n%s%s" % [km.name, Data.describe_effects(km.effects), ("\n" + k.reason) if k.reason != "" else ""])
		b.disabled = k.reason != "" or busy
		b.add_theme_color_override("font_color", Color("ffcf5a"))
		b.add_theme_stylebox_override("normal", UI.box(Color("3a2a10"), Color("ffcf5a"), 2, 6, 10, 6))
		killer_box.add_child(b)


func _update_log() -> void:
	var lines := []
	var src: Array = c.lines
	for i in range(maxi(0, src.size() - 80), src.size()):
		var e: Dictionary = src[i]
		lines.append("[color=#%s]%s[/color]" % [UI.hex(UI.LOG_COLORS.get(e.kind, UI.TEXT)), e.text])
	log_rich.text = "\n".join(lines)


# ---------------------------------------------------------------- actions --
func _play(i: int) -> void:
	if busy or c.result != "" or i >= c.player.hand.size():
		return
	var why: String = c.can_play(i)
	if why != "":
		main.toast(why, "warn")
		Sfx.play("fail")
		return
	c.play_card(i, target)
	_after_action()


func _killer(id: String) -> void:
	if busy or c.result != "":
		return
	if c.use_killer(id, target):
		_after_action()


func _end_turn() -> void:
	if busy or c.result != "":
		return
	busy = true
	c.end_turn()
	_after_action()


func _flee() -> void:
	if busy or c.can_flee() != "":
		return
	if not c.try_flee():
		main.toast("You fail to escape!", "bad")
		c.end_turn()
	_after_action()


func _auto() -> void:
	if busy or c.result != "":
		return
	busy = true
	c.auto_turn()
	_after_action()


func bot_step() -> void:
	if result_shown:
		_close()
		return
	if busy:
		return
	_auto()


func _after_action() -> void:
	busy = true
	_refresh()
	await _drain_fx(true)
	busy = false
	if not is_inside_tree():
		return
	_refresh()
	if c.result != "" and not result_shown:
		_show_result()


func _drain_fx(animate: bool):
	var n := 0
	while _fx_i < c.fx.size():
		var f: Dictionary = c.fx[_fx_i]
		_fx_i += 1
		if animate and is_inside_tree():
			_fx(f)
			n += 1
			if n % 3 == 0 and main.bot == null:
				await get_tree().create_timer(0.12).timeout
	if animate and is_inside_tree():
		await get_tree().create_timer(0.05).timeout


func _anchor_for(who: String) -> Control:
	if who == "p" or who.begins_with("s"):
		return player_panel
	return enemy_views.get(who, player_panel)


func _fx(f: Dictionary) -> void:
	var who: String = str(f.get("who", "p"))
	var a := _anchor_for(who)
	match str(f.type):
		"damage":
			var amt := int(f.get("amount", 0))
			if amt > 0:
				_float(a, "-%d" % amt, UI.CRIMSON if who != "p" else Color("ff8a7a"), 30 if amt >= 20 else 24)
				_shake(a, 6.0 if amt >= 20 else 3.0)
				Sfx.play("hit_heavy" if amt >= 30 else "hit")
			if int(f.get("blocked", 0)) > 0:
				_float(a, "blocked %d" % int(f.blocked), Color("9fd3ff"), 16, Vector2(0, 30))
		"heal":
			_float(a, "+%d" % int(f.get("amount", 0)), UI.JADE, 24)
			Sfx.play("heal")
		"shield":
			_float(a, "+%d shield" % int(f.get("amount", 0)), Color("9fd3ff"), 20)
			Sfx.play("shield")
		"miss":
			_float(a, "miss", UI.TEXT_DIM, 20)
		"status":
			var sd: Dictionary = Data.statuses.get(f.get("status", ""), {"name": f.get("status", ""), "debuff": false})
			_float(a, sd.name, UI.CRIMSON if sd.get("debuff", false) else UI.JADE, 16, Vector2(0, -30))
			Sfx.play("poison" if f.get("status", "") in ["poison", "burn", "bleed"] else "buff")
		"essence":
			_float(a, "+%d essence" % int(f.get("amount", 0)), Color("7fb5ff"), 16)
		"card":
			Sfx.play("card")
		"killer":
			_banner(str(f.get("name", "Killer move")), who == "p")
			Sfx.play("killer")
		"lightning":
			_flash(Color(0.8, 0.9, 1.0, 0.5))
			Sfx.play("thunder")
		"summon":
			_float(a, str(f.get("name", "")), UI.JADE, 18, Vector2(0, -40))
			Sfx.play("summon")
		"death":
			if a != player_panel:
				create_tween().tween_property(a, "modulate", Color(1, 1, 1, 0.35), 0.4)
		"flee":
			_float(a, "fled", UI.TEXT_DIM, 20)
		"buff":
			_float(a, str(f.get("text", "")), UI.GOLD, 16, Vector2(0, -30))


var _stack := {}   # target instance id -> [count, time] so simultaneous numbers don't overlap


func _float(a: Control, text: String, col: Color, size := 22, off := Vector2.ZERO) -> void:
	if a == null or not is_instance_valid(a):
		return
	var now := Time.get_ticks_msec()
	var st: Array = _stack.get(a.get_instance_id(), [0, 0])
	if now - int(st[1]) > 500:
		st = [0, now]
	off += Vector2(0, -28.0 * st[0])
	_stack[a.get_instance_id()] = [int(st[0]) + 1, now]
	var l := UI.lbl(text, size, col, true)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	fx_layer.add_child(l)
	var r := a.get_global_rect()
	var base := r.position + Vector2(r.size.x * 0.5 + randf_range(-20, 20), r.size.y * 0.35) + off - fx_layer.get_global_rect().position
	l.position = base
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position", base + Vector2(0, -60), 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


func _shake(a: Control, amt: float) -> void:
	if a == null or not is_instance_valid(a):
		return
	var base := a.position
	var tw := create_tween()
	for k in 4:
		tw.tween_property(a, "position", base + Vector2(randf_range(-amt, amt), randf_range(-amt * 0.5, amt * 0.5)), 0.03)
	tw.tween_property(a, "position", base, 0.03)


func _flash(col: Color) -> void:
	var r := ColorRect.new()
	r.color = col
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.35)
	tw.tween_callback(r.queue_free)


func _banner(text: String, mine: bool) -> void:
	_flash(Color(1.0, 0.85, 0.4, 0.25) if mine else Color(0.8, 0.1, 0.1, 0.25))
	var l := UI.lbl(text.to_upper(), 46, Color("ffcf5a") if mine else UI.CRIMSON, true)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	l.add_theme_constant_override("outline_size", 10)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.grow_vertical = Control.GROW_DIRECTION_BOTH
	fx_layer.add_child(l)
	l.pivot_offset = l.size / 2
	l.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


# ---------------------------------------------------------------- result --
var _res := {}


func _show_result() -> void:
	result_shown = true
	_res = Game.finish_combat()
	if not Game.has_run():
		return   # death: run_ended shows the life summary
	var v := UI.vbox(12)
	var won: bool = str(_res.result) in ["win", "stalemate_win"]
	var t := UI.heading(str(_res.title), 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", UI.GOLD if won else (UI.TEXT if _res.result == "fled" else UI.CRIMSON))
	v.add_child(t)
	var body := UI.rich(str(_res.text))
	body.custom_minimum_size = Vector2(520, 0)
	v.add_child(body)
	v.add_child(UI.lbl("Turns: %d · Damage dealt: %d" % [int(c.stats.turns), int(c.stats.damage_dealt)], 14, UI.TEXT_DIM))
	var b := UI.btn("Continue", _close)
	b.custom_minimum_size = Vector2(200, 44)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(b)
	var m: Control = main.modal(v, false, 600)
	m.set_meta("bot_close", true)
	m.set_meta("combat_result", true)
	set_meta("result_modal", m)


func _close() -> void:
	var m = get_meta("result_modal", null)
	if m != null and is_instance_valid(m):
		main.close_modal(m)
	main.combat_finished(_res)
