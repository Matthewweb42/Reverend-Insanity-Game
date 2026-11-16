extends SceneTree
func _initialize() -> void:
	await process_frame
	var G = root.get_node("Game")
	root.get_node("Meta").reset_for_tests()
	G.headless = true
	G.new_game({"clan": "gu_yue", "seed": 1000})
	var bot = load("res://core/bot.gd").new(G)
	var lastd = -1
	var n = 0
	while G.has_run() and n < 20000:
		bot.step(); n += 1
		var d = int(G.s.day)
		if d % 30 == 0 and d != lastd:
			lastd = d
			var pl = G.s.player
			print("d%d r%d.%d prog %.0f/%.0f stones %d feed/wk %d hp %d/%d act %s battles %d/%d loc %s gu %d" % [d, pl.rank, pl.stage, pl.progress, root.get_node("Data").stage_req(pl.rank, pl.stage), pl.stones, G.weekly_feed_cost(), pl.hp, G.max_hp(), pl.activity, G.s.stats.wins, G.s.stats.battles, pl.location, pl.gu.size()])
	for l in G.s.log.slice(-25): print("  ", l.text)
	quit()
