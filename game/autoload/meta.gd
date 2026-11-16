extends Node
## Everything that outlives a single life: inheritance points and the legacy bank, permanent unlocks,
## the statistics vault (used for dynamic balancing), achievements and settings. Saved to user://meta.json.

const PATH := "user://meta.json"
const MAX_LEGACY := 3

var persist := true
var d := {}


func _ready() -> void:
	load_meta()


func defaults() -> Dictionary:
	return {
		"version": 1, "points": 0, "pending": [], "flags": {}, "achievements": {},
		"unlocked": {"clans": ["gu_yue"], "starts": ["standard"], "modes": ["normal"], "regions": ["southern_border"]},
		"stats": {"runs": 0, "victories": 0, "best_rank": 1, "total_days": 0, "deaths": {}, "clan_best": {},
				"path_plays": {}, "streak_rank": 0, "streak": 0, "best_points": 0, "history": []},
		"settings": {"api_key": "", "model": "claude-opus-5-5", "ai_enabled": true, "music": 0.6, "sfx": 0.8,
				"fullscreen": false, "sandbox": false, "autopause": {"event": true, "combat": true, "breakthrough": true,
				"travel": true, "mission": false}, "speed_default": 1, "tutorial": true},
	}


func load_meta() -> void:
	d = defaults()
	if not persist or not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var v = JSON.parse_string(f.get_as_text())
	if typeof(v) != TYPE_DICTIONARY:
		return
	_merge(d, v)
	d.points = int(d.points)
	d.stats.best_rank = int(d.stats.best_rank)


func _merge(into: Dictionary, src: Dictionary) -> void:
	for k in src:
		if into.has(k) and typeof(into[k]) == TYPE_DICTIONARY and typeof(src[k]) == TYPE_DICTIONARY:
			_merge(into[k], src[k])
		else:
			into[k] = src[k]


func save_meta() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "\t"))


func reset_for_tests() -> void:
	persist = false
	d = defaults()


func setting(k: String, def = null):
	return d.settings.get(k, def)


func set_setting(k: String, v) -> void:
	d.settings[k] = v
	save_meta()


func sandbox() -> bool:
	return bool(d.settings.get("sandbox", false))


# ------------------------------------------------------------------ unlocks ----
func is_unlocked(kind: String, id: String) -> bool:
	return sandbox() or id in d.unlocked.get(kind, [])


func unlock(kind: String, id: String, label := "") -> void:
	if id in d.unlocked[kind]:
		return
	d.unlocked[kind].append(id)
	save_meta()
	if Game.has_run() and label != "":
		Game.add_log("Unlocked for future lives: %s." % label, "great")
		Game.emit_signal("toast", "Unlocked: %s" % label)


func unlock_text(cond) -> String:
	if cond == null:
		return ""
	return str(cond.get("text", "Locked"))


func _cond_met(cond, ctx: Dictionary) -> bool:
	if cond == null:
		return true
	match str(cond.type):
		"rank":
			return int(ctx.get("rank", d.stats.best_rank)) >= int(cond.rank) or int(d.stats.best_rank) >= int(cond.rank)
		"rank_with_clan":
			return int(d.stats.clan_best.get(cond.clan, 0)) >= int(cond.rank)
		"rank_attain":
			var attain: Dictionary = ctx.get("attain", {})
			return int(ctx.get("rank", 0)) >= int(cond.rank) and \
					Data.tier_index(float(attain.get(cond.path, 0))) >= Data.tier_index_of(cond.tier)
		"flag":
			return d.flags.has(cond.flag)
		"days":
			return int(ctx.get("days", 0)) >= int(cond.days)
	return false


