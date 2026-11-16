extends Control
## The main play screen: top status bar, the world map, and tabbed panels for cultivation,
## the aperture (Gu), the current location, people, goals, the journal and (later) the blessed land.

const MapView := preload("res://ui/map_view.gd")

var main
var map: Control
var tabs: TabContainer
var pages := {}          # name -> {node, build, sig, last}
var top := {}            # top bar widgets
var status_rich: RichTextLabel
var act_label: Label
var travel_bar: ProgressBar
var land_btn: Button
var _dirty := true
var _acc := 0.0
var _speed_btns := []
var _play_btn: Button
var _auto_btn: Button


func _ready() -> void:
	var root := UI.vbox(0)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(_build_top())
	var body := UI.hbox(10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var m := MarginContainer.new()
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for k in ["left", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + k, 10)
	m.add_theme_constant_override("margin_top", 6)
	m.add_child(body)
	root.add_child(m)
	# left: map + status card
	var left := UI.vbox(8)
	UI.expand(left, true, true)
	body.add_child(left)
	map = MapView.new()
	UI.expand(map, true, true)
	map.location_clicked.connect(_on_map_click)
	left.add_child(map)
	var card := UI.panel(Color(UI.PANEL, 0.94), UI.GOLD_DIM, 10)
	card.custom_minimum_size.y = 150
	var cv := UI.vbox(4)
	card.add_child(cv)
	var ch := UI.hbox()
	act_label = UI.lbl("", 16, UI.GOLD, true)
	UI.expand(act_label)
	ch.add_child(act_label)
	land_btn = UI.btn("Enter Blessed Land", _toggle_land)
	ch.add_child(land_btn)
	cv.add_child(ch)
	travel_bar = UI.bar(0, 1, UI.GOLD_DIM, 8, false)
	cv.add_child(travel_bar)
	status_rich = UI.rich("", false)
	status_rich.custom_minimum_size.y = 96
	UI.expand(status_rich, true, true)
	cv.add_child(status_rich)
	left.add_child(card)
	# right: tabs
	tabs = TabContainer.new()
	tabs.clip_tabs = false
	tabs.custom_minimum_size.x = 590
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.tab_changed.connect(func(_i): _dirty = true; refresh(true))
	body.add_child(tabs)
	_add_page("Cultivate", _build_cultivate, _sig_cultivate)
	_add_page("Aperture", _build_aperture, _sig_aperture)
	_add_page("Location", _build_location, _sig_location)
	_add_page("People", _build_people, _sig_people)
	_add_page("Goals", _build_goals, _sig_goals)
	_add_page("Journal", _build_journal, _sig_journal)
	_add_page("Immortal", _build_immortal, _sig_immortal)
	Game.state_changed.connect(func(): _dirty = true)
	refresh(true)


func _add_page(name: String, build: Callable, sig: Callable) -> void:
	var sc := ScrollContainer.new()
	sc.name = name
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := UI.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	tabs.add_child(sc)
	pages[name] = {"node": v, "scroll": sc, "build": build, "sig": sig, "last": "#"}


func _process(delta: float) -> void:
	_acc += delta
	if _acc >= 0.2 and _dirty:
		_acc = 0.0
		refresh()


func refresh(force := false) -> void:
	if not Game.has_run() or not is_inside_tree():
		return
	_dirty = false
	_update_top()
	_update_status()
	var imm := Game.is_immortal()
	pass
	var name: String = tabs.get_child(tabs.current_tab).name
	if not pages.has(name):
		return
	var pg: Dictionary = pages[name]
	var sg: String = pg.sig.call()
	if force or sg != pg.last:
		# don't rebuild under the cursor more than needed: keep scroll position
		var sc: ScrollContainer = pg.scroll
		var y := sc.scroll_vertical
		pg.last = sg
		UI.clear(pg.node)
		pg.build.call(pg.node)
		await get_tree().process_frame
		if is_instance_valid(sc):
			sc.scroll_vertical = y


func hotkey(ev: InputEventKey) -> void:
	match ev.keycode:
		KEY_SPACE:
			_toggle_pause()
		KEY_1:
			_set_speed(1)
		KEY_2:
			_set_speed(2)
		KEY_3:
			_set_speed(4)
		KEY_A:
			main.toggle_bot()
		KEY_ESCAPE:
			main.dialogs.pause_menu()
		KEY_B:
			_breakthrough()


# ==================================================================== TOP BAR
func _build_top() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(Color(0.07, 0.06, 0.05, 0.96), UI.GOLD_DIM, 0, 0, 12, 8))
	var h := UI.hbox(14)
	p.add_child(h)
	top.clan_icon = UI.icon("moon", 40, UI.GOLD)
	h.add_child(top.clan_icon)
	var nv := UI.vbox(0)
	top.name = UI.lbl("", 19, UI.GOLD, true)
	top.rank = UI.lbl("", 14, UI.TEXT)
	nv.add_child(top.name)
	nv.add_child(top.rank)
	nv.custom_minimum_size.x = 230
	h.add_child(nv)
	var bars := UI.vbox(3)
	bars.custom_minimum_size.x = 210
	top.hp = UI.bar(1, 1, UI.CRIMSON, 15)
	top.prog = UI.bar(0, 1, UI.JADE, 15)
	bars.add_child(top.hp)
	bars.add_child(top.prog)
	h.add_child(bars)
	var money := UI.vbox(0)
	top.stones = UI.lbl("", 17, UI.AMBER)
	top.stones.tooltip_text = "Primeval stones: food for your Gu and fuel for cultivation."
	top.feed = UI.lbl("", 13, UI.TEXT_DIM)
	money.add_child(top.stones)
	money.add_child(top.feed)
	money.custom_minimum_size.x = 170
	h.add_child(money)
	var age := UI.vbox(0)
	top.age = UI.lbl("", 15, UI.TEXT)
	top.date = UI.lbl("", 13, UI.TEXT_DIM)
	age.add_child(top.age)
	age.add_child(top.date)
	age.custom_minimum_size.x = 210
	h.add_child(age)
	h.add_child(UI.expand(UI.spacer()))
	_play_btn = UI.btn("▶ Play", _toggle_pause, "Space: pause / resume time", 96)
	h.add_child(_play_btn)
	for sp in [1, 2, 4]:
		var b := UI.btn("%d×" % sp, func(): _set_speed(sp), "Time speed (keys 1, 2, 3)", 46)
		_speed_btns.append([sp, b])
		h.add_child(b)
	_auto_btn = UI.btn("Auto", func(): main.toggle_bot(), "Let the game play itself (A)")
	h.add_child(_auto_btn)
	h.add_child(UI.btn("Menu", func(): main.dialogs.pause_menu(), "Save, settings, retire (Esc)"))
	return p


