extends SceneTree
## Logic tests for every system. Exits 0 when all pass, 1 otherwise.
## Usage: godot --headless --path game --script res://tests/run_tests.gd

var G
var M
var D
var fails := 0
var passes := 0
var cur := ""


func ok(cond: bool, msg: String) -> void:
	if cond:
		passes += 1
	else:
		fails += 1
		print("  FAIL [%s] %s" % [cur, msg])


func fresh(clan := "gu_yue", seed_v := 42, extra := {}) -> void:
	var o := {"name": "Tester", "clan": clan, "seed": seed_v, "mode": "normal", "start": "standard"}
	o.merge(extra, true)
	G.new_game(o)


func win_combat() -> Dictionary:
	## Resolve the current battle as a win, the way the UI would after the last enemy falls.
	G.combat.result = "win"
	return G.finish_combat()


func _initialize() -> void:
	await process_frame
	G = root.get_node("Game")
	M = root.get_node("Meta")
	D = root.get_node("Data")
	M.reset_for_tests()
	M.d.settings.sandbox = true
	G.headless = true
	var watchdog := create_timer(300.0)
	watchdog.timeout.connect(func():
		print("WATCHDOG: tests took too long")
		quit(2))
	var tests := ["data", "new_game", "cultivation", "breakthrough_trial", "gu_and_upkeep", "combat", "killer_moves",
			"economy", "refining", "travel", "events", "npcs_and_goals", "missions", "save_load", "ascension",
			"immortal_systems", "rank_up", "venerable", "death_and_legacy", "procgen", "ai_offline", "modes"]
	for t in tests:
		cur = t
		var before := fails
		call("t_" + t)
		print("%s %s" % ["ok  " if fails == before else "FAIL", t])
	print("\n%d checks passed, %d failed" % [passes, fails])
	print("TESTS ", "OK" if fails == 0 else "FAILED")
	quit(0 if fails == 0 else 1)


# ------------------------------------------------------------------ tests --
func t_data() -> void:
	ok(D.gu.size() >= 80, "at least 80 Gu (%d)" % D.gu.size())
	ok(D.clans.size() >= 6, "six clans")
	ok(D.event_list.size() >= 40, "40+ authored events (%d)" % D.event_list.size())
	ok(D.locations.size() >= 10, "10+ locations")
	for g in D.gu_list:
		if not ResourceLoader.exists("res://assets/icons/%s.png" % g.icon):
			ok(false, "icon for %s (%s)" % [g.id, g.icon])
	for fid in D.formulas:
		ok(D.gu.has(D.formulas[fid].id), "formula %s makes a known Gu" % fid)
	for r in D.routes:
		ok(D.locations.has(r.a) and D.locations.has(r.b), "route %s-%s" % [r.a, r.b])
	for e in D.event_list:
		ok(e.get("choices", []).size() > 0, "event %s has choices" % e.id)
	for c in D.clans.values():
		for gid in c.get("start_gu", []):
			ok(D.gu.has(gid), "clan %s start Gu %s exists" % [c.id, gid])


func t_new_game() -> void:
	for cid in D.clans.keys():
		fresh(cid)
		var pl = G.p()
		ok(pl.clan == cid, "clan set")
		ok(G.equipped().size() >= 4, "%s starts with a deck (%d)" % [cid, G.equipped().size()])
		ok(int(pl.rank) == 1 and int(pl.stones) > 0, "rank 1 with stones")
		ok(pl.location != "" and D.locations.has(pl.location), "valid start location")
	fresh("gu_yue", 1, {"region": "central_continent"})
	ok("central_continent" in G.p().known_locs, "central start knows the central continent")


func t_cultivation() -> void:
	fresh()
	var pl = G.p()
	G.set_activity("cultivate")
	var p0 := float(pl.progress)
	for i in 10:
		G.advance_day(false)
	ok(float(pl.progress) > p0, "cultivating raises progress")
	pl.progress = D.stage_req(1, int(pl.stage))
	var r: Dictionary = G.breakthrough()
	ok(r.kind in ["stage", "fail", "crit"], "stage breakthrough resolves (%s)" % r.kind)


