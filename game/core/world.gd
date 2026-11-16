class_name World
extends RefCounted
## NPCs and their off-screen lives, relationships, goals, missions, epochs and the rival.

var g


func _init(game) -> void:
	g = game


func p() -> Dictionary:
	return g.s.player


# ============================================================== NPCS =======
func _npc_from(seed: Dictionary) -> Dictionary:
	return {
		"id": seed.id, "name": seed.name, "arch": seed.arch, "loc": seed.loc, "align": int(seed.get("align", 0)),
		"rank": int(seed.get("rank", 1)), "path": seed.get("path", "none"), "personality": seed.get("personality", ""),
		"desire": seed.get("desire", ""), "icon": seed.get("icon", "person"), "disp": 0, "relation": "Stranger",
		"talks": 0, "met": false, "alive": true, "last_talk": -99, "rival": seed.get("rival", false),
		"memory": [], "age": g.rng.randi_range(18, 70), "favour_owed": false,
	}


func spawn_seed(id: String) -> void:
	for sd in Data.npc_seeds:
		if sd.id == id:
			g.s.npcs[id] = _npc_from(sd)
			return


func random_name(family := "") -> String:
	var fams: Array = Data.npc_names.family
	var giv: Array = Data.npc_names.given
	var f = family if family != "" else fams[g.rng.randi_range(0, fams.size() - 1)]
	var n: String = giv[g.rng.randi_range(0, giv.size() - 1)]
	if g.rng.randf() < 0.4:
		n += giv[g.rng.randi_range(0, giv.size() - 1)].to_lower()
	return "%s %s" % [f, n]


func generate() -> void:
	var pl := p()
	for sd in Data.npc_seeds:
		g.s.npcs[sd.id] = _npc_from(sd)
	# procedural NPCs scattered around the known world
	var archs := ["merchant", "cultivator", "broker", "beast_tamer", "wanderer", "cultivator", "elder", "antagonist"]
	var locs := []
	for l in Data.locations.values():
		if l.type in ["village", "city", "wild"] and not l.get("hidden", false):
			locs.append(l.id)
	var paths := Data.path_list.filter(func(x): return x.id != "none")
	for i in 10:
		var arch: String = archs[i % archs.size()]
		var loc: String = locs[g.rng.randi_range(0, locs.size() - 1)]
		var fam := ""
		var lclan: String = Data.locations[loc].get("clan", "")
		if lclan != "":
			fam = Data.clans[lclan].name.replace(" Clan", "").replace(" Tribe", "")
		var id := "npc_%d" % i
		var path_d: Dictionary = paths[g.rng.randi_range(0, paths.size() - 1)]
		var al = g.rng.randi_range(-30, 40) if arch != "antagonist" else g.rng.randi_range(-70, -10)
		g.s.npcs[id] = _npc_from({"id": id, "name": random_name(fam), "arch": arch, "loc": loc, "align": al,
				"rank": g.rng.randi_range(1, 4), "path": path_d.id, "personality": g.procgen.personality(),
				"desire": g.procgen.desire(), "icon": _arch_icon(arch)})
	# the rival
	if not pl.flags.has("no_rival"):
		var clan: Dictionary = Data.clans[pl.clan]
		var rid := ""
		if clan.get("rival", null) == "bai" and g.s.npcs.has("bai_hao"):
			rid = "bai_hao"
		else:
			var rv = clan.get("rival")
			var rclan: String = str(rv) if rv != null else ""
			if rclan == "" or not Data.clans.has(rclan):
				var others := Data.clan_list.filter(func(c): return c.id != pl.clan)
				rclan = others[g.rng.randi_range(0, others.size() - 1)].id
			var fam2: String = Data.clans[rclan].name.replace(" Clan", "").replace(" Tribe", "")
			rid = "rival"
			g.s.npcs[rid] = _npc_from({"id": rid, "name": random_name(fam2), "arch": "antagonist", "loc": Data.clans[rclan].home,
					"align": -20, "rank": 1, "path": Data.clans[rclan].primary, "personality": "arrogant, relentless",
					"desire": "to surpass you", "icon": "sword-brandish", "rival": true})
		g.s.npcs[rid].rival = true
		g.s.npcs[rid].disp = -30
		pl.rival_id = rid
	# shang clan starts with extra contacts
	var contacts := int(Data.clans[pl.clan].bonus.get("contacts", 0))
	var merchants = g.s.npcs.values().filter(func(n): return n.arch in ["merchant", "broker"])
	for i in mini(contacts, merchants.size()):
		merchants[i].met = true
		merchants[i].talks = 3
		merchants[i].disp = 30
		set_relation(merchants[i].id, "Acquaintance")
	# your clan elder knows you
	for n in g.s.npcs.values():
		if n.arch == "elder" and n.loc == Data.clans[pl.clan].home:
			n.met = true
			n.disp = 10
	_schedule_epochs()


