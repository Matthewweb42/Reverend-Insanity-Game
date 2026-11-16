extends Node
## Run state and the real-time loop. Everything a run needs lives in `s` (JSON-safe dicts) so it
## can be saved verbatim. Systems live in core/*.gd and reach back here through `g`.

signal state_changed
signal log_added(entry)
signal event_ready(inst)
signal combat_started
signal run_ended(summary)
signal toast(text, kind)
signal market_requested(kind, discount)
signal notice(title, text)   # modal information (breakthrough results, tribulations, etc.)

const SAVE_DIR := "user://saves"
const DAYS_PER_SEC := 5.0
const CLOSED_DOOR_MULT := 25.0
const BASE_LIFESPAN_YEARS := 100
const STORAGE_BASE := 6

var s := {}
var rng := RandomNumberGenerator.new()
var cult: Cultivation
var events: EventSystem
var econ: Economy
var world: World
var immortal: Immortal
var procgen: ProcGen

var speed := 1             # 1, 2, 4
var paused := true
var headless := false      # tests / bot: no auto time, no UI
var combat: Combat = null
var combat_setup := {}
var current_event := {}
var _acc := 0.0
var _uid := 0
var slot := 1


func _ready() -> void:
	cult = Cultivation.new(self)
	events = EventSystem.new(self)
	econ = Economy.new(self)
	world = World.new(self)
	immortal = Immortal.new(self)
	procgen = ProcGen.new(self)


func has_run() -> bool:
	return not s.is_empty() and not s.get("ended", false)


func p() -> Dictionary:
	return s.player


# ====================================================================== NEW GAME
func roll_aptitude(r: RandomNumberGenerator = null) -> String:
	var rr := r if r != null else rng
	var x := rr.randf() + Meta.aptitude_luck()
	if x >= 0.92:
		return "A"
	if x >= 0.68:
		return "B"
	if x >= 0.22:
		return "C"
	return "D"


func new_game(opts: Dictionary) -> void:
	## opts: name, clan, start, mode, aptitude, seed, legacy (bool: apply pending inheritances)
	var seed_v: int = int(opts.get("seed", 0))
	if seed_v == 0:
		rng.randomize()
		seed_v = rng.randi()
	rng.seed = seed_v
	_uid = 0
	var clan: Dictionary = Data.clans[opts.get("clan", "gu_yue")]
	var start: String = opts.get("start", "standard")
	var mode: String = opts.get("mode", "normal")
	var apt: String = opts.get("aptitude", roll_aptitude())
	if start == "prodigy":
		apt = "A"
	var age_years := int(clan.age)
	var stones := int(clan.stones)
	if start == "young":
		age_years -= 3
		stones = int(stones * 0.7)
	var lifespan_years := BASE_LIFESPAN_YEARS + rng.randi_range(-8, 8)
	if mode == "speed":
		lifespan_years = 60
	s = {
		"version": 1, "seed": seed_v, "mode": mode, "start": start, "day": 0, "ended": false, "uid": 0,
		"world_start_year": 3000 + rng.randi_range(0, 400),
		"player": {
			"name": opts.get("name", "Fang Yuan"), "clan": clan.id, "aptitude": apt, "rank": 1, "stage": 0,
			"progress": 0.0, "intensity": 2, "stones": stones, "istones": 0, "hp": 1, "info": 0, "align": 0,
			"fame": 0, "standing": 0, "location": clan.home, "activity": "idle", "act": {},
			"gu": [], "mats": {}, "formulas": [], "killers": [], "attain": {}, "injuries": [],
			"known_locs": [], "visited": [clan.home], "flags": {}, "lifespan_days": lifespan_years * Data.YEAR,
			"age_days": age_years * Data.YEAR + rng.randi_range(0, 200), "primary_path": clan.primary,
			"bt_bonus": 0.0, "bt_cooldown": 0, "peak_days": 0, "lost_slots": 0, "zombie": false, "rival_id": "",
			"dao": {}, "intel": {}, "faction": "", "mentor": "", "specialization": "", "trial_passed": false,
			"auto_feed": true, "last_breakthrough_text": "",
		},
		"npcs": {}, "events": {"queue": [], "seen": {}, "last_seen": {}}, "goals": [], "stories": {},
		"epochs": [], "markets": {}, "blessed": null, "log": [],
		"stats": {"battles": 0, "wins": 0, "losses": 0, "fled": 0, "bosses": 0, "killers": 0, "gu_refined": 0,
				"events": 0, "stories": 0, "max_stones": stones, "max_rank": 1, "deaths_avoided": 0,
				"plays": {}, "tribulations": 0, "days_cultivated": 0},
		"achieved": {},
	}
	var pl := p()
	for path in clan.paths:
		pl.attain[path] = 10.0
	pl.attain[clan.primary] = 30.0
	pl.attain["none"] = 0.0
	if clan.km != null and clan.km != "":
		pl.killers.append(clan.km)
	_init_known_locations()
	var region: String = opts.get("region", "southern_border")
	if region == "northern_plains" or region == "central_continent":
		pl.known_locs.append("northern_plains")
	if region == "central_continent":
		pl.known_locs.append("central_continent")
	for gid in clan.start_gu:
		var gi := add_gu(gid, true)
		if not gi.is_empty() and can_equip(gi) == "":
			gi.eq = true
	pl.hp = max_hp()
	if start == "reincarnator":
		pl.known_locs.append("hu_immortal_land")
		for path in clan.paths:
			pl.attain[path] = float(pl.attain[path]) + 50.0
		learn_random_formula(1, clan.primary)
		learn_random_formula(2, clan.primary)
	if start == "prodigy":
		pl.flags["no_rival"] = true
	world.generate()
	if opts.get("legacy", true):
		Meta.apply_legacy(self)
	_starter_formulas()
	add_log("%s, %s of the %s, begins cultivating. Age %d, %s aptitude." % [pl.name, "a youth", clan.name,
			int(cult.age_years()), Data.APTITUDE[apt].label], "head")
	add_log("Set a goal from the Goals panel to steer what you find.", "info")
	add_goal("path_training", {"path": clan.primary}, true)
	paused = true
	speed = 1
	current_event = {}
	combat = null
	emit_signal("state_changed")


func _init_known_locations() -> void:
	var pl := p()
	for l in Data.locations.values():
		if l.get("hidden", false):
			continue
		if l.get("hidden_unless_clan", false) and l.get("clan", "") != pl.clan:
			continue
		if l.has("region_unlock"):
			continue
		pl.known_locs.append(l.id)


func _starter_formulas() -> void:
	## Each clan teaches the formulas for its own Rank 1 Gu.
	var pl := p()
	for f in Data.formulas.values():
		if int(f.rank) == 1 and (f.get("clan", "") == pl.clan or f.path in Data.clans[pl.clan].paths):
			if not (f.id in pl.formulas):
				pl.formulas.append(f.id)


