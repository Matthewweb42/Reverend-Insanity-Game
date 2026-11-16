class_name Economy
extends RefCounted
## Markets, prices, haggling, services and Gu refinement (docs/Systems/Economy.md).

var g


func _init(game) -> void:
	g = game


func p() -> Dictionary:
	return g.s.player


const KINDS := {
	"market": {"name": "Clan Market", "desc": "Stable prices, limited stock, clan Gu for members."},
	"black_market": {"name": "Black Market", "desc": "Demonic Gu and stolen goods. Buying here darkens your name."},
	"caravan": {"name": "Merchant Caravan", "desc": "Random wares at good prices, here today and gone tomorrow."},
	"auction": {"name": "Grand Auction", "desc": "Rare and legendary Gu, sold to the highest bidder."},
	"treasure_yellow_heaven": {"name": "Treasure Yellow Heaven", "desc": "The immortal market. Prices in immortal essence stones."},
}


# ------------------------------------------------------------- pricing ------
func price_mult(kind: String) -> float:
	var pl := p()
	var m := 1.0
	m *= 1.0 + float(Data.clans[pl.clan].bonus.get("trade", 0.0))
	if g.s.mode == "hard":
		m *= 1.15
	match kind:
		"black_market":
			m *= 1.25
		"caravan":
			m *= 0.85
		"auction":
			m *= 1.4
	# a friendly merchant nearby gives a discount
	for n in g.s.npcs.values():
		if n.alive and n.met and n.arch == "merchant" and n.loc == pl.location and int(n.disp) >= 25:
			m *= 0.9
			break
	if g.s.get("epoch_flags", {}).has("plague"):
		m *= 1.2
	return m


func gu_price(gid: String, kind := "market") -> int:
	var gd: Dictionary = Data.gu[gid]
	return maxi(1, int(round(float(gd.value) * price_mult(kind))))


func mat_price(mid: String, kind := "market") -> int:
	return maxi(1, int(round(float(Data.materials[mid].value) * price_mult(kind))))


func sell_price_gu(gi: Dictionary) -> int:
	var gd: Dictionary = Data.gu[gi.id]
	return maxi(1, int(float(gd.value) * 0.45))


func sell_price_mat(mid: String) -> int:
	return maxi(1, int(float(Data.materials[mid].value) * 0.5))


# ------------------------------------------------------------- markets ------
func market_kinds_here() -> Array:
	var pl := p()
	var out := []
	var svc: Array = Data.locations.get(pl.location, {}).get("services", [])
	if "market" in svc:
		out.append("market")
	if "black_market" in svc:
		out.append("black_market")
	if g.s.markets.has(pl.location + ":caravan"):
		out.append("caravan")
	if g.s.markets.has(pl.location + ":auction"):
		out.append("auction")
	if g.is_immortal():
		out.append("treasure_yellow_heaven")
	return out


func market(kind: String) -> Dictionary:
	var pl := p()
	var key: String = ("anywhere" if kind == "treasure_yellow_heaven" else pl.location) + ":" + kind
	if not g.s.markets.has(key):
		g.s.markets[key] = _stock(kind)
	return g.s.markets[key]


