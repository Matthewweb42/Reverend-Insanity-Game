extends Node
## Static content database. Loads game/data/*.json (built by tools/content/build_content.py).

const TIERS := ["Ordinary", "Adept", "Master", "Quasi-Grandmaster", "Grandmaster"]
const TIER_POINTS := [0, 100, 300, 600, 1000]
const TIER_PLAYS := [1, 2, 3, 5, 6]
const STAGES := ["Initial", "Middle", "Upper", "Peak"]
const STAGE_REQ := {
	1: [50, 75, 100, 150], 2: [100, 150, 200, 300], 3: [200, 300, 400, 600],
	4: [400, 600, 800, 1200], 5: [800, 1200, 1800, 2400],
}
const SLOTS := [10, 20, 30, 40, 50, 100, 150, 200, 300]
const MAX_ESSENCE := [100, 200, 350, 500, 700, 2000, 5000, 10000, 50000]
const MAX_HP := [100, 155, 235, 340, 480, 1300, 2800, 5600, 11000]
const DMG_BASE := [12, 28, 48, 72, 98, 300, 650, 1300, 2800]
const ENEMY_HP := [80, 230, 450, 720, 1050, 3200, 7000, 14000, 30000]
const INTENSITY := [
	{"name": "Meditation", "stones": 0, "points": 0.25},
	{"name": "Steady", "stones": 1, "points": 0.5},
	{"name": "Focused", "stones": 2, "points": 1.0},
	{"name": "Intense", "stones": 5, "points": 1.75, "risk": 0.002},
	{"name": "Reckless", "stones": 12, "points": 2.5, "risk": 0.008},
]
const APTITUDE := {
	"A": {"mult": 1.5, "rank": 15, "stage": 5, "label": "A-grade"},
	"B": {"mult": 1.2, "rank": 8, "stage": 3, "label": "B-grade"},
	"C": {"mult": 1.0, "rank": 0, "stage": 0, "label": "C-grade"},
	"D": {"mult": 0.7, "rank": -10, "stage": -5, "label": "D-grade"},
}
const STAGE_BT := [95, 85, 75]
const RANK_BT := [70, 55, 40, 25, 10]
const IMMORTAL_DAO := {6: 300, 7: 900, 8: 2700}
const YEAR := 360

var paths := {}
var path_list := []
var statuses := {}
var forms := {}
var gu := {}
var gu_list := []
var killers := {}
var materials := {}
var formulas := {}
var clans := {}
var clan_list := []
var locations := {}
var routes := []
var adjacency := {}
var environments := {}
var enemies := {}
var enemy_list := []
var enemy_tiers := {}
var npc_seeds := []
var npc_names := {}
var archetypes := {}
var bands := []
var levels := []
var inheritance := []
var starts := []
var modes := []
var achievements := {}
var goal_types := []
var epochs := []
var missions := []
var standing := []
var stipend := {}
var events := {}
var event_list := []
var storylines := {}
var templates := []
var words := {}
var _icons := {}


func _ready() -> void:
	load_all()


func _read(name: String):
	var f := FileAccess.open("res://data/%s.json" % name, FileAccess.READ)
	if f == null:
		push_error("missing data file " + name)
		return null
	var txt := f.get_as_text()
	var v = JSON.parse_string(txt)
	if v == null:
		push_error("bad json " + name)
	return v


func load_all() -> void:
	path_list = _read("paths")
	for p in path_list:
		paths[p.id] = p
	statuses = _read("statuses")
	forms = _read("forms")
	gu_list = _read("gu")
	for g in gu_list:
		gu[g.id] = g
	for k in _read("killer_moves"):
		killers[k.id] = k
	for m in _read("materials"):
		materials[m.id] = m
	for f in _read("formulas"):
		formulas[f.id] = f
	clan_list = _read("clans")
	for c in clan_list:
		clans[c.id] = c
	for l in _read("locations"):
		locations[l.id] = l
	routes = _read("routes")
	adjacency.clear()
	for r in routes:
		if not adjacency.has(r.a):
			adjacency[r.a] = {}
		if not adjacency.has(r.b):
			adjacency[r.b] = {}
		adjacency[r.a][r.b] = int(r.days)
		adjacency[r.b][r.a] = int(r.days)
	environments = _read("environments")
	var en = _read("enemies")
	enemy_list = en.list
	enemy_tiers = en.tiers
	for e in enemy_list:
		enemies[e.id] = e
	var n = _read("npcs")
	npc_seeds = n.seeds
	npc_names = n.names
	archetypes = n.archetypes
	bands = n.bands
	levels = n.levels
	var meta = _read("meta")
	inheritance = meta.inheritance
	starts = meta.starts
	modes = meta.modes
	for a in meta.achievements:
		achievements[a.id] = a
	var w = _read("world")
	goal_types = w.goals
	epochs = w.epochs
	missions = w.missions
	standing = w.standing
	stipend = w.stipend
	var ev = _read("events")
	event_list = ev.events
	for e in event_list:
		events[e.id] = e
	for s in ev.storylines:
		storylines[s.id] = s
	templates = ev.templates
	words = ev.words


