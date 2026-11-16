class_name EventSystem
extends RefCounted
## Event queue, selection, requirement checks and the effect interpreter (docs/Systems/Events.md).

var g


func _init(game) -> void:
	g = game


func p() -> Dictionary:
	return g.s.player


# ------------------------------------------------------------ selection -----
func roll_daily(where_kind: String) -> void:
	## where_kind: "travel" or "location"
	var pl := p()
	if pl.activity == "closed_door":
		return
	var chance := 0.0
	if where_kind == "travel":
		chance = 0.20
	else:
		var loc: Dictionary = Data.locations.get(pl.location, {"danger": 1})
		chance = 0.022 + 0.004 * int(loc.get("danger", 1))
		if pl.location == "blessed_land":
			chance = 0.01
	if g.s.events.queue.size() >= 3:
		return
	if g.rng.randf() >= chance:
		return
	var ev := pick_event(where_kind)
	if ev.is_empty():
		return
	enqueue(ev.id, {})


func _where_ok(e: Dictionary, where_kind: String) -> bool:
	var pl := p()
	var w: Array = e.where
	if "any" in w:
		return true
	if where_kind == "travel":
		return "travel" in w
	if pl.location == "blessed_land":
		return false
	var loc: Dictionary = Data.locations.get(pl.location, {})
	if pl.location in w:
		return true
	var t: String = loc.get("type", "")
	if t in w:
		return true
	if t in ["danger", "blessed", "region"] and "wild" in w:
		return true
	return false


func pick_event(where_kind: String) -> Dictionary:
	var pl := p()
	var cands := []
	var total := 0.0
	var goal_tags := g.goal_tags()
	var primary_tag: String = g.primary_goal_tag()
	for e in Data.event_list:
		if float(e.weight) <= 0:
			continue
		if e.once and g.s.events.seen.has(e.id):
			continue
		if pl.rank < int(e.rank[0]) or pl.rank > int(e.rank[1]):
			continue
		if not _where_ok(e, where_kind):
			continue
		if e.has("req") and req_fail(e.req, e) != "":
			continue
		if e.has("chain") and _chain_blocked(e):
			continue
		if _recent(e.id):
			continue
		var w := float(e.weight)
		for gt in e.goals:
			if gt == primary_tag:
				w *= 3.0   # primary goal carries ~50% of the weighting
			elif gt in goal_tags:
				w *= 1.6
		cands.append([e, w])
		total += w
	# procedural template events (offline generation)
	var tw := total * 0.18
	if where_kind == "travel" or Data.locations.get(pl.location, {}).get("type", "") in ["wild", "danger", "region"]:
		cands.append([{"id": "__proc_wild"}, tw])
		total += tw
	else:
		cands.append([{"id": "__proc_town"}, tw * 0.6])
		total += tw * 0.6
	if total <= 0:
		return {}
	var roll := g.rng.randf() * total
	for c in cands:
		roll -= c[1]
		if roll <= 0:
			if c[0].id.begins_with("__proc"):
				return g.procgen.make_event(c[0].id == "__proc_wild")
			return c[0]
	return {}


func _recent(id: String) -> bool:
	var last = g.s.events.last_seen.get(id, -9999)
	return int(g.s.day) - int(last) < 45


func _chain_blocked(e: Dictionary) -> bool:
	var sid: String = e.chain
	var st: Dictionary = g.s.stories.get(sid, {})
	if st.get("done", false):
		return true
	var first: bool = Data.storylines.has(sid) and Data.storylines[sid].start == e.id
	if first and not st.is_empty():
		return true
	if not first and st.is_empty():
		return true
	return false


func enqueue(id: String, ctx: Dictionary, delay := 0, proc: Dictionary = {}) -> void:
	var ev: Dictionary = proc if not proc.is_empty() else Data.events.get(id, {})
	if ev.is_empty():
		return
	var entry := {"id": id, "due": int(g.s.day) + delay, "expires": int(g.s.day) + delay + int(ev.get("expiry", 20)),
			"urgency": ev.get("urgency", "normal"), "ctx": ctx}
	if not proc.is_empty():
		entry["proc"] = proc
	g.s.events.queue.append(entry)