func _stock(kind: String, discount := 0.0) -> Dictionary:
	var pl := p()
	var r := int(pl.rank)
	var loc: Dictionary = Data.locations.get(pl.location, {})
	var items := []
	var n_gu := 6
	var ranks := [maxi(1, r - 1), r, mini(5, r + 1)]
	var filt := {"consumables": true}
	match kind:
		"market":
			n_gu = 5 + (2 if loc.get("type", "") == "city" else 0)
		"black_market":
			n_gu = 5
		"caravan":
			n_gu = 6
		"auction":
			n_gu = 4
			ranks = [r, mini(6, r + 1)]
		"treasure_yellow_heaven":
			n_gu = 6
			ranks = [6, mini(8, maxi(6, r)), mini(8, r + 1)]
	var used := {}
	for i in n_gu * 3:
		if items.size() >= n_gu:
			break
		var rk: int = ranks[g.rng.randi_range(0, ranks.size() - 1)]
		var f := filt.duplicate()
		f["rank"] = rk
		if kind == "black_market":
			var dark := ["poison", "blood", "dark", "enslavement"]
			f["path"] = dark[g.rng.randi_range(0, dark.size() - 1)]
		if kind == "auction":
			f["rarity"] = ["rare", "legendary"][g.rng.randi_range(0, 1)]
		var pool := Data.gu_pool(f)
		if pool.is_empty():
			f.erase("path")
			f.erase("rarity")
			pool = Data.gu_pool(f)
		if pool.is_empty():
			continue
		var gd: Dictionary = pool[g.rng.randi_range(0, pool.size() - 1)]
		if used.has(gd.id):
			continue
		used[gd.id] = true
		var price := gu_price(gd.id, kind)
		var cur := "stones"
		if kind == "treasure_yellow_heaven":
			price = maxi(1, int(float(gd.value) / 150.0))
			cur = "istones"
		elif kind == "auction":
			price = int(price * g.rng.randf_range(0.9, 1.3))
		price = int(price * (1.0 - discount) * g.rng.randf_range(0.85, 1.15))
		items.append({"type": "gu", "id": gd.id, "price": maxi(1, price), "cur": cur, "haggled": false})
	# clan Gu for members
	if kind == "market" and loc.get("clan", "") == pl.clan and g.standing_index() >= 2:
		var clan: Dictionary = Data.clans[pl.clan]
		for uid in clan.unique:
			var gd2: Dictionary = Data.gu.get(uid, {})
			if not gd2.is_empty() and int(gd2.rank) <= r + 1 and items.size() < n_gu + 2:
				items.append({"type": "gu", "id": uid, "price": gu_price(uid, kind), "cur": "stones", "haggled": false, "clan": true})
	# materials
	var mtiers := ["common", "common", "uncommon"]
	if r >= 3:
		mtiers.append("rare")
	if kind == "auction":
		mtiers = ["rare", "legendary"]
	if kind == "treasure_yellow_heaven":
		items.append({"type": "mat", "id": "immortal_stone", "price": 2, "cur": "istones", "haggled": false})
		mtiers = ["legendary"]
	for i in 4:
		var lst := Data.material_tier_list(mtiers[g.rng.randi_range(0, mtiers.size() - 1)])
		if lst.is_empty():
			continue
		var mid: String = lst[g.rng.randi_range(0, lst.size() - 1)]
		var mp := mat_price(mid, kind)
		var cur2 := "stones"
		if kind == "treasure_yellow_heaven":
			mp = maxi(1, mp / 120)
			cur2 = "istones"
		items.append({"type": "mat", "id": mid, "price": maxi(1, int(mp * (1.0 - discount))), "cur": cur2, "haggled": false})
	return {"kind": kind, "day": int(g.s.day), "items": items, "info_price": 15 + 10 * r}


func weekly() -> void:
	# markets restock every few weeks; caravans and auctions leave
	var keep := {}
	for k in g.s.markets.keys():
		var m: Dictionary = g.s.markets[k]
		var age := int(g.s.day) - int(m.day)
		if m.kind in ["caravan", "auction"] and age > 14:
			continue
		if m.kind in ["market", "black_market", "treasure_yellow_heaven"] and age > 28:
			continue
		keep[k] = m
	g.s.markets = keep


func open_special(kind: String, discount: float) -> void:
	var key: String = p().location + ":" + kind
	g.s.markets[key] = _stock(kind, discount)


func buy(kind: String, idx: int) -> String:
	var pl := p()
	var m := market(kind)
	if idx < 0 or idx >= m.items.size():
		return "Gone"
	var it: Dictionary = m.items[idx]
	var cur: String = it.cur
	if int(pl[cur]) < int(it.price):
		return "Not enough %s" % ("immortal essence stones" if cur == "istones" else "primeval stones")
	if it.type == "gu" and g.stored_count() >= g.storage_cap() and g.can_equip({"uid": -1, "id": it.id, "eq": false}) != "":
		return "No room in your aperture or storage"
	pl[cur] = int(pl[cur]) - int(it.price)
	if it.type == "gu":
		g.add_gu(it.id)
	else:
		g.add_material(it.id, 1)
		g.add_log("Bought %s." % Data.materials[it.id].name, "info")
	if kind == "black_market":
		g.change_align(-3)
	m.items.remove_at(idx)
	Sfx.play("coin")
	g.emit_signal("state_changed")
	return ""


