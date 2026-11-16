extends SceneTree
## UI smoke test: builds the real interface, opens every screen and dialog, auto-plays for a
## while and (when run with a display) saves screenshots.
## Usage: godot --path game --script res://tests/ui_smoke.gd -- [shot_dir] [bot_seconds]

var shots := ""
var main


func _shot(name: String) -> void:
	for i in 3:
		await process_frame
	if shots == "" or DisplayServer.get_name() == "headless":
		return
	var img: Image = root.get_texture().get_image()
	img.save_png("%s/%s.png" % [shots, name])
	print("shot ", name)


func _initialize() -> void:
	await process_frame
	var G = root.get_node("Game")
	var M = root.get_node("Meta")
	M.reset_for_tests()
	M.d.settings.sandbox = true
	M.d.settings.tutorial = false
	var args := OS.get_cmdline_user_args()
	shots = args[0] if args.size() > 0 else ""
	var bot_secs := float(args[1]) if args.size() > 1 else 20.0
	root.size = Vector2i(1440, 810)
	main = load("res://ui/Main.tscn").instantiate()
	root.add_child(main)
	await _shot("01_menu")
	main.dialogs.settings()
	await _shot("02_settings")
	main.close_modal(main.modals[-1])
	main.dialogs.vault()
	await _shot("03_vault")
	main._close_all_modals()
	main.dialogs.records()
	main._close_all_modals()
	main.dialogs.credits()
	await _shot("04_credits")
	main._close_all_modals()
	main.show_new_game()
	await _shot("05_new_game")
	main.start_run({"name": "Fang Yuan", "clan": "gu_yue", "start": "standard", "mode": "normal", "region": "southern_border", "seed": 7})
	await _shot("06_world")
	var w = main.world
	for i in w.tabs.get_tab_count():
		w.tabs.current_tab = i
		w.refresh(true)
		await _shot("07_tab_%d" % i)
	main.dialogs.tutorial()
	await _shot("08_tutorial")
	main._close_all_modals()
	var pl = G.p()
	if pl.gu.size() > 0:
		main.dialogs.gu_options(pl.gu[0])
		await _shot("09_gu")
		main._close_all_modals()
	main.dialogs.market("market")
	await _shot("10_market")
	main._close_all_modals()
	main.dialogs.refinery()
	await _shot("11_refinery")
	main._close_all_modals()
	main.dialogs.missions()
	main._close_all_modals()
	main.dialogs.tutor()
	main._close_all_modals()
	main.dialogs.travel_list()
	await _shot("12_travel")
	main._close_all_modals()
	var others = G.p().known_locs.filter(func(x): return x != G.p().location)
	if others.size() > 0:
		main.dialogs.travel(others[0])
		main._close_all_modals()
	var npcs = G.world.npcs_here()
	if npcs.size() > 0:
		main.dialogs.npc(npcs[0].id)
		await _shot("13_npc")
		main._close_all_modals()
	for gt in root.get_node("Data").goal_types:
		main.dialogs.add_goal(gt)
		main._close_all_modals()
	main._close_all_modals()
	main.dialogs.specialize()
	main._close_all_modals()
	main.dialogs.pause_menu()
	await _shot("14_pause")
	main._close_all_modals()
	main.dialogs.load_dialog()
	main._close_all_modals()
	# a fight
	w._arena()
	await _shot("15_combat")
	if main.combat_ui:
		for i in 6:
			main.combat_ui.bot_step()
			await _shot("16_combat_%d" % i)
	# an event
	main._close_all_modals()
	if main.combat_ui:
		for i in 60:
			if main.combat_ui == null:
				break
			main.combat_ui.bot_step()
			await process_frame
	print("after combat loop mem=", OS.get_static_memory_usage() / 1048576)
	var ev = G.debug_event() if G.has_method("debug_event") else {}
	if not ev.is_empty():
		main.dialogs.event(ev)
		await _shot("17_event")
		main._close_all_modals()
	# auto-play
	main.toggle_bot()
	var t0 := Time.get_ticks_msec()
	var n := 0
	while Time.get_ticks_msec() - t0 < bot_secs * 1000.0:
		await process_frame
		n += 1
		if n % 100 == 0:
			print("frame ", n, " mem=", OS.get_static_memory_usage() / 1048576, "MB nodes=", Performance.get_monitor(Performance.OBJECT_NODE_COUNT), " day=", G.s.day if G.has_run() else -1, " combat=", G.combat != null, " modals=", main.modals.size())
		if n % 600 == 0:
			await _shot("18_bot_%d" % (n / 600))
		if not G.has_run():
			break
	await _shot("19_end")
	print("UI SMOKE OK frames=", n, " ran=", G.has_run(), " day=", G.s.day if G.has_run() else -1, " rank=", G.p().rank if G.has_run() else -1, " modals=", main.modals.size())
	quit(0)