func _arch_icon(arch: String) -> String:
	return {"merchant": "coins-pile", "cultivator": "meditation", "broker": "hood", "beast_tamer": "wolf-head",
			"wanderer": "walking-boot", "elder": "wizard-face", "antagonist": "sword-brandish"}.get(arch, "person")


func npcs_here() -> Array:
	var out := []
	for n in g.s.npcs.values():
		if n.alive and n.loc == p().location:
			out.append(n)
	return out


func band(disp: int) -> String:
	var out := "Neutral"
	for b in Data.bands:
		if disp >= int(b[0]):
			out = b[1]
	return out


func level_cap(level: String) -> int:
	for l in Data.levels:
		if l[0] == level:
			return int(l[1])
	return 25


func change_disp(id: String, n: int) -> void:
	if not g.s.npcs.has(id):
		return
	var npc: Dictionary = g.s.npcs[id]
	var cap := level_cap(npc.relation)
	if n > 0:
		npc.disp = maxi(int(npc.disp), mini(cap, int(npc.disp) + n))
	else:
		npc.disp = maxi(-100, int(npc.disp) + n)
	npc.disp = clampi(int(npc.disp), -100, 100)


func set_relation(id: String, level: String) -> void:
	if not g.s.npcs.has(id):
		return
	g.s.npcs[id].relation = level
	_check_connected()


func _check_connected() -> void:
	var n := 0
	for npc in g.s.npcs.values():
		if npc.relation in ["Contact", "Connection"]:
			n += 1
	if n >= 3:
		g.achieve("connected")


func _maybe_level_up(npc: Dictionary) -> void:
	var idx := 0
	for i in Data.levels.size():
		if Data.levels[i][0] == npc.relation:
			idx = i
	if idx + 1 < Data.levels.size():
		var nxt: Array = Data.levels[idx + 1]
		if int(npc.talks) >= int(nxt[2]) and int(npc.disp) >= int(Data.levels[idx][1]) - 5:
			npc.relation = nxt[0]
			g.add_log("%s is now your %s." % [npc.name, nxt[0]], "good")
			_check_connected()


func line(npc: Dictionary) -> String:
	var lines: Array = Data.archetypes[npc.arch].lines
	var t: String = lines[g.rng.randi_range(0, lines.size() - 1)]
	var gen = g.procgen.npc_line(npc)
	if gen != "" and g.rng.randf() < 0.5:
		t = gen
	return t