func _update_top() -> void:
	var pl: Dictionary = Game.p()
	var clan: Dictionary = Data.clans[pl.clan]
	top.clan_icon.texture = Data.icon(clan.icon)
	top.clan_icon.modulate = Data.path_color(clan.primary).lightened(0.3)
	top.name.text = pl.name
	var rk := int(pl.rank)
	if rk >= 6:
		top.rank.text = "%s · %s" % [Data.rank_title(rk), Game.standing_name() if not Game.is_immortal() else ("Lone Immortal" if pl.faction in ["", "lone"] else Game.immortal.FACTIONS[pl.faction].name)]
	else:
		top.rank.text = "Rank %d %s · %s %s" % [rk, Data.STAGES[int(pl.stage)], clan.name, Game.standing_name()]
	UI.set_bar(top.hp, int(pl.hp), Game.max_hp(), "HP %d / %d" % [int(pl.hp), Game.max_hp()])
	if rk >= 6:
		var need: int = Data.IMMORTAL_DAO.get(rk, 1)
		UI.set_bar(top.prog, Game.dao_total(), need, "Dao marks %d / %d" % [Game.dao_total(), need] if rk < 9 else "Venerable")
	else:
		var req := Data.stage_req(rk, int(pl.stage))
		UI.set_bar(top.prog, float(pl.progress), req, "Aperture %d / %d" % [int(pl.progress), int(req)])
	top.stones.text = "◈ %s stones" % UI.num(pl.stones)
	if int(pl.istones) > 0 or Game.is_immortal():
		top.stones.text += "   ✦ %s" % UI.num(pl.istones)
	var fc: int = Game.weekly_feed_cost()
	top.feed.text = "Gu upkeep %d / week" % fc
	top.feed.add_theme_color_override("font_color", UI.CRIMSON if int(pl.stones) < fc else UI.TEXT_DIM)
	var band: Dictionary = Game.cult.age_band()
	top.age.text = "Age %d of ~%d  (%s)" % [int(Game.cult.age_years()), int(pl.lifespan_days) / Data.YEAR, band.name]
	top.age.add_theme_color_override("font_color", UI.TEXT if band.name == "Prime" else (UI.AMBER if band.name in ["First Signs", "Decline"] else UI.CRIMSON))
	top.date.text = "%s · %s%s" % [Game.date_text(), Game.season(), " · night" if Game.is_night() else ""]
	_play_btn.text = "▶ Play" if Game.paused else "❚❚ Pause"
	for pair in _speed_btns:
		var b: Button = pair[1]
		b.add_theme_color_override("font_color", UI.GOLD if Game.speed == pair[0] else UI.TEXT_DIM)
	_auto_btn.add_theme_color_override("font_color", UI.AMBER if main.bot != null else UI.TEXT)


func _toggle_pause() -> void:
	if Game.combat != null or not Game.current_event.is_empty():
		return
	Game.paused = not Game.paused
	_dirty = true


func _set_speed(sp: int) -> void:
	Game.speed = sp
	if Game.paused and Game.combat == null and Game.current_event.is_empty():
		Game.paused = false
	_dirty = true


func _update_status() -> void:
	var pl: Dictionary = Game.p()
	var loc: Dictionary = Data.locations[pl.location]
	var where: String = loc.name if pl.activity != "travel" else "On the road"
	if pl.get("in_land", false) and Game.s.blessed != null:
		where = Game.s.blessed.name
	act_label.text = "%s  —  %s" % [where, Game.activity_text()]
	travel_bar.visible = pl.activity in ["travel", "refine", "mission"]
	if pl.activity == "travel":
		UI.set_bar(travel_bar, Game.travel_progress() * 100.0, 100.0)
	elif pl.activity in ["refine", "mission"]:
		var tot := maxf(1.0, float(pl.act.get("total", pl.act.get("days", 1))))
		UI.set_bar(travel_bar, tot - float(pl.act.get("left", 0)), tot)
	land_btn.visible = Game.is_immortal() and Game.s.blessed != null
	land_btn.text = "Leave Blessed Land" if pl.get("in_land", false) else "Enter Blessed Land"
	var lines := []
	var lg: Array = Game.s.log
	for i in range(maxi(0, lg.size() - 6), lg.size()):
		var e: Dictionary = lg[i]
		lines.append("[color=#%s]%s[/color]" % [UI.hex(UI.LOG_COLORS.get(e.get("kind", "info"), UI.TEXT)), e.text])
	status_rich.text = "\n".join(lines)