# ====================================================================== LOG/UTIL
func add_log(text: String, kind := "info") -> void:
	if s.is_empty():
		return
	var entry := {"day": int(s.day), "text": text, "kind": kind}
	s.log.append(entry)
	if s.log.size() > 400:
		s.log = s.log.slice(s.log.size() - 400)
	emit_signal("log_added", entry)
	if kind in ["great", "bad", "warn"]:
		emit_signal("toast", text, kind)


func next_uid() -> int:
	s.uid = int(s.uid) + 1
	return int(s.uid)


func world_year() -> int:
	return int(s.world_start_year) + int(s.day) / Data.YEAR


func date_text() -> String:
	var d := int(s.day)
	var y := world_year()
	var month := (d % Data.YEAR) / 30 + 1
	var dom := d % 30 + 1
	return "Year %d, Month %d, Day %d" % [y, month, dom]


func season() -> String:
	var m := (int(s.day) % Data.YEAR) / 30
	return ["Spring", "Spring", "Spring", "Summer", "Summer", "Summer", "Autumn", "Autumn", "Autumn", "Winter", "Winter", "Winter"][m]


func scaled_amount(v) -> int:
	## "40r" -> 40 * rank. Plain numbers pass through.
	if typeof(v) == TYPE_STRING:
		var t: String = v
		if t.ends_with("r"):
			return int(float(t.substr(0, t.length() - 1)) * int(p().rank))
		return int(t)
	return int(v)


func is_immortal() -> bool:
	return int(p().rank) >= 6


# ====================================================================== DERIVED STATS
func max_hp() -> int:
	var pl := p()
	var hp := int(Data.MAX_HP[int(pl.rank) - 1])
	hp += int(Data.clans[pl.clan].hp_bonus) * int(pl.rank)
	for gi in equipped():
		var gd: Dictionary = Data.gu[gi.id]
		if gd.kind == "defense":
			hp += int(4 * int(gd.rank))
	if pl.get("zombie", false):
		hp = int(hp * 1.3)
	return hp


func max_essence() -> int:
	var pl := p()
	var e := int(Data.MAX_ESSENCE[int(pl.rank) - 1])
	var apt: String = pl.aptitude
	e = int(e * {"A": 1.2, "B": 1.1, "C": 1.0, "D": 0.85}[apt])
	return e


func slots_total() -> int:
	return int(Data.SLOTS[int(p().rank) - 1]) - int(p().get("lost_slots", 0))


func slots_used() -> int:
	var n := 0
	for gi in equipped():
		n += int(Data.gu[gi.id].rank)
	return n


func storage_cap() -> int:
	var c := STORAGE_BASE
	for gi in equipped():
		var gd: Dictionary = Data.gu[gi.id]
		if gd.has("passive") and gd.passive.has("carry"):
			c += int(gd.passive.carry)
	if s.blessed != null:
		c += 30
	return c


func stored_count() -> int:
	var n := 0
	for gi in p().gu:
		if not gi.eq:
			n += 1
	return n


func equipped() -> Array:
	var out := []
	for gi in p().gu:
		if gi.eq:
			out.append(gi)
	return out


func find_gu(uid: int) -> Dictionary:
	for gi in p().gu:
		if int(gi.uid) == uid:
			return gi
	return {}


func feed_state(gi: Dictionary) -> String:
	var w := int(gi.unfed)
	if w <= 1:
		return "Fed"
	if w <= 3:
		return "Hungry"
	return "Starving"


func gu_power(gi: Dictionary) -> float:
	var pl := p()
	var gd: Dictionary = Data.gu[gi.id]
	var diff := int(pl.rank) - int(gd.rank)
	var eff := 1.0
	if diff >= 1:
		eff = [1.0, 0.9, 0.7, 0.5][mini(diff, 3)]
	if int(pl.rank) >= 6 and int(gd.rank) < 6:
		eff *= 0.6   # mortal Gu barely scratch immortals
	var w := int(gi.unfed)
	var feed := 1.0 if w <= 1 else (0.5 if w <= 3 else 0.25)
	var tier := Data.tier_index(float(pl.attain.get(gd.path, 0)))
	var att := 1.0 + 0.1 * tier
	if gd.path == "none":
		att = 1.0
	var dao_bonus := 1.0 + 0.002 * int(pl.dao.get(gd.path, 0))
	return eff * feed * att * dao_bonus * (1.0 + float(gi.get("refined", 0.0)))


func can_equip(gi: Dictionary) -> String:
	var pl := p()
	var gd: Dictionary = Data.gu[gi.id]
	if gi.eq:
		return ""
	if int(gd.rank) > int(pl.rank):
		return "Rank %d Gu: you are only Rank %d" % [int(gd.rank), int(pl.rank)]
	if int(gd.rank) >= 6 and int(pl.rank) < 6:
		return "Only an immortal can use an Immortal Gu"
	if slots_used() + int(gd.rank) > slots_total():
		return "Not enough aperture space (%d/%d)" % [slots_used(), slots_total()]
	if s.mode == "path_challenge" and gd.path != pl.primary_path and gd.path != "none":
		return "Path Challenge: only %s and neutral Gu" % Data.path_name(pl.primary_path)
	if gd.kind == "consumable":
		return "Consumables stay in storage; use them instead"
	return ""


func equip(uid: int, on: bool) -> String:
	var gi := find_gu(uid)
	if gi.is_empty():
		return "No such Gu"
	if on:
		var r := can_equip(gi)
		if r != "":
			return r
		gi.eq = true
	else:
		if stored_count() >= storage_cap():
			return "Your storage is full"
		gi.eq = false
	emit_signal("state_changed")
	return ""


func add_gu(gid: String, quiet := false) -> Dictionary:
	if not Data.gu.has(gid):
		return {}
	var gi := {"uid": next_uid(), "id": gid, "eq": false, "unfed": 0, "refined": 0.0}
	var gd: Dictionary = Data.gu[gid]
	p().gu.append(gi)
	if not s.is_empty() and s.has("achieved") and not quiet:
		add_log("Obtained %s (Rank %d %s)." % [gd.name, int(gd.rank), gd.rarity], "good")
	# auto-equip if room, otherwise into storage, otherwise lost
	if can_equip(gi) == "" and gd.kind != "consumable":
		gi.eq = true
	elif stored_count() > storage_cap():
		p().gu.erase(gi)
		add_log("No room for %s. You release it." % gd.name, "warn")
		return {}
	world.check_goals()
	return gi


func remove_gu(uid: int) -> void:
	var gi := find_gu(uid)
	if not gi.is_empty():
		p().gu.erase(gi)


