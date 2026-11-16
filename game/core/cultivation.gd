class_name Cultivation
extends RefCounted
## Cultivation, aging and breakthroughs (docs/Systems/Cultivation.md, docs/Systems/Time.md).

var g  # Game autoload


func _init(game) -> void:
	g = game


func p() -> Dictionary:
	return g.s.player


func age_years() -> float:
	return float(p().age_days) / Data.YEAR


func life_left_pct() -> float:
	var pl := p()
	return clampf((float(pl.lifespan_days) - float(pl.age_days)) / float(pl.lifespan_days), 0.0, 1.0)


func age_band() -> Dictionary:
	var left := life_left_pct()
	if left >= 0.5:
		return {"name": "Prime", "cult": 1.0, "combat": 1.0}
	if left >= 0.25:
		return {"name": "First Signs", "cult": 0.95, "combat": 1.0}
	if left >= 0.10:
		return {"name": "Decline", "cult": 0.85, "combat": 0.95}
	if left >= 0.03:
		return {"name": "Severe Decline", "cult": 0.65, "combat": 0.85}
	return {"name": "Death's Door", "cult": 0.4, "combat": 0.7}


func cult_multiplier() -> float:
	var pl := p()
	var m: float = Data.APTITUDE[pl.aptitude].mult
	m *= age_band().cult
	var best := 1.0
	for gi in g.equipped():
		var gd: Dictionary = Data.gu[gi.id]
		if gd.has("passive") and gd.passive.has("cult_bonus"):
			best = maxf(best, float(gd.passive.cult_bonus) * g.gu_power(gi))
	m *= maxf(1.0, best)
	var loc: Dictionary = Data.locations.get(pl.location, {})
	m *= float(loc.get("cult", 1.0))
	if pl.location == "blessed_land":
		m *= 2.0
	m *= 1.0 + float(Data.clans[pl.clan].bonus.get("cult", 0.0))
	m *= pow(0.85, pl.injuries.size())
	if pl.get("zombie", false):
		m *= 0.3
	if g.s.mode == "hard":
		m *= 0.9
	return m


func daily(cultivating: bool, active: bool) -> void:
	## One day of cultivation or decay.
	var pl := p()
	if pl.rank >= 6:
		return
	var req := Data.stage_req(pl.rank, pl.stage)
	if cultivating:
		var tier: int = int(pl.intensity)
		while tier > 0 and pl.stones < Data.INTENSITY[tier].stones:
			tier -= 1
		pl.stones -= Data.INTENSITY[tier].stones
		var gain := float(Data.INTENSITY[tier].points) * cult_multiplier()
		pl.progress = minf(req, float(pl.progress) + gain)
		if tier < int(pl.intensity) and not pl.get("_warned_stones", false):
			pl["_warned_stones"] = true
			g.add_log("Not enough primeval stones: cultivating at %s instead." % Data.INTENSITY[tier].name, "warn")
		elif tier == int(pl.intensity):
			pl["_warned_stones"] = false
	else:
		var decay := 0.25 if active else 0.5
		for gi in g.equipped():
			var gd: Dictionary = Data.gu[gi.id]
			if gd.has("passive") and gd.passive.has("decay"):
				decay = minf(decay, float(gd.passive.decay))
		pl.progress = maxf(0.0, float(pl.progress) - decay)
	if pl.stage == 3 and float(pl.progress) >= req:
		pl.peak_days = int(pl.get("peak_days", 0)) + 1


func can_breakthrough() -> String:
	var pl := p()
	if pl.rank >= 6:
		return "Immortals advance through tribulation."
	if float(pl.progress) < Data.stage_req(pl.rank, pl.stage):
		return "Your aperture is not yet full."
	if int(pl.get("bt_cooldown", 0)) > 0:
		return "Your aperture is still recovering (%d days)." % int(pl.bt_cooldown)
	return ""


func is_rank_breakthrough() -> bool:
	return p().stage == 3


