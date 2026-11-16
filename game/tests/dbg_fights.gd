extends SceneTree
func _initialize() -> void:
	await process_frame
	var G = root.get_node("Game")
	var D = root.get_node("Data")
	root.get_node("Meta").reset_for_tests()
	G.headless = true
	for clan in ["gu_yue", "bai", "xiong", "shang", "wu", "chi"]:
		var res = {}
		for i in 40:
			G.new_game({"clan": clan, "seed": 500 + i})
			var home = D.locations[D.clans[clan].home]
			var groups = []
			for l in D.locations.values():
				if int(l.rank[0]) <= 1 and l.get("enemies", []).size() > 0:
					groups += l.enemies
			var grp = groups[i % groups.size()]
			G.start_combat({"enemies": G.enemies_from_group(grp, 1, 1), "env": [], "flee_allowed": false})
			var names = G.combat.enemies.map(func(e): return e.name)
			var guard = 0
			while G.combat.result == "" and guard < 60:
				guard += 1
				G.combat.auto_turn()
			var k = str(names[0])
			if not res.has(k): res[k] = [0, 0, 0]
			res[k][1] += 1
			if G.combat.result in ["win", "stalemate_win"]: res[k][0] += 1
			res[k][2] += G.combat.turn
			G.combat = null
		print(clan, " ", res)
	quit()