func random_gu(rank_v, rarity := "", path := "") -> String:
	var r := scaled_amount(rank_v) if typeof(rank_v) == TYPE_STRING else int(rank_v)
	r = clampi(r, 1, 8)
	var f := {"rank": r, "consumables": true}
	if rarity != "":
		f["rarity"] = rarity
	if path != "":
		f["path"] = p().primary_path if path == "primary" else path
	var pool := Data.gu_pool(f)
	if pool.is_empty():
		f.erase("rarity")
		pool = Data.gu_pool(f)
	if pool.is_empty():
		f.erase("path")
		pool = Data.gu_pool(f)
	if pool.is_empty():
		return ""
	# rarity weighting
	var weights := {"common": 10.0, "uncommon": 5.0, "rare": 2.0, "legendary": 0.6}
	var total := 0.0
	for g in pool:
		total += weights.get(g.rarity, 1.0)
	var roll := rng.randf() * total
	for g in pool:
		roll -= weights.get(g.rarity, 1.0)
		if roll <= 0:
			return g.id
	return pool[0].id


func add_material(id: String, n: int) -> void:
	var pl := p()
	pl.mats[id] = maxi(0, int(pl.mats.get(id, 0)) + n)
	if int(pl.mats[id]) == 0:
		pl.mats.erase(id)


func learn_random_formula(rank_v, path := "") -> String:
	var r := scaled_amount(rank_v) if typeof(rank_v) == TYPE_STRING else int(rank_v)
	var pl := p()
	var cands := []
	for f in Data.formulas.values():
		if int(f.rank) != r or f.id in pl.formulas:
			continue
		if path != "" and f.path != (pl.primary_path if path == "primary" else path):
			continue
		cands.append(f.id)
	if cands.is_empty():
		for f in Data.formulas.values():
			if int(f.rank) <= r and not (f.id in pl.formulas):
				cands.append(f.id)
	if cands.is_empty():
		return ""
	var id: String = cands[rng.randi_range(0, cands.size() - 1)]
	pl.formulas.append(id)
	return id


func primary_killer() -> String:
	var pl := p()
	for km in Data.killers.values():
		if km.path == pl.primary_path and not (km.id in pl.killers):
			return km.id
	for km in Data.killers.values():
		if not (km.id in pl.killers):
			return km.id
	return ""


func add_attain(path: String, n: float) -> void:
	var pl := p()
	if path == "" or path == "none":
		return
	var mult := 1.0 + float(Data.clans[pl.clan].bonus.get("attain", {}).get(path, 0.0))
	var before := Data.tier_index(float(pl.attain.get(path, 0)))
	pl.attain[path] = float(pl.attain.get(path, 0)) + n * mult
	var after := Data.tier_index(float(pl.attain[path]))
	if after > before:
		add_log("%s attainment reaches %s!" % [Data.path_name(path), Data.TIERS[after]], "great")
		if after >= 2:
			achieve("master_path")
	world.check_goals()


func add_dao(n: int) -> void:
	var pl := p()
	var path: String = pl.primary_path
	pl.dao[path] = int(pl.dao.get(path, 0)) + n
	if s.blessed != null:
		s.blessed.dao[path] = int(s.blessed.dao.get(path, 0)) + n


func dao_total() -> int:
	var t := 0
	for v in p().dao.values():
		t += int(v)
	return t


func add_injury(name: String, days: int) -> void:
	var pl := p()
	for inj in pl.injuries:
		if inj.name == name:
			inj.days = maxi(int(inj.days), days)
			return
	pl.injuries.append({"name": name, "days": days})


func change_align(n: int) -> void:
	p().align = clampi(int(p().align) + n, -100, 100)


func alignment_text() -> String:
	var a := int(p().align)
	if a >= 50:
		return "Righteous Hero"
	if a >= 15:
		return "Righteous"
	if a > -15:
		return "Unaligned"
	if a > -50:
		return "Demonic"
	return "Demonic Devil"


func wisdom_score() -> int:
	var pl := p()
	var w := 20 + int(Data.tier_index(float(pl.attain.get("wisdom", 0))) * 15)
	for gi in equipped():
		var gd: Dictionary = Data.gu[gi.id]
		if gd.has("passive") and gd.passive.has("wisdom"):
			w += int(gd.passive.wisdom)
	w += mini(15, int(pl.info) / 4)
	return w


func mentor_bonus() -> int:
	var m: String = p().get("mentor", "")
	if m != "" and s.npcs.has(m) and s.npcs[m].alive and int(s.npcs[m].disp) >= 50:
		return 5
	return 0


# ---- clan standing
func standing_name() -> String:
	var pts := int(p().standing)
	var out := "Outsider"
	for st in Data.standing:
		if pts >= int(st[1]):
			out = st[0]
	if int(p().align) < -40:
		return "Outsider"   # demonic deeds get you cast out
	return out


func standing_index() -> int:
	var nm := standing_name()
	for i in Data.standing.size():
		if Data.standing[i][0] == nm:
			return i
	return 0


func add_standing(n: int) -> void:
	var before := standing_name()
	p().standing = int(p().standing) + n
	var after := standing_name()
	if after != before:
		add_log("Your clan standing is now %s." % after, "great" if n > 0 else "bad")
		if after == "Elder":
			achieve("elder")


# ---- NPC helpers
func known_npcs() -> Array:
	var out := []
	for n in s.npcs.values():
		if n.met and n.alive:
			out.append(n.id)
	return out


func ensure_npc_met(id: String) -> void:
	if not s.npcs.has(id):
		world.spawn_seed(id)
	if s.npcs.has(id) and not s.npcs[id].met:
		s.npcs[id].met = true
		add_log("You make the acquaintance of %s." % s.npcs[id].name, "info")


func npc_by_arch(arch: String, any := false) -> String:
	var best := ""
	for n in s.npcs.values():
		if n.arch == arch and n.alive:
			if n.loc == p().location:
				return n.id
			if best == "" or any:
				best = n.id
	return best


func change_disp(id: String, n: int) -> void:
	world.change_disp(id, n)


func set_relation(id: String, level: String) -> void:
	world.set_relation(id, level)


func request_market(kind: String, discount: float) -> void:
	econ.open_special(kind, discount)
	emit_signal("market_requested", kind, discount)


func achieve(id: String) -> void:
	if s.achieved.has(id) or not Data.achievements.has(id):
		return
	s.achieved[id] = int(s.day)
	add_log("Achievement: %s." % Data.achievements[id].name, "great")
	Meta.record_achievement(id)


# ---- goals (thin wrappers; logic in world.gd)
func add_goal(type_id: String, params: Dictionary, primary := false) -> String:
	return world.add_goal(type_id, params, primary)


func goal_tags() -> Array:
	var out := []
	for gl in s.goals:
		if not gl.done:
			out.append(gl.tag)
	return out


func primary_goal_tag() -> String:
	for gl in s.goals:
		if gl.primary and not gl.done:
			return gl.tag
	return ""


# ====================================================================== TIME LOOP
func _process(delta: float) -> void:
	if headless or not has_run() or paused or combat != null or not current_event.is_empty():
		return
	var mult := float(speed)
	if p().activity == "closed_door":
		mult *= CLOSED_DOOR_MULT
	_acc += delta * DAYS_PER_SEC * mult
	var guard := 0
	while _acc >= 1.0 and guard < 400:
		guard += 1
		_acc -= 1.0
		advance_day()
		if paused or combat != null or not current_event.is_empty() or not has_run():
			_acc = 0.0
			break


