extends Control
## Character creation: name, region, clan, start, mode, aptitude roll and the legacies you carry.

var main
var opts := {"name": "", "clan": "gu_yue", "start": "standard", "mode": "normal", "region": "southern_border"}
var apt := "C"
var rerolls := 2
var name_edit: LineEdit
var clan_box: GridContainer
var detail: RichTextLabel
var start_box: VBoxContainer
var mode_box: HBoxContainer
var region_box: HBoxContainer
var apt_label: Label
var apt_btn: Button
var legacy_box: VBoxContainer
var rng := RandomNumberGenerator.new()

const REGIONS := [
	{"id": "southern_border", "name": "Southern Border", "desc": "Mountain clans, beast tides and petty feuds. Where every life begins.", "need": ""},
	{"id": "northern_plains", "name": "Northern Plains", "desc": "You start knowing the road to the Northern Plains, with its wealthier markets.", "need": "Reach Rank 6 in any life."},
	{"id": "central_continent", "name": "Central Continent", "desc": "You start knowing the way to the Central Continent, seat of sects and immortals.", "need": "Reach Rank 7 in any life."},
]


func _ready() -> void:
	rng.randomize()
	apt = Game.roll_aptitude(rng)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + k, 36)
	add_child(m)
	var v := UI.vbox(10)
	m.add_child(v)
	var top := UI.hbox()
	top.add_child(UI.heading("A New Life", 34))
	top.add_child(UI.expand(UI.spacer()))
	top.add_child(UI.btn("Back", main.show_menu))
	v.add_child(top)
	var body := UI.hbox(18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	# left column: identity
	var left := UI.vbox(10)
	left.custom_minimum_size.x = 420
	body.add_child(left)
	left.add_child(UI.lbl("Name", 15, UI.TEXT_DIM))
	var nh := UI.hbox()
	name_edit = LineEdit.new()
	name_edit.text = Game.world.random_name() if Game.world else "Fang Yuan"
	name_edit.max_length = 28
	UI.expand(name_edit)
	nh.add_child(name_edit)
	nh.add_child(UI.btn("Random", func(): name_edit.text = Game.world.random_name()))
	left.add_child(nh)
	left.add_child(UI.lbl("Region", 15, UI.TEXT_DIM))
	region_box = UI.hbox(6)
	left.add_child(region_box)
	left.add_child(UI.lbl("Start", 15, UI.TEXT_DIM))
	start_box = UI.vbox(4)
	left.add_child(start_box)
	left.add_child(UI.lbl("Mode", 15, UI.TEXT_DIM))
	mode_box = UI.hbox(6)
	left.add_child(mode_box)
	left.add_child(UI.lbl("Aptitude", 15, UI.TEXT_DIM))
	var ah := UI.hbox()
	apt_label = UI.lbl("", 22, UI.GOLD, true)
	ah.add_child(apt_label)
	ah.add_child(UI.expand(UI.spacer()))
	apt_btn = UI.btn("Reroll", _reroll, "Your aperture's talent sets how fast you cultivate.")
	ah.add_child(apt_btn)
	left.add_child(ah)
	left.add_child(UI.lbl("Legacies carried into this life", 15, UI.TEXT_DIM))
	legacy_box = UI.vbox(3)
	left.add_child(legacy_box)
	left.add_child(UI.btn("Open the Legacy Vault", func(): main.dialogs.vault(func(): _refresh())))
	# middle: clans
	var mid := UI.vbox(8)
	UI.expand(mid, true, true)
	body.add_child(mid)
	mid.add_child(UI.lbl("Clan", 15, UI.TEXT_DIM))
	clan_box = GridContainer.new()
	clan_box.columns = 3
	clan_box.add_theme_constant_override("h_separation", 10)
	clan_box.add_theme_constant_override("v_separation", 10)
	mid.add_child(clan_box)
	var dp := UI.panel(UI.PANEL, UI.GOLD_DIM, 14)
	UI.expand(dp, true, true)
	detail = UI.rich("", false)
	UI.expand(detail, true, true)
	dp.add_child(detail)
	mid.add_child(dp)
	var go := UI.btn("Begin This Life", _begin)
	go.custom_minimum_size = Vector2(320, 54)
	go.add_theme_font_override("font", UI.font_head_bold)
	go.add_theme_font_size_override("font_size", 22)
	go.size_flags_horizontal = Control.SIZE_SHRINK_END
	mid.add_child(go)
	_refresh()


func _refresh() -> void:
	apt_label.text = "%s  ·  %s" % [apt, Data.APTITUDE[apt].label]
	apt_label.add_theme_color_override("font_color", {"A": UI.AMBER, "B": UI.JADE, "C": UI.TEXT, "D": UI.TEXT_DIM}[apt])
	apt_btn.text = "Reroll (%d left)" % rerolls
	apt_btn.disabled = rerolls <= 0 or opts.start == "prodigy"
	# regions
	UI.clear(region_box)
	for r in REGIONS:
		var ok: bool = Meta.is_unlocked("regions", r.id)
		var b := _choice(r.name, opts.region == r.id, ok, r.desc if ok else "Locked: " + r.need)
		b.pressed.connect(func():
			opts.region = r.id
			_refresh())
		region_box.add_child(b)
	# starts
	UI.clear(start_box)
	for st in Data.starts:
		var ok2: bool = Meta.is_unlocked("starts", st.id)
		var b2 := _choice(st.name, opts.start == st.id, ok2, st.desc if ok2 else "Locked: " + Meta.unlock_text(st.unlock))
		b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b2.pressed.connect(func():
			opts.start = st.id
			if st.id == "prodigy":
				apt = "A"
			_refresh())
		start_box.add_child(b2)
	# modes
	UI.clear(mode_box)
	for md in Data.modes:
		var ok3: bool = Meta.is_unlocked("modes", md.id)
		var b3 := _choice(md.name, opts.mode == md.id, ok3, md.desc if ok3 else "Locked: reach Rank 3 (Speed, Path Challenge) or Rank 5 (Hard, Ironman), or win once.")
		b3.pressed.connect(func():
			opts.mode = md.id
			_refresh())
		mode_box.add_child(b3)
	# legacy
	UI.clear(legacy_box)
	if Meta.d.pending.is_empty():
		legacy_box.add_child(UI.lbl("None. Earn points by living, then spend them in the vault.", 14, UI.TEXT_DIM))
	for id in Meta.d.pending:
		legacy_box.add_child(UI.lbl("•  " + Meta.inheritance_def(id).get("name", id), 15, UI.JADE))
	# clans
	UI.clear(clan_box)
	for c in Data.clan_list:
		clan_box.add_child(_clan_card(c))
	_show_clan(Data.clans[opts.clan])


func _choice(text: String, selected: bool, ok: bool, tip: String) -> Button:
	var b := Button.new()
	b.text = text if ok else text + " (locked)"
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not ok
	b.tooltip_text = tip
	if selected:
		b.add_theme_stylebox_override("normal", UI.box(Color("4a3a28"), UI.GOLD, 2, 5, 8, 5))
		b.add_theme_color_override("font_color", UI.GOLD)
	return b


func _clan_card(c: Dictionary) -> Control:
	var ok: bool = Meta.is_unlocked("clans", c.id)
	var sel: bool = opts.clan == c.id
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(200, 118)
	b.toggle_mode = false
	var pc := Data.path_color(c.primary)
	b.add_theme_stylebox_override("normal", UI.box(Color("1d1814").lerp(pc, 0.12 if ok else 0.0), UI.GOLD if sel else UI.GOLD_DIM, 2 if sel else 1, 8, 8))
	b.add_theme_stylebox_override("hover", UI.box(Color("2a221b").lerp(pc, 0.18), UI.GOLD, 1, 8, 8))
	b.add_theme_stylebox_override("disabled", UI.box(Color("15110e"), Color("3a3127"), 1, 8, 8))
	b.disabled = not ok
	b.tooltip_text = c.desc if ok else "Locked: " + Meta.unlock_text(c.unlock)
	var v := UI.vbox(2)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(v)
	var ic := UI.icon(c.icon, 44, pc.lightened(0.3) if ok else UI.TEXT_DIM)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var n := UI.lbl(c.name, 16, UI.GOLD if sel else (UI.TEXT if ok else UI.TEXT_DIM), true)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var s := UI.lbl(c.theme if ok else "Locked", 12, UI.TEXT_DIM)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	b.pressed.connect(func():
		Sfx.play("click")
		opts.clan = c.id
		_refresh())
	b.mouse_entered.connect(func(): _show_clan(c))
	b.mouse_exited.connect(func(): _show_clan(Data.clans[opts.clan]))
	return b


func _show_clan(c: Dictionary) -> void:
	var ok: bool = Meta.is_unlocked("clans", c.id)
	var t := "[font_size=24][color=#%s]%s[/color][/font_size]   [i]%s[/i]\n" % [UI.hex(UI.GOLD), c.name, c.theme]
	t += "%s\n\n" % c.desc
	var paths := []
	for p in c.paths:
		paths.append(UI.path_tag(p))
	t += "[b]Paths:[/b] %s   [b]Primary:[/b] %s\n" % [", ".join(paths), UI.path_tag(c.primary)]
	t += "[b]Starts with:[/b] %s primeval stones, age %d\n" % [UI.num(c.stones), int(c.age)]
	var gus := []
	for g in c.start_gu:
		if Data.gu.has(g):
			gus.append(Data.gu[g].name)
	t += "[b]Starting Gu:[/b] %s\n" % ", ".join(gus)
	if c.km != null and str(c.km) != "" and Data.killers.has(c.km):
		t += "[b]Clan killer move:[/b] %s (needs %s attainment)\n" % [Data.killers[c.km].name, Data.killers[c.km].need_tier]
	if c.get("rival") != null and Data.clans.has(str(c.rival)):
		t += "[b]Rival clan:[/b] %s\n" % Data.clans[str(c.rival)].name
	if not ok:
		t += "\n[color=#%s]Locked: %s[/color]" % [UI.hex(UI.CRIMSON), Meta.unlock_text(c.unlock)]
	detail.text = t


func _reroll() -> void:
	if rerolls <= 0:
		return
	rerolls -= 1
	apt = Game.roll_aptitude(rng)
	Sfx.play("coin")
	_refresh()


func _begin() -> void:
	var nm := name_edit.text.strip_edges()
	if nm == "":
		nm = Game.world.random_name()
	main.start_run({"name": nm, "clan": opts.clan, "start": opts.start, "mode": opts.mode, "aptitude": apt,
			"region": opts.region, "legacy": true})
