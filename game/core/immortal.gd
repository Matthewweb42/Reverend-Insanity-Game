class_name Immortal
extends RefCounted
## Rank 6 ascension (heaven / earth / human tribulation), blessed land, dao marks, recurring
## tribulations, Rank 7-8 advancement and the Rank 9 Venerable ascension (the win condition).

var g

const STRUCTURES := {
	"refinement_room": {"name": "Refinement Room", "cost": 10, "desc": "+15% refinement success."},
	"cultivation_chamber": {"name": "Cultivation Chamber", "cost": 15, "desc": "Dao comprehension x1.5 inside your land."},
	"defensive_formation": {"name": "Defensive Formation", "cost": 12, "desc": "Tribulations are 15% weaker."},
	"beast_pen": {"name": "Beast Pen", "cost": 8, "desc": "Immortal beasts weaken tribulations further (5% each, up to 3)."},
	"guest_pavilion": {"name": "Guest Pavilion", "cost": 10, "desc": "Invite friends; allies help in tribulations."},
}
const FACTIONS := {
	"righteous": {"name": "Righteous Alliance", "desc": "Monthly stipend; demonic cultivators hunt you.", "align": 10},
	"demonic": {"name": "Demonic Sect", "desc": "Monthly stipend; righteous elders hunt you.", "align": -10},
	"lone": {"name": "Lone Immortal", "desc": "No stipend, no masters. +10% dao comprehension.", "align": 0},
}
const TRIB_EVERY_YEARS := 3


func _init(game) -> void:
	g = game


func p() -> Dictionary:
	return g.s.player


# ===================================================== ASCENSION (R5 -> R6) ==
func ascension_factors() -> Dictionary:
	var pl := p()
	var f := {}
	# heaven: combat readiness shown as a guide only; the fight itself decides
	var rare_gu := 0
	for gi in g.equipped():
		if Data.gu[gi.id].rarity in ["rare", "legendary"]:
			rare_gu += 1
	f["heaven"] = "Battle the Heavenly Tribulation. Your deck: %d Gu (%d rare or better)." % [g.equipped().size(), rare_gu]
	f["earth_chance"] = earth_chance(0)
	f["human_chance"] = human_chance()
	f["allies"] = allies().size()
	f["spec"] = pl.specialization
	return f


func earth_chance(offer: int) -> float:
	var pl := p()
	var mats := 0
	for mid in pl.mats.keys():
		var t: String = Data.materials[mid].tier
		mats += int(pl.mats[mid]) * {"common": 1, "uncommon": 3, "rare": 10, "legendary": 40}.get(t, 1)
	var c := 0.25 + minf(0.45, (offer + mats * 4) / 4000.0)
	c += 0.05 * Data.tier_index(float(pl.attain.get(pl.specialization, 0))) if pl.specialization != "" else 0.0
	return clampf(c, 0.05, 0.95)


func allies() -> Array:
	var out := []
	for n in g.s.npcs.values():
		if n.alive and int(n.disp) >= 50:
			out.append(n)
	return out


func human_chance() -> float:
	var pl := p()
	var c := 0.3 + 0.12 * allies().size() + minf(0.15, int(pl.fame) / 200.0)
	if absi(int(pl.align)) >= 40:
		c += 0.08   # a clear reputation draws clear supporters
	c += 0.04 * g.standing_index()
	return clampf(c, 0.05, 0.95)


func begin_ascension() -> Dictionary:
	var pl := p()
	if not pl.has("trib") or pl.trib == null or pl.trib.is_empty():
		pl["trib"] = {"kind": "ascension", "stage": "prepare", "heaven": false, "earth": false, "human": false}
	return {"ok": false, "kind": "tribulation", "text": "Your aperture trembles at the edge of immortality. The tribulation is coming."}