func skip_days(n: int) -> void:
	for i in n:
		advance_day(false)
		if not has_run():
			return


func advance_day(allow_events := true) -> void:
	if not has_run():
		return
	var pl := p()
	s.day = int(s.day) + 1
	pl.age_days = int(pl.age_days) + 1
	var d := int(s.day)
	_activity_tick()
	if not has_run():
		return
	# passive recovery
	if pl.activity != "rest":
		pl.hp = mini(max_hp(), int(pl.hp) + maxi(1, int(max_hp() * 0.03)))
	var keep := []
	for inj in pl.injuries:
		inj.days = int(inj.days) - (2 if pl.activity == "rest" else 1)
		if int(inj.days) > 0:
			keep.append(inj)
		else:
			add_log("Recovered from %s." % inj.name, "good")
	pl.injuries = keep
	if int(pl.bt_cooldown) > 0:
		pl.bt_cooldown = int(pl.bt_cooldown) - 1
	if d % 7 == 0:
		_weekly()
	if d % 30 == 0:
		_monthly()
	if d % Data.YEAR == 0:
		_yearly()
	immortal.daily()
	if not has_run():
		return
	# aging
	if int(pl.age_days) >= int(pl.lifespan_days):
		end_run("age", "Died of old age at %d." % int(cult.age_years()))
		return
	var band_now: String = cult.age_band().name
	if band_now != pl.get("_band", "Prime"):
		pl["_band"] = band_now
		if band_now != "Prime":
			add_log("Aging: %s. Your body is weakening; seek longevity Gu." % band_now, "warn")
	s.stats.max_stones = maxi(int(s.stats.max_stones), int(pl.stones))
	if int(pl.stones) >= 2000:
		achieve("wealthy")
	if cult.age_years() >= 100:
		achieve("centenarian")
	if allow_events:
		events.expire()
		var kind := "travel" if pl.activity == "travel" else "location"
		events.roll_daily(kind)
		world.daily()
		_surface_event()
	emit_signal("state_changed")


func _surface_event() -> void:
	if not current_event.is_empty() or combat != null:
		return
	var q := events.next_ready()
	if q.is_empty():
		return
	current_event = events.instantiate(q)
	s.stats.events = int(s.stats.events) + 1
	paused = true
	Sfx.play("page")
	emit_signal("event_ready", current_event)


func open_queued_event(q: Dictionary) -> void:
	if not current_event.is_empty():
		return
	q.erase("deferred_until")
	current_event = events.instantiate(q)
	paused = true
	emit_signal("event_ready", current_event)


func resolve_event_choice(idx: int) -> Dictionary:
	## Returns {"text"} or {"combat": true}. Closes the event unless a battle follows.
	var inst := current_event
	var r := events.choose(inst, idx)
	if r.get("blocked", false):
		return r
	if r.has("combat"):
		current_event = {}
		start_combat(r.combat)
		return {"combat": true}
	current_event = {}
	world.check_goals()
	emit_signal("state_changed")
	return r


func defer_event() -> void:
	if current_event.is_empty():
		return
	events.defer(current_event)
	current_event = {}


func dismiss_event() -> void:
	if current_event.is_empty():
		return
	events.dismiss(current_event)
	current_event = {}


func _weekly() -> void:
	_feed_gu()
	world.weekly()
	econ.weekly()


func _monthly() -> void:
	var pl := p()
	var stip := int(Data.stipend.get(standing_name(), 0))
	if stip > 0 and not is_immortal():
		pl.stones = int(pl.stones) + stip
		add_log("Clan stipend: +%d primeval stones." % stip, "info")
	if is_immortal() and pl.faction != "":
		pl.istones = int(pl.istones) + 2
	world.monthly()
	autosave()


func _yearly() -> void:
	world.yearly()
	add_log("A new year begins: %d. You are %d." % [world_year(), int(cult.age_years())], "head")


func _feed_gu() -> void:
	var pl := p()
	var mult := 1.0
	for gi in equipped():
		var gd: Dictionary = Data.gu[gi.id]
		if gd.has("passive") and gd.passive.has("feed_mult"):
			mult = minf(mult, float(gd.passive.feed_mult))
	var died := []
	var unfed_names := []
	for gi in pl.gu:
		var gd: Dictionary = Data.gu[gi.id]
		if gd.kind == "consumable":
			continue
		var cost := int(ceil(float(gd.feed) * mult))
		if int(gd.rank) >= 6:
			# immortal Gu eat immortal essence stones (1 per 10 mortal-equivalent)
			var ic := maxi(1, cost / 150)
			if pl.auto_feed and int(pl.istones) >= ic:
				pl.istones = int(pl.istones) - ic
				gi.unfed = 0
				continue
		elif pl.auto_feed and int(pl.stones) >= cost:
			pl.stones = int(pl.stones) - cost
			gi.unfed = 0
			continue
		gi.unfed = int(gi.unfed) + 1
		unfed_names.append(gd.name)
		if int(gi.unfed) >= 8:
			died.append(gi)
	for gi in died:
		pl.gu.erase(gi)
		add_log("%s starved to death." % Data.gu[gi.id].name, "bad")
	if unfed_names.size() > 0:
		add_log("Could not feed: %s." % ", ".join(unfed_names.slice(0, 4)), "warn")


func weekly_feed_cost() -> int:
	var mult := 1.0
	for gi in equipped():
		var gd: Dictionary = Data.gu[gi.id]
		if gd.has("passive") and gd.passive.has("feed_mult"):
			mult = minf(mult, float(gd.passive.feed_mult))
	var c := 0
	for gi in p().gu:
		var gd: Dictionary = Data.gu[gi.id]
		if gd.kind != "consumable" and int(gd.rank) < 6:
			c += int(ceil(float(gd.feed) * mult))
	return c


# ====================================================================== ACTIVITIES
func set_activity(kind: String, data: Dictionary = {}) -> String:
	var pl := p()
	if pl.activity == "travel" and kind != "idle" and kind != "travel":
		return "You are travelling."
	match kind:
		"cultivate", "closed_door":
			if is_immortal():
				pass
			elif float(pl.progress) >= Data.stage_req(int(pl.rank), int(pl.stage)):
				return "Your aperture is full. Attempt a breakthrough."
		"study":
			if not data.has("path"):
				data["path"] = pl.primary_path
		"refine":
			var why := econ.can_refine(data.get("formula", ""))
			if why != "":
				return why
			econ.start_refine(data.formula)
			return ""
		"mission":
			return world.start_mission(data.get("mission", ""))
	pl.activity = kind
	pl.act = data
	if kind == "closed_door":
		add_log("You seal yourself in closed-door cultivation. Time rushes by.", "info")
	emit_signal("state_changed")
	return ""