func haggle(kind: String, idx: int) -> String:
	var pl := p()
	var m := market(kind)
	var it: Dictionary = m.items[idx]
	if it.haggled:
		return "The merchant will not budge again."
	it.haggled = true
	var c := 0.45 + 0.05 * Data.tier_index(float(pl.attain.get("wisdom", 0))) + 0.03 * int(pl.rank)
	if pl.clan == "shang":
		c += 0.15
	var roll = g.rng.randf()
	if roll < c * 0.25:
		it.price = maxi(1, int(it.price * g.rng.randf_range(0.5, 0.6)))
		return "A brilliant bargain! The price drops to %d." % int(it.price)
	if roll < c:
		it.price = maxi(1, int(it.price * g.rng.randf_range(0.7, 0.9)))
		return "You talk the price down to %d." % int(it.price)
	if roll > 0.92:
		it.price = int(it.price * 1.1)
		return "The merchant takes offence and raises the price to %d." % int(it.price)
	return "The merchant refuses to lower the price."


func sell_gu(uid: int) -> String:
	var gi: Dictionary = g.find_gu(uid)
	if gi.is_empty():
		return "Gone"
	var gd: Dictionary = Data.gu[gi.id]
	if "key" in gd.flags:
		return "You cannot bring yourself to sell this."
	var price := sell_price_gu(gi)
	if int(gd.rank) >= 6:
		p().istones = int(p().istones) + maxi(1, int(float(gd.value) / 300.0))
	else:
		p().stones = int(p().stones) + price
	g.remove_gu(uid)
	g.add_log("Sold %s for %d stones." % [gd.name, price], "info")
	Sfx.play("coin")
	g.emit_signal("state_changed")
	return ""


func sell_mat(mid: String) -> String:
	var pl := p()
	if int(pl.mats.get(mid, 0)) <= 0:
		return "None left"
	g.add_material(mid, -1)
	pl.stones = int(pl.stones) + sell_price_mat(mid)
	Sfx.play("coin")
	g.emit_signal("state_changed")
	return ""


func buy_info(kind: String) -> String:
	var pl := p()
	var price := int(market(kind).info_price)
	if int(pl.stones) < price:
		return "Not enough stones"
	pl.stones = int(pl.stones) - price
	pl.info = int(pl.info) + 1
	var line := _rumour()
	g.add_log("You buy information: %s" % line, "info")
	g.emit_signal("state_changed")
	return line


func _rumour() -> String:
	var pl := p()
	# reveal a hidden place sometimes, otherwise an epoch hint or NPC whereabouts
	if not ("hu_immortal_land" in pl.known_locs) and int(pl.rank) >= 2 and g.rng.randf() < 0.25:
		pl.known_locs.append("hu_immortal_land")
		return "an old map shows a hidden grotto beyond Qing Mao Woods. (Hu Immortal Blessed Land revealed)"
	for ep in g.s.epochs:
		if not ep.done and int(ep.year) - (int(g.s.day) / Data.YEAR) <= 10:
			return "people whisper of the %s." % Data.epochs.filter(func(x): return x.id == ep.id)[0].name
	var names := []
	for n in g.s.npcs.values():
		if n.alive:
			names.append("%s was seen at %s" % [n.name, Data.locations.get(n.loc, {"name": "?"}).name])
	if names.size() > 0:
		return names[g.rng.randi_range(0, names.size() - 1)] + "."
	return "nothing of note."


# ------------------------------------------------------------- services -----
func heal_cost() -> int:
	return 10 * int(p().rank) * maxi(1, p().injuries.size())