func _toggle_land() -> void:
	if Game.p().get("in_land", false):
		Game.leave_land()
	else:
		var why: String = Game.enter_land()
		if why != "":
			main.toast(why, "warn")
	refresh(true)


func _on_map_click(id: String) -> void:
	main.dialogs.travel(id)


# =============================================================== helpers ====
func _section(parent: Control, title: String) -> VBoxContainer:
	var v := UI.vbox(5)
	var l := UI.lbl(title, 16, UI.GOLD, true)
	v.add_child(l)
	parent.add_child(v)
	return v


func _act(text: String, cb: Callable, tip := "", disabled_reason := "") -> Button:
	var b := UI.btn(text, func():
		var r = cb.call()
		if typeof(r) == TYPE_STRING and r != "":
			main.toast(r, "warn")
		_dirty = true
		refresh(true), tip)
	if disabled_reason != "":
		b.disabled = true
		b.tooltip_text = disabled_reason
	return b


func _flow(parent: Control) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 6)
	f.add_theme_constant_override("v_separation", 6)
	parent.add_child(f)
	return f


# ============================================================== CULTIVATE ===
func _sig_cultivate() -> String:
	var pl: Dictionary = Game.p()
	return "%s|%s|%s|%s|%s|%d|%d|%s|%d|%s" % [pl.rank, pl.stage, pl.activity, pl.intensity, Game.cult.can_breakthrough(),
			int(pl.progress) / 5, int(Game.cult.age_years()), pl.injuries.size(), int(pl.stones) / 20, str(pl.attain.values())]


func _build_cultivate(v: VBoxContainer) -> void:
	var pl: Dictionary = Game.p()
	if Game.is_immortal():
		v.add_child(UI.wrap("You are a Gu Immortal. You no longer fill an aperture; you comprehend the Dao and gather dao marks. See the Immortal tab.", 16, UI.TEXT))
		var row := _flow(v)
		row.add_child(_act("Comprehend the Dao", func(): return Game.set_activity("cultivate")))
		row.add_child(_act("Closed-door (fast)", func(): return Game.set_activity("closed_door")))
		row.add_child(_act("Rest", func(): return Game.set_activity("rest")))
		_attain_section(v)
		return
	var rk := int(pl.rank)
	var s := _section(v, "Aperture — Rank %d %s" % [rk, Data.STAGES[int(pl.stage)]])
	var req := Data.stage_req(rk, int(pl.stage))
	var b := UI.bar(float(pl.progress), req, UI.JADE, 22)
	s.add_child(b)
	var why: String = Game.cult.can_breakthrough()
	var info := "Essence %d · Gu slots %d / %d · Aptitude %s" % [Game.max_essence(), Game.slots_used(), Game.slots_total(), Data.APTITUDE[pl.aptitude].label]
	s.add_child(UI.lbl(info, 14, UI.TEXT_DIM))
	if why == "":
		var kind := "rank breakthrough to Rank %d" % (rk + 1) if Game.cult.is_rank_breakthrough() else "breakthrough to %s stage" % Data.STAGES[mini(3, int(pl.stage) + 1)]
		if rk == 5 and int(pl.stage) == 3:
			kind = "immortal ascension (three tribulations)"
		var bb := UI.btn("Attempt %s  (%d%%)" % [kind, int(Game.cult.breakthrough_chance())], _breakthrough, "Key: B")
		bb.add_theme_color_override("font_color", UI.GOLD)
		bb.custom_minimum_size.y = 44
		s.add_child(bb)
		if Game.cult.is_rank_breakthrough() and rk >= 2 and not pl.trial_passed:
			s.add_child(UI.wrap("A rank breakthrough at Rank %d first requires defeating your heart demon in a trial." % rk, 14, UI.AMBER))
	else:
		var dtf: int = Game.cult.days_to_fill()
		s.add_child(UI.lbl(why + ("" if dtf <= 0 else "   About %d days at this pace." % dtf), 14, UI.TEXT_DIM))
	# activity
	var a := _section(v, "Activity")
	a.add_child(UI.lbl(Game.activity_text(), 15, UI.TEXT))
	var row2 := _flow(a)
	var busy: bool = pl.activity in ["travel", "refine", "mission"]
	var busy_why := "You are busy: %s" % Game.activity_text() if busy else ""
	row2.add_child(_act("Cultivate", func(): return Game.set_activity("cultivate"), "Fill your aperture with primeval essence.", busy_why))
	row2.add_child(_act("Closed-door", func(): return Game.set_activity("closed_door"), "Cultivate in seclusion: time passes 25x faster. Stop when you like.", busy_why))
	row2.add_child(_act("Rest", func(): return Game.set_activity("rest"), "Recover HP and heal injuries faster.", busy_why))
	row2.add_child(_act("Study %s" % Data.path_name(pl.primary_path), func(): return Game.set_activity("study", {"path": pl.primary_path}), "Raise attainment (doubled at a library).", busy_why))
	row2.add_child(_act("Idle", func(): return Game.set_activity("idle"), "Do nothing (aperture progress slowly decays).", busy_why))
	# intensity
	var it := _section(v, "Cultivation intensity")
	var row3 := _flow(it)
	for i in Data.INTENSITY.size():
		var d: Dictionary = Data.INTENSITY[i]
		var cost := int(d.stones) * rk
		var lab := "%s  (%s/day)" % [d.name, ("%d ◈" % cost) if cost > 0 else "free"]
		var bt := UI.btn(lab, func():
			pl.intensity = i
			_dirty = true
			refresh(true), "Progress x%s. Costs %d stones per day while cultivating.%s" % [str(d.points), cost,
			("\nRisk of qi deviation: about %s%% per day." % str(snappedf(float(d.get("risk", 0.0)) * 100.0, 0.1))) if float(d.get("risk", 0.0)) > 0.0 else ""])
		if int(pl.intensity) == i:
			bt.add_theme_stylebox_override("normal", UI.box(Color("4a3a28"), UI.GOLD, 2, 5, 8, 5))
			bt.add_theme_color_override("font_color", UI.GOLD)
		row3.add_child(bt)
	it.add_child(UI.wrap("Cultivation always leaves a week of Gu upkeep in reserve; if stones run short it drops to a cheaper intensity.", 13, UI.TEXT_DIM))
	# body
	var bd := _section(v, "Body")
	var band: Dictionary = Game.cult.age_band()
	bd.add_child(UI.lbl("Age %d, lifespan about %d years (%s). Cultivation x%.2f." % [int(Game.cult.age_years()), int(pl.lifespan_days) / Data.YEAR, band.name, Game.cult.cult_multiplier()], 14, UI.TEXT))
	if pl.injuries.size() > 0:
		var inj := []
		for x in pl.injuries:
			inj.append("%s (%dd)" % [x.name, int(x.days)])
		bd.add_child(UI.wrap("Injuries: " + ", ".join(inj), 14, UI.CRIMSON))
	if pl.specialization != "":
		bd.add_child(UI.lbl("Specialization: " + Data.path_name(pl.specialization), 14, UI.JADE))
	bd.add_child(UI.lbl("Alignment: %s · Fame %d · Information %d" % [Game.alignment_text(), int(pl.fame), int(pl.info)], 14, UI.TEXT_DIM))
	_attain_section(v)