func breakthrough_chance() -> float:
	var pl := p()
	var apt: Dictionary = Data.APTITUDE[pl.aptitude]
	var c := 0.0
	var tier := Data.tier_index(float(pl.attain.get(pl.primary_path, 0)))
	if pl.stage < 3:
		c = Data.STAGE_BT[pl.stage] + apt.stage
	else:
		c = Data.RANK_BT[pl.rank - 1] + apt.rank
		c += mini(10, int(pl.get("peak_days", 0)) / 30)
		c += [0, 2, 5, 8, 10][tier]
		c += g.mentor_bonus()
	c += float(pl.get("bt_bonus", 0))
	if g.s.mode == "hard":
		c -= 5
	return clampf(c, 3.0, 99.0)


func attempt_breakthrough() -> Dictionary:
	## Returns {ok, text, kind}
	var pl := p()
	var why := can_breakthrough()
	if why != "":
		return {"ok": false, "text": why, "kind": "blocked"}
	if pl.rank == 5 and pl.stage == 3:
		return {"ok": false, "text": "tribulation", "kind": "tribulation"}
	var chance := breakthrough_chance()
	var roll := g.rng.randf() * 100.0
	pl.bt_bonus = 0
	var req := Data.stage_req(pl.rank, pl.stage)
	if roll < chance:
		if pl.stage < 3:
			pl.stage += 1
			pl.progress = 0.0
			g.add_log("Breakthrough! You reach %s Stage of Rank %d." % [Data.STAGES[pl.stage], pl.rank], "great")
			return {"ok": true, "text": "You break through to the %s Stage." % Data.STAGES[pl.stage], "kind": "stage"}
		pl.rank += 1
		pl.stage = 0
		pl.progress = 0.0
		pl.peak_days = 0
		g.on_rank_up()
		return {"ok": true, "text": "Your aperture transforms. You are now a Rank %d Gu Master!" % pl.rank, "kind": "rank"}
	# failure
	if pl.stage < 3:
		pl.progress = req * 0.7
		g.add_log("Breakthrough failed. Your progress falls back to 70%.", "bad")
		return {"ok": false, "text": "The breakthrough fails. Progress falls to 70%.", "kind": "fail"}
	var crit := g.rng.randf() < 0.05
	pl.bt_cooldown = 30
	if crit:
		pl.progress = req * 0.25
		g.add_injury("Shattered Meridians", 90)
		var txt := "Critical failure! Your progress collapses to 25% and your meridians shatter."
		if g.rng.randf() < 0.10:
			pl.lost_slots = int(pl.get("lost_slots", 0)) + 2
			txt += " Two aperture slots are lost."
		if g.rng.randf() < 0.01:
			g.add_log(txt, "bad")
			g.end_run("death", "Died in a catastrophic breakthrough.")
			return {"ok": false, "text": txt + " It is fatal.", "kind": "death"}
		g.add_log(txt, "bad")
		return {"ok": false, "text": txt, "kind": "crit"}
	pl.progress = req * 0.5
	var t := "The rank breakthrough fails. Progress falls to 50%; you must wait 30 days."
	if g.rng.randf() < 0.25:
		g.add_injury("Aperture Wound", 45)
		t += " You are injured."
	g.add_log(t, "bad")
	return {"ok": false, "text": t, "kind": "fail"}


func use_relic() -> String:
	var pl := p()
	if pl.rank >= 6:
		return "Relic Gu cannot help an immortal."
	if pl.stage >= 3:
		return "A Relic Gu cannot carry you across a rank."
	pl.stage += 1
	pl.progress = 0.0
	g.add_log("The Relic Gu dissolves. You advance to the %s Stage." % Data.STAGES[pl.stage], "great")
	return ""


func days_to_fill() -> int:
	var pl := p()
	if pl.rank >= 6:
		return -1
	var gain: float = Data.INTENSITY[int(pl.intensity)].points * cult_multiplier()
	if gain <= 0:
		return -1
	return int(ceil(maxf(0.0, Data.stage_req(pl.rank, pl.stage) - float(pl.progress)) / gain))