func due_entries() -> Array:
	var out := []
	for q in g.s.events.queue:
		if int(q.due) <= int(g.s.day):
			out.append(q)
	return out


func expire() -> void:
	var keep := []
	for q in g.s.events.queue:
		if int(q.expires) < int(g.s.day):
			var ev: Dictionary = q.get("proc", Data.events.get(q.id, {}))
			g.add_log("Missed: %s." % ev.get("title", q.id), "warn")
			continue
		keep.append(q)
	g.s.events.queue = keep


func next_ready() -> Dictionary:
	## Highest-urgency due event to show now (or empty).
	var order := {"immediate": 0, "urgent": 1, "normal": 2, "background": 3}
	var best := {}
	for q in due_entries():
		if q.get("deferred_until", -1) > int(g.s.day):
			continue
		if p().activity == "closed_door" and q.urgency in ["normal", "background"]:
			continue
		if best.is_empty() or order.get(q.urgency, 2) < order.get(best.urgency, 2):
			best = q
	return best


# ------------------------------------------------------------ instances -----
func instantiate(q: Dictionary) -> Dictionary:
	var ev: Dictionary = q.get("proc", Data.events.get(q.id, {}))
	var ctx: Dictionary = q.ctx.duplicate()
	if ev.has("npc") and not ctx.has("npc"):
		if ev.npc == "known":
			var known := g.known_npcs()
			if known.size() > 0:
				ctx["npc"] = known[g.rng.randi_range(0, known.size() - 1)]
		else:
			ctx["npc"] = ev.npc
			g.ensure_npc_met(ev.npc)
	var inst := {"q": q, "ev": ev, "ctx": ctx, "title": fill(ev.title, ctx), "text": fill(ev.text, ctx), "choices": []}
	for c in ev.choices:
		var reason := req_fail(c.get("req", {}), ev)
		inst.choices.append({"text": fill(c.text, ctx), "reason": reason, "hint": c.get("hint", ""), "odds": odds_text(c), "raw": c})
	return inst


func fill(t: String, ctx: Dictionary) -> String:
	var pl := p()
	var npc_name := ""
	if ctx.has("npc") and g.s.npcs.has(ctx.npc):
		npc_name = g.s.npcs[ctx.npc].name
	var rival := ""
	if g.s.npcs.has(pl.get("rival_id", "")):
		rival = g.s.npcs[pl.rival_id].name
	var loc_name: String = Data.locations.get(pl.location, {"name": "the wilds"}).name
	return t.format({"name": pl.name, "clan": Data.clans[pl.clan].name, "loc": loc_name, "path": Data.path_name(pl.primary_path),
			"npc": npc_name, "rival": rival, "year": str(g.world_year())})


func req_fail(req: Dictionary, ev: Dictionary) -> String:
	var pl := p()
	for k in req.keys():
		var v = req[k]
		match k:
			"stones":
				var need := g.scaled_amount(v)
				if pl.stones < need:
					return "Needs %d stones" % need
			"immortal_stones":
				if int(pl.istones) < int(v):
					return "Needs %d immortal essence stones" % int(v)
			"info":
				if int(pl.info) < int(v):
					return "Needs %d information" % int(v)
			"mat":
				var n := int(req.get("mat_n", 1))
				if int(pl.mats.get(v, 0)) < n:
					return "Needs %d %s" % [n, Data.materials[v].name]
			"mat_n":
				pass
			"rank":
				if pl.rank < int(v):
					return "Needs Rank %d" % int(v)
			"injured":
				if v and pl.injuries.is_empty():
					return "You are not injured"
			"gu_tag":
				var found := false
				for gi in g.equipped():
					if v in Data.gu[gi.id].tags:
						found = true
				if not found:
					return "Needs an equipped %s Gu" % v
			"has_rival":
				if not g.s.npcs.has(pl.get("rival_id", "")) or not g.s.npcs[pl.rival_id].alive:
					return "No rival"
			"rival_alive":
				if not g.s.npcs.has(pl.get("rival_id", "")) or not g.s.npcs[pl.rival_id].alive:
					return "Rival gone"
			"story":
				var st: Dictionary = g.s.stories.get(v, {})
				if st.is_empty() or st.get("done", false) or int(st.step) < int(req.get("step", 0)) or int(st.step) > int(req.get("step", 0)):
					return "story"
			"step", "days_since":
				if k == "days_since" and req.has("story"):
					var st2: Dictionary = g.s.stories.get(req.story, {})
					if not st2.is_empty() and int(g.s.day) - int(st2.get("day", 0)) < int(v):
						return "Not yet"
			"not_known":
				if v in pl.known_locs:
					return "known"
			"age_min":
				if g.cult.age_years() < float(v):
					return "Too young"
			"align_max":
				if int(pl.align) > int(v):
					return "Not demonic enough"
			"align_min":
				if int(pl.align) < int(v):
					return "Not righteous enough"
			"flag":
				if not pl.flags.has(v):
					return "Locked"
			"standing":
				if g.standing_index() < Data.standing.map(func(x): return x[0]).find(v):
					return "Needs %s standing" % v
	return ""


