class_name ProcGen
extends RefCounted
## Offline content generation: new Gu cards, template events, NPC personality and dialogue.
## Optional Claude API text (AIGen) only rewrites names and flavour; numbers always come from here.

var g

const NAME_A := ["Moon", "Iron", "Jade", "Thunder", "Crimson", "Shadow", "Frost", "Golden", "Bitter", "Silent",
		"Wild", "Ancient", "Hollow", "Spring", "Autumn", "Star", "Bone", "Ember", "Silk", "Mist"]
const NAME_B := {
	"strength": ["Fist", "Bull", "Hammer", "Boulder", "Might"], "light": ["Ray", "Glow", "Halo", "Crescent", "Lantern"],
	"dark": ["Veil", "Shade", "Eclipse", "Gloom", "Night"], "wisdom": ["Thought", "Sage", "Insight", "Mirror", "Scroll"],
	"blood": ["Vein", "Leech", "Crimson", "Heart", "Thirst"], "poison": ["Fang", "Toad", "Miasma", "Sting", "Rot"],
	"food": ["Rice", "Wine", "Feast", "Honey", "Broth"], "refinement": ["Forge", "Crucible", "Anvil", "Kiln", "Ember"],
	"transformation": ["Scale", "Shell", "Hide", "Wing", "Claw"], "enslavement": ["Chain", "Leash", "Collar", "Thread", "Whip"],
	"fire": ["Flame", "Cinder", "Blaze", "Spark", "Furnace"], "none": ["Wind", "Cloud", "Step", "Stone", "Leaf"],
}
const PERSONALITIES := ["calm, watchful", "boastful, generous", "cautious, kind", "sharp-tongued, loyal", "greedy, charming",
		"quiet, stubborn", "proud, honest", "nervous, clever", "cheerful, reckless", "cold, fair"]
const DESIRES := ["a rare Gu", "revenge on a rival clan", "to reach Rank 5", "a lost family heirloom", "wealth",
		"respect from the elders", "to protect their village", "forbidden knowledge", "a worthy apprentice", "freedom"]


func _init(game) -> void:
	g = game


func personality() -> String:
	return PERSONALITIES[g.rng.randi_range(0, PERSONALITIES.size() - 1)]


func desire() -> String:
	return DESIRES[g.rng.randi_range(0, DESIRES.size() - 1)]


func npc_line(npc: Dictionary) -> String:
	var pl: Dictionary = g.s.player
	var band: String = g.world.band(int(npc.disp))
	var bits := []
	match band:
		"Mortal Enemy", "Hostile":
			bits = ["Leave, before I make you.", "I have not forgotten what you did.", "Your luck will run out, %s." % pl.name]
		"Unfriendly":
			bits = ["What do you want?", "Make it quick.", "I am busy."]
		"Neutral":
			bits = ["Another Gu Master on the road.", "These are strange times in %s." % Data.locations.get(npc.loc, {"name": "these parts"}).name,
					"I hear the %s is restless." % ["mountain", "plains", "market", "clan hall"][g.rng.randi_range(0, 3)]]
		_:
			bits = ["Good to see you, %s." % pl.name, "If you ever need %s, come to me." % ["stones", "help", "a place to rest", "advice"][g.rng.randi_range(0, 3)],
					"I keep thinking about %s." % npc.desire]
	if g.is_immortal():
		bits.append("An immortal, talking to me? The world is strange.")
	var t: String = bits[g.rng.randi_range(0, bits.size() - 1)]
	var ai: String = AIGen.cached_line(npc)
	if ai != "":
		t = ai
	return t