func _attain_section(v: VBoxContainer) -> void:
	var pl: Dictionary = Game.p()
	var s := _section(v, "Path attainment")
	var keys: Array = pl.attain.keys().filter(func(k): return k != "none" and float(pl.attain[k]) > 0)
	keys.sort_custom(func(a, b): return float(pl.attain[a]) > float(pl.attain[b]))
	for path in keys:
		var pts := float(pl.attain[path])
		var ti := Data.tier_index(pts)
		var nxt: float = Data.TIER_POINTS[mini(4, ti + 1)]
		var h := UI.hbox()
		var nl := UI.rich(UI.path_tag(path))
		nl.custom_minimum_size.x = 150
		h.add_child(nl)
		var b := UI.bar(pts, nxt if ti < 4 else pts, Data.path_color(path), 16, false)
		UI.expand(b)
		h.add_child(b)
		var plays: int = Data.TIER_PLAYS[ti]
		h.add_child(UI.lbl("%s · %d/turn" % [Data.TIERS[ti], plays], 13, UI.TEXT_DIM))
		h.tooltip_text = "%d attainment points. Each tier lets you play more %s Gu per turn." % [int(pts), Data.path_name(path)]
		s.add_child(h)
	if Game.is_immortal():
		var d := _section(v, "Dao marks")
		var dk: Array = pl.dao.keys()
		if dk.is_empty():
			d.add_child(UI.lbl("None yet.", 14, UI.TEXT_DIM))
		for path in dk:
			d.add_child(UI.rich("%s: %d marks" % [UI.path_tag(path), int(pl.dao[path])]))


func _breakthrough() -> void:
	if not Game.has_run() or Game.combat != null:
		return
	var r: Dictionary = Game.breakthrough()
	match str(r.get("kind", "")):
		"specialize":
			main.dialogs.specialize()
		"tribulation":
			main.dialogs.tribulation()
		"trial":
			pass   # combat screen opens
		"blocked":
			main.toast(r.text, "warn")
		_:
			main.dialogs.notice("Breakthrough" if r.get("ok", false) else "Breakthrough failed", r.get("text", ""), r.get("ok", false))
	_dirty = true
	refresh(true)


# ============================================================== APERTURE ====
func _sig_aperture() -> String:
	var pl: Dictionary = Game.p()
	var parts := []
	for gi in pl.gu:
		parts.append("%d%s%d%s" % [int(gi.uid), "e" if gi.eq else "s", int(gi.get("unfed", 0)), str(gi.get("refined", 0))])
	return "%s|%s|%s|%s|%d|%s" % [",".join(parts), str(pl.mats), str(pl.formulas.size()), str(pl.killers), int(pl.stones) / 25, pl.rank]


