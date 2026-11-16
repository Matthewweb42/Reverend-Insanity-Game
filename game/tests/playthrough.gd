extends SceneTree
## Headless playthrough: the bot plays whole lives, from character creation to an ending.
## Usage: godot --headless --path game --script res://tests/playthrough.gd -- [runs] [seed]

func _initialize() -> void:
	await process_frame
	var G = root.get_node("Game")
	var M = root.get_node("Meta")
	M.reset_for_tests()
	M.d.settings.sandbox = true
	G.headless = true
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if args.size() > 0 else 3
	var seed0 := int(args[1]) if args.size() > 1 else 1000
	var clans := ["gu_yue", "bai", "xiong", "shang", "wu", "chi"]
	var ok := true
	var results := []
	for i in runs:
		var t0 := Time.get_ticks_msec()
		G.new_game({"name": "Bot %d" % i, "clan": clans[i % clans.size()], "seed": seed0 + i, "mode": "normal"})
		var bot = load("res://core/bot.gd").new(G)
		var res: Dictionary = bot.play_life()
		var cause := str(G.s.get("ended_cause", ""))
		var line := "run %d clan=%s ended=%s day=%d years=%.1f rank=%d max=%d stones=%d wins=%d/%d events=%d killers=%d steps=%d ms=%d log_end=%s" % [
				i, G.s.player.clan, res.ended, res.day, res.day / 360.0, res.rank, int(G.s.stats.max_rank), int(G.s.player.stones),
				int(G.s.stats.wins), int(G.s.stats.battles), int(G.s.stats.events), int(G.s.stats.killers), res.steps,
				Time.get_ticks_msec() - t0, str(G.s.log[-1].text if G.s.log.size() > 0 else "")]
		print(line)
		results.append(res)
		if not res.ended:
			ok = false
	print("PLAYTHROUGH ", "OK" if ok else "FAILED")
	quit(0 if ok else 1)