func interact(id: String, action: String) -> String:
	## Actions: talk, gift, ask_info, ask_help, mentor, trade, spar, threaten
	var pl := p()
	var npc: Dictionary = g.s.npcs[id]
	if not npc.alive:
		return "%s is gone." % npc.name
	npc.met = true
	var band_now := band(int(npc.disp))
	var out := ""
	match action:
		"talk":
			if int(g.s.day) - int(npc.last_talk) < 1:
				return "%s has nothing more to say today." % npc.name
			npc.last_talk = int(g.s.day)
			npc.talks = int(npc.talks) + 1
			var gain = g.rng.randi_range(2, 6)
			if npc.arch == "antagonist":
				gain = g.rng.randi_range(-3, 2)
			# alignment affinity
			if signi(int(npc.align)) == signi(int(pl.align)) and absi(int(pl.align)) > 10:
				gain += 2
			change_disp(id, gain)
			_maybe_level_up(npc)
			g.skip_days(0)
			out = "\"%s\"" % line(npc)
			if g.rng.randf() < 0.25 and npc.arch in ["broker", "wanderer", "elder"]:
				pl.info = int(pl.info) + 1
				out += "\nYou learn something useful. (+1 information)"
			_remember(npc, "talked")
		"gift":
			var cost := 10 * int(npc.rank)
			if int(pl.stones) < cost:
				return "A fitting gift costs %d stones." % cost
			pl.stones = int(pl.stones) - cost
			npc.talks = int(npc.talks) + 1
			change_disp(id, g.rng.randi_range(6, 12))
			_maybe_level_up(npc)
			out = "%s accepts your gift (%d stones)." % [npc.name, cost]
			_remember(npc, "gift")
		"ask_info":
			if int(npc.disp) < 10:
				return "%s does not trust you enough." % npc.name
			out = g.econ._rumour()
			pl.info = int(pl.info) + 1
			change_disp(id, -2)
			out = "%s tells you: %s" % [npc.name, out]
		"ask_help":
			if int(npc.disp) < 50:
				return "Only an Allied friend would help you like that."
			if npc.favour_owed:
				return "You already owe %s a favour." % npc.name
			npc.favour_owed = true
			var r = g.rng.randi()
			match r % 3:
				0:
					var st := 20 * int(npc.rank)
					pl.stones = int(pl.stones) + st
					out = "%s lends you %d stones." % [npc.name, st]
				1:
					pl.hp = g.max_hp()
					pl.injuries.clear()
					out = "%s tends your wounds." % npc.name
				2:
					var gid = g.random_gu(mini(int(npc.rank), int(pl.rank)), "", npc.path)
					if gid != "":
						g.add_gu(gid)
						out = "%s gives you a %s." % [npc.name, Data.gu[gid].name]
					else:
						out = "%s has nothing to spare." % npc.name
		"mentor":
			if npc.arch != "elder":
				return "%s is not a mentor." % npc.name
			if int(npc.disp) < 50:
				return "%s will only teach an Allied disciple." % npc.name
			pl.mentor = id
			out = "%s agrees to guide you. (+5%% to rank breakthroughs, and lessons)" % npc.name
			g.add_attain(npc.path, 20)
		"spar":
			if int(npc.disp) < 0:
				return "%s will not spar with you." % npc.name
			g.start_combat({"enemies": [{"id": "rogue_cultivator", "rank": clampi(int(npc.rank), 1, 9), "tier": "trained", "name": npc.name}],
					"env": [], "flee_allowed": true, "spar": id})
			npc.talks = int(npc.talks) + 1
			change_disp(id, 3)
			return ""
		"challenge":
			g.start_combat({"enemies": [{"id": "rival_disciple" if int(npc.rank) <= 2 else "rogue_cultivator",
					"rank": clampi(int(npc.rank), 1, 9), "tier": "elite", "name": npc.name}], "env": g.location_env(),
					"flee_allowed": true, "duel": id})
			change_disp(id, -10)
			return ""
		"threaten":
			change_disp(id, -15)
			g.change_align(-4)
			var st2 := 5 * int(npc.rank) * (2 if int(pl.rank) > int(npc.rank) else 0)
			pl.stones = int(pl.stones) + st2
			out = "%s hands over %d stones, eyes full of hate." % [npc.name, st2] if st2 > 0 else "%s laughs at you." % npc.name
			_remember(npc, "threatened")
	g.world.check_goals()
	g.emit_signal("state_changed")
	return out


func _remember(npc: Dictionary, what: String) -> void:
	npc.memory.append({"day": int(g.s.day), "what": what})
	if npc.memory.size() > 8:
		npc.memory = npc.memory.slice(npc.memory.size() - 8)