func activity_text() -> String:
	var pl := p()
	match pl.activity:
		"idle":
			return "Idle (progress slowly decays)"
		"cultivate":
			if is_immortal():
				return "Comprehending the Dao"
			return "Cultivating (%s)" % Data.INTENSITY[int(pl.intensity)].name
		"closed_door":
			return "Closed-door cultivation"
		"rest":
			return "Resting"
		"study":
			return "Studying %s" % Data.path_name(pl.act.get("path", pl.primary_path))
		"refine":
			return "Refining %s (%d days left)" % [Data.gu[Data.formulas[pl.act.formula].id].name if Data.formulas.has(pl.act.get("formula", "")) else "Gu", int(pl.act.get("left", 0))]
		"mission":
			return "Mission: %s (%d days left)" % [pl.act.get("name", ""), int(pl.act.get("left", 0))]
		"travel":
			var dest: String = pl.act.get("dest", "")
			return "Travelling to %s (%d days left)" % [Data.locations[dest].name if Data.locations.has(dest) else dest, int(pl.act.get("left", 0))]
	return pl.activity


func _activity_tick() -> void:
	var pl := p()
	var a: String = pl.activity
	match a:
		"cultivate", "closed_door":
			if is_immortal():
				immortal.cultivate_day(a == "closed_door")
			else:
				cult.daily(true, true)
				s.stats.days_cultivated = int(s.stats.days_cultivated) + 1
				if float(pl.progress) >= Data.stage_req(int(pl.rank), int(pl.stage)):
					pl.activity = "idle"
					add_log("Your aperture is full. You can attempt a breakthrough.", "great")
					if bool(Meta.setting("autopause", {}).get("breakthrough", true)):
						paused = true
		"rest":
			pl.hp = mini(max_hp(), int(pl.hp) + maxi(2, int(max_hp() * 0.15)))
			cult.daily(false, true)
		"study":
			var path: String = pl.act.get("path", pl.primary_path)
			var lib := 2.0 if "library" in Data.locations.get(pl.location, {}).get("services", []) else 1.0
			add_attain(path, 0.9 * lib * (1.0 + 0.15 * cult.age_band().cult - 0.15))
			cult.daily(false, true)
			if rng.randf() < 0.05:
				pl.info = int(pl.info) + 1
		"refine":
			cult.daily(false, true)
			pl.act.left = int(pl.act.left) - 1
			if int(pl.act.left) <= 0:
				econ.finish_refine()
				pl.activity = "idle"
		"mission":
			cult.daily(false, true)
			pl.act.left = int(pl.act.left) - 1
			if int(pl.act.left) <= 0:
				pl.activity = "idle"
				world.finish_mission()
		"travel":
			cult.daily(false, true)
			_travel_tick()
		_:
			cult.daily(false, false)


# ---- travel
func travel_mult() -> float:
	var m := 1.0
	for gi in equipped():
		var gd: Dictionary = Data.gu[gi.id]
		if gd.has("passive") and gd.passive.has("travel_mult"):
			m = minf(m, float(gd.passive.travel_mult))
	if is_immortal():
		m *= 0.3
	return m


func travel_plan(dest: String) -> Dictionary:
	var pl := p()
	if dest == pl.location:
		return {"error": "You are already here."}
	if not (dest in pl.known_locs):
		return {"error": "You do not know the way."}
	var loc: Dictionary = Data.locations[dest]
	if loc.has("req"):
		if int(pl.rank) < int(loc.req.get("rank", 0)):
			return {"error": "Needs Rank %d." % int(loc.req.rank)}
		if loc.req.has("item") and not has_item(loc.req.item):
			return {"error": "Needs the %s." % Data.gu[loc.req.item].name}
	var route := Data.path_between(pl.location, dest, pl.known_locs)
	if route.is_empty():
		return {"error": "No known route."}
	var days := maxi(1, int(round(Data.route_days(route) * travel_mult())))
	return {"route": route, "days": days}


func has_item(gid: String) -> bool:
	for gi in p().gu:
		if gi.id == gid:
			return true
	return false


func enter_land() -> String:
	## Step inside your own blessed land (immortals only). Time there runs on the land's own clock.
	if not is_immortal() or s.blessed == null:
		return "You have no blessed land."
	var pl := p()
	if pl.activity == "travel":
		return "Finish your journey first."
	pl.in_land = true
	add_log("You step into %s." % s.blessed.get("name", "your blessed land"), "info")
	Sfx.music("immortal")
	emit_signal("state_changed")
	return ""


func leave_land() -> void:
	p().in_land = false
	add_log("You return to the mortal world at %s." % Data.locations[p().location].name, "info")
	emit_signal("state_changed")


func start_travel(dest: String) -> String:
	var plan := travel_plan(dest)
	if plan.has("error"):
		return plan.error
	var pl := p()
	pl.in_land = false
	pl.activity = "travel"
	pl.act = {"dest": dest, "route": plan.route, "left": plan.days, "total": plan.days, "from": pl.location}
	add_log("You set out for %s (%d days)." % [Data.locations[dest].name, plan.days], "info")
	emit_signal("state_changed")
	return ""


func _travel_tick() -> void:
	var pl := p()
	pl.act.left = int(pl.act.left) - 1
	if int(pl.act.left) <= 0:
		arrive(pl.act.dest)


func arrive(dest: String) -> void:
	var pl := p()
	pl.location = dest
	pl.activity = "idle"
	pl.act = {}
	if not (dest in pl.visited):
		pl.visited.append(dest)
		add_log("You arrive at %s for the first time." % Data.locations[dest].name, "good")
		if pl.visited.size() >= 8:
			achieve("explorer")
	else:
		add_log("You arrive at %s." % Data.locations[dest].name, "info")
	world.on_arrive(dest)
	world.check_goals()
	if not headless and bool(Meta.setting("autopause", {}).get("travel", true)):
		paused = true
	emit_signal("state_changed")


func travel_progress() -> float:
	var pl := p()
	if pl.activity != "travel":
		return 0.0
	return 1.0 - float(pl.act.left) / maxf(1.0, float(pl.act.total))


# ---- breakthrough
func breakthrough() -> Dictionary:
	var pl := p()
	if is_immortal():
		return immortal.attempt_rank_up()
	var why := cult.can_breakthrough()
	if why != "":
		return {"ok": false, "text": why, "kind": "blocked"}
	if int(pl.rank) == 5 and int(pl.stage) == 3:
		return immortal.begin_ascension()
	# Rank 2->3 and above need a trial; Rank 4->5 also asks for a specialization.
	if cult.is_rank_breakthrough() and int(pl.rank) >= 2 and not pl.trial_passed:
		if int(pl.rank) == 4 and pl.specialization == "":
			return {"ok": false, "kind": "specialize", "text": "Choose your specialization before the Rank 5 breakthrough."}
		start_trial()
		return {"ok": false, "kind": "trial", "text": "A heart demon rises to test you."}
	var r := cult.attempt_breakthrough()
	if r.kind in ["stage", "rank", "fail", "crit"]:
		Sfx.play("gong" if r.ok else "fail")
	if r.kind == "rank":
		pl.trial_passed = false
	pl.last_breakthrough_text = r.text
	emit_signal("state_changed")
	return r


