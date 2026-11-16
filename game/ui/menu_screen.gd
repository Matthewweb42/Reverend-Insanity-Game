extends Control
## Title screen: continue, new life, load, legacy vault, records, settings, credits, quit.

var main


func _ready() -> void:
	var root := UI.hbox(0)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(UI.spacer(120))
	var col := UI.vbox(10)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size.x = 480
	root.add_child(col)
	var t1 := UI.lbl("REVEREND INSANITY", 58, UI.GOLD, true)
	col.add_child(t1)
	var t2 := UI.lbl("Path of the Gu Master", 26, UI.TEXT_DIM)
	t2.add_theme_font_override("font", UI.font_italic)
	col.add_child(t2)
	col.add_child(UI.wrap("A roguelike deckbuilder of Gu, cultivation and a single mortal lifespan.", 16, UI.TEXT_DIM))
	col.add_child(UI.spacer(0, 24))
	var saves: Array = Game.list_saves()
	saves.sort_custom(func(a, b): return str(a.get("saved", "")) > str(b.get("saved", "")))
	if saves.size() > 0:
		var s: Dictionary = saves[0]
		var b := _big("Continue", func():
			if Game.load_game(int(s.slot)) == "":
				main.show_world())
		b.tooltip_text = "%s, %s, Rank %d (%s)" % [s.name, Data.clans.get(s.clan, {"name": s.clan}).name, int(s.rank), s.date]
		col.add_child(b)
	col.add_child(_big("New Life", main.show_new_game))
	if saves.size() > 0:
		col.add_child(_big("Load", func(): main.dialogs.load_dialog()))
	col.add_child(_big("Legacy Vault  (%s points)" % UI.num(Meta.d.points), func(): main.dialogs.vault()))
	col.add_child(_big("Records", func(): main.dialogs.records()))
	col.add_child(_big("Settings", func(): main.dialogs.settings()))
	col.add_child(_big("Credits", func(): main.dialogs.credits()))
	col.add_child(_big("Quit", func(): get_tree().quit()))
	col.add_child(UI.spacer(0, 20))
	var st: Dictionary = Meta.d.stats
	if int(st.runs) > 0:
		col.add_child(UI.lbl("Lives lived: %d   Best rank: %d   Venerables: %d" % [int(st.runs), int(st.best_rank), int(st.victories)], 14, UI.TEXT_DIM))
	col.add_child(UI.lbl("v%s  ·  Built with Godot  ·  Fan project, not affiliated with the novel's author" % ProjectSettings.get_setting("application/config/version", "0.1"), 12, UI.TEXT_DIM))
	root.add_child(UI.spacer(0, 0, true))
	# a big emblem on the right
	var emb := UI.vbox(0)
	emb.alignment = BoxContainer.ALIGNMENT_CENTER
	emb.custom_minimum_size.x = 620
	root.add_child(emb)
	var ic := UI.icon("butterfly", 360, Color(UI.GOLD, 0.22))
	emb.add_child(ic)
	var tw := create_tween().set_loops()
	tw.tween_property(ic, "modulate:a", 0.12, 3.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(ic, "modulate:a", 0.22, 3.0).set_trans(Tween.TRANS_SINE)
	var quote := UI.lbl("\"Spring and autumn pass; only the Gu remains.\"", 18, UI.TEXT_DIM)
	quote.add_theme_font_override("font", UI.font_italic)
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emb.add_child(quote)
	root.add_child(UI.spacer(60))


func _big(text: String, cb: Callable) -> Button:
	var b := UI.btn(text, cb)
	b.custom_minimum_size = Vector2(360, 48)
	b.add_theme_font_override("font", UI.font_head_bold)
	b.add_theme_font_size_override("font_size", 20)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return b