func start_heaven(offer: int) -> String:
	## Called by the tribulation dialog once the player commits resources.
	var pl := p()
	if int(pl.stones) < offer:
		return "Not enough stones"
	pl.stones = int(pl.stones) - offer
	pl.trib.offer = offer
	pl.trib.stage = "heaven"
	var defs := [{"id": "tribulation_avatar", "rank": 5, "tier": "boss"}]
	if g.s.mode == "hard":
		defs.append({"id": "earthly_calamity", "rank": 5, "tier": "mook"})
	g.start_combat({"enemies": defs, "env": ["thunder_plain"] if Data.environments.has("thunder_plain") else [], "flee_allowed": false,
			"tribulation": true, "trib": "ascension"})
	return ""


func on_trib_combat(won: bool, setup: Dictionary) -> String:
	var kind: String = setup.get("trib", "earthly")
	match kind:
		"ascension":
			return _finish_ascension(won)
		"earthly", "heavenly":
			return _finish_periodic(won, kind)
		"rank_up":
			return _finish_rank_up(won)
		"venerable":
			return _venerable_stage_done(won)
		"inheritance":
			return _finish_inheritance(won)
	return ""


func _finish_ascension(heaven_won: bool) -> String:
	var pl := p()
	var t: Dictionary = pl.trib
	g.s.stats.tribulations = int(g.s.stats.tribulations) + 1
	t.heaven = heaven_won
	t.earth = g.rng.randf() < earth_chance(int(t.get("offer", 0)))
	t.human = g.rng.randf() < human_chance()
	var lines := []
	lines.append("Heaven Tribulation: %s." % ("you weather the lightning" if heaven_won else "the lightning breaks you"))
	lines.append("Earth Tribulation: %s." % ("the land accepts your offering" if t.earth else "the earth rejects you; resources crumble"))
	lines.append("Human Tribulation: %s." % ("allies stand with you" if t.human else "jealous cultivators strike while you are weak"))
	var score := (2 if heaven_won else 0) + (1 if t.earth else 0) + (1 if t.human else 0)
	pl.trib = {}
	if score >= 3:
		_become_immortal(score)
		lines.append("\nSUCCESS. You ascend as a Rank 6 Gu Immortal and a blessed land opens within your aperture.")
	elif score == 2:
		_become_immortal(1)
		pl.stones = int(pl.stones) / 2
		g.add_injury("Tribulation Scars", 360)
		lines.append("\nPARTIAL SUCCESS. You survive and ascend, but your blessed land is small and your body scarred.")
	else:
		lines.append("\nFAILURE. Your aperture collapses under the weight of heaven and earth.")
		g.end_run("tribulation", "Died during the immortal tribulation.")
	return "\n".join(lines)


func _become_immortal(quality: int) -> void:
	var pl := p()
	pl.rank = 6
	pl.stage = 0
	pl.progress = 0.0
	pl.lifespan_days = int(pl.lifespan_days) + 400 * Data.YEAR
	pl.istones = int(pl.istones) + 10 + 5 * quality
	pl.hp = g.max_hp()
	var grade := clampi(quality, 1, 4)
	var path: String = pl.specialization if pl.specialization != "" else pl.primary_path
	var mats := Data.material_tier_list("rare")
	var nodes := [{"mat": "immortal_stone", "level": 1, "stock": 0.0}]
	for i in grade:
		nodes.append({"mat": mats[g.rng.randi_range(0, mats.size() - 1)], "level": 1, "stock": 0.0})
	g.s.blessed = {"name": "%s's Blessed Land" % pl.name, "grade": grade, "dao": {path: 20 * grade}, "nodes": nodes,
			"structures": [], "beasts": [], "flow": 20, "next_trib": int(g.s.day) + TRIB_EVERY_YEARS * Data.YEAR, "trib_count": 0}
	pl.dao[path] = int(pl.dao.get(path, 0)) + 20 * grade
	if not ("central_continent" in pl.known_locs):
		pl.known_locs.append("central_continent")
	g.achieve("immortal")
	g.on_rank_up()
	Sfx.music("immortal")