func start_trial() -> void:
	var pl := p()
	var stages := 1 if int(pl.rank) == 2 else 2
	var defs := []
	for i in stages:
		defs.append({"id": "heart_demon", "rank": int(pl.rank), "tier": "elite" if i == 0 else "trained",
				"name": "Heart Demon" if i == 0 else "Shadow of Doubt"})
	start_combat({"enemies": defs, "env": [], "flee_allowed": false, "trial": true, "title": "Breakthrough Trial"})


func choose_specialization(path: String) -> void:
	var pl := p()
	pl.specialization = path
	add_attain(path, 50)
	add_log("You choose to specialise in %s. It will shape your tribulation." % Data.path_name(path), "great")


func on_rank_up() -> void:
	var pl := p()
	s.stats.max_rank = maxi(int(s.stats.max_rank), int(pl.rank))
	pl.hp = max_hp()
	add_log("RANK UP! You are now a %s." % Data.rank_title(int(pl.rank)), "great")
	if int(pl.rank) in [2, 3, 5]:
		achieve("rank_%d" % int(pl.rank))
	Meta.on_rank(int(pl.rank), pl.clan, pl.attain)
	if int(pl.rank) == 5 and not ("northern_plains" in pl.known_locs):
		pl.known_locs.append("northern_plains")
		add_log("Your strength lets you travel north: the Northern Plains are open to you.", "good")
	world.on_rank_up()
	emit_signal("state_changed")


func use_consumable(uid: int) -> String:
	var gi := find_gu(uid)
	if gi.is_empty():
		return "No such Gu"
	var gd: Dictionary = Data.gu[gi.id]
	if not gd.has("consumable"):
		return "Not a consumable"
	var pl := p()
	var c: Dictionary = gd.consumable
	match c.kind:
		"relic":
			var why := cult.use_relic()
			if why != "":
				return why
		"lifespan":
			pl.lifespan_days = int(pl.lifespan_days) + int(c.years) * Data.YEAR
			add_log("Lifespan extended by %d years." % int(c.years), "great")
		"breakthrough":
			pl.bt_bonus = float(pl.bt_bonus) + float(c.bonus)
			add_log("+%d%% to your next breakthrough." % int(c.bonus), "good")
		"heal_injury":
			pl.injuries.clear()
			pl.hp = max_hp()
			add_log("Your injuries close.", "good")
		"dao":
			add_dao(int(c.get("n", 30)))
			add_attain(pl.primary_path, 40)
			add_log("Insight floods your mind.", "great")
		"key":
			return "The key opens the Three Kings Blessed Land: travel there."
	remove_gu(uid)
	emit_signal("state_changed")
	return ""


# ====================================================================== COMBAT
func is_night() -> bool:
	return rng.randf() < 0.35


func combat_ctx(flee_allowed := true) -> Dictionary:
	var pl := p()
	var deck := []
	var can_flee := false
	var flee_bonus := 0
	var eva := 0
	for gi in equipped():
		var gd: Dictionary = Data.gu[gi.id]
		if gd.has("passive"):
			if gd.passive.has("flee"):
				can_flee = true
				flee_bonus = maxi(flee_bonus, int(float(gd.passive.flee) * 100) if float(gd.passive.flee) < 1.0 else int(gd.passive.flee))
				eva += 5
		if gd.effects.is_empty() or gd.kind == "consumable":
			continue
		deck.append({"id": gd.id, "name": gd.name, "path": gd.path, "rank": int(gd.rank), "cost": int(gd.cost),
				"effects": gd.effects, "flags": gd.flags, "power": gu_power(gi), "tags": gd.get("tags", []),
				"icon": gd.icon, "rarity": gd.rarity, "kind": gd.kind})
	var band: Dictionary = cult.age_band()
	var injury_mult := pow(0.95, pl.injuries.size())
	var night := is_night()
	return {
		"name": pl.name, "rank": int(pl.rank), "hp": int(pl.hp), "max_hp": max_hp(), "essence": max_essence(),
		"max_essence": max_essence(), "primary": pl.primary_path, "deck": deck, "attain": pl.attain.duplicate(),
		"km_practice": pl.get("km_practice", {}).duplicate(),
		"killers": pl.killers.duplicate(), "can_flee": can_flee, "flee_bonus": flee_bonus, "flee_allowed": flee_allowed,
		"damage_bonus": float(Data.clans[pl.clan].bonus.get("damage", 0.0)), "age_combat": float(band.combat) * injury_mult,
		"intel": 0, "night": night, "night_bonus": float(Data.clans[pl.clan].bonus.get("night", 0.0)),
		"enemy_mult": 1.3 if s.mode == "hard" else 1.0, "regen_bonus": 0, "eva_bonus": eva, "bot_may_flee": true,
		"icon": "meditation",
	}


func enemies_from_group(group: String, rank: int, count: int, tier := "") -> Array:
	var cands := []
	for e in Data.enemy_list:
		if e.group == group and int(e.rank) <= rank + 1:
			cands.append(e)
	if cands.is_empty():
		for e in Data.enemy_list:
			if e.group == group:
				cands.append(e)
	if cands.is_empty():
		cands = [Data.enemies.grey_wolf]
	# prefer enemies close to the requested rank
	cands.sort_custom(func(a, b): return absi(int(a.rank) - rank) < absi(int(b.rank) - rank))
	var top := cands.slice(0, mini(3, cands.size()))
	var out := []
	for i in count:
		var e: Dictionary = top[rng.randi_range(0, top.size() - 1)]
		var d := {"id": e.id, "rank": clampi(rank, 1, 9)}
		if tier != "":
			d["tier"] = tier
		elif e.tier == "boss" and count > 1:
			d["tier"] = "elite"
		out.append(d)
	return out


func combat_setup_from_check(chk: Dictionary) -> Dictionary:
	var pl := p()
	var rank := int(pl.rank)
	if chk.has("rank"):
		var rv = chk.rank
		if typeof(rv) == TYPE_STRING:
			if rv == "r":
				rank = int(pl.rank)
			elif rv.begins_with("r+"):
				rank = int(pl.rank) + int(rv.substr(2))
			elif rv.begins_with("r-"):
				rank = int(pl.rank) - int(rv.substr(2))
			else:
				rank = int(rv)
		else:
			rank = int(rv)
	rank = clampi(rank, 1, 9)
	var count := int(chk.get("count", 1))
	var tier: String = chk.get("tier", "")
	var defs := []
	if chk.has("enemy"):
		for i in count:
			var d := {"id": chk.enemy, "rank": rank}
			if tier != "":
				d["tier"] = tier
			defs.append(d)
	else:
		var group: String = chk.get("group", "")
		if group == "":
			var loc_groups: Array = Data.locations.get(pl.location, {}).get("enemies", ["wild"])
			group = loc_groups[rng.randi_range(0, loc_groups.size() - 1)] if loc_groups.size() > 0 else "wild"
		defs = enemies_from_group(group, rank, count, tier)
	return {"enemies": defs, "env": location_env(), "flee_allowed": not chk.get("no_flee", false),
			"ambush": chk.get("ambush", false)}