func weekly() -> void:
	# off-screen lives: cultivate, wander, feud, age
	var pl := p()
	var town_locs := []
	for l in Data.locations.values():
		if l.type in ["village", "city", "wild"] and not l.get("hidden", false) and not l.get("hidden_unless_clan", false):
			town_locs.append(l.id)
	for n in g.s.npcs.values():
		if not n.alive:
			continue
		if g.rng.randf() < 0.01 * (1 + int(n.rank)) and int(n.rank) < 6:
			if n.rival:
				continue
			n.rank = int(n.rank) + 1
		if n.arch in ["wanderer", "cultivator", "antagonist", "beast_tamer"] and g.rng.randf() < 0.12:
			n.loc = town_locs[g.rng.randi_range(0, town_locs.size() - 1)]
		# disposition drifts back toward neutral
		if absi(int(n.disp)) > 5 and g.rng.randf() < 0.1:
			n.disp = int(n.disp) - signi(int(n.disp))
		if g.rng.randf() < 0.0015 and not n.rival and n.arch != "elder":
			n.alive = false
			if n.met:
				g.add_log("Word arrives: %s has died on the road." % n.name, "warn")
	# the rival keeps pace, a little behind or ahead
	var rid: String = pl.rival_id
	if rid != "" and g.s.npcs.has(rid) and g.s.npcs[rid].alive:
		var rv: Dictionary = g.s.npcs[rid]
		var target := int(pl.rank) + (1 if g.rng.randf() < 0.3 else 0)
		if int(rv.rank) < target and g.rng.randf() < 0.05:
			rv.rank = int(rv.rank) + 1
			g.add_log("Rumour says your rival %s has broken through to Rank %d." % [rv.name, int(rv.rank)], "warn")
	# storyline starts that are not location-bound
	if rid != "" and not g.s.stories.has("rival") and int(g.s.day) > 60 and g.rng.randf() < 0.08:
		g.events.enqueue("rv_1", {})
	if not g.s.stories.has("three_kings") and int(pl.rank) >= 2 and g.rng.randf() < 0.02:
		g.events.enqueue("tk_1", {})


func monthly() -> void:
	_epoch_tick()
	check_goals()
	if g.s.goals.filter(func(x): return not x.done).size() == 0:
		suggest_goal()


func yearly() -> void:
	for n in g.s.npcs.values():
		n.age = int(n.age) + 1


func daily() -> void:
	pass


func on_arrive(loc: String) -> void:
	var pl := p()
	# a cache from a past life waits here
	for c in pl.get("caches", []):
		if c.loc == loc and not c.claimed:
			c.claimed = true
			pl.stones = int(pl.stones) + int(c.stones)
			g.add_log("You find the cache your past self hid here: %d primeval stones!" % int(c.stones), "great")
	# meeting people who are here
	for n in npcs_here():
		if not n.met and g.rng.randf() < 0.35:
			n.met = true
			g.add_log("You meet %s, a %s." % [n.name, Data.archetypes[n.arch].name.to_lower()], "info")
	if loc == "three_kings_land" and not pl.flags.has("tk_claimed") and Data.events.has("tk_10"):
		if int(g.s.stories.get("three_kings", {}).get("step", 0)) >= 9:
			g.events.enqueue("tk_10", {})


func on_rank_up() -> void:
	var pl := p()
	if int(pl.rank) == 3:
		suggest_goal()


# ============================================================== GOALS ======
func add_goal(type_id: String, params: Dictionary, primary := false) -> String:
	var gt: Dictionary = {}
	for x in Data.goal_types:
		if x.id == type_id:
			gt = x
	if gt.is_empty():
		return "Unknown goal"
	var active = g.s.goals.filter(func(x): return not x.done)
	if active.size() >= 3:
		return "You can pursue at most three goals"
	var pl := p()
	var pr := params.duplicate()
	if not pr.has("path"):
		pr["path"] = pl.primary_path
	if not pr.has("kind"):
		pr["kind"] = "movement"
	if not pr.has("n"):
		pr["n"] = {"resources": 200 * int(pl.rank), "connections": 3, "information": 5, "trouble": 5, "explore": pl.visited.size() + 2, "prepare": mini(5, int(pl.rank) + 1)}.get(type_id, 1)
	if not pr.has("event"):
		pr["event"] = "the coming storm"
	var fmt := {"path": Data.path_name(pr.path), "kind": pr.kind, "n": str(pr.n), "event": pr.event}
	if primary:
		for x in g.s.goals:
			x.primary = false
	var goal := {"id": "g%d" % g.next_uid(), "type": type_id, "tag": gt.tag, "name": gt.name.format(fmt), "desc": gt.desc.format(fmt),
			"params": pr, "primary": primary or active.is_empty(), "done": false, "start": int(g.s.day),
			"base": _goal_base(type_id)}
	g.s.goals.append(goal)
	g.add_log("New goal: %s." % goal.name, "info")
	g.emit_signal("state_changed")
	return ""


func _goal_base(type_id: String) -> int:
	var pl := p()
	match type_id:
		"seek_path_gu", "seek_type_gu":
			return pl.gu.size()
		"trouble":
			return int(g.s.stats.wins)
		"information":
			return int(pl.info)
	return 0


func remove_goal(id: String) -> void:
	g.s.goals = g.s.goals.filter(func(x): return x.id != id)
	g.emit_signal("state_changed")