# ------------------------------------------------------- odds (wisdom) ------
func check_chance(chk: Dictionary) -> float:
	var pl := p()
	var c := float(chk.get("p", 0.5))
	if chk.has("stat"):
		var stat: String = chk.stat
		var pts := float(pl.attain.get(stat, 0))
		c += 0.06 * Data.tier_index(pts) + minf(0.1, pts / 2000.0)
	c += 0.02 * (pl.rank - 1)
	if g.s.mode == "hard":
		c -= 0.08
	return clampf(c, 0.05, 0.95)


func odds_text(c: Dictionary) -> String:
	if not c.has("check"):
		return ""
	var chk: Dictionary = c.check
	if chk.type == "combat":
		return "Battle"
	var pc := check_chance(chk) * 100.0
	var w := g.wisdom_score()
	if w < 20:
		return "You have no idea what might happen"
	if w < 40:
		return "Looks promising" if pc >= 55 else ("Seems risky" if pc < 45 else "Hard to say")
	if w < 60:
		if pc >= 70:
			return "Good chance"
		if pc >= 55:
			return "Better than even"
		if pc >= 45:
			return "About even odds"
		return "Poor odds"
	if w < 80:
		return "~%d%% success" % int(round(pc / 5.0) * 5)
	return "%.1f%% success" % pc


# ------------------------------------------------------------ resolution ----
func choose(inst: Dictionary, idx: int) -> Dictionary:
	## Returns {"combat": setup} if a battle must be fought first, else {"text": outcome}.
	var ch: Dictionary = inst.choices[idx]
	if ch.reason != "":
		return {"text": ch.reason, "blocked": true}
	var raw: Dictionary = ch.raw
	_consume(inst)
	g.s.events.seen[inst.q.id] = true
	g.s.events.last_seen[inst.q.id] = int(g.s.day)
	if raw.has("check") and raw.check.type == "combat":
		var setup := g.combat_setup_from_check(raw.check)
		setup["after"] = {"inst": inst, "choice": idx}
		return {"combat": setup}
	var ok := true
	if raw.has("check") and raw.check.type == "chance":
		ok = g.rng.randf() < check_chance(raw.check)
	var effects: Array = raw.ok if ok else raw.get("fail", [])
	var lines := apply(effects, inst.ctx)
	var head := ""
	if raw.has("check"):
		head = "Success. " if ok else "Failure. "
	return {"text": head + "\n".join(lines), "ok": ok}


func after_combat(inst: Dictionary, idx: int, won: bool) -> String:
	var raw: Dictionary = inst.choices[idx].raw
	var effects: Array = raw.ok if won else raw.get("fail", [])
	return "\n".join(apply(effects, inst.ctx))


func _consume(inst: Dictionary) -> void:
	g.s.events.queue.erase(inst.q)


func defer(inst: Dictionary) -> void:
	inst.q["deferred_until"] = int(g.s.day) + 1


func dismiss(inst: Dictionary) -> void:
	_consume(inst)
	g.s.events.seen[inst.q.id] = true
	g.s.events.last_seen[inst.q.id] = int(g.s.day)