func _build_aperture(v: VBoxContainer) -> void:
	var pl: Dictionary = Game.p()
	var s := _section(v, "Equipped Gu — your deck  (%d / %d slots)" % [Game.slots_used(), Game.slots_total()])
	s.add_child(UI.wrap("Equipped Gu become your combat deck. Each needs feeding every week (%d stones/week). Starving Gu weaken and finally die. Click a Gu for options." % Game.weekly_feed_cost(), 13, UI.TEXT_DIM))
	var grid := _flow(s)
	for gi in Game.equipped():
		grid.add_child(_gu_tile(gi))
	var st := _section(v, "Stored  (%d / %d)" % [Game.stored_count(), Game.storage_cap()])
	var grid2 := _flow(st)
	var stored := 0
	for gi in pl.gu:
		if not gi.eq:
			grid2.add_child(_gu_tile(gi))
			stored += 1
	if stored == 0:
		st.add_child(UI.lbl("Nothing in storage.", 14, UI.TEXT_DIM))
	# killer moves
	var km := _section(v, "Killer moves")
	if pl.killers.is_empty():
		km.add_child(UI.lbl("None known. Clans, mentors, inheritances and legacies teach them.", 14, UI.TEXT_DIM))
	for kid in pl.killers:
		if not Data.killers.has(kid):
			continue
		var k: Dictionary = Data.killers[kid]
		var comp: Dictionary = k.components
		var need := ("%d %s Gu" % [int(comp.count), comp.tag]) if comp.has("tag") else ("%d %s Gu" % [int(comp.count), Data.path_name(comp.get("path", "none"))])
		km.add_child(UI.rich("%s [b]%s[/b] — needs %s attainment and %s equipped. %s" % [UI.path_tag(k.path), k.name, k.need_tier, need, Data.describe_effects(k.effects)]))
	# materials
	var ms := _section(v, "Materials")
	var mk: Array = pl.mats.keys().filter(func(m): return int(pl.mats[m]) > 0)
	if mk.is_empty():
		ms.add_child(UI.lbl("None. Hunt beasts, gather on missions or buy them at markets.", 14, UI.TEXT_DIM))
	var mf := _flow(ms)
	for mid in mk:
		var md: Dictionary = Data.materials[mid]
		var chip := UI.panel(UI.PANEL_2, UI.RARITY_COLORS.get(md.tier, UI.GOLD_DIM), 6, 4)
		var hh := UI.hbox(4)
		hh.add_child(UI.icon(md.get("icon", "stone-pile"), 22, UI.RARITY_COLORS.get(md.tier, UI.TEXT)))
		hh.add_child(UI.lbl("%s ×%d" % [md.name, int(pl.mats[mid])], 13))
		chip.add_child(hh)
		chip.tooltip_text = "%s (%s%s). Sells for %d stones." % [md.name, md.tier, (", " + Data.path_name(str(md.path))) if str(md.get("path", "")) not in ["", "none", "<null>"] else "", Game.econ.sell_price_mat(mid)]
		mf.add_child(chip)
	# formulas
	var fs := _section(v, "Known refinement formulas (%d)" % pl.formulas.size())
	var ff := _flow(fs)
	for fid in pl.formulas:
		if not Data.formulas.has(fid):
			continue
		var f: Dictionary = Data.formulas[fid]
		var gd: Dictionary = Data.gu.get(f.id, {})
		var lab := UI.lbl("%s (R%d)" % [gd.get("name", f.id), int(f.rank)], 13, UI.TEXT if Game.econ.can_refine(fid) == "" else UI.TEXT_DIM)
		lab.tooltip_text = "Needs %d stones, %s, %d days. %s" % [int(f.stones), str(f.mats), int(f.days), Game.econ.can_refine(fid)]
		lab.mouse_filter = Control.MOUSE_FILTER_PASS
		ff.add_child(lab)
	fs.add_child(UI.wrap("Refine at any refinery from the Location tab.", 13, UI.TEXT_DIM))


func _gu_tile(gi: Dictionary) -> Control:
	var gd: Dictionary = Data.gu[gi.id]
	var card := UI.gu_card(gd, Game.gu_power(gi), 122, 168)
	var fs: String = Game.feed_state(gi)
	if fs != "fed":
		var warn := UI.lbl(fs.capitalize(), 12, UI.CRIMSON if fs in ["starving", "dying"] else UI.AMBER, true)
		warn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		card.get_child(0).add_child(warn)
	if float(gi.get("refined", 0.0)) > 0.0:
		card.tooltip_text += "\nRefined +%d%%" % int(round(float(gi.refined) * 100))
	card.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			Sfx.play("card")
			main.dialogs.gu_options(gi))
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return card


# ============================================================== LOCATION ====
func _sig_location() -> String:
	var pl: Dictionary = Game.p()
	var npcs := []
	for n in Game.world.npcs_here():
		npcs.append("%s%d" % [n.id, int(n.disp) / 10])
	return "%s|%s|%s|%d|%s|%s|%d" % [pl.location, pl.activity, ",".join(npcs), int(pl.stones) / 25, Game.standing_name(), pl.hp == Game.max_hp(), Game.s.markets.size()]