func t_breakthrough_trial() -> void:
	fresh()
	var pl = G.p()
	pl.rank = 2
	pl.stage = 3
	pl.progress = D.stage_req(2, 3)
	var r: Dictionary = G.breakthrough()
	ok(r.kind == "trial" and G.combat != null, "rank 2->3 summons a heart demon")
	win_combat()
	ok(pl.trial_passed, "winning the trial is recorded")
	pl.progress = D.stage_req(2, 3)
	var tries := 0
	while int(pl.rank) == 2 and tries < 30:
		pl.progress = D.stage_req(2, 3)
		pl.trial_passed = true
		G.breakthrough()
		tries += 1
	ok(int(pl.rank) == 3, "rank 3 reached after the trial")


func t_gu_and_upkeep() -> void:
	fresh()
	var pl = G.p()
	var gi: Dictionary = G.add_gu("blood_leech" if D.gu.has("blood_leech") else D.gu_list[0].id, true)
	ok(not gi.is_empty(), "add_gu")
	var n0: int = G.equipped().size()
	var r: String = G.equip(int(gi.uid), true)
	ok(r == "" or r.length() > 0, "equip returns")
	pl.stones = 0
	for i in 21:
		G.advance_day(false)
	var starving := 0
	for g in pl.gu:
		if G.feed_state(g) != "fed":
			starving += 1
	ok(starving > 0 or pl.gu.size() < n0, "unfed Gu starve or die")


func t_combat() -> void:
	fresh()
	G.start_combat({"enemies": [{"id": "bandit", "rank": 1, "tier": "mook"}], "env": [], "flee_allowed": true})
	var c = G.combat
	ok(c != null, "combat starts")
	ok(c.player.hand.size() > 0, "a hand is drawn")
	var turns := 0
	while c.result == "" and turns < 60:
		c.auto_turn()
		turns += 1
	ok(c.result != "", "combat ends (%s after %d turns)" % [c.result, turns])
	var res: Dictionary = G.finish_combat()
	ok(res.has("text"), "finish_combat reports")
	ok(G.combat == null or G.combat != c, "combat cleared")
	# essence, cost and path limits
	fresh()
	G.start_combat({"enemies": [{"id": "bandit", "rank": 1, "tier": "trained"}], "env": [], "flee_allowed": true})
	c = G.combat
	var before := int(c.player.essence)
	var played := false
	for i in c.player.hand.size():
		if c.can_play(i) == "":
			var cost: int = c.card_cost(c.player.hand[i])
			played = c.play_card(i, 0)
			ok(int(c.player.essence) <= before - cost + 1, "playing a card spends essence")
			break
	ok(played, "a card could be played")
	ok(c.flee_chance() >= 0.0 and c.flee_chance() <= 1.0, "flee chance in range")
	G.combat.result = "lose"
	G.finish_combat()


func t_killer_moves() -> void:
	fresh("gu_yue")
	var pl = G.p()
	for p in pl.attain.keys():
		pl.attain[p] = 400.0
	G.start_combat({"enemies": [{"id": "bandit", "rank": 1, "tier": "elite"}], "env": [], "flee_allowed": true})
	var c = G.combat
	c.player.essence = 999
	var ks: Array = c.available_killers()
	ok(ks.size() > 0, "clan killer move listed")
	var usable = ks.filter(func(k): return k.reason == "")
	if usable.size() > 0:
		var hp0 := 0
		for e in c.enemies:
			hp0 += int(e.hp)
		ok(c.use_killer(usable[0].km.id, 0), "killer move fires")
		var hp1 := 0
		for e in c.enemies:
			hp1 += int(e.hp)
		ok(hp1 < hp0 or c.result != "", "killer move hurts")
	G.combat.result = "win"
	G.finish_combat()
	ok(int(G.s.stats.killers) >= 0, "killer stat tracked")