func apply(effects: Array, ctx: Dictionary) -> Array:
	var out := []
	for e in effects:
		var line = _apply_one(e, ctx)
		if line != null and str(line) != "":
			out.append(str(line))
	g.emit_signal("state_changed")
	return out


func _chance_gate(e: Dictionary) -> bool:
	return not e.has("chance") or g.rng.randf() < float(e.chance)


func _apply_one(e: Dictionary, ctx: Dictionary):
	var pl := p()
	if not _chance_gate(e):
		return null
	match e.do:
		"log":
			return e.text
		"stones":
			var n := g.scaled_amount(e.n)
			if n < 0 and pl.stones < -n:
				n = -pl.stones
			pl.stones += n
			if n != 0:
				Sfx.play("coin")
			return "%+d primeval stones." % n if n != 0 else ""
		"immortal_stones":
			pl.istones = maxi(0, int(pl.istones) + int(e.n))
			return "%+d immortal essence stones." % int(e.n)
		"mat":
			g.add_material(e.id, int(e.n))
			return "%+d %s." % [int(e.n), Data.materials[e.id].name]
		"mat_tier":
			var lst := Data.material_tier_list(e.tier)
			var got := []
			for i in int(e.n):
				var m: String = lst[g.rng.randi_range(0, lst.size() - 1)]
				g.add_material(m, 1)
				got.append(Data.materials[m].name)
			return "Found: %s." % ", ".join(got)
		"gu":
			var gi := g.add_gu(e.id)
			return "Obtained %s!" % Data.gu[e.id].name if not gi.is_empty() else "Your storage is full; you leave a Gu behind."
		"gu_pool":
			var gid := g.random_gu(e.get("rank", "r"), e.get("rarity", ""), e.get("path", ""))
			if gid == "":
				return ""
			var gi2 := g.add_gu(gid)
			if gi2.is_empty():
				return "Your storage is full; you leave a Gu behind."
			return e.get("log", "") + (" " if e.has("log") else "") + "Obtained %s!" % Data.gu[gid].name
		"time":
			g.skip_days(int(e.days))
			return "%d days pass." % int(e.days)
		"rep":
			g.change_align(int(e.n))
			return ("Your righteous reputation grows." if int(e.n) > 0 else "Your name grows darker.") if absi(int(e.n)) >= 5 else ""
		"fame":
			pl.fame = maxi(0, int(pl.fame) + int(e.n))
			return "Fame %+d." % int(e.n)
		"damage":
			var d := int(g.max_hp() * float(e.pct))
			pl.hp = maxi(1, pl.hp - d)
			return "You lose %d HP." % d
		"heal":
			pl.hp = mini(g.max_hp(), pl.hp + int(g.max_hp() * float(e.pct)))
			return "You recover."
		"cult":
			var n := float(g.scaled_amount(e.n))
			if pl.rank < 6:
				pl.progress = minf(Data.stage_req(pl.rank, pl.stage), float(pl.progress) + n)
			else:
				g.add_dao(int(n / 4.0))
			return e.get("log", "") + (" " if e.has("log") else "") + "Cultivation +%d." % int(n)
		"attain":
			var path: String = pl.primary_path if e.path == "primary" else e.path
			g.add_attain(path, float(e.n))
			return "%s attainment +%d." % [Data.path_name(path), int(e.n)]
		"info":
			pl.info = maxi(0, int(pl.info) + int(e.n))
			return "Information %+d." % int(e.n)
		"formula":
			var f := g.learn_random_formula(e.get("rank", "r"), e.get("path", ""))
			return "Learned the formula for %s." % Data.gu[f].name if f != "" else ""
		"killer":
			var id: String = e.get("id", "")
			if id == "primary":
				id = g.primary_killer()
			if id != "" and not (id in pl.killers):
				pl.killers.append(id)
				return "Learned the killer move %s!" % Data.killers[id].name
			return ""
		"flag":
			pl.flags[e.id] = true
			if e.id == "beat_fire_boss":
				Meta.set_flag("beat_fire_boss")
			return ""
		"unflag":
			pl.flags.erase(e.id)
			return ""
		"injury":
			g.add_injury(e.name, int(e.days))
			return "Injured: %s." % e.name
		"status":
			g.add_injury("Lingering Poison", 20)
			return "Poison lingers in your veins."
		"cure":
			pl.injuries.clear()
			return "Your injuries are healed."
		"lifespan":
			pl.lifespan_days += int(e.years) * Data.YEAR
			return "Lifespan +%d years." % int(e.years)
		"story":
			if not g.s.stories.has(e.id):
				g.s.stories[e.id] = {"step": 0, "day": g.s.day}
				g.add_log("New storyline: %s." % Data.storylines[e.id].name, "great")
			g.s.stories[e.id].step = int(e.step)
			g.s.stories[e.id].day = int(g.s.day)
			return ""
		"story_done":
			if not g.s.stories.has(e.id):
				g.s.stories[e.id] = {"step": 0, "day": g.s.day}
			g.s.stories[e.id].done = true
			g.add_log("Storyline complete: %s." % Data.storylines[e.id].name, "great")
			g.s.stats.stories += 1
			return "Storyline complete!"
		"queue":
			enqueue(e.id, ctx, int(e.get("days", 1)))
			return ""
		"reveal":
			if not (e.loc in pl.known_locs):
				pl.known_locs.append(e.loc)
				return "Discovered: %s!" % Data.locations[e.loc].name
			return ""
		"meet_npc":
			var nid: String = e.get("npc", "")
			if nid == "":
				nid = g.npc_by_arch(e.arch)
			if nid != "":
				g.ensure_npc_met(nid)
				g.change_disp(nid, int(e.get("disp", 5)))
				return "You meet %s." % g.s.npcs[nid].name
			return ""
		"disp":
			g.ensure_npc_met(e.npc)
			g.change_disp(e.npc, int(e.n))
			return "%s's opinion of you %s." % [g.s.npcs[e.npc].name, "improves" if int(e.n) > 0 else "sours"]
		"disp_npc":
			if ctx.has("npc"):
				g.change_disp(ctx.npc, int(e.n))
				return "%s seems %s." % [g.s.npcs[ctx.npc].name, "pleased" if int(e.n) > 0 else "displeased"]
			return ""
		"disp_arch":
			var nid2 := g.npc_by_arch(e.arch, true)
			if nid2 != "":
				g.ensure_npc_met(nid2)
				g.change_disp(nid2, int(e.n))
			return ""
		"disp_rival":
			if g.s.npcs.has(pl.get("rival_id", "")):
				g.change_disp(pl.rival_id, int(e.n))
			return ""
		"relation":
			g.ensure_npc_met(e.npc)
			g.set_relation(e.npc, e.level)
			return "%s is now a %s." % [g.s.npcs[e.npc].name, e.level]
		"standing":
			g.add_standing(int(e.n))
			return "Clan contribution %+d." % int(e.n)
		"open_market":
			g.request_market(e.kind, float(e.get("discount", 0)))
			return ""
		"starve":
			for gi in pl.gu:
				gi.unfed = int(gi.unfed) + int(e.weeks)
			return "Your Gu go hungry."
		"bt_bonus":
			pl.bt_bonus = float(pl.get("bt_bonus", 0)) + float(e.n)
			return "+%d%% to your next breakthrough." % int(e.n)
		"achieve":
			g.achieve(e.id)
			return ""
		"kill_npc":
			if g.s.npcs.has(e.npc):
				g.s.npcs[e.npc].alive = false
			return ""
		"kill_rival":
			if g.s.npcs.has(pl.get("rival_id", "")):
				g.s.npcs[pl.rival_id].alive = false
			return ""
		"rival_lose":
			return ""
		"rival_friend":
			if g.s.npcs.has(pl.get("rival_id", "")):
				g.set_relation(pl.rival_id, "Connection")
				g.change_disp(pl.rival_id, 60)
			return ""
		"dao":
			g.add_dao(int(e.n))
			return "Dao marks +%d." % int(e.n)
		"beast_companion":
			if g.s.blessed != null:
				g.s.blessed.beasts.append(e.name)
				return "A %s now guards your blessed land." % e.name
			return ""
	return ""