func location_env() -> Array:
	var pl := p()
	var envs: Array = Data.locations.get(pl.location, {}).get("env", [])
	var out := []
	if envs.size() > 0 and rng.randf() < 0.7:
		out.append(envs[rng.randi_range(0, envs.size() - 1)])
	return out


func start_combat(setup: Dictionary) -> void:
	var pl := p()
	combat_setup = setup
	combat = Combat.new()
	var ctx := combat_ctx(setup.get("flee_allowed", true))
	var intel_key := ""
	if setup.enemies.size() > 0:
		intel_key = setup.enemies[0].id
	ctx.intel = int(pl.intel.get(intel_key, 0))
	if setup.get("trial", false) or setup.get("tribulation", false):
		ctx.bot_may_flee = false
	combat.setup(ctx, setup.enemies, setup.get("env", []), rng.randi())
	combat.start(setup.get("ambush", false))
	paused = true
	s.stats.battles = int(s.stats.battles) + 1
	Sfx.music("combat" if not setup.get("tribulation", false) else "tribulation")
	emit_signal("combat_started")


func finish_combat() -> Dictionary:
	## Apply the outcome of `combat` and return {result, text, title}.
	var pl := p()
	var c := combat
	var setup := combat_setup
	combat = null
	combat_setup = {}
	Sfx.music("world" if not is_immortal() else "immortal")
	var res: String = c.result
	var won := res in ["win", "stalemate_win"]
	pl.hp = clampi(int(c.player.hp), 1, max_hp())
	var lines := []
	# attainment from use (practice builds understanding)
	for path in c.stats.plays.keys():
		var n := int(c.stats.plays[path])
		if path != "none" and n > 0:
			add_attain(path, n * 1.6 * (1.0 if won else 0.6))
			s.stats.plays[path] = int(s.stats.plays.get(path, 0)) + n
	if not pl.has("km_practice"):
		pl["km_practice"] = {}
	for kid in c.stats.get("killer_ids", {}):
		pl.km_practice[kid] = int(pl.km_practice.get(kid, 0)) + int(c.stats.killer_ids[kid])
	if c.stats.killer_used:
		s.stats.killers = int(s.stats.killers) + 1
		achieve("killer_move")
	# intel is spent
	if setup.enemies.size() > 0:
		pl.intel.erase(setup.enemies[0].id)
	if won:
		s.stats.wins = int(s.stats.wins) + 1
		achieve("first_blood")
		if setup.has("spar"):
			lines.append("A good bout. You both learned something.")
			add_attain(pl.primary_path, 4)
		elif not setup.get("trial", false) and not setup.get("tribulation", false):
			lines.append_array(_loot(c))
		if setup.has("duel"):
			pl.fame = int(pl.fame) + 3
			if g_npc(setup.duel).get("rival", false):
				lines.append("Your rival limps away, humiliated.")
		for e in c.enemies:
			if e.tier == "boss" and (not e.alive):
				s.stats.bosses = int(s.stats.bosses) + 1
				achieve("boss_slayer")
			if e.get("flag_on_win", "") != "":
				pl.flags[e.flag_on_win] = true
				Meta.set_flag(e.flag_on_win)
			if e.def == "ember_tyrant":
				pl.flags["beat_fire_boss"] = true
				Meta.set_flag("beat_fire_boss")
		if res == "stalemate_win":
			lines.push_front("The battle drags on until your foes withdraw.")
	elif res == "fled":
		s.stats.fled = int(s.stats.fled) + 1
		lines.append("You escaped.")
	else:
		s.stats.losses = int(s.stats.losses) + 1
		if setup.has("spar"):
			lines.append("You yield before anyone is badly hurt.")
			pl.hp = maxi(int(pl.hp), int(max_hp() * 0.3))
		elif not setup.get("trial", false) and not setup.get("tribulation", false):
			var out := _defeat(c)
			if not has_run():
				return {"result": "death", "text": out, "title": "Death"}
			lines.append(out)
	var text := "\n".join(lines)
	var title := {"win": "Victory", "stalemate_win": "Victory", "fled": "Escaped", "lose": "Defeat", "stalemate_lose": "Defeat"}.get(res, res)
	# continuations
	if setup.has("after"):
		var more := events.after_combat(setup.after.inst, int(setup.after.choice), won)
		if more != "":
			text = (text + "\n" if text != "" else "") + more
	if setup.get("mission", false):
		text += "\n" + world.mission_combat_done(won)
	if setup.get("trial", false):
		if won:
			pl.trial_passed = true
			text = "The heart demon dissolves. Your mind is clear: attempt the breakthrough again."
			add_log("You passed the breakthrough trial.", "great")
		else:
			pl.progress = float(pl.progress) * 0.8
			pl.bt_cooldown = 15
			add_injury("Heart Wound", 20)
			text = "The heart demon overwhelms you. Progress falls by 20% and you must wait 15 days."
			add_log("You failed the breakthrough trial.", "bad")
	if setup.get("tribulation", false):
		text = immortal.on_trib_combat(won, setup)
		if not has_run():
			return {"result": "death", "text": text, "title": "Death"}
	if setup.get("market_guard", false) and won:
		pass
	Sfx.play("victory" if won else ("defeat" if res != "fled" else "click"))
	world.check_goals()
	emit_signal("state_changed")
	return {"result": res, "text": text, "title": title}


func _loot(c: Combat) -> Array:
	var pl := p()
	var lines := []
	var stones := 0
	var tier_mult := {"mook": 0.6, "trained": 1.0, "elite": 2.0, "boss": 5.0}
	for e in c.enemies:
		var def: Dictionary = Data.enemies[e.def]
		var r := int(e.rank)
		if r >= 6:
			if rng.randf() < 0.6:
				var ist := int(r - 5) * rng.randi_range(1, 3)
				pl.istones = int(pl.istones) + ist
				lines.append("+%d immortal essence stones." % ist)
		if def.kind != "beast" or def.get("stones", false):
			stones += int(round(r * 10 * tier_mult.get(e.tier, 1.0) * rng.randf_range(0.5, 1.5)))
		else:
			# beasts guard little caches of primeval stones in their dens
			stones += int(round(r * 4 * tier_mult.get(e.tier, 1.0) * rng.randf_range(0.5, 1.5)))
		for m in def.get("mats", []):
			if rng.randf() < 0.5 + (0.3 if e.tier in ["elite", "boss"] else 0.0):
				add_material(m, 1)
				lines.append("+1 %s." % Data.materials[m].name)
		var drop := 0.10 + 0.05 * maxi(0, r - int(pl.rank))
		if e.tier == "boss":
			drop = 1.0
		elif e.tier == "elite":
			drop += 0.1
		if rng.randf() < drop:
			var gid := random_gu(mini(r, maxi(1, int(pl.rank))), "", def.path if rng.randf() < 0.5 else "")
			if gid != "":
				var gi := add_gu(gid, true)
				if not gi.is_empty():
					lines.append("Captured %s!" % Data.gu[gid].name)
	if stones > 0:
		if s.mode == "hard":
			stones = int(stones * 0.8)
		pl.stones = int(pl.stones) + stones
		lines.push_front("+%d primeval stones." % stones)
	return lines