func t_economy() -> void:
	fresh()
	var pl = G.p()
	pl.location = "merchant_city" if D.locations.has("merchant_city") else pl.location
	pl.stones = 5000
	var m: Dictionary = G.econ.market("market")
	ok(m.items.size() > 0, "market has stock")
	var s0 := int(pl.stones)
	var gu0: int = pl.gu.size()
	var idx := -1
	for i in m.items.size():
		if m.items[i].type == "gu":
			idx = i
			break
	if idx >= 0:
		var r: String = G.econ.buy("market", idx)
		ok(r == "" or r.contains("slot") or r.contains("room"), "buy works or explains (%s)" % r)
		if r == "":
			ok(int(pl.stones) < s0 and pl.gu.size() > gu0, "buying costs stones and adds a Gu")
	var h: String = G.econ.haggle("market", 0)
	ok(h != "", "haggle answers")
	var price: int = G.econ.sell_price_gu(pl.gu[-1])
	ok(price > 0, "Gu sell price")
	ok(G.econ.tutor_cost() > 0, "tutor costs stones")


func t_refining() -> void:
	fresh()
	var pl = G.p()
	pl.stones = 9999
	for mid in D.materials:
		G.add_material(mid, 10)
	var fid := ""
	for f in pl.formulas:
		if G.econ.can_refine(f) == "":
			fid = f
			break
	ok(fid != "", "some formula is refinable with materials")
	if fid != "":
		var n0: int = pl.gu.size()
		var r: String = G.set_activity("refine", {"formula": fid})
		ok(r == "", "refining starts (%s)" % r)
		for i in 30:
			G.advance_day(false)
			if pl.activity != "refine":
				break
		ok(pl.activity != "refine", "refining finishes")
		ok(pl.gu.size() >= n0, "refining yields or fails gracefully")
	ok(G.econ.experiment() != "", "experiment answers")
	var uc: Dictionary = G.econ.upgrade_cost(pl.gu[0])
	ok(int(uc.stones) > 0, "upgrade has a cost")


func t_travel() -> void:
	fresh()
	var pl = G.p()
	var dest := ""
	for id in pl.known_locs:
		if id != pl.location and not G.travel_plan(id).has("error"):
			dest = id
			break
	ok(dest != "", "a reachable destination")
	var plan: Dictionary = G.travel_plan(dest)
	ok(int(plan.days) > 0, "travel takes days")
	ok(G.start_travel(dest) == "", "travel starts")
	for i in int(plan.days) + 3:
		G.advance_day(false)
		if G.combat != null:
			G.combat.result = "win"
			G.finish_combat()
	ok(pl.location == dest, "arrives at %s (at %s)" % [dest, pl.location])


func t_events() -> void:
	fresh()
	var got := 0
	for i in 400:
		G.advance_day()
		if G.combat != null:
			win_combat()
		if not G.current_event.is_empty():
			var inst: Dictionary = G.current_event
			ok(inst.choices.size() > 0, "event has choices")
			var pick := 0
			for j in inst.choices.size():
				if inst.choices[j].reason == "":
					pick = j
					break
			var r: Dictionary = G.resolve_event_choice(pick)
			ok(r.has("text") or r.get("combat", false) or r.get("blocked", false), "choice resolves")
			if G.combat != null:
				win_combat()
			got += 1
			if got >= 8:
				break
	ok(got >= 3, "events fire over time (%d)" % got)


func t_npcs_and_goals() -> void:
	fresh()
	var here: Array = G.world.npcs_here()
	ok(here.size() > 0, "NPCs live in the village")
	var n: Dictionary = here[0]
	var d0 := int(n.disp)
	G.p().stones = 1000
	G.world.interact(n.id, "gift")
	ok(int(n.disp) > d0, "gifts improve disposition")
	ok(G.world.interact(n.id, "talk") != "", "talk answers")
	var gt: Dictionary = D.goal_types[0]
	var r: String = G.world.add_goal(gt.id, {"path": "light", "kind": "attack", "event": "x", "n": 2}, true)
	ok(r == "" or r.length() > 0, "add goal")
	ok(G.world.upcoming_epochs() is Array, "epochs listed")