func check_unlocks(ctx := {}) -> void:
	for c in Data.clan_list:
		if not (c.id in d.unlocked.clans) and _cond_met(c.get("unlock"), ctx):
			unlock("clans", c.id, "the %s clan" % c.name)
	for st in Data.starts:
		if not (st.id in d.unlocked.starts) and _cond_met(st.get("unlock"), ctx):
			unlock("starts", st.id, st.name)
	# New Game+ modes: Hard and Ironman after any victory or Rank 5; Speed and Path Challenge after Rank 3.
	var best := int(d.stats.best_rank)
	if best >= 3 or int(d.stats.victories) > 0:
		unlock("modes", "speed", "Speed Run mode")
		unlock("modes", "path_challenge", "Path Challenge mode")
	if best >= 5 or int(d.stats.victories) > 0:
		unlock("modes", "hard", "Hard mode")
		unlock("modes", "ironman", "Ironman mode")
	if best >= 6:
		unlock("regions", "northern_plains", "the Northern Plains")
	if best >= 7:
		unlock("regions", "central_continent", "the Central Continent")


func set_flag(id: String) -> void:
	if d.flags.has(id):
		return
	d.flags[id] = true
	save_meta()
	check_unlocks()


func record_achievement(id: String) -> void:
	if d.achievements.has(id):
		return
	d.achievements[id] = Time.get_date_string_from_system()
	save_meta()


func on_rank(rank: int, clan: String, attain: Dictionary) -> void:
	d.stats.best_rank = maxi(int(d.stats.best_rank), rank)
	d.stats.clan_best[clan] = maxi(int(d.stats.clan_best.get(clan, 0)), rank)
	save_meta()
	check_unlocks({"rank": rank, "attain": attain})


# ------------------------------------------------------------- inheritance ----
func points_for(summary: Dictionary) -> int:
	## Docs/Systems/Inheritance.md, with DEC-043: time bonus is years lived as a cultivator x 5.
	var pts := int(summary.max_rank) * 100
	pts += int(float(summary.days) / Data.YEAR * 5.0)
	pts += summary.get("achieved", []).size() * 25
	pts += int(summary.stats.get("bosses", 0)) * 20
	if summary.get("victory", false):
		pts += 500 + 1000   # victory bonus + Venerable legacy
	if str(summary.get("mode", "")) == "hard":
		pts = int(pts * 1.25)
	elif str(summary.get("mode", "")) == "speed" and summary.get("victory", false):
		pts += maxi(0, 3000 - int(float(summary.days) / Data.YEAR * 50.0))
	# catch-up: repeated deaths at the same rank earn more
	if not summary.get("victory", false) and int(d.stats.streak_rank) == int(summary.max_rank):
		pts = int(pts * (1.0 + 0.1 * mini(5, int(d.stats.streak))))
	return pts


func on_run_end(summary: Dictionary) -> void:
	var st: Dictionary = d.stats
	st.runs = int(st.runs) + 1
	st.total_days = int(st.total_days) + int(summary.days)
	if summary.get("victory", false):
		st.victories = int(st.victories) + 1
	st.deaths[summary.cause] = int(st.deaths.get(summary.cause, 0)) + 1
	if int(st.streak_rank) == int(summary.max_rank) and not summary.get("victory", false):
		st.streak = int(st.streak) + 1
	else:
		st.streak_rank = int(summary.max_rank)
		st.streak = 1
	for path in summary.stats.get("plays", {}):
		st.path_plays[path] = int(st.path_plays.get(path, 0)) + int(summary.stats.plays[path])
	st.best_points = maxi(int(st.best_points), int(summary.points))
	st.history.append({"name": summary.name, "clan": summary.clan, "rank": summary.max_rank, "age": summary.age,
			"cause": summary.cause, "points": summary.points, "date": Time.get_date_string_from_system()})
	while st.history.size() > 30:
		st.history.pop_front()
	d.points = int(d.points) + int(summary.points)
	save_meta()
	check_unlocks({"rank": int(summary.max_rank), "days": int(summary.days)})


func inheritance_def(id: String) -> Dictionary:
	for i in Data.inheritance:
		if i.id == id:
			return i
	return {}