# ===================================================== IMMORTAL DAILY =======
func daily() -> void:
	var b = g.s.blessed
	if b == null:
		return
	var pl := p()
	var flow := float(b.flow) / 20.0
	for nd in b.nodes:
		nd.stock = float(nd.stock) + 0.04 * int(nd.level) * flow
	if int(g.s.day) >= int(b.next_trib) and g.combat == null:
		_periodic_tribulation()


func cultivate_day(closed_door: bool) -> void:
	var pl := p()
	var rate := 0.6 * float(Data.APTITUDE[pl.aptitude].mult) * float(g.cult.age_band().cult)
	if pl.get("in_land", false) or closed_door:
		rate *= 2.0
		if g.s.blessed != null and "cultivation_chamber" in g.s.blessed.structures:
			rate *= 1.5
	if pl.faction == "lone":
		rate *= 1.1
	rate *= float(Data.locations.get(pl.location, {}).get("cult", 1.0))
	pl["_dao_frac"] = float(pl.get("_dao_frac", 0.0)) + rate
	if float(pl._dao_frac) >= 1.0:
		var n := int(pl._dao_frac)
		pl._dao_frac = float(pl._dao_frac) - n
		g.add_dao(n)
	g.s.stats.days_cultivated = int(g.s.stats.days_cultivated) + 1


func harvest() -> String:
	var b = g.s.blessed
	if b == null:
		return "You have no blessed land."
	var got := []
	for nd in b.nodes:
		var n := int(nd.stock)
		if n <= 0:
			continue
		nd.stock = float(nd.stock) - n
		if nd.mat == "immortal_stone":
			p().istones = int(p().istones) + n
			got.append("%d immortal essence stones" % n)
		else:
			g.add_material(nd.mat, n)
			got.append("%d %s" % [n, Data.materials[nd.mat].name])
	if got.is_empty():
		return "Nothing is ready to harvest yet."
	g.add_log("Harvested %s from your blessed land." % ", ".join(got), "good")
	g.emit_signal("state_changed")
	return "Harvested: " + ", ".join(got)


func node_upgrade_cost(i: int) -> int:
	return 5 * int(g.s.blessed.nodes[i].level)


func upgrade_node(i: int) -> String:
	var b = g.s.blessed
	var c := node_upgrade_cost(i)
	if int(p().istones) < c:
		return "Needs %d immortal essence stones" % c
	p().istones = int(p().istones) - c
	b.nodes[i].level = int(b.nodes[i].level) + 1
	g.emit_signal("state_changed")
	return ""


func plant(mat: String) -> String:
	var b = g.s.blessed
	if b == null:
		return "No blessed land"
	if b.nodes.size() >= 2 + int(b.grade) * 2:
		return "Your land has no room for another resource point. Nurture it to grow."
	if int(p().istones) < 6:
		return "Needs 6 immortal essence stones"
	if int(p().mats.get(mat, 0)) < 1:
		return "You need one %s as a seed" % Data.materials[mat].name
	p().istones = int(p().istones) - 6
	g.add_material(mat, -1)
	b.nodes.append({"mat": mat, "level": 1, "stock": 0.0})
	g.add_log("You plant %s in your blessed land." % Data.materials[mat].name, "good")
	g.emit_signal("state_changed")
	return ""


func build(sid: String) -> String:
	var b = g.s.blessed
	if b == null:
		return "No blessed land"
	if sid in b.structures:
		return "Already built"
	var c := int(STRUCTURES[sid].cost)
	if int(p().istones) < c:
		return "Needs %d immortal essence stones" % c
	p().istones = int(p().istones) - c
	b.structures.append(sid)
	g.add_log("Built a %s in your blessed land." % STRUCTURES[sid].name, "good")
	g.emit_signal("state_changed")
	return ""


func nurture_cost() -> int:
	return 20 * int(g.s.blessed.grade)