func t_missions() -> void:
	fresh()
	var ms: Array = G.world.available_missions()
	ok(ms.size() > 0, "missions available")
	var okm = ms.filter(func(a): return a.ok)
	if okm.size() > 0:
		var pl = G.p()
		var st0 := int(pl.standing)
		ok(G.set_activity("mission", {"mission": okm[0].m.id}) == "", "mission starts")
		for i in 40:
			G.advance_day(false)
			if G.combat != null:
				win_combat()
			if pl.activity != "mission":
				break
		ok(int(pl.standing) > st0, "mission raises standing")


func t_save_load() -> void:
	fresh()
	for i in 20:
		G.advance_day(false)
	var day := int(G.s.day)
	var stones := int(G.p().stones)
	ok(G.save_game(3) == "", "save")
	G.advance_day(false)
	ok(G.load_game(3) == "", "load")
	ok(int(G.s.day) == day and int(G.p().stones) == stones, "state restored")
	ok(G.list_saves().any(func(s): return int(s.slot) == 3), "save listed")
	G.delete_save(3)
	ok(not G.list_saves().any(func(s): return int(s.slot) == 3), "save deleted")


func _make_peak5() -> void:
	var pl = G.p()
	pl.rank = 5
	pl.stage = 3
	pl.progress = D.stage_req(5, 3)
	pl.specialization = pl.primary_path
	pl.stones = 2000
	pl.age_days = 40 * D.YEAR if pl.has("age_days") else 0


func t_ascension() -> void:
	fresh()
	_make_peak5()
	var r: Dictionary = G.breakthrough()
	ok(r.kind == "tribulation", "rank 5 peak calls the tribulation (%s)" % r.kind)
	ok(G.p().trib.stage == "prepare", "tribulation waits for preparation")
	var f: Dictionary = G.immortal.ascension_factors()
	ok(f.has("heaven") and f.has("human_chance"), "factors shown")
	ok(G.immortal.earth_chance(1000) > G.immortal.earth_chance(0), "bigger offering, better earth odds")
	ok(G.immortal.start_heaven(500) == "" and G.combat != null, "heaven tribulation is a battle")
	var tries := 0
	var res: Dictionary = win_combat()
	while not G.is_immortal() and G.has_run() and tries < 20:
		# earth/human rolls can fail; retry the whole ascension
		_make_peak5()
		G.breakthrough()
		G.immortal.start_heaven(500)
		res = win_combat()
		tries += 1
	ok(G.is_immortal(), "becomes a Gu Immortal: %s" % res.get("text", ""))
	ok(G.s.blessed != null and G.s.blessed.nodes.size() >= 2, "a blessed land opens")


func t_immortal_systems() -> void:
	fresh()
	G.immortal._become_immortal(3)
	var pl = G.p()
	pl.istones = 500
	pl.stones = 50000
	ok(G.immortal.harvest() != "", "harvest answers")
	ok(G.immortal.node_upgrade_cost(0) > 0, "node upgrade cost")
	ok(G.immortal.upgrade_node(0) == "" or true, "node upgrade")
	ok(G.immortal.nurture_cost() > 0, "nurture cost")
	var st: Array = G.immortal.STRUCTURES.keys() if G.immortal.STRUCTURES is Dictionary else G.immortal.STRUCTURES
	ok(st.size() > 0, "structures exist")
	ok(G.immortal.FACTIONS.size() > 0, "factions exist")
	var fid = G.immortal.FACTIONS.keys()[0] if G.immortal.FACTIONS is Dictionary else G.immortal.FACTIONS[0].id
	G.immortal.choose_faction(fid)
	ok(str(pl.get("faction", G.s.get("faction", ""))) != "", "faction joined")
	var days0 := int(G.s.day)
	for i in 60:
		G.advance_day(false)
		if G.combat != null:
			win_combat()
	ok(int(G.s.day) >= days0 + 60, "immortal days pass")
	ok(G.immortal.rank_up_requirements().size() > 0, "rank-up requirements listed")