func _build_location(v: VBoxContainer) -> void:
	var pl: Dictionary = Game.p()
	var loc: Dictionary = Data.locations[pl.location]
	var head := UI.hbox()
	head.add_child(UI.icon(loc.get("icon", "village"), 48, map.TYPE_COLORS.get(loc.type, UI.TEXT)))
	var hv := UI.vbox(0)
	hv.add_child(UI.lbl(loc.name, 22, UI.GOLD, true))
	hv.add_child(UI.lbl("%s · danger %d · suits Rank %d-%d%s" % [loc.type.capitalize(), int(loc.get("danger", 1)), int(loc.rank[0]), int(loc.rank[1]), " · safe" if loc.get("safe", false) else ""], 13, UI.TEXT_DIM))
	head.add_child(hv)
	v.add_child(head)
	v.add_child(UI.wrap(loc.get("desc", ""), 15, UI.TEXT))
	if pl.activity == "travel":
		v.add_child(UI.lbl("You are on the road.", 15, UI.AMBER))
		return
	var svc: Array = loc.get("services", [])
	var s := _section(v, "Services")
	var row := _flow(s)
	for kind in Game.econ.market_kinds_here():
		var nm := {"market": "Market", "black_market": "Black Market", "caravan": "Caravan", "auction": "Auction House", "treasure_yellow_heaven": "Treasure Yellow Heaven"}.get(kind, kind)
		row.add_child(_act(nm, func(): main.dialogs.market(kind)))
	if "refinery" in svc or pl.get("in_land", false):
		row.add_child(_act("Refinery", func(): main.dialogs.refinery()))
	if "clan_hall" in svc and loc.get("clan", "") == pl.clan:
		row.add_child(_act("Clan Hall (missions)", func(): main.dialogs.missions()))
	if "inn" in svc:
		row.add_child(_act("Inn (%d ◈)" % Game.econ.inn_cost(), func(): return Game.econ.inn_rest(), "Sleep one night: full HP."))
	if "clinic" in svc or "inn" in svc or "clan_hall" in svc:
		row.add_child(_act("Healer (%d ◈)" % Game.econ.heal_cost(), func(): return Game.econ.heal_service(), "Restore HP and cure injuries."))
	if "library" in svc:
		row.add_child(_act("Tutor (%d ◈)" % Game.econ.tutor_cost(), func(): main.dialogs.tutor(), "Three days of drills: +25 attainment."))
	if "broker" in svc or "market" in svc:
		var mk: String = "market" if "market" in svc else Game.econ.market_kinds_here()[0] if Game.econ.market_kinds_here().size() > 0 else ""
		if mk != "":
			row.add_child(_act("Buy information (%d ◈)" % int(Game.econ.market(mk).info_price), func():
				var r: String = Game.econ.buy_info(mk)
				if r != "" and not r.begins_with("Not enough"):
					main.dialogs.notice("Rumour", r)
					return ""
				return r, "Rumours about places, people and coming epochs."))
	if "arena" in svc:
		row.add_child(_act("Arena bout", func(): return _arena(), "Fight a ranked opponent for fame and stones."))
	if row.get_child_count() == 0:
		s.add_child(UI.lbl("No services here.", 14, UI.TEXT_DIM))
	# danger
	var d := _section(v, "Venture out")
	var row2 := _flow(d)
	if loc.get("safe", false):
		row2.add_child(_act("Hunt", func(): return "", "", "This place is safe; nothing to hunt."))
	else:
		row2.add_child(_act("Hunt the area", func(): return Game.hunt(), "Seek out beasts or bandits: loot, materials and attainment."))
	if pl.get("caches", []).size() > 0:
		for c in pl.caches:
			if not c.claimed and c.loc == pl.location:
				row2.add_child(_act("Dig up your past-life cache", func():
					c.claimed = true
					pl.stones = int(pl.stones) + int(c.stones)
					Game.add_log("You unearth the cache from a past life: +%d stones." % int(c.stones), "great")
					Sfx.play("coin")
					return ""))
	row2.add_child(_act("Travel…", func(): main.dialogs.travel_list()))
	# people
	var ppl := _section(v, "People here")
	var here: Array = Game.world.npcs_here()
	if here.is_empty():
		ppl.add_child(UI.lbl("Nobody of note.", 14, UI.TEXT_DIM))
	for n in here:
		ppl.add_child(_npc_row(n, true))


func _arena() -> String:
	var pl: Dictionary = Game.p()
	var defs: Array = Game.enemies_from_group("bandit", int(pl.rank), 1, "elite")
	if defs.is_empty():
		return "No challengers today."
	defs[0]["name"] = "Arena Champion"
	Game.start_combat({"enemies": defs, "env": [], "flee_allowed": true, "duel": "", "title": "Arena Bout"})
	return ""


func _npc_row(n: Dictionary, here: bool) -> Control:
	var p := UI.panel(UI.PANEL_2, UI.GOLD_DIM, 8)
	var h := UI.hbox()
	p.add_child(h)
	var arch: Dictionary = Data.archetypes.get(n.arch, {"name": n.arch})
	h.add_child(UI.icon(n.get("icon", "hood"), 38, Data.path_color(n.get("path", "none")).lightened(0.3)))
	var v := UI.vbox(1)
	UI.expand(v)
	v.add_child(UI.lbl("%s  ·  %s, Rank %d" % [n.name, arch.get("name", ""), int(n.rank)], 15, UI.TEXT, true))
	var band: String = Game.world.band(int(n.disp))
	var col := UI.JADE if int(n.disp) >= 20 else (UI.CRIMSON if int(n.disp) <= -20 else UI.TEXT_DIM)
	var where = "" if here else "  ·  at " + Data.locations.get(n.loc, {"name": "?"}).name
	v.add_child(UI.lbl("%s (%+d) · %s%s" % [band, int(n.disp), n.relation, where], 13, col))
	h.add_child(v)
	if here:
		h.add_child(UI.btn("Interact", func(): main.dialogs.npc(n.id)))
	p.tooltip_text = "%s. Personality: %s. Wants %s." % [arch.get("desc", ""), n.get("personality", "?"), n.get("desire", "?")]
	return p