# -------------------------------------------------------------- events ------
func make_event(wild: bool) -> Dictionary:
	var cands := []
	for t in Data.templates:
		if wild and ("wild" in t.where or "travel" in t.where):
			cands.append(t)
		elif not wild and ("village" in t.where or "city" in t.where):
			cands.append(t)
	if cands.is_empty():
		return {}
	var t: Dictionary = cands[g.rng.randi_range(0, cands.size() - 1)]
	var w: Dictionary = Data.words
	var pl: Dictionary = g.s.player
	var r := int(pl.rank)
	var loc_name: String = Data.locations.get(pl.location, {"name": "the road"}).name
	var adj: String = w.adj[g.rng.randi_range(0, w.adj.size() - 1)]
	var beast: String = w.beast[g.rng.randi_range(0, w.beast.size() - 1)]
	var thing: String = w.thing[g.rng.randi_range(0, w.thing.size() - 1)]
	var fmt := {"adj": adj, "adj_l": adj.to_lower(), "beast": beast, "beast_l": beast.to_lower(), "thing": thing,
			"thing_l": thing.to_lower(), "loc": loc_name, "terrain": w.terrain[g.rng.randi_range(0, w.terrain.size() - 1)],
			"flavor": w.flavor[g.rng.randi_range(0, w.flavor.size() - 1)], "need": w.need[g.rng.randi_range(0, w.need.size() - 1)],
			"offer": w.offer[g.rng.randi_range(0, w.offer.size() - 1)], "name": pl.name}
	var ev := {"id": "proc_%d" % g.next_uid(), "title": t.title.format(fmt), "text": t.text.format(fmt), "urgency": "normal",
			"expiry": 6, "where": t.where, "proc": true, "choices": []}
	match t.kind:
		"combat":
			var enemy: String = w.beast_enemy.get(beast, "grey_wolf")
			var tier := "elite" if adj in ["Ancient", "Enormous", "Thunderous", "Scarred"] else "trained"
			ev.choices = [
				{"text": "Hunt it.", "check": {"type": "combat", "enemy": enemy, "rank": "r", "count": 1, "tier": tier},
						"ok": [{"do": "mat_tier", "tier": "uncommon" if tier == "elite" else "common", "n": 2}, {"do": "attain", "path": "primary", "n": 6}],
						"fail": [{"do": "log", "text": "It escapes into the %s." % fmt.terrain}]},
				{"text": "Leave it be.", "ok": [{"do": "log", "text": "You give it a wide berth."}]},
			]
		"discovery":
			ev.choices = [
				{"text": "Search the %s carefully (1 day)." % fmt.thing_l, "check": {"type": "chance", "p": 0.55, "stat": "wisdom"},
						"ok": [{"do": "time", "days": 1}, {"do": "gu_pool", "rank": "r", "log": "Inside, a dormant Gu stirs."}],
						"fail": [{"do": "time", "days": 1}, {"do": "stones", "n": "8r"}, {"do": "log", "text": "Only a few stones."}]},
				{"text": "Force it open.", "check": {"type": "chance", "p": 0.45, "stat": "strength"},
						"ok": [{"do": "mat_tier", "tier": "uncommon" if r >= 2 else "common", "n": 2}],
						"fail": [{"do": "damage", "pct": 0.15}, {"do": "log", "text": "A trap bites into your hand."}]},
				{"text": "Move on.", "ok": [{"do": "log", "text": "Some things are better left alone."}]},
			]
		"favour":
			ev.choices = [
				{"text": "Help them (3 days).", "ok": [{"do": "time", "days": 3}, {"do": "rep", "n": 4}, {"do": "fame", "n": 2},
						{"do": "stones", "n": "15r"}, {"do": "log", "text": "They thank you and offer %s." % fmt.offer}]},
				{"text": "Ask for payment up front.", "check": {"type": "chance", "p": 0.5, "stat": "wisdom"},
						"ok": [{"do": "time", "days": 3}, {"do": "stones", "n": "30r"}], "fail": [{"do": "rep", "n": -2}, {"do": "log", "text": "They leave, offended."}]},
				{"text": "Refuse.", "ok": [{"do": "log", "text": "You have your own path to walk."}]},
			]
		"trade":
			ev.choices = [
				{"text": "Browse their wares.", "ok": [{"do": "open_market", "kind": "caravan", "discount": 0.1}]},
				{"text": "Sell them rumours (+information required).", "req": {"info": 1},
						"ok": [{"do": "info", "n": -1}, {"do": "stones", "n": "20r"}]},
				{"text": "Ignore them.", "ok": [{"do": "log", "text": "The caravan rolls on."}]},
			]
	var flav: String = AIGen.cached_event_text(t.id, t.title, t.text)
	if flav != "":
		ev.text = flav + "\n\n" + ev.text
	return ev


# -------------------------------------------------------------- Gu cards ----
func make_gu(rank: int, path: String, rarity := "") -> String:
	## Builds a brand-new Gu from the effect templates of existing Gu, scaled for balance.
	var cands := []
	var loose := []
	for x in Data.gu_list:
		if int(x.rank) != rank or x.effects.is_empty() or x.kind == "consumable" or x.get("generated", false):
			continue
		loose.append(x)
		if x.path == path and not ("temporary" in x.flags):
			cands.append(x)
	if cands.is_empty():
		cands = loose
	if cands.is_empty():
		return ""
	var base: Dictionary = cands[g.rng.randi_range(0, cands.size() - 1)]
	var other: Dictionary = cands[g.rng.randi_range(0, cands.size() - 1)]
	if rarity == "":
		rarity = base.rarity
	var eff: Array = base.effects.duplicate(true)
	# borrow a secondary effect for a little variety, paying for it in essence
	var extra := []
	for e in other.effects:
		if e.v in ["status", "draw", "combo", "shield", "heal", "essence"] and e.v != eff[0].v:
			extra.append(e.duplicate(true))
	var cost := int(base.cost)
	if extra.size() > 0 and g.rng.randf() < 0.6:
		eff.append(extra[0])
		cost += maxi(1, int(base.cost * 0.25))
	# dynamic balancing: paths that past runs overused generate slightly weaker Gu
	var bal := Meta.path_balance(path)
	for e in eff:
		if e.has("n"):
			e.n = round(float(e.n) * bal * g.rng.randf_range(0.92, 1.08))
	var a: String = NAME_A[g.rng.randi_range(0, NAME_A.size() - 1)]
	var bl: Array = NAME_B.get(path, NAME_B.none)
	var b: String = bl[g.rng.randi_range(0, bl.size() - 1)]
	var name := "%s %s Gu" % [a, b]
	var id := "gen_%d_%s" % [g.next_uid(), path]
	var gd := {"id": id, "name": name, "path": path, "rank": rank, "rarity": rarity, "cost": cost, "effects": eff,
			"kind": base.kind, "flags": base.flags.duplicate(), "icon": base.icon, "flavor": "A Gu no record names. You named it yourself.",
			"target": base.target, "tags": base.get("tags", []).duplicate(), "feed": base.feed, "value": int(base.value * 1.1),
			"pool": false, "generated": true}
	register_gu(gd)
	if not g.s.has("custom_gu"):
		g.s["custom_gu"] = []
	g.s.custom_gu.append(gd)
	AIGen.request_gu_flavor(id, gd)
	return id


func register_gu(gd: Dictionary) -> void:
	Data.gu[gd.id] = gd
	if not Data.gu_list.has(gd):
		Data.gu_list.append(gd)


func restore_custom() -> void:
	for gd in g.s.get("custom_gu", []):
		gd.rank = int(gd.rank)
		gd.cost = int(gd.cost)
		register_gu(gd)