# ---------------------------------------------------------------- helpers ---
func tier_index(points: float) -> int:
	var idx := 0
	for i in TIER_POINTS.size():
		if points >= TIER_POINTS[i]:
			idx = i
	return idx


func tier_name(points: float) -> String:
	return TIERS[tier_index(points)]


func tier_index_of(name: String) -> int:
	return max(0, TIERS.find(name))


func path_color(path_id: String) -> Color:
	if paths.has(path_id):
		return Color(paths[path_id].color)
	return Color(0.72, 0.69, 0.64)


func path_name(path_id: String) -> String:
	return paths[path_id].name if paths.has(path_id) else path_id.capitalize()


func path_symbol(path_id: String) -> String:
	return paths[path_id].symbol if paths.has(path_id) else "○"


func icon(name: String) -> Texture2D:
	if _icons.has(name):
		return _icons[name]
	var p := "res://assets/icons/%s.png" % name
	var tex: Texture2D = null
	if ResourceLoader.exists(p):
		tex = load(p)
	elif ResourceLoader.exists("res://assets/icons/circle.png"):
		tex = load("res://assets/icons/circle.png")
	_icons[name] = tex
	return tex


func stage_req(rank: int, stage: int) -> float:
	if rank <= 5:
		return float(STAGE_REQ[rank][stage])
	return 0.0


func rank_title(rank: int) -> String:
	if rank >= 9:
		return "Rank 9 Venerable"
	if rank >= 6:
		return "Rank %d Gu Immortal" % rank
	return "Rank %d Gu Master" % rank


func material_tier_list(tier: String) -> Array:
	var out := []
	for m in materials.values():
		if m.tier == tier and m.id != "immortal_stone":
			out.append(m.id)
	return out


func gu_pool(filter: Dictionary) -> Array:
	## filter keys: rank (exact), max_rank, path, kind, rarity, include_clan, consumables
	var out := []
	for g in gu_list:
		if not g.pool and not filter.get("include_clan", false):
			continue
		if "temporary" in g.flags or "key" in g.flags:
			continue
		if filter.has("rank") and int(g.rank) != int(filter.rank):
			continue
		if filter.has("max_rank") and int(g.rank) > int(filter.max_rank):
			continue
		if filter.has("path") and g.path != filter.path:
			continue
		if filter.has("kind") and g.kind != filter.kind:
			continue
		if filter.has("rarity") and g.rarity != filter.rarity:
			continue
		if not filter.get("consumables", true) and g.kind == "consumable":
			continue
		out.append(g)
	return out


func describe_effects(effects: Array, power: float = 1.0) -> String:
	var parts := []
	for e in effects:
		parts.append(describe_effect(e, power))
	return " ".join(parts)


func _t(e: Dictionary) -> String:
	var t: String = e.get("t", "")
	if t == "all":
		return " to all enemies"
	return ""