func can_buy(id: String) -> String:
	var i := inheritance_def(id)
	if i.is_empty():
		return "Unknown"
	if d.pending.size() >= MAX_LEGACY:
		return "You may carry at most %d legacies into one life." % MAX_LEGACY
	if id in d.pending and i.kind in ["killer", "location"]:
		return "Already chosen."
	if int(d.points) < int(i.cost) and not sandbox():
		return "Needs %d points." % int(i.cost)
	return ""


func buy(id: String) -> String:
	var why := can_buy(id)
	if why != "":
		return why
	if not sandbox():
		d.points = int(d.points) - int(inheritance_def(id).cost)
	d.pending.append(id)
	save_meta()
	return ""


func refund(idx: int) -> void:
	if idx < 0 or idx >= d.pending.size():
		return
	var i := inheritance_def(d.pending[idx])
	if not sandbox():
		d.points = int(d.points) + int(i.get("cost", 0))
	d.pending.remove_at(idx)
	save_meta()


func apply_legacy(g) -> void:
	var pl: Dictionary = g.s.player
	for id in d.pending:
		var i := inheritance_def(id)
		if i.is_empty():
			continue
		match str(i.kind):
			"formula":
				var f: String = g.learn_random_formula(int(i.rank), pl.primary_path)
				if f != "":
					g.add_log("Legacy: you remember how to refine %s." % Data.gu[f].name, "great")
			"killer":
				var k: String = g.primary_killer()
				if k != "" and not (k in pl.killers):
					pl.killers.append(k)
					g.add_log("Legacy: the killer move %s is already in your mind." % Data.killers[k].name, "great")
			"cache":
				var locs := []
				for l in Data.locations.values():
					if l.id != pl.location and l.type in ["village", "wild"] and int(l.rank[0]) <= 1 \
							and not l.get("hidden", false) and not l.has("region_unlock"):
						locs.append(l.id)
				if locs.size() > 0:
					var loc: String = locs[g.rng.randi_range(0, locs.size() - 1)]
					if not pl.has("caches"):
						pl["caches"] = []
					pl.caches.append({"loc": loc, "stones": int(i.stones), "claimed": false})
					g.add_log("Legacy: you dreamt of a cache hidden at %s." % Data.locations[loc].name, "great")
			"insight":
				g.add_attain(pl.primary_path, float(i.points))
				g.add_log("Legacy: insight from a past life (+%d %s attainment)." % [int(i.points), Data.path_name(pl.primary_path)], "great")
			"npc":
				var cands := []
				for n in g.s.npcs.values():
					if n.get("notable", false) or n.has("seed"):
						cands.append(n)
				if cands.is_empty():
					cands = g.s.npcs.values()
				if cands.size() > 0:
					var n: Dictionary = cands[g.rng.randi_range(0, cands.size() - 1)]
					n.met = true
					n.disp = maxi(int(n.disp), 40 if i.level == "Contact" else 70)
					g.set_relation(n.id, i.level)
					g.add_log("Legacy: %s feels they have known you for years." % n.name, "great")
			"location":
				if not (i.loc in pl.known_locs):
					pl.known_locs.append(i.loc)
				g.add_log("Legacy: you know the way to %s." % Data.locations[i.loc].name, "great")
			"reputation":
				pl.fame = int(pl.fame) + int(i.points)
	d.pending = []
	save_meta()


# ----------------------------------------------------- dynamic balancing ------
func aptitude_luck() -> float:
	## Catch-up: each consecutive death at the same rank nudges aptitude rolls upward a little.
	return 0.03 * mini(4, int(d.stats.get("streak", 0)) - 1) if int(d.stats.get("streak", 0)) > 1 else 0.0


func path_balance(path: String) -> float:
	## Paths that players lean on heavily generate slightly weaker new Gu; neglected paths slightly stronger.
	var total := 0
	for k in d.stats.path_plays:
		total += int(d.stats.path_plays[k])
	if total < 200:
		return 1.0
	var share := float(d.stats.path_plays.get(path, 0)) / float(total)
	if share > 0.3:
		return maxf(0.9, 1.0 - (share - 0.3) * 0.3)
	if share < 0.05:
		return 1.05
	return 1.0