func heal_service() -> String:
	var pl := p()
	if pl.injuries.is_empty() and int(pl.hp) >= g.max_hp():
		return "You are already healthy."
	var c := heal_cost()
	if int(pl.stones) < c:
		return "Needs %d stones" % c
	pl.stones = int(pl.stones) - c
	pl.injuries.clear()
	pl.hp = g.max_hp()
	Sfx.play("heal")
	g.add_log("A healer treats your wounds (%d stones)." % c, "good")
	g.emit_signal("state_changed")
	return ""


func inn_cost() -> int:
	return 3 * int(p().rank)


func inn_rest() -> String:
	var pl := p()
	var c := inn_cost()
	if int(pl.stones) < c:
		return "Needs %d stones" % c
	pl.stones = int(pl.stones) - c
	pl.hp = g.max_hp()
	g.skip_days(1)
	g.add_log("You rest at the inn. Fully recovered.", "info")
	g.emit_signal("state_changed")
	return ""


func tutor_cost() -> int:
	return 25 * int(p().rank)


func tutor(path: String) -> String:
	var pl := p()
	var c := tutor_cost()
	if int(pl.stones) < c:
		return "Needs %d stones" % c
	pl.stones = int(pl.stones) - c
	g.skip_days(3)
	g.add_attain(path, 25)
	g.add_log("A tutor drills you in %s for three days." % Data.path_name(path), "good")
	g.emit_signal("state_changed")
	return ""


# ------------------------------------------------------------- refinement ---
func formula_needs(fid: String) -> Dictionary:
	## {stones, mats: {mat_id: n}} resolved to concrete materials the player owns where possible.
	var f: Dictionary = Data.formulas[fid]
	return {"stones": int(f.stones), "days": int(f.days), "tiers": f.mats, "path": f.path}


func _pick_mats(f: Dictionary) -> Dictionary:
	## Choose concrete materials for each tier requirement. Returns {} if impossible.
	var pl := p()
	var have: Dictionary = pl.mats.duplicate()
	var pick := {}
	for tier in f.mats.keys():
		var need := int(f.mats[tier])
		if tier == "path":
			var found := false
			for mid in have.keys():
				var md: Dictionary = Data.materials[mid]
				if md.path == f.path and int(have[mid]) > 0:
					have[mid] = int(have[mid]) - 1
					pick[mid] = int(pick.get(mid, 0)) + 1
					found = true
					break
			if not found:
				return {}
			continue
		for mid in have.keys():
			if need <= 0:
				break
			var md2: Dictionary = Data.materials[mid]
			if md2.tier != tier or md2.id == "immortal_stone":
				continue
			var take := mini(need, int(have[mid]))
			if take > 0:
				have[mid] = int(have[mid]) - take
				pick[mid] = int(pick.get(mid, 0)) + take
				need -= take
		if need > 0:
			return {}
	return pick


func can_refine(fid: String) -> String:
	var pl := p()
	if not Data.formulas.has(fid):
		return "Unknown formula"
	if not (fid in pl.formulas):
		return "You do not know this formula"
	var f: Dictionary = Data.formulas[fid]
	if int(f.rank) > int(pl.rank):
		return "Too advanced for your rank"
	if int(pl.stones) < int(f.stones):
		return "Needs %d stones" % int(f.stones)
	if _pick_mats(f).is_empty():
		return "Missing materials"
	if int(f.rank) >= 6 and int(pl.mats.get("immortal_stone", 0)) < 1:
		return "Needs an Immortal Stone"
	return ""


func refine_chance(fid: String) -> float:
	var pl := p()
	var f: Dictionary = Data.formulas[fid]
	var c := 0.6 + 0.08 * Data.tier_index(float(pl.attain.get("refinement", 0)))
	c -= 0.05 * maxi(0, int(f.rank) - 1)
	if "refinery" in Data.locations.get(pl.location, {}).get("services", []):
		c += 0.1
	if g.s.blessed != null and "refinement_room" in g.s.blessed.structures:
		c += 0.15
	return clampf(c, 0.1, 0.95)