func describe_effect(e: Dictionary, power: float = 1.0) -> String:
	var n := int(round(float(e.get("n", 0)) * power))
	match e.v:
		"damage":
			var s := "Deal %d damage%s" % [n, _t(e)]
			if int(e.get("times", 1)) > 1:
				s = "Deal %d damage %d times%s" % [n, int(e.times), _t(e)]
			if e.get("pierce", false):
				s += ", ignoring shields"
			if e.has("lifesteal"):
				s += ", heal %d%% of it" % int(e.lifesteal * 100)
			if e.has("bd"):
				s += " (+%d%% if the target is debuffed)" % int(e.bd * 100)
			return s + "."
		"heal":
			return "Heal %d." % n
		"shield":
			return "Gain %d shield." % n
		"status":
			var st: Dictionary = statuses.get(e.s, {"name": e.s})
			var who := "yourself" if e.get("t", "enemy") == "self" else ("all enemies" if e.get("t", "") == "all" else "the target")
			if e.s in ["stun", "control"]:
				return "%s %s for %d turn%s." % [st.name, who, int(e.turns), "" if int(e.turns) == 1 else "s"]
			if e.s in ["poison", "burn", "bleed", "regen", "thorns"]:
				return "Apply %d %s to %s." % [int(e.stacks), st.name, who]
			return "%s %s (%d turns)." % [st.name, who, int(e.turns)]
		"self_damage":
			return "Lose %d HP." % n
		"essence":
			return "Gain %d essence." % n
		"draw":
			return "Draw %d." % int(e.n)
		"combo":
			return "+%d combo." % int(e.n)
		"dmg_combo":
			return "Deal %d + %d per combo." % [int(e.base * power), int(e.per * power)]
		"cheapen":
			return "Your next %d Gu cost half." % int(e.n)
		"reveal":
			return "Reveal intents for %d turns (+10 accuracy)." % int(e.n)
		"dmg_missing_hp":
			return "Deal %d + %d%% of your missing HP." % [int(e.get("base", 0) * power), int(e.pct * 100)]
		"create":
			var c: Dictionary = gu.get(e.card, {"name": e.card})
			return "Add %d %s to your hand." % [int(e.n), c.name]
		"upgrade_hand":
			return "Empower your hand by %d%%." % int(e.pct * 100)
		"form":
			return "Take %s (%d turns)." % [forms[e.form].name, int(e.turns)]
		"mimic":
			return "Copy the enemy's last technique into your hand."
		"summon":
			return "Summon a %s (%d HP, %d attack)." % [e.name, int(e.hp * power), int(e.atk * power)]
		"steal_essence":
			return "Steal %d essence." % n
		"multiply_status":
			return "Multiply %s on %s by %d." % [statuses[e.s].name, "all enemies" if e.get("t", "") == "all" else "the target", int(e.x)]
		"detonate":
			return "Detonate %s for %s damage per stack%s." % [statuses[e.s].name, str(snapped(e.mult * power, 0.1)), _t(e)]
		"execute":
			return "Execute if below %d%% HP, otherwise deal %d." % [int(e.pct * 100), n]
		"dmg_shield":
			return "Deal damage equal to %d%% of your shield%s." % [int(e.mult * 100), " (consumes it)" if e.get("consume", false) else ""]
		"shield_pct_hp":
			return "Gain shield equal to %d%% of max HP." % int(e.pct * 100)
		"dmg_essence":
			return "Deal %d + %d%% of your essence." % [int(e.get("base", 0) * power), int(e.pct * 100)]
		"cleanse":
			return "Remove your debuffs."
	return str(e.v)


func gu_description(g: Dictionary, power: float = 1.0) -> String:
	var s := describe_effects(g.effects, power)
	if g.has("passive"):
		var p: Dictionary = g.passive
		var bits := []
		if p.has("travel_mult"):
			bits.append("Travel %d%% faster" % int((1.0 - p.travel_mult) * 100))
		if p.has("flee"):
			bits.append("lets you flee combat")
		if p.has("cult_bonus"):
			bits.append("Cultivation x%s" % str(p.cult_bonus))
		if p.has("decay"):
			bits.append("Progress decay only -%s/day" % str(p.decay))
		if p.has("feed_mult"):
			bits.append("Gu feeding -%d%%" % int((1.0 - p.feed_mult) * 100))
		if p.has("soul_guard"):
			bits.append("Protects against soul damage")
		if p.has("storage"):
			bits.append("+%d storage, +%d carry" % [int(p.storage), int(p.get("carry", 0))])
		if p.has("wisdom"):
			bits.append("+%d wisdom (see odds)" % int(p.wisdom))
		s = (s + " " if s != "" else "") + "Passive: " + ", ".join(bits) + "."
	if g.has("consumable"):
		var c: Dictionary = g.consumable
		match c.kind:
			"relic":
				s = "Use: advance one cultivation stage (cannot cross a rank)."
			"lifespan":
				s = "Use: +%d years of lifespan." % int(c.years)
			"breakthrough":
				s = "Use: +%d%% to your next breakthrough." % int(c.bonus)
			"heal_injury":
				s = "Use: cure all injuries."
			"key":
				s = "Opens the Three Kings Blessed Land."
	var fl := []
	if "quick" in g.flags:
		fl.append("Quick")
	if "slow" in g.flags:
		fl.append("Slow")
	if "temporary" in g.flags:
		fl.append("Temporary")
	if fl.size() > 0:
		s += " [" + ", ".join(fl) + "]"
	return s


func path_between(a: String, b: String, known: Array) -> Array:
	## Dijkstra over routes; only through locations in `known` (plus b).
	if a == b:
		return [a]
	var dist := {a: 0}
	var prev := {}
	var open := [a]
	while open.size() > 0:
		var best = open[0]
		for o in open:
			if dist[o] < dist[best]:
				best = o
		open.erase(best)
		if best == b:
			break
		for nb in adjacency.get(best, {}).keys():
			if nb != b and not (nb in known):
				continue
			var nd: int = dist[best] + int(adjacency[best][nb])
			if not dist.has(nb) or nd < dist[nb]:
				dist[nb] = nd
				prev[nb] = best
				if not (nb in open):
					open.append(nb)
	if not dist.has(b):
		return []
	var out := [b]
	var cur = b
	while prev.has(cur):
		cur = prev[cur]
		out.push_front(cur)
	return out


func route_days(path: Array) -> int:
	var d := 0
	for i in range(path.size() - 1):
		d += int(adjacency[path[i]][path[i + 1]])
	return d