func nurture() -> String:
	var b = g.s.blessed
	if int(b.grade) >= 5:
		return "Your land is already a grand blessed land"
	var c := nurture_cost()
	if int(p().istones) < c:
		return "Needs %d immortal essence stones" % c
	p().istones = int(p().istones) - c
	b.grade = int(b.grade) + 1
	b.flow = int(b.flow) + 5
	g.add_log("Your blessed land grows to grade %d." % int(b.grade), "great")
	g.emit_signal("state_changed")
	return ""


func annex() -> String:
	## Territory expansion: swallow a nearby grotto-heaven.
	var pl := p()
	var b = g.s.blessed
	if int(pl.rank) < 7:
		return "Only a Rank 7 immortal can annex a grotto-heaven"
	if int(pl.istones) < 60:
		return "Needs 60 immortal essence stones"
	pl.istones = int(pl.istones) - 60
	g.start_combat({"enemies": [{"id": "guardian_construct", "rank": int(pl.rank), "tier": "boss", "name": "Grotto Guardian"}],
			"env": [], "flee_allowed": true, "tribulation": true, "trib": "inheritance", "annex": true})
	return ""


func invite_guest(id: String) -> String:
	var b = g.s.blessed
	if not ("guest_pavilion" in b.structures):
		return "Build a Guest Pavilion first"
	var npc: Dictionary = g.s.npcs[id]
	if int(npc.disp) < 25:
		return "%s does not know you well enough." % npc.name
	g.change_disp(id, 12)
	npc.talks = int(npc.talks) + 2
	var gift := ""
	if g.rng.randf() < 0.5:
		p().istones = int(p().istones) + 3
		gift = " They leave 3 immortal essence stones as a guest gift."
	g.skip_days(2)
	g.add_log("%s visits your blessed land.%s" % [npc.name, gift], "good")
	return ""


func choose_faction(fid: String) -> void:
	var pl := p()
	pl.faction = fid
	g.change_align(int(FACTIONS[fid].align))
	g.add_log("You declare yourself: %s." % FACTIONS[fid].name, "great")
	g.emit_signal("state_changed")


# ===================================================== PERIODIC TRIBULATION ==
func _trib_mult() -> float:
	var b = g.s.blessed
	var m := 1.0
	if b != null:
		if "defensive_formation" in b.structures:
			m -= 0.15
		if "beast_pen" in b.structures:
			m -= 0.05 * mini(3, b.beasts.size())
		if "guest_pavilion" in b.structures:
			m -= 0.03 * mini(3, allies().size())
	return maxf(0.55, m)


func _periodic_tribulation() -> void:
	var pl := p()
	var b = g.s.blessed
	b.trib_count = int(b.trib_count) + 1
	b.next_trib = int(g.s.day) + TRIB_EVERY_YEARS * Data.YEAR
	var heavenly: bool = int(b.trib_count) % 5 == 0
	var r := int(pl.rank)
	var defs := []
	if heavenly:
		defs = [{"id": "tribulation_avatar", "rank": r, "tier": "boss", "name": "Heavenly Tribulation"}]
	else:
		defs = [{"id": "earthly_calamity", "rank": r, "tier": "elite"}]
	g.notice.emit("Tribulation", "A %s descends upon your blessed land!" % ("HEAVENLY tribulation" if heavenly else "earthly tribulation"))
	g.start_combat({"enemies": defs, "env": [], "flee_allowed": false, "tribulation": true,
			"trib": "heavenly" if heavenly else "earthly", "enemy_mult": _trib_mult()})
	if g.combat != null:
		for e in g.combat.enemies:
			e.hp = int(e.hp * _trib_mult())
			e.max_hp = e.hp
			e.dmg_base = float(e.dmg_base) * _trib_mult()