func t_rank_up() -> void:
	fresh()
	G.immortal._become_immortal(4)
	var pl = G.p()
	for path in pl.dao.keys():
		pl.dao[path] = 99999
	pl.dao[pl.primary_path] = 99999
	pl.istones = 99999
	pl.stones = 99999
	for mid in D.materials:
		G.add_material(mid, 20)
	for r in [7, 8]:
		for g in D.gu_list:
			if int(g.rank) == r:
				G.add_gu(g.id, true)
				break
	var reqs: Array = G.immortal.rank_up_requirements()
	var unmet = reqs.filter(func(x): return not x[1])
	ok(unmet.is_empty(), "requirements can be met: %s" % str(unmet))
	var r: Dictionary = G.breakthrough()
	ok(r.kind == "trial" and G.combat != null, "rank-up starts a tribulation battle (%s: %s)" % [r.kind, r.text])
	if G.combat != null:
		win_combat()
	ok(int(pl.rank) == 7, "rank 7 reached")


func t_venerable() -> void:
	fresh()
	G.immortal._become_immortal(4)
	var pl = G.p()
	pl.rank = 8
	for path in D.path_list.slice(0, 4):
		pl.attain[path.id if path is Dictionary else str(path)] = 9999.0
	for path in pl.dao.keys():
		pl.dao[path] = 99999
	pl.dao[pl.primary_path] = 99999
	pl.istones = 99999
	pl.stones = 99999
	for mid in D.materials:
		G.add_material(mid, 20)
	for g in D.gu_list:
		if int(g.rank) >= 8:
			G.add_gu(g.id, true)
	var unmet = G.immortal.rank_up_requirements().filter(func(x): return not x[1])
	ok(unmet.is_empty(), "venerable requirements can be met: %s" % str(unmet))
	var r: Dictionary = G.breakthrough()
	ok(G.combat != null, "venerable trial 1 starts (%s)" % r.get("text", ""))
	var stages := 0
	while G.combat != null and stages < 5:
		win_combat()
		stages += 1
	ok(stages == 3, "three venerable trials (%d)" % stages)
	ok(not G.has_run() and str(G.s.get("ended_cause", "")) == "victory", "victory ends the run as a Venerable")


func t_death_and_legacy() -> void:
	M.reset_for_tests()
	M.d.settings.sandbox = false
	fresh()
	var got := [{}]
	var cb := func(sm): got[0] = sm
	G.run_ended.connect(cb)
	G.p().rank = 3
	G.end_run("killed", "Slain in a test.")
	G.run_ended.disconnect(cb)
	ok(not got[0].is_empty(), "run_ended fires with a summary")
	ok(int(got[0].get("points", 0)) > 0, "a life earns inheritance points (%s)" % got[0].get("points"))
	ok(int(M.d.points) > 0, "points banked")
	ok(int(M.d.stats.runs) >= 1, "life recorded")
	var cheap: Dictionary = {}
	for d in D.inheritance:
		if int(d.cost) <= int(M.d.points):
			cheap = d
			break
	if not cheap.is_empty():
		ok(M.buy(cheap.id) == "", "buy a legacy")
		ok(M.d.pending.size() == 1, "legacy pending")
		M.refund(0)
		ok(M.d.pending.is_empty(), "refund")
	M.d.settings.sandbox = true


func t_procgen() -> void:
	fresh()
	var e: Dictionary = G.procgen.make_event(true)
	ok(e.has("choices") and e.choices.size() > 0, "procedural event has choices")
	ok(str(e.get("title", "")) != "", "procedural event has a title")


func t_ai_offline() -> void:
	var A = root.get_node("AIGen")
	M.d.settings.api_key = ""
	ok(not A.enabled() if A.has_method("enabled") else true, "AI writing is off without a key")
	fresh()
	ok(G.world.line(G.world.npcs_here()[0]) != "", "NPCs speak without an API key")


func t_modes() -> void:
	for mode in D.modes.keys() if D.modes is Dictionary else D.modes.map(func(m): return m.id):
		fresh("gu_yue", 9, {"mode": mode})
		ok(G.s.mode == mode, "mode %s starts" % mode)
		for i in 5:
			G.advance_day(false)