# ================================================================ PEOPLE ====
func _known() -> Array:
	return Game.known_npcs().map(func(id): return Game.s.npcs[id])


func _sig_people() -> String:
	var parts := []
	for n in _known():
		parts.append("%s%d%s%s" % [n.id, int(n.disp) / 5, n.loc, n.alive])
	return ",".join(parts) + Game.p().location


func _build_people(v: VBoxContainer) -> void:
	var known: Array = _known()
	v.add_child(UI.wrap("People you have met. Disposition grows with talk, gifts and help; at 50+ they may stand with you in a tribulation.", 13, UI.TEXT_DIM))
	if known.is_empty():
		v.add_child(UI.lbl("You have not met anyone yet.", 15, UI.TEXT_DIM))
	known.sort_custom(func(a, b): return int(a.disp) > int(b.disp))
	for n in known:
		if not n.alive:
			continue
		v.add_child(_npc_row(n, n.loc == Game.p().location))


# ================================================================= GOALS ====
func _sig_goals() -> String:
	var parts := []
	for g in Game.s.goals:
		var pr: Array = Game.world.goal_progress(g)
		parts.append("%s%s%s%s" % [g.id, g.primary, g.done, str(pr)])
	return ",".join(parts) + str(Game.world.upcoming_epochs().size())


func _build_goals(v: VBoxContainer) -> void:
	v.add_child(UI.wrap("Goals steer which events, Gu and opportunities find you. Your primary goal counts most. Up to three at once.", 13, UI.TEXT_DIM))
	var active: Array = Game.s.goals.filter(func(g): return not g.done)
	for g in active:
		var p := UI.panel(UI.PANEL_2, UI.GOLD if g.primary else UI.GOLD_DIM, 8)
		var gv := UI.vbox(3)
		p.add_child(gv)
		var h := UI.hbox()
		h.add_child(UI.lbl(("★ " if g.primary else "") + g.name, 16, UI.GOLD if g.primary else UI.TEXT, true))
		h.add_child(UI.expand(UI.spacer()))
		if not g.primary:
			h.add_child(_act("Make primary", func(): Game.world.set_primary(g.id)))
		h.add_child(_act("Drop", func(): Game.world.remove_goal(g.id)))
		gv.add_child(h)
		gv.add_child(UI.lbl(g.desc, 14, UI.TEXT_DIM))
		var pr: Array = Game.world.goal_progress(g)
		gv.add_child(UI.bar(float(pr[0]), float(pr[1]), UI.JADE, 14))
		v.add_child(p)
	if active.size() < 3:
		var s := _section(v, "Add a goal")
		var f := _flow(s)
		for gt in Data.goal_types:
			if gt.id in ["prepare"] and Game.world.upcoming_epochs().is_empty():
				continue
			f.add_child(_act(gt.name.format({"path": Data.path_name(Game.p().primary_path), "kind": "movement", "n": "", "event": "an epoch"}).replace("  ", " "),
					func(): main.dialogs.add_goal(gt), gt.desc.format({"path": "a path", "kind": "certain", "n": "several", "event": "it"})))
	var done: Array = Game.s.goals.filter(func(g): return g.done)
	if done.size() > 0:
		var ds := _section(v, "Completed")
		for g in done.slice(maxi(0, done.size() - 6)):
			ds.add_child(UI.lbl("✓ " + g.name, 14, UI.JADE))
	var ep: Array = Game.world.upcoming_epochs()
	var es := _section(v, "Signs of coming epochs")
	if ep.is_empty():
		es.add_child(UI.lbl("The world is quiet. Buy information to hear rumours.", 14, UI.TEXT_DIM))
	for e in ep:
		es.add_child(UI.wrap("%s — %s (about %d years away)" % [e.name, e.signs, maxi(0, int(e.in_years))], 14, UI.AMBER))


# =============================================================== JOURNAL ====
func _sig_journal() -> String:
	return str(Game.s.log.size())


func _build_journal(v: VBoxContainer) -> void:
	var st: Dictionary = Game.s.stats
	v.add_child(UI.lbl("Battles %d (won %d, fled %d) · Bosses %d · Events %d · Gu refined %d · Tribulations %d" % [int(st.battles), int(st.wins), int(st.fled), int(st.bosses), int(st.events), int(st.gu_refined), int(st.tribulations)], 13, UI.TEXT_DIM))
	var lines := []
	var lg: Array = Game.s.log
	for i in range(lg.size() - 1, maxi(-1, lg.size() - 220), -1):
		var e: Dictionary = lg[i]
		var c: Color = UI.LOG_COLORS.get(e.get("kind", "info"), UI.TEXT)
		lines.append("[color=#%s]%s[/color]  [color=#%s]%s[/color]" % [UI.hex(UI.TEXT_DIM), "Y%d" % (int(Game.s.world_start_year) + int(e.get("day", 0)) / Data.YEAR), UI.hex(c), e.text])
	var r := UI.rich("\n".join(lines))
	v.add_child(r)