func _finish_periodic(won: bool, kind: String) -> String:
	var pl := p()
	g.s.stats.tribulations = int(g.s.stats.tribulations) + 1
	if won:
		var gain := 30 if kind == "heavenly" else 12
		g.add_dao(gain)
		pl.istones = int(pl.istones) + (10 if kind == "heavenly" else 4)
		return "The tribulation passes. Its residue hardens your dao (+%d dao marks)." % gain
	var death := 0.4 if kind == "heavenly" else 0.15
	if g.s.mode == "hard":
		death += 0.1
	if g.rng.randf() < death:
		g.end_run("tribulation", "Destroyed by a %s tribulation." % kind)
		return "The tribulation tears your blessed land apart, and you with it."
	pl.istones = int(int(pl.istones) * 0.7)
	g.add_injury("Tribulation Wounds", 120)
	var b = g.s.blessed
	if b.nodes.size() > 1:
		b.nodes.remove_at(g.rng.randi_range(1, b.nodes.size() - 1))
	return "You survive, barely. A resource point is destroyed and your stores are scattered."


# ===================================================== RANK 6 -> 9 ==========
func rank_up_requirements() -> Array:
	## [[text, met], ...] for the next rank.
	var pl := p()
	var r := int(pl.rank)
	var out := []
	var need: int = Data.IMMORTAL_DAO.get(r, 0)
	if r < 9:
		out.append(["%d dao marks (you have %d)" % [need, g.dao_total()], g.dao_total() >= need])
	var gm := 0
	for path in pl.attain.keys():
		if Data.tier_index(float(pl.attain[path])) >= 4:
			gm += 1
	match r:
		6:
			out.append(["Own a Rank 7 Gu", _has_rank_gu(7)])
		7:
			out.append(["Grandmaster attainment in 2 paths (%d)" % gm, gm >= 2])
			out.append(["3 legendary materials", _legendary_mats() >= 3])
		8:
			out.append(["Own a Rank 8 Gu", _has_rank_gu(8)])
			out.append(["Grandmaster attainment in 3 paths (%d)" % gm, gm >= 3])
			out.append(["300 immortal essence stones", int(pl.istones) >= 300])
	return out


func _has_rank_gu(r: int) -> bool:
	for gi in p().gu:
		if int(Data.gu[gi.id].rank) >= r:
			return true
	return false


func _legendary_mats() -> int:
	var n := 0
	for mid in p().mats.keys():
		if Data.materials[mid].tier == "legendary" and mid != "immortal_stone":
			n += int(p().mats[mid])
	return n


func attempt_rank_up() -> Dictionary:
	var pl := p()
	if int(pl.rank) >= 9:
		return {"ok": false, "kind": "blocked", "text": "You stand at the summit."}
	for req in rank_up_requirements():
		if not req[1]:
			return {"ok": false, "kind": "blocked", "text": "Not ready: %s." % req[0]}
	if int(pl.rank) == 8:
		return begin_venerable()
	var r := int(pl.rank) + 1
	var defs := [{"id": "tribulation_avatar", "rank": r, "tier": "boss", "name": "Rank %d Tribulation" % r},
			{"id": "earthly_calamity", "rank": r - 1, "tier": "trained"}]
	g.start_combat({"enemies": defs, "env": [], "flee_allowed": false, "tribulation": true, "trib": "rank_up"})
	return {"ok": false, "kind": "trial", "text": "Heaven answers your challenge."}


func _finish_rank_up(won: bool) -> String:
	var pl := p()
	if not won:
		pl.dao[pl.primary_path] = int(int(pl.dao.get(pl.primary_path, 0)) * 0.7)
		g.add_injury("Dao Wound", 180)
		if g.rng.randf() < 0.2:
			g.end_run("tribulation", "Struck down while attempting Rank %d." % (int(pl.rank) + 1))
			return "Heaven's will crushes you."
		return "You fail. Your dao is shaken (dao marks -30%)."
	if int(pl.rank) == 7:
		var used := 0
		for mid in pl.mats.keys():
			if used >= 3:
				break
			if Data.materials[mid].tier == "legendary" and mid != "immortal_stone":
				var take := mini(3 - used, int(pl.mats[mid]))
				g.add_material(mid, -take)
				used += take
	pl.rank = int(pl.rank) + 1
	pl.lifespan_days = int(pl.lifespan_days) + 500 * Data.YEAR
	g.on_rank_up()
	return "You ascend to %s!" % Data.rank_title(int(pl.rank))