func _defeat(c: Combat) -> String:
	var pl := p()
	var leth := 0.0
	var group := ""
	for e in c.enemies:
		var def: Dictionary = Data.enemies[e.def]
		if float(def.lethality) >= leth:
			leth = float(def.lethality)
			group = def.group
	if s.mode == "hard":
		leth += 0.1
	var death_chance := leth * 0.2
	if int(pl.rank) == 1 and s.mode != "hard":
		death_chance *= 0.5   # fledglings are usually left for dead rather than finished off
	if rng.randf() < death_chance:
		var killer: String = c.enemies[0].name
		end_run("combat", "Slain by %s." % killer)
		return "You were slain."
	s.stats.deaths_avoided = int(s.stats.deaths_avoided) + 1
	var lost := int(int(pl.stones) * 0.3)
	pl.stones = int(pl.stones) - lost
	add_injury("Battle Wounds", 20 + int(leth * 40))
	pl.hp = maxi(1, int(max_hp() * 0.2))
	var t := "You are beaten and left for dead. You lose %d stones and wake badly hurt." % lost
	if group in ["bandit", "demonic"] and rng.randf() < 0.35:
		var eq := equipped()
		var stored := []
		for gi in pl.gu:
			if not gi.eq:
				stored.append(gi)
		var pool := stored if stored.size() > 0 else eq
		if pool.size() > 1:
			var gi: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
			t += " They took your %s." % Data.gu[gi.id].name
			pl.gu.erase(gi)
	add_log(t, "bad")
	return t


func g_npc(id: String) -> Dictionary:
	return s.npcs.get(id, {})


func bot_fight() -> Dictionary:
	## Headless: let the bot play the current battle to its end.
	var guard := 0
	while combat != null and combat.result == "" and guard < 200:
		guard += 1
		combat.auto_turn()
	return finish_combat()


# ---- hunting / sparring from the world screen
func hunt() -> String:
	var pl := p()
	var loc: Dictionary = Data.locations[pl.location]
	if loc.get("safe", false):
		return "Nothing hunts here."
	var groups: Array = loc.get("enemies", [])
	if groups.is_empty():
		return "There is nothing to hunt here."
	var group: String = groups[rng.randi_range(0, groups.size() - 1)]
	var r := clampi(int(pl.rank) + rng.randi_range(-1, 0) + (1 if int(loc.danger) >= 5 else 0), 1, 9)
	var count := 1 + (1 if rng.randf() < 0.35 else 0)
	start_combat({"enemies": enemies_from_group(group, r, count), "env": location_env(), "flee_allowed": true})
	return ""


func research_enemy(enemy_id: String) -> String:
	var pl := p()
	if int(pl.info) < 1:
		return "Needs 1 information."
	pl.info = int(pl.info) - 1
	pl.intel[enemy_id] = mini(3, int(pl.intel.get(enemy_id, 0)) + 2)
	add_log("You study the habits of the %s. (+intel for your next fight against it)" % Data.enemies[enemy_id].name, "info")
	return ""


# ====================================================================== END OF RUN
func end_run(cause: String, text: String) -> void:
	if s.get("ended", false):
		return
	s.ended = true
	s.ended_cause = cause
	paused = true
	var pl := p()
	var summary := {
		"cause": cause, "text": text, "name": pl.name, "clan": pl.clan, "rank": int(pl.rank),
		"max_rank": maxi(int(s.stats.max_rank), int(pl.rank)), "days": int(s.day),
		"age": int(cult.age_years()), "victory": cause == "victory", "mode": s.mode,
		"achieved": s.achieved.keys(), "stats": s.stats.duplicate(true),
	}
	summary["points"] = Meta.points_for(summary)
	add_log(text, "head")
	Meta.on_run_end(summary)
	if s.mode == "ironman":
		delete_save(0)
	emit_signal("run_ended", summary)


func retire() -> void:
	end_run("retired", "%s retires from cultivation." % p().name)


# ====================================================================== SAVE / LOAD
func save_path(n: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, n]


func save_game(n: int = -1) -> String:
	if s.is_empty():
		return "Nothing to save"
	if n < 0:
		n = slot
	if s.mode == "ironman":
		n = 0
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var f := FileAccess.open(save_path(n), FileAccess.WRITE)
	if f == null:
		return "Could not write save"
	var meta := {"name": p().name, "clan": p().clan, "rank": int(p().rank), "date": date_text(), "mode": s.mode,
			"saved": Time.get_datetime_string_from_system(false, true)}
	f.store_string(JSON.stringify({"meta": meta, "state": s, "rng": rng.state}))
	f.close()
	return ""


func autosave() -> void:
	if has_run() and not headless:
		save_game(0 if s.mode == "ironman" else 0)


func list_saves() -> Array:
	var out := []
	for n in range(0, 4):
		var path := save_path(n)
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			var d = JSON.parse_string(f.get_as_text())
			if d != null and d.has("meta"):
				var m: Dictionary = d.meta
				m["slot"] = n
				out.append(m)
	return out


func load_game(n: int) -> String:
	var path := save_path(n)
	if not FileAccess.file_exists(path):
		return "No save in that slot"
	var f := FileAccess.open(path, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if d == null or not d.has("state"):
		return "Save is damaged"
	s = d.state
	_fix_types()
	procgen.restore_custom()
	rng.state = int(d.get("rng", 0))
	slot = n if n > 0 else 1
	combat = null
	current_event = {}
	paused = true
	emit_signal("state_changed")
	return ""


func delete_save(n: int) -> void:
	var path := save_path(n)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _fix_types() -> void:
	## JSON turns every number into a float; put the integer fields back.
	var ints := ["day", "uid", "world_start_year", "seed"]
	for k in ints:
		if s.has(k):
			s[k] = int(s[k])
	var pl := p()
	for k in ["rank", "stage", "intensity", "stones", "istones", "hp", "info", "align", "fame", "standing",
			"lifespan_days", "age_days", "bt_cooldown", "peak_days", "lost_slots"]:
		if pl.has(k):
			pl[k] = int(pl[k])
	for gi in pl.gu:
		gi.uid = int(gi.uid)
		gi.unfed = int(gi.unfed)
	for k in pl.mats.keys():
		pl.mats[k] = int(pl.mats[k])
	for n in s.npcs.values():
		for k in ["rank", "disp", "align", "talks"]:
			if n.has(k):
				n[k] = int(n[k])
