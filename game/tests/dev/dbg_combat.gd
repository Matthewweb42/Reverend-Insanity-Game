extends SceneTree
func _initialize() -> void:
	await process_frame
	var G = root.get_node("Game")
	root.get_node("Meta").reset_for_tests()
	G.headless = true
	G.new_game({"clan": "gu_yue", "seed": 1000})
	var pl = G.s.player
	print("hp ", pl.hp, " maxhp ", G.max_hp(), " ess ", G.max_essence(), " gu ", pl.gu.map(func(x): return [x.id, x.get("eq")]))
	G.start_combat({"enemies": G.enemies_from_group("beasts", 1, 1) if false else [{"id": "grey_wolf", "rank": 1, "tier": "trained"}], "env": [], "flee_allowed": true})
	var c = G.combat
	for e in c.enemies: print("enemy ", e.name, " hp ", e.hp, " atk ", e.get("atk"), e.keys())
	print("player ", c.player.hp, " ess ", c.player.get("ess"), " hand ", c.player.get("hand", []).map(func(x): return x.id))
	var guard = 0
	while c.result == "" and guard < 30:
		guard += 1
		c.auto_turn()
	for l in c.lines: print(l.text if l is Dictionary else l)
	print("RESULT ", c.result, " turns ", c.turn)
	quit()