func start_refine(fid: String) -> void:
	var pl := p()
	var f: Dictionary = Data.formulas[fid]
	var pick := _pick_mats(f)
	for mid in pick.keys():
		g.add_material(mid, -int(pick[mid]))
	if int(f.rank) >= 6:
		g.add_material("immortal_stone", -1)
	pl.stones = int(pl.stones) - int(f.stones)
	pl.activity = "refine"
	pl.act = {"formula": fid, "left": int(f.days), "chance": refine_chance(fid), "mats": pick}
	g.add_log("You begin refining %s (%d days)." % [Data.gu[f.id].name, int(f.days)], "info")
	g.emit_signal("state_changed")


func finish_refine() -> void:
	var pl := p()
	var fid: String = pl.act.formula
	var f: Dictionary = Data.formulas[fid]
	var ok = g.rng.randf() < float(pl.act.chance)
	g.add_attain("refinement", 8 + 4 * int(f.rank))
	if ok:
		g.add_gu(f.id)
		g.s.stats.gu_refined = int(g.s.stats.gu_refined) + 1
		g.achieve("refiner")
		g.add_log("Refinement succeeds: %s is born." % Data.gu[f.id].name, "great")
		Sfx.play("summon")
	else:
		# half the materials can be recovered
		for mid in pl.act.mats.keys():
			g.add_material(mid, int(pl.act.mats[mid]) / 2)
		g.add_log("Refinement fails. You salvage some materials.", "bad")
		Sfx.play("fail")
	g.notice.emit("Refinement", ("Success! You refined %s." % Data.gu[f.id].name) if ok else "The refinement failed. Some materials were saved.")


func experiment() -> String:
	## Spend 3 random materials and 3 days to maybe discover a formula.
	var pl := p()
	var total := 0
	for v in pl.mats.values():
		total += int(v)
	if total < 3:
		return "Needs at least 3 materials"
	var used := []
	for i in 3:
		var keys: Array = pl.mats.keys().filter(func(k): return k != "immortal_stone")
		if keys.is_empty():
			break
		var mid: String = keys[g.rng.randi_range(0, keys.size() - 1)]
		g.add_material(mid, -1)
		used.append(Data.materials[mid].name)
	g.skip_days(3)
	g.add_attain("refinement", 6)
	var c := 0.3 + 0.06 * Data.tier_index(float(pl.attain.get("refinement", 0)))
	if g.rng.randf() < c:
		var fid = g.learn_random_formula(mini(5, int(pl.rank)), "")
		if fid != "":
			g.add_log("Experimenting with %s, you discover the formula for %s!" % [", ".join(used), Data.gu[Data.formulas[fid].id].name], "great")
			return "Discovered the formula for %s!" % Data.gu[Data.formulas[fid].id].name
	g.add_log("Your experiment with %s yields nothing but smoke." % ", ".join(used), "info")
	return "Nothing but smoke."


func upgrade_cost(gi: Dictionary) -> Dictionary:
	var gd: Dictionary = Data.gu[gi.id]
	var lvl := int(round(float(gi.get("refined", 0.0)) / 0.1))
	return {"stones": 15 * int(gd.rank) * (lvl + 1), "tier": ["common", "uncommon", "rare"][mini(2, lvl)], "n": 2}


func upgrade_gu(uid: int) -> String:
	var pl := p()
	var gi: Dictionary = g.find_gu(uid)
	if gi.is_empty():
		return "Gone"
	if float(gi.get("refined", 0.0)) >= 0.3 - 0.001:
		return "Already refined to its limit (+30%)"
	var c := upgrade_cost(gi)
	if int(pl.stones) < int(c.stones):
		return "Needs %d stones" % int(c.stones)
	var pick := _pick_mats({"mats": {c.tier: c.n}, "path": ""})
	if pick.is_empty():
		return "Needs %d %s materials" % [int(c.n), c.tier]
	for mid in pick.keys():
		g.add_material(mid, -int(pick[mid]))
	pl.stones = int(pl.stones) - int(c.stones)
	gi["refined"] = float(gi.get("refined", 0.0)) + 0.1
	g.add_attain("refinement", 4)
	g.skip_days(1)
	g.add_log("You refine %s further (+%d%% power)." % [Data.gu[gi.id].name, int(round(gi.refined * 100))], "good")
	g.emit_signal("state_changed")
	return ""