func set_primary(id: String) -> void:
	for x in g.s.goals:
		x.primary = x.id == id
	g.emit_signal("state_changed")


func goal_progress(goal: Dictionary) -> Array:
	## [current, target]
	var pl := p()
	var pr: Dictionary = goal.params
	match goal.type:
		"seek_path_gu":
			var n := 0
			for gi in pl.gu:
				if Data.gu[gi.id].path == pr.path:
					n += 1
			return [mini(1, maxi(0, n - _count_at_start(goal, "path"))), 1]
		"seek_type_gu":
			var have := 0
			for gi in pl.gu:
				var gd: Dictionary = Data.gu[gi.id]
				if (pr.kind == "movement" and gd.has("passive") and gd.passive.has("travel_mult")) or gd.kind == pr.kind:
					have += 1
			return [mini(1, maxi(0, have - _count_at_start(goal, "kind"))), 1]
		"resources":
			return [mini(int(pl.stones), int(pr.n)), int(pr.n)]
		"connections":
			var c := 0
			for n in g.s.npcs.values():
				if n.relation != "Stranger" and n.alive:
					c += 1
			return [mini(c, int(pr.n)), int(pr.n)]
		"information":
			return [mini(int(pl.info), int(pr.n)), int(pr.n)]
		"path_training":
			return [mini(int(pl.attain.get(pr.path, 0)), 100), 100]
		"trouble":
			return [mini(int(g.s.stats.wins) - int(goal.base), int(pr.n)), int(pr.n)]
		"explore":
			return [mini(pl.visited.size(), int(pr.n)), int(pr.n)]
		"inheritance":
			var done = pl.visited.has("hu_immortal_land") or pl.visited.has("three_kings_land") or pl.flags.has("found_inheritance")
			return [1 if done else 0, 1]
		"prepare":
			return [mini(int(pl.rank), int(pr.n)), int(pr.n)]
	return [0, 1]


func _count_at_start(goal: Dictionary, key: String) -> int:
	if not goal.has("start_counts"):
		var pl := p()
		var pr: Dictionary = goal.params
		var n := 0
		for gi in pl.gu:
			var gd: Dictionary = Data.gu[gi.id]
			if key == "path" and gd.path == pr.path:
				n += 1
			elif key == "kind" and ((pr.kind == "movement" and gd.has("passive") and gd.passive.has("travel_mult")) or gd.kind == pr.kind):
				n += 1
		goal["start_counts"] = n
	return int(goal.start_counts)


func check_goals() -> void:
	if g.s.is_empty():
		return
	for goal in g.s.goals:
		if goal.done:
			continue
		var pr := goal_progress(goal)
		if int(pr[0]) >= int(pr[1]):
			goal.done = true
			_goal_reward(goal)


func _goal_reward(goal: Dictionary) -> void:
	var pl := p()
	var r := int(pl.rank)
	g.add_attain(pl.primary_path, 15 + 5 * r)
	pl.stones = int(pl.stones) + 15 * r
	g.add_log("Goal complete: %s! (+%d stones, +attainment)" % [goal.name, 15 * r], "great")


func suggest_goal() -> void:
	var pl := p()
	var opts := ["seek_type_gu", "trouble", "explore", "connections", "resources"]
	if int(pl.rank) >= 3:
		opts.append("inheritance")
	add_goal(opts[g.rng.randi_range(0, opts.size() - 1)], {}, false)


# ============================================================== MISSIONS ===
func available_missions() -> Array:
	var pl := p()
	var loc: Dictionary = Data.locations[pl.location]
	if loc.get("clan", "") != pl.clan or not ("clan_hall" in loc.get("services", [])):
		return []
	var out := []
	var idx = g.standing_index()
	for m in Data.missions:
		var need := 0
		for i in Data.standing.size():
			if Data.standing[i][0] == m.min:
				need = i
		out.append({"m": m, "ok": idx >= need, "reason": "" if idx >= need else "Needs %s standing" % m.min})
	return out


func start_mission(mid: String) -> String:
	var pl := p()
	for a in available_missions():
		if a.m.id == mid:
			if not a.ok:
				return a.reason
			pl.activity = "mission"
			pl.act = {"id": mid, "name": a.m.name, "left": int(a.m.days), "fought": false}
			g.add_log("You accept the mission: %s." % a.m.name, "info")
			g.emit_signal("state_changed")
			return ""
	return "No such mission here"