# ============================================================== IMMORTAL ====
func _sig_immortal() -> String:
	if not Game.is_immortal() or Game.s.blessed == null:
		return "-"
	var b: Dictionary = Game.s.blessed
	return "%s|%s|%s|%d|%s|%s|%s" % [str(b.nodes), str(b.structures), b.grade, int(Game.p().istones), Game.dao_total() / 10, Game.p().faction, Game.p().location]


func _build_immortal(v: VBoxContainer) -> void:
	if not Game.is_immortal() or Game.s.blessed == null:
		v.add_child(UI.lbl("Reach Rank 6 to open a blessed land.", 15, UI.TEXT_DIM))
		return
	var pl: Dictionary = Game.p()
	var b: Dictionary = Game.s.blessed
	var im = Game.immortal
	v.add_child(UI.lbl(b.name, 22, UI.GOLD, true))
	var days_left := int(b.next_trib) - int(Game.s.day)
	v.add_child(UI.lbl("Grade %d · next tribulation in %d days · %d tribulations weathered" % [int(b.grade), maxi(0, days_left), int(b.trib_count)], 14, UI.TEXT_DIM))
	# advancement
	var adv := _section(v, "Advancement to %s" % (Data.rank_title(int(pl.rank) + 1) if int(pl.rank) < 9 else "—"))
	for req in im.rank_up_requirements():
		adv.add_child(UI.lbl(("✓ " if req[1] else "✗ ") + req[0], 14, UI.JADE if req[1] else UI.CRIMSON))
	var row := _flow(adv)
	row.add_child(_act("Challenge heaven", func():
		var r: Dictionary = Game.breakthrough()
		if r.get("kind", "") == "blocked":
			return r.text
		return ""))
	row.add_child(_act("Seek an ancient inheritance", func(): return im.seek_inheritance(), "Rank 7+, in the Central Continent."))
	# faction
	if pl.faction == "":
		var fs := _section(v, "Choose your allegiance")
		var fr := _flow(fs)
		for fid in im.FACTIONS:
			var fd: Dictionary = im.FACTIONS[fid]
			fr.add_child(_act(fd.name, func(): im.choose_faction(fid), fd.desc))
	else:
		v.add_child(UI.lbl("Allegiance: %s" % im.FACTIONS.get(pl.faction, {"name": pl.faction}).name, 14, UI.TEXT))
	# resource points
	var ns := _section(v, "Resource points")
	for i in b.nodes.size():
		var n: Dictionary = b.nodes[i]
		var md: Dictionary = Data.materials.get(n.mat, {"name": n.mat})
		var h := UI.hbox()
		h.add_child(UI.lbl("%s · level %d · stock %.1f" % [md.name, int(n.level), float(n.stock)], 14))
		h.add_child(UI.expand(UI.spacer()))
		h.add_child(_act("Upgrade (%d ✦)" % im.node_upgrade_cost(i), func(): return im.upgrade_node(i)))
		ns.add_child(h)
	var nr := _flow(ns)
	nr.add_child(_act("Harvest all", func():
		var r: String = im.harvest()
		if r != "":
			main.toast(r, "good")
		return ""))
	nr.add_child(_act("Nurture the land (%d ✦)" % im.nurture_cost(), func(): return im.nurture(), "Raise the land's grade."))
	nr.add_child(_act("Annex territory", func(): return im.annex(), "Add a resource point."))
	if "beast_pen" in Game.s.blessed.structures:
		nr.add_child(_act("Raise a beast (15 ✦) · %d/3" % Game.s.blessed.beasts.size(), func(): return im.raise_beast(), "Immortal beasts weaken tribulations by 5% each."))
	# structures
	var ss := _section(v, "Structures")
	var sf := _flow(ss)
	for sid in im.STRUCTURES:
		var sd: Dictionary = im.STRUCTURES[sid]
		if sid in b.structures:
			var l := UI.lbl("✓ " + sd.name, 14, UI.JADE)
			l.tooltip_text = sd.desc
			l.mouse_filter = Control.MOUSE_FILTER_PASS
			sf.add_child(l)
		else:
			sf.add_child(_act("Build %s (%d ✦)" % [sd.name, int(sd.cost)], func(): return im.build(sid), sd.desc))
	# planting
	var ps := _section(v, "Plant a material")
	var pf := _flow(ps)
	for mid in pl.mats.keys():
		if int(pl.mats[mid]) > 0 and mid != "immortal_stone":
			pf.add_child(_act("Plant %s" % Data.materials[mid].name, func(): return im.plant(mid), "Turn it into a new resource point."))
	if pf.get_child_count() == 0:
		ps.add_child(UI.lbl("No materials to plant.", 14, UI.TEXT_DIM))
	# guests
	if "guest_pavilion" in b.structures:
		var gs := _section(v, "Invite a guest")
		var gf := _flow(gs)
		for n in _known():
			if n.alive and int(n.disp) >= 20:
				gf.add_child(_act(n.name, func(): return im.invite_guest(n.id)))