# ===================================================== VENERABLE ===========
func begin_venerable() -> Dictionary:
	var pl := p()
	pl.istones = int(pl.istones) - 300
	pl["trib"] = {"kind": "venerable", "stage": 1}
	_venerable_stage(1)
	return {"ok": false, "kind": "trial", "text": "The Venerable tribulation begins: three trials of heaven, earth and fate."}


func _venerable_stage(n: int) -> void:
	var defs := []
	match n:
		1:
			defs = [{"id": "earthly_calamity", "rank": 9, "tier": "elite", "name": "Calamity of the Nine Earths"},
					{"id": "earthly_calamity", "rank": 8, "tier": "trained", "name": "Calamity Spawn"}]
		2:
			defs = [{"id": "tribulation_avatar", "rank": 9, "tier": "boss", "name": "Nine-Heavens Lightning"}]
		3:
			defs = [{"id": "heaven_will", "rank": 9, "tier": "boss", "name": "Heaven's Will"}]
	g.start_combat({"enemies": defs, "env": [], "flee_allowed": false, "tribulation": true, "trib": "venerable"})


func _venerable_stage_done(won: bool) -> String:
	var pl := p()
	var n := int(pl.trib.get("stage", 1))
	if not won:
		pl.trib = {}
		g.end_run("tribulation", "Fell during the Venerable tribulation (trial %d of 3)." % n)
		return "So close to the summit. Heaven claims you."
	if n >= 3:
		pl.trib = {}
		pl.rank = 9
		g.s.stats.max_rank = 9
		g.add_log("YOU HAVE BECOME A RANK 9 VENERABLE.", "great")
		g.end_run("victory", "Ascended as a Rank 9 Venerable.")
		return "Heaven's Will shatters. You are a Venerable: the world itself bows."
	pl.trib.stage = n + 1
	# heal a little between stages
	pl.hp = mini(g.max_hp(), int(pl.hp) + int(g.max_hp() * 0.35))
	g.notice.emit("Venerable Tribulation", "Trial %d passed. Trial %d begins." % [n, n + 1])
	_venerable_stage(n + 1)
	return "Trial %d of 3 passed." % n


# ===================================================== ANCIENT INHERITANCE ==
func seek_inheritance() -> String:
	var pl := p()
	if int(pl.rank) < 7:
		return "Ancient inheritances answer only to Rank 7 immortals."
	if pl.location != "central_continent":
		return "The ancient inheritances lie in the Central Continent."
	g.start_combat({"enemies": [{"id": "guardian_construct", "rank": 8, "tier": "boss", "name": "Ancient Guardian"}],
			"env": [], "flee_allowed": true, "tribulation": true, "trib": "inheritance"})
	return ""


func _finish_inheritance(won: bool) -> String:
	var pl := p()
	if not won:
		g.add_injury("Guardian Wounds", 60)
		return "The guardian drives you out."
	if g.s.blessed != null and pl.get("_annex", false):
		pass
	var r := 8 if g.rng.randf() < 0.35 else 7
	var gid = g.random_gu(r)
	var t := "The inheritance opens."
	if gid != "":
		g.add_gu(gid, true)
		t += " You claim %s." % Data.gu[gid].name
	g.add_material(["dao_shard", "heavens_tear"][g.rng.randi_range(0, 1)], 2)
	pl.istones = int(pl.istones) + 25
	g.add_dao(40)
	if g.s.blessed != null:
		g.s.blessed.grade = mini(5, int(g.s.blessed.grade) + 1)
	pl.flags["found_inheritance"] = true
	return t + " +2 legendary materials, +25 immortal essence stones, +40 dao marks."