func finish_mission() -> void:
	var pl := p()
	var m: Dictionary = {}
	for x in Data.missions:
		if x.id == pl.act.get("id", ""):
			m = x
	if m.is_empty():
		return
	var last_act: Dictionary = pl.act.duplicate()
	if float(m.get("combat", 0)) > 0 and g.rng.randf() < float(m.combat):
		var r := int(pl.rank)
		var loc_groups: Array = Data.locations[pl.location].get("enemies", ["wild"])
		var groups := ["wild", "bandit"] if loc_groups.is_empty() else loc_groups
		var defs = g.enemies_from_group(groups[g.rng.randi_range(0, groups.size() - 1)], r, 1, "elite" if m.get("elite", false) else "")
		pl["_mission"] = m.id
		g.start_combat({"enemies": defs, "env": g.location_env(), "flee_allowed": true, "mission": true})
		return
	_mission_reward(m, true)


func mission_combat_done(won: bool) -> String:
	var pl := p()
	var mid: String = pl.get("_mission", "")
	pl.erase("_mission")
	for x in Data.missions:
		if x.id == mid:
			return _mission_reward(x, won)
	return ""


func _mission_reward(m: Dictionary, ok: bool) -> String:
	var pl := p()
	if not ok:
		g.add_standing(-int(m.contrib) / 2)
		g.add_log("Mission failed: %s." % m.name, "bad")
		return "Mission failed."
	var st = g.rng.randi_range(int(m.stones[0]), int(m.stones[1])) * maxi(1, int(pl.rank) - 0)
	pl.stones = int(pl.stones) + st
	g.add_standing(int(m.contrib))
	var t := "Mission complete: %s. +%d stones, +%d contribution." % [m.name, st, int(m.contrib)]
	if m.get("mats", false):
		var lst := Data.material_tier_list("common" if int(pl.rank) < 3 else "uncommon")
		var mid: String = lst[g.rng.randi_range(0, lst.size() - 1)]
		g.add_material(mid, 2)
		t += " +2 %s." % Data.materials[mid].name
	if m.has("info"):
		pl.info = int(pl.info) + int(m.info)
		t += " +%d information." % int(m.info)
	if m.get("reward_gu", false):
		var gid = g.random_gu(int(pl.rank), "rare")
		if gid != "":
			g.add_gu(gid, true)
			t += " The elders reward you with %s." % Data.gu[gid].name
	g.add_log(t, "good")
	return t


# ============================================================== EPOCHS =====
func _schedule_epochs() -> void:
	g.s.epochs = []
	for e in Data.epochs:
		if e.has("year"):
			var y = g.rng.randi_range(int(e.year[0]), int(e.year[1]))
			g.s.epochs.append({"id": e.id, "year": y, "announced": false, "done": false})
		elif e.has("every"):
			var y2 := int(e.offset)
			while y2 < 300:
				if y2 > 0:
					g.s.epochs.append({"id": e.id, "year": y2, "announced": false, "done": false})
				y2 += int(e.every)
	g.s.epochs.sort_custom(func(a, b): return int(a.year) < int(b.year))


func epoch_def(id: String) -> Dictionary:
	for e in Data.epochs:
		if e.id == id:
			return e
	return {}


func _epoch_tick() -> void:
	var years := float(g.s.day) / Data.YEAR
	for ep in g.s.epochs:
		if ep.done:
			continue
		var d := epoch_def(ep.id)
		if not ep.announced and years >= float(ep.year) - 3.0:
			ep.announced = true
			g.add_log("Omens: %s (%s)" % [d.signs, d.name], "warn")
		if years >= float(ep.year):
			ep.done = true
			g.add_log("World event: %s!" % d.name, "head")
			if d.id == "plague":
				if not g.s.has("epoch_flags"):
					g.s["epoch_flags"] = {}
				g.s.epoch_flags["plague"] = int(g.s.day)
			if Data.events.has(d.event):
				g.events.enqueue(d.event, {}, 0)


func upcoming_epochs() -> Array:
	var out := []
	for ep in g.s.epochs:
		if ep.announced and not ep.done:
			var d := epoch_def(ep.id)
			out.append({"name": d.name, "signs": d.signs, "in_years": int(ep.year) - int(g.s.day) / Data.YEAR})
	return out
