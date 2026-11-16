class_name Bot
extends RefCounted
## A simple autopilot that plays a whole life. Used by the automated playthrough tests and by
## the in-game "Auto-play" toggle. It only calls the same public functions the UI calls.

var g
var log_lines := []
var last_hunt := 0
var last_shop := 0
var decisions := 0


func _init(game) -> void:
	g = game


func p() -> Dictionary:
	return g.s.player


func step() -> void:
	## One decision. Call repeatedly; it advances time itself when there is nothing to decide.
	if not g.has_run():
		return
	decisions += 1
	if g.combat != null:
		g.bot_fight()
		return
	if not g.current_event.is_empty():
		_answer_event()
		return
	var pl := p()
	# immortal tribulation preparation
	if pl.get("trib", {}) is Dictionary and pl.get("trib", {}).get("stage", "") == "prepare":
		var offer := mini(int(pl.stones), 400 + 200 * g.immortal.allies().size())
		g.immortal.start_heaven(offer)
		return
	if pl.activity in ["travel", "refine", "mission"]:
		g.advance_day()
		return
	# health first
	if int(pl.hp) < int(g.max_hp() * 0.45) or pl.injuries.size() > 1:
		if int(pl.stones) > g.econ.heal_cost() * 2 and "clinic" in Data.locations[pl.location].get("services", []):
			g.econ.heal_service()
		elif pl.activity != "rest":
			g.set_activity("rest")
		g.advance_day()
		return
	if g.is_immortal():
		_immortal_turn()
		return
	# breakthrough when ready
	if g.cult.can_breakthrough() == "":
		var r: Dictionary = g.breakthrough()
		if r.get("kind", "") == "specialize":
			g.choose_specialization(pl.primary_path)
		return
	_maybe_shop()
	_maybe_refine()
	if pl.activity == "refine":
		return
	# clan missions are the steadiest income
	if int(pl.hp) >= int(g.max_hp() * 0.7) and int(pl.stones) < g.weekly_feed_cost() * 8 + 120 * int(pl.rank):
		var ms: Array = g.world.available_missions().filter(func(a): return a.ok)
		if ms.size() > 0:
			var pick: Dictionary = ms[g.rng.randi_range(0, ms.size() - 1)]
			if g.set_activity("mission", {"mission": pick.m.id}) == "":
				return
	if not g.world.available_missions().is_empty() == false and int(pl.stones) < g.weekly_feed_cost() * 3 \
			and Data.locations[pl.location].get("clan", "") != pl.clan and g.rng.randf() < 0.05:
		g.start_travel(Data.clans[pl.clan].home)
		return
	# hunt now and then for materials, attainment and loot
	if int(g.s.day) - last_hunt > 25 and not Data.locations[pl.location].get("safe", false) \
			and int(pl.hp) >= int(g.max_hp() * 0.8):
		last_hunt = int(g.s.day)
		if g.hunt() == "":
			return
	if int(g.s.day) - last_hunt > 25 and Data.locations[pl.location].get("safe", false) and g.rng.randf() < 0.02:
		_travel_somewhere()
		return
	_manage_upkeep()
	if pl.activity != "cultivate":
		pl.intensity = 2 if int(pl.stones) > g.weekly_feed_cost() * 4 + 60 * int(pl.rank) else 1
		var why: String = g.set_activity("cultivate")
		if why != "":
			g.set_activity("study", {"path": pl.primary_path})
	g.advance_day()


func _answer_event() -> void:
	var inst: Dictionary = g.current_event
	var best := -1
	var choices: Array = inst.get("choices", [])
	# prefer a choice that has no reason to be blocked; skip obviously suicidal ones when weak
	for i in choices.size():
		if choices[i].get("reason", "") == "":
			best = i
			if g.rng.randf() < 0.55:
				break
	if best < 0:
		g.dismiss_event()
		return
	var r: Dictionary = g.resolve_event_choice(best)
	if r.get("blocked", false):
		g.dismiss_event()


func _maybe_shop() -> void:
	var pl := p()
	if int(g.s.day) - last_shop < 30:
		return
	last_shop = int(g.s.day)
	for kind in g.econ.market_kinds_here():
		var m: Dictionary = g.econ.market(kind)
		for i in range(m.items.size() - 1, -1, -1):
			var it: Dictionary = m.items[i]
			if it.type != "gu" or it.cur != "stones":
				continue
			var gd: Dictionary = Data.gu[it.id]
			if int(gd.rank) > int(pl.rank):
				continue
			if int(it.price) < int(pl.stones) * 0.4 and g.can_equip({"uid": -1, "id": it.id, "eq": false}) == "":
				g.econ.buy(kind, i)
				return


func _manage_upkeep() -> void:
	## Sell materials and starving Gu rather than letting them die.
	var pl := p()
	if int(pl.stones) >= g.weekly_feed_cost() * 2:
		return
	for mid in pl.mats.keys():
		while int(pl.mats.get(mid, 0)) > 2 and mid != "immortal_stone":
			if g.econ.sell_mat(mid) != "":
				break
	for gi in pl.gu.duplicate():
		if int(gi.get("unfed", 0)) >= 4 and pl.gu.size() > 5:
			g.econ.sell_gu(int(gi.uid))
			return


func _maybe_refine() -> void:
	var pl := p()
	for fid in pl.formulas:
		if g.econ.can_refine(fid) == "" and g.rng.randf() < 0.5:
			g.set_activity("refine", {"formula": fid})
			return


func _travel_somewhere() -> void:
	var pl := p()
	var opts := []
	for lid in pl.known_locs:
		var l: Dictionary = Data.locations[lid]
		if lid != pl.location and int(l.rank[0]) <= int(pl.rank) and int(l.get("danger", 1)) <= int(pl.rank) * 2 + 1:
			opts.append(lid)
	if opts.is_empty():
		return
	g.start_travel(opts[g.rng.randi_range(0, opts.size() - 1)])


func _immortal_turn() -> void:
	var pl := p()
	var b = g.s.blessed
	if b != null:
		if g.rng.randf() < 0.05:
			g.immortal.harvest()
		for sid in ["cultivation_chamber", "refinement_room", "defensive_formation"]:
			if not (sid in b.structures) and g.immortal.build(sid) == "":
				break
	var r: Dictionary = g.immortal.attempt_rank_up() if g.rng.randf() < 0.1 else {"kind": "blocked"}
	if r.get("kind", "") != "blocked":
		return
	_maybe_shop()
	_maybe_refine()
	if pl.activity == "refine":
		return
	if int(g.s.day) - last_hunt > 40 and int(pl.hp) >= int(g.max_hp() * 0.8) and not Data.locations[pl.location].get("safe", false):
		last_hunt = int(g.s.day)
		if g.hunt() == "":
			return
	if pl.activity != "closed_door":
		if not pl.get("in_land", false):
			g.enter_land()
		g.set_activity("closed_door")
	g.advance_day()


func play_life(max_steps := 400000) -> Dictionary:
	var n := 0
	while g.has_run() and n < max_steps:
		step()
		n += 1
	return {"steps": n, "ended": g.s.get("ended", false), "day": int(g.s.day), "rank": int(p().rank)}
