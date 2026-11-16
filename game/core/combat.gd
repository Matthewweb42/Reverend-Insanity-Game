class_name Combat
extends RefCounted
## Deckbuilder combat (docs/Systems/Combat.md, docs/Systems/Cards.md, DEC-026/039).
## Pure logic: the UI reads state and drains `fx` for animations; the bot uses auto_turn().

const HAND_SIZE := 5
const DRAW_PER_TURN := 2   # spec says 1; raised to 2 so hands do not run dry (DEC-042)
const HAND_MAX := 8
const ESSENCE_REGEN_PCT := 0.12
const MAX_TURNS := 60
const KILLER_COOLDOWN := 3

var rng := RandomNumberGenerator.new()
var player := {}
var enemies := []
var env := []
var turn := 0
var result := ""          # "", "win", "lose", "fled", "stalemate_win", "stalemate_lose"
var lines := []
var fx := []
var stats := {"plays": {}, "killer_used": false, "damage_dealt": 0, "turns": 0, "bosses": [], "killed": [], "enemies_fled": 0}
var ctx := {}
var killer_cd := {}
var night := false
var _uid := 0


# ------------------------------------------------------------------ setup ---
func setup(p_ctx: Dictionary, enemy_defs: Array, env_ids: Array, seed_value: int = 0) -> void:
	ctx = p_ctx
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	night = bool(p_ctx.get("night", false))
	env = []
	for id in env_ids:
		if Data.environments.has(id):
			var e: Dictionary = Data.environments[id].duplicate(true)
			e["id"] = id
			env.append(e)
	var r: int = int(p_ctx.rank)
	player = {
		"id": "p", "name": p_ctx.name, "is_player": true, "rank": r, "path": p_ctx.get("primary", "none"),
		"hp": int(p_ctx.hp), "max_hp": int(p_ctx.max_hp), "shield": 0,
		"essence": int(p_ctx.essence), "max_essence": int(p_ctx.max_essence),
		"regen": int(round(p_ctx.max_essence * ESSENCE_REGEN_PCT)) + int(p_ctx.get("regen_bonus", 0)),
		"statuses": {}, "acc": 80 + r * 2, "eva": 50 + int(p_ctx.get("eva_bonus", 0)),
		"deck": [], "hand": [], "draw": [], "discard": [], "exhaust": [],
		"path_plays": {}, "combo": 0, "forms": {}, "reveal": 0, "cheapen": 0,
		"summons": [], "alive": true, "icon": p_ctx.get("icon", "meditation"),
	}
	for c in p_ctx.deck:
		var card: Dictionary = c.duplicate(true)
		card["upgrade"] = 0.0
		card["cuid"] = _next()
		player.deck.append(card)
	player.draw = player.deck.duplicate()
	_shuffle(player.draw)
	enemies = []
	var idx := 0
	for d in enemy_defs:
		enemies.append(_make_enemy(d, idx, enemy_defs.size()))
		idx += 1
	for e in env:
		if e.has("enemy_buff"):
			for en in enemies:
				if en.kind == "beast":
					_apply_status(en, e.enemy_buff, 1, 2)


func _next() -> int:
	_uid += 1
	return _uid


func _make_enemy(d: Dictionary, idx: int, count: int) -> Dictionary:
	var def: Dictionary = Data.enemies[d.id]
	var r: int = clampi(int(d.get("rank", def.rank)), 1, 9)
	var tier: String = d.get("tier", def.tier)
	var tm: Dictionary = Data.enemy_tiers[tier]
	var hp_mult: float = float(ctx.get("enemy_mult", 1.0))
	var hp := int(round(Data.ENEMY_HP[r - 1] * float(tm.hp) * hp_mult * rng.randf_range(0.9, 1.1)))
	var e := {
		"id": "e%d" % idx, "def": def.id, "name": def.name, "is_player": false, "rank": r, "tier": tier,
		"kind": def.kind, "group": def.group, "path": def.path, "behaviour": def.behaviour,
		"hp": hp, "max_hp": hp, "shield": 0, "statuses": {}, "forms": {}, "summons": [],
		"acc": 75 + r * 2 + 10 * (count - 1), "eva": 50, "alive": true, "fled": false,
		"dmg_base": Data.DMG_BASE[r - 1] * float(tm.dmg) * float(ctx.get("enemy_mult", 1.0)),
		"abilities": def.abilities, "killer": def.get("killer", null), "km_chance": float(tm.km),
		"km_cd": 2, "intent": {}, "icon": def.icon, "last": null, "flag_on_win": def.get("flag_on_win", ""),
		"combo": 0,
	}
	if d.has("name"):
		e.name = d.name
	return e


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


func _log(text: String, kind := "info") -> void:
	lines.append({"text": text, "kind": kind, "turn": turn})


func _fx(d: Dictionary) -> void:
	fx.append(d)


# ------------------------------------------------------------------ flow ----
func start(ambush := false) -> void:
	turn = 1
	_log("Battle begins: %s." % ", ".join(enemies.map(func(e): return e.name)), "head")
	for e in env:
		_log("%s: %s" % [e.name, e.desc], "env")
	_draw(player, HAND_SIZE)
	for e in enemies:
		_choose_intent(e)
	if ambush and int(ctx.get("intel", 0)) < 3:
		_log("Ambush! The enemy strikes first.", "bad")
		_enemy_phase()
		if result != "":
			return
	_begin_player_turn(true)


func _begin_player_turn(first := false) -> void:
	if result != "":
		return
	stats.turns = turn
	player.path_plays = {}
	_tick_statuses(player)
	_env_turn_effects()
	if _check_end():
		return
	if not first:
		player.shield = int(player.shield * 0.5)
		var regen: int = player.regen
		for e in env:
			regen += int(e.get("regen", 0)) * player.rank
		player.essence = mini(player.max_essence, player.essence + maxi(0, regen))
		var n := DRAW_PER_TURN
		if _has(player, "slow"):
			n -= 1
		if player.forms.has("wind"):
			n += 1
		_draw(player, n)
	if player.reveal > 0:
		player.reveal -= 1
	for k in killer_cd.keys():
		killer_cd[k] = maxi(0, killer_cd[k] - 1)
	_tick_forms(player)


func end_turn() -> void:
	if result != "":
		return
	_summons_act(player)
	if _check_end():
		return
	_enemy_phase()
	if result != "":
		return
	turn += 1
	if turn > MAX_TURNS:
		var pp = float(player.hp) / player.max_hp
		var ep := 0.0
		for e in _living_enemies():
			ep = maxf(ep, float(e.hp) / e.max_hp)
		result = "stalemate_win" if pp >= ep else "stalemate_lose"
		_log("The battle drags to a standstill.", "head")
		return
	for e in _living_enemies():
		_choose_intent(e)
	_begin_player_turn()


func _enemy_phase() -> void:
	for e in enemies.duplicate():
		if result != "":
			return
		if not e.alive:
			continue
		_tick_statuses(e)
		if _check_end():
			return
		if not e.alive:
			continue
		if _has(e, "stun"):
			_log("%s is stunned." % e.name, "info")
			_consume_turns(e, "stun")
			continue
		if e.behaviour == "cautious" and float(e.hp) / e.max_hp < 0.25 and rng.randf() < 0.4 and e.tier != "boss":
			e.alive = false
			e.fled = true
			stats.enemies_fled += 1
			_log("%s flees the battle!" % e.name, "info")
			_fx({"type": "flee", "who": e.id})
			continue
		if _has(e, "control"):
			_consume_turns(e, "control")
			var others := _living_enemies().filter(func(x): return x.id != e.id)
			if others.size() > 0:
				var victim = others[rng.randi_range(0, others.size() - 1)]
				_log("%s is controlled and attacks %s!" % [e.name, victim.name], "good")
				_deal(e, victim, e.dmg_base, {"path": e.path})
			else:
				_log("%s is controlled and stands still." % e.name, "good")
			continue
		_enemy_act(e)
		_tick_forms(e)
		if _check_end():
			return
		if e.behaviour == "berserk" and float(e.hp) / e.max_hp < 0.4 and not _has(e, "strong"):
			_apply_status(e, "strong", 1, 2)
			_log("%s goes berserk!" % e.name, "bad")


func _enemy_act(e: Dictionary) -> void:
	var ab: Dictionary = e.intent
	if ab.is_empty():
		_choose_intent(e)
		ab = e.intent
	e.last = ab
	if ab.get("kind", "") == "killer":
		_log("%s unleashes its killer move: %s!" % [e.name, ab.name], "bad")
		_fx({"type": "killer", "who": e.id, "name": ab.name})
		e.km_cd = 3
	else:
		_log("%s uses %s." % [e.name, ab.name], "enemy")
	e.km_cd = maxi(0, e.km_cd - 1)
	var target: Dictionary = player
	# enemies sometimes strike summons standing in front of the player
	if player.summons.size() > 0 and rng.randf() < 0.35:
		target = player.summons[rng.randi_range(0, player.summons.size() - 1)]
	_resolve_effects(e, target, ab.effects, {"enemy_scale": e.dmg_base, "path": e.path, "rank": e.rank})


func _choose_intent(e: Dictionary) -> void:
	var abilities: Array = e.abilities
	if e.killer != null and e.km_cd <= 0 and turn >= 2 and rng.randf() < e.km_chance:
		e.intent = e.killer
		return
	var pool := []
	var hp_pct = float(e.hp) / e.max_hp
	for a in abilities:
		var w := float(a.get("w", 1))
		match e.behaviour:
			"aggressive":
				if a.kind == "attack":
					w *= 2.0
			"defensive":
				if a.kind == "defend" and hp_pct < 0.6:
					w *= 4.0
			"tactical":
				if a.kind == "debuff" and not _is_debuffed(player):
					w *= 3.0
				if a.kind == "defend" and hp_pct < 0.4:
					w *= 2.0
			"berserk":
				if a.kind != "attack":
					w *= 0.4
			"cautious":
				if a.kind == "defend":
					w *= 1.5
		pool.append([a, w])
	var total := 0.0
	for p in pool:
		total += p[1]
	var roll := rng.randf() * total
	for p in pool:
		roll -= p[1]
		if roll <= 0:
			e.intent = p[0]
			return
	e.intent = abilities[0]


func intent_text(e: Dictionary) -> String:
	var ab: Dictionary = e.intent
	if ab.is_empty():
		return ""
	var kind: String = ab.get("kind", "attack")
	if player.reveal <= 0:
		match kind:
			"attack": return "Attack"
			"killer": return "Killer move!"
			"defend": return "Defend"
			"buff": return "Buff"
			"debuff": return "Debuff"
		return "?"
	var parts := []
	for x in ab.effects:
		match x.v:
			"damage":
				var n := int(round(float(x.n) * e.dmg_base * _out_mult(e, null)))
				if int(x.get("times", 1)) > 1:
					parts.append("%dx%d" % [n, int(x.times)])
				else:
					parts.append(str(n))
			"shield":
				parts.append("shield %d" % int(float(x.n) * e.dmg_base))
			"status":
				parts.append(Data.statuses[x.s].name)
			"heal":
				parts.append("heal")
	return "%s: %s" % [ab.name, ", ".join(parts)]


# ------------------------------------------------------------- player acts --
func card_cost(card: Dictionary) -> int:
	var c := int(card.cost)
	for e in env:
		if e.has("cost") and e.cost.has(card.path):
			c += int(e.cost[card.path]) * player.rank
	if player.cheapen > 0:
		c = int(ceil(c / 2.0))
	return maxi(0, c)


func path_limit(path: String) -> int:
	if path == "none":
		return 99
	var pts := float(ctx.get("attain", {}).get(path, 0))
	return Data.TIER_PLAYS[Data.tier_index(pts)]


func can_play(i: int) -> String:
	## returns "" if playable, otherwise a reason
	if result != "":
		return "Battle over"
	if i < 0 or i >= player.hand.size():
		return "No card"
	var card: Dictionary = player.hand[i]
	if "passive" in card.flags:
		return "Passive"
	if card_cost(card) > player.essence:
		return "Not enough essence"
	if not ("quick" in card.flags) and card.path != "none":
		if int(player.path_plays.get(card.path, 0)) >= path_limit(card.path):
			return "%s attainment limit (%d/turn)" % [Data.path_name(card.path), path_limit(card.path)]
	return ""


func play_card(i: int, target_idx := -1) -> bool:
	if can_play(i) != "":
		return false
	var card: Dictionary = player.hand[i]
	var cost := card_cost(card)
	player.essence -= cost
	if player.cheapen > 0:
		player.cheapen -= 1
	player.hand.remove_at(i)
	if not ("quick" in card.flags):
		player.path_plays[card.path] = int(player.path_plays.get(card.path, 0)) + 1
	stats.plays[card.path] = int(stats.plays.get(card.path, 0)) + 1
	var target := _pick_target(target_idx)
	_log("You activate %s." % card.name, "player")
	_fx({"type": "card", "name": card.name, "path": card.path})
	var power: float = float(card.get("power", 1.0)) * (1.0 + float(card.get("upgrade", 0.0)))
	_resolve_effects(player, target, card.effects, {"power": power, "path": card.path, "card_rank": int(card.rank), "card": card})
	if "temporary" in card.flags:
		player.exhaust.append(card)
	else:
		player.discard.append(card)
	_check_end()
	if result == "" and "slow" in card.flags:
		_log("%s is slow: your turn ends." % card.name, "info")
		end_turn()
	return true


func _pick_target(idx: int) -> Dictionary:
	var living := _living_enemies()
	if living.is_empty():
		return {}
	for e in living:
		if enemies.find(e) == idx:
			return e
	return living[0]


func available_killers() -> Array:
	var out := []
	for id in ctx.get("killers", []):
		if not Data.killers.has(id):
			continue
		var km: Dictionary = Data.killers[id]
		var reason := killer_block_reason(km)
		out.append({"km": km, "reason": reason, "cost": killer_cost(km)})
	return out


func killer_cost(km: Dictionary) -> int:
	return int(round(float(km.cost) * pow(player.max_essence / 100.0, 0.8)))


func killer_block_reason(km: Dictionary) -> String:
	var pts := float(ctx.get("attain", {}).get(km.path, 0))
	if Data.tier_index(pts) < Data.tier_index_of(km.need_tier):
		return "Needs %s %s attainment" % [km.need_tier, Data.path_name(km.path)]
	var comp: Dictionary = km.components
	var have := 0
	for c in player.deck:
		if comp.has("tag") and comp.tag in c.get("tags", []):
			have += 1
		elif comp.has("path") and c.path == comp.path:
			have += 1
	if have < int(comp.count):
		var what: String = ("%s Gu" % comp.tag) if comp.has("tag") else ("%s Gu" % Data.path_name(comp.path))
		return "Needs %d %s equipped" % [int(comp.count), what]
	if int(killer_cd.get(km.id, 0)) > 0:
		return "Recovering (%d)" % int(killer_cd[km.id])
	if player.essence < killer_cost(km):
		return "Not enough essence"
	if result != "":
		return "Battle over"
	return ""


func use_killer(id: String, target_idx := -1) -> bool:
	if not Data.killers.has(id):
		return false
	var km: Dictionary = Data.killers[id]
	if killer_block_reason(km) != "":
		return false
	player.essence -= killer_cost(km)
	killer_cd[id] = KILLER_COOLDOWN
	stats.killer_used = true
	var target := _pick_target(target_idx)
	_log("KILLER MOVE: %s!" % km.name, "killer")
	_fx({"type": "killer", "who": "p", "name": km.name, "path": km.path})
	var power := 1.0
	if night and km.has("night_bonus"):
		power += float(km.night_bonus)
	stats.plays[km.path] = int(stats.plays.get(km.path, 0)) + 2
	_resolve_effects(player, target, km.effects, {"power": power, "path": km.path, "card_rank": player.rank, "killer": true})
	_check_end()
	return true


func can_flee() -> String:
	if result != "":
		return "Battle over"
	if not ctx.get("can_flee", false):
		return "Needs a movement Gu"
	if _has(player, "root"):
		return "Rooted"
	if not ctx.get("flee_allowed", true):
		return "Cannot flee this battle"
	return ""


func flee_chance() -> float:
	var c := 0.55 + float(ctx.get("flee_bonus", 0)) / 100.0 - 0.1 * (_living_enemies().size() - 1)
	return clampf(c, 0.1, 0.95)


func try_flee() -> bool:
	if can_flee() != "":
		return false
	if rng.randf() < flee_chance():
		result = "fled"
		_log("You escape!", "head")
		return true
	_log("You fail to escape!", "bad")
	end_turn()
	return false


# ------------------------------------------------------------- resolution ---
func _resolve_effects(src: Dictionary, target: Dictionary, effects: Array, o: Dictionary) -> void:
	var power: float = float(o.get("power", 1.0))
	var is_enemy_src = not src.get("is_player", false) and o.has("enemy_scale")
	var hit := -1.0
	for e in effects:
		if result != "":
			return
		var tsel: String = _default_target(e, o)
		var targets := []
		if tsel == "self":
			targets = [src]
		elif tsel == "all":
			targets = _opponents_of(src)
		else:
			if target.is_empty() or not target.get("alive", true):
				var opp := _opponents_of(src)
				target = opp[0] if opp.size() > 0 else {}
			targets = [target] if not target.is_empty() else []
		var n := _scaled(e, src, o, power)
		match e.v:
			"damage":
				for t in targets:
					var times := int(e.get("times", 1))
					for k in times:
						if not t.get("alive", true):
							break
						if hit < 0 or times > 1:
							hit = _hit_roll(src, t)
						var amt := _attack_amount(src, t, n, o, e)
						_deal(src, t, amt * hit, {"pierce": e.get("pierce", false), "lifesteal": float(e.get("lifesteal", 0)), "bd": float(e.get("bd", 0)), "path": o.get("path", "none"), "hit": hit})
			"heal":
				for t in targets:
					_heal(t, n)
			"shield":
				for t in targets:
					_add_shield(t, n)
			"status":
				for t in targets:
					_apply_status(t, e.s, int(e.stacks), int(e.turns))
			"self_damage":
				src.hp -= int(n)
				_fx({"type": "damage", "who": src.id, "amount": int(n), "self": true})
				_log("%s pays %d HP." % [src.name, int(n)], "info")
				if src.hp <= 0:
					src.hp = 1 if src.get("is_player", false) else 0
			"essence":
				if src.has("essence"):
					src.essence = mini(src.max_essence, src.essence + int(n))
					_fx({"type": "essence", "who": src.id, "amount": int(n)})
			"draw":
				_draw(src, int(e.n))
			"combo":
				src.combo = int(src.get("combo", 0)) + int(e.n)
			"dmg_combo":
				for t in targets:
					var base := (float(e.base) + float(e.per) * int(src.get("combo", 0))) * _rank_scale(src, o, e) * power
					if hit < 0:
						hit = _hit_roll(src, t)
					_deal(src, t, _attack_amount(src, t, base, o, e) * hit, {"path": o.get("path", "none"), "hit": hit})
			"cheapen":
				src.cheapen = int(src.get("cheapen", 0)) + int(e.n)
			"reveal":
				src.reveal = int(src.get("reveal", 0)) + int(e.n)
			"dmg_missing_hp":
				for t in targets:
					var base = (float(e.get("base", 0)) * _rank_scale(src, o, e) * power) + float(e.pct) * (src.max_hp - src.hp)
					if hit < 0:
						hit = _hit_roll(src, t)
					_deal(src, t, _attack_amount(src, t, base, o, e) * hit, {"path": o.get("path", "none"), "lifesteal": float(e.get("lifesteal", 0)), "hit": hit})
			"create":
				for k in int(e.n):
					if Data.gu.has(e.card) and src.get("is_player", false):
						var g: Dictionary = Data.gu[e.card]
						var c := {"id": g.id, "name": g.name, "path": g.path, "rank": g.rank, "cost": g.cost, "effects": g.effects,
								"flags": g.flags, "power": _created_power(g), "tags": g.tags, "icon": g.icon, "upgrade": 0.0, "cuid": _next()}
						if src.hand.size() < HAND_MAX:
							src.hand.append(c)
				_log("Forged %d %s." % [int(e.n), Data.gu.get(e.card, {"name": e.card}).name], "good")
			"upgrade_hand":
				for c in src.get("hand", []):
					c.upgrade = float(c.get("upgrade", 0)) + float(e.pct)
				_log("Your hand is empowered by %d%%." % int(e.pct * 100), "good")
			"form":
				src.forms[e.form] = int(e.turns) + 1
				_log("%s takes %s." % [src.name, Data.forms[e.form].name], "good")
				_fx({"type": "buff", "who": src.id, "text": Data.forms[e.form].name})
			"mimic":
				_mimic(src)
			"summon":
				var s := {"id": "s%d" % _next(), "name": e.name, "hp": int(e.hp * power), "max_hp": int(e.hp * power),
						"atk": int(e.atk * power), "turns": int(e.turns), "icon": e.get("icon", "wolf-head"), "alive": true,
						"is_summon": true, "statuses": {}, "shield": 0, "forms": {}, "rank": src.rank}
				src.summons.append(s)
				_log("%s answers your call." % e.name, "good")
				_fx({"type": "summon", "who": src.id, "name": e.name})
			"steal_essence":
				if src.has("essence"):
					src.essence = mini(src.max_essence, src.essence + int(n))
				_log("You steal %d essence." % int(n), "good")
				for t in targets:
					t.shield = maxi(0, t.shield - int(n))
			"multiply_status":
				for t in targets:
					if t.statuses.has(e.s):
						t.statuses[e.s].stacks = int(t.statuses[e.s].stacks * float(e.x))
						_log("%s's %s multiplies to %d!" % [t.name, Data.statuses[e.s].name, t.statuses[e.s].stacks], "good")
						_fx({"type": "status", "who": t.id, "status": e.s})
			"detonate":
				for t in targets:
					if t.statuses.has(e.s):
						var stacks := int(t.statuses[e.s].stacks)
						var amt := stacks * float(e.mult) * _stack_scale(t) * power
						if not e.get("keep", false):
							t.statuses.erase(e.s)
						_log("%s's %s detonates!" % [t.name, Data.statuses[e.s].name], "good")
						_deal(src, t, amt, {"pierce": true, "path": o.get("path", "none"), "hit": 1.0, "nomods": true})
			"execute":
				for t in targets:
					if t.get("tier", "") != "boss" and float(t.hp) / t.max_hp <= float(e.pct):
						_log("%s executes %s!" % [src.name, t.name], "killer")
						_deal(src, t, t.hp + t.shield + 1, {"pierce": true, "hit": 1.0, "nomods": true, "path": o.get("path", "none")})
					elif t.get("tier", "") == "boss" and float(t.hp) / t.max_hp <= float(e.pct):
						if hit < 0:
							hit = _hit_roll(src, t)
						_deal(src, t, _attack_amount(src, t, n * 2.0, o, e) * hit, {"path": o.get("path", "none"), "hit": hit})
					else:
						if hit < 0:
							hit = _hit_roll(src, t)
						_deal(src, t, _attack_amount(src, t, n, o, e) * hit, {"path": o.get("path", "none"), "hit": hit})
			"dmg_shield":
				var amt := float(src.shield) * float(e.mult) * power
				if e.get("consume", false):
					src.shield = 0
				for t in targets:
					if amt > 0:
						_deal(src, t, _attack_amount(src, t, amt, o, e, false), {"path": o.get("path", "none"), "hit": 1.0})
			"shield_pct_hp":
				_add_shield(src, float(e.pct) * src.max_hp * power)
			"dmg_essence":
				for t in targets:
					var base := float(e.get("base", 0)) * _rank_scale(src, o, e) * power + float(e.pct) * float(src.get("essence", 0))
					if hit < 0:
						hit = _hit_roll(src, t)
					_deal(src, t, _attack_amount(src, t, base, o, e) * hit, {"path": o.get("path", "none"), "hit": hit})
			"cleanse":
				for s in src.statuses.keys():
					if Data.statuses[s].debuff:
						src.statuses.erase(s)
	if is_enemy_src:
		pass


const SELF_VERBS := ["shield", "shield_pct_hp", "heal", "essence", "draw", "combo", "cheapen", "reveal", "upgrade_hand",
		"form", "self_damage", "summon", "create", "mimic"]
const BUFFS := ["thorns", "prot", "stealth", "regen", "strong"]


func _default_target(e: Dictionary, o: Dictionary) -> String:
	if e.has("t"):
		return str(e.t)
	if e.v in SELF_VERBS:
		return "self"
	if e.v == "status" and str(e.get("s", "")) in BUFFS:
		return "self"
	var card_t := str(o.get("card", {}).get("target", "enemy")) if o.get("card") is Dictionary else "enemy"
	if card_t == "all":
		return "all"
	if card_t == "self" and e.v == "status":
		return "self"
	return "enemy"


func _created_power(g: Dictionary) -> float:
	var diff := int(player.rank) - int(g.rank)
	if diff <= 0:
		return 1.0
	return [1.0, 0.9, 0.7, 0.5][mini(diff, 3)]


func _rank_scale(src: Dictionary, o: Dictionary, e: Dictionary) -> float:
	if e.get("rankscale", false):
		return Data.DMG_BASE[int(src.rank) - 1] / 12.0
	return 1.0


func _scaled(e: Dictionary, src: Dictionary, o: Dictionary, power: float) -> float:
	if not e.has("n"):
		return 0.0
	var n := float(e.n)
	if o.has("enemy_scale"):
		return n * float(o.enemy_scale)
	return n * power * _rank_scale(src, o, e)


func _attack_amount(src: Dictionary, t: Dictionary, base: float, o: Dictionary, e: Dictionary, path_bonus := true) -> float:
	var amt := base
	if src.get("is_player", false) and not o.has("enemy_scale") and path_bonus:
		var pts := float(ctx.get("attain", {}).get(o.get("path", "none"), 0))
		amt += Data.tier_index(pts) * 2 * int(o.get("card_rank", 1))
	var diff := clampi(int(src.rank) - int(t.get("rank", src.rank)), -3, 3)
	amt *= 1.0 + diff * 0.1
	return amt


func _hit_roll(src: Dictionary, t: Dictionary) -> float:
	var acc := float(src.get("acc", 80))
	var eva := float(t.get("eva", 40))
	for e in env:
		acc += float(e.get("acc", 0))
		eva += float(e.get("eva", 0))
	if src.get("reveal", 0) > 0:
		acc += 10
	var n_en := _living_enemies().size()
	if src.get("is_player", false):
		if n_en >= 4: acc -= 20
		elif n_en == 3: acc -= 10
	if t.get("is_player", false):
		if n_en >= 4: eva -= 30
		elif n_en == 3: eva -= 20
		elif n_en == 2: eva -= 10
	if _has(t, "stealth"):
		eva += 40
	if t.get("forms", {}).has("wind"):
		eva += 30
	if t.get("forms", {}).has("beast"):
		eva -= 10
	if _has(t, "root"):
		eva -= 15
	if _has(t, "stun"):
		eva -= 30
	var diff := (acc + rng.randi_range(-10, 10)) - (eva + rng.randi_range(-10, 10))
	if diff > 20:
		return 1.0
	if diff > 0:
		return 0.5 + 0.3 * diff / 20.0
	return 0.0


func _out_mult(src: Dictionary, t) -> float:
	var m := 1.0
	if _has(src, "strong"):
		m *= 1.25 + 0.15 * (int(src.statuses.strong.stacks) - 1)
	if _has(src, "weak"):
		m *= 0.75
	if _has(src, "slow") and not src.get("is_player", false):
		m *= 0.85
	if src.get("forms", {}).has("beast"):
		m *= 1.3
	if src.get("is_player", false):
		m *= 1.0 + float(ctx.get("damage_bonus", 0))
		m *= float(ctx.get("age_combat", 1.0))
		m *= 1.0 + 0.05 * int(ctx.get("intel", 0))
		if night:
			m *= 1.0 + float(ctx.get("night_bonus", 0))
	for e in env:
		m *= 1.0 + float(e.get("dmg", 0))
	return m


func _deal(src: Dictionary, t: Dictionary, amount: float, o: Dictionary) -> void:
	if t.is_empty() or not t.get("alive", true):
		return
	if float(o.get("hit", 1.0)) <= 0.0:
		_log("%s misses %s." % [src.name, t.name], "miss")
		_fx({"type": "miss", "who": t.id})
		return
	var amt := amount
	if not o.get("nomods", false):
		amt *= _out_mult(src, t)
		var path: String = o.get("path", "none")
		for e in env:
			amt *= 1.0 + float(e.get("path_bonus", {}).get(path, 0))
		amt *= rng.randf_range(0.9, 1.1)
		if _has(src, "stealth"):
			amt *= 1.5
			src.statuses.erase("stealth")
		if float(o.get("bd", 0)) > 0 and _is_debuffed(t):
			amt *= 1.0 + float(o.bd)
	if _has(t, "vuln"):
		amt *= 1.25
	if _has(t, "prot"):
		amt *= 0.75
	if t.get("forms", {}).has("stone"):
		amt *= 0.6
	var dmg := maxi(0, int(round(amt)))
	var absorbed := 0
	if not o.get("pierce", false) and t.shield > 0:
		absorbed = mini(t.shield, dmg)
		t.shield -= absorbed
	var to_hp := dmg - absorbed
	t.hp -= to_hp
	if src.get("is_player", false):
		stats.damage_dealt += dmg
	var partial := float(o.get("hit", 1.0)) < 1.0
	_log("%s hits %s for %d%s%s." % [src.name, t.name, dmg, " (blocked %d)" % absorbed if absorbed > 0 else "", " (glancing)" if partial else ""],
			"hit_player" if t.get("is_player", false) else "hit")
	_fx({"type": "damage", "who": t.id, "amount": dmg, "blocked": absorbed, "partial": partial})
	var ls := float(o.get("lifesteal", 0))
	if src.get("forms", {}).has("blood"):
		ls += 0.2
	if ls > 0 and src.get("alive", true):
		_heal(src, dmg * ls)
	var thorns := 0
	if _has(t, "thorns"):
		thorns += int(t.statuses.thorns.stacks) * maxi(1, int(Data.DMG_BASE[int(t.rank) - 1] / 12.0))
	if t.get("forms", {}).has("bone"):
		thorns += 4 * int(t.rank)
	if thorns > 0 and src.get("alive", true) and src.id != t.id and not o.get("nomods", false):
		src.hp -= thorns
		_log("%s takes %d thorn damage." % [src.name, thorns], "info")
		_fx({"type": "damage", "who": src.id, "amount": thorns})
		_check_dead(src)
	_check_dead(t)


func _check_dead(t: Dictionary) -> void:
	if t.hp > 0 or not t.get("alive", true):
		return
	if t.get("is_summon", false):
		t.alive = false
		player.summons.erase(t)
		_log("%s falls." % t.name, "info")
		return
	if t.get("is_player", false):
		t.hp = 0
		t.alive = false
		return
	t.hp = 0
	t.alive = false
	stats.killed.append(t.def)
	if t.tier == "boss":
		stats.bosses.append(t.def)
	_log("%s is defeated!" % t.name, "good")
	_fx({"type": "death", "who": t.id})


func _heal(t: Dictionary, n: float) -> void:
	var m := 1.0
	for e in env:
		m += float(e.get("heal", 0))
	var amt := int(round(n * m))
	var before: int = t.hp
	t.hp = mini(t.max_hp, t.hp + amt)
	if t.hp > before:
		_fx({"type": "heal", "who": t.id, "amount": t.hp - before})


func _add_shield(t: Dictionary, n: float) -> void:
	var m := 1.0
	for e in env:
		m += float(e.get("shield", 0))
	var amt := int(round(n * m))
	t.shield += amt
	_fx({"type": "shield", "who": t.id, "amount": amt})


func _stack_scale(t: Dictionary) -> float:
	return maxf(1.0, Data.DMG_BASE[int(t.get("rank", 1)) - 1] / 12.0)


func _apply_status(t: Dictionary, s: String, stacks: int, turns: int) -> void:
	if t.is_empty() or not t.get("alive", true):
		return
	if not t.has("statuses"):
		t["statuses"] = {}
	if t.statuses.has(s):
		t.statuses[s].stacks = int(t.statuses[s].stacks) + stacks if s in ["poison", "burn", "bleed", "regen", "thorns", "strong"] else maxi(int(t.statuses[s].stacks), stacks)
		t.statuses[s].turns = maxi(int(t.statuses[s].turns), turns)
	else:
		t.statuses[s] = {"stacks": stacks, "turns": turns}
	_fx({"type": "status", "who": t.id, "status": s})


func _has(t: Dictionary, s: String) -> bool:
	return t.has("statuses") and t.statuses.has(s) and int(t.statuses[s].stacks) > 0 and int(t.statuses[s].turns) > 0


func _consume_turns(t: Dictionary, s: String) -> void:
	if t.statuses.has(s):
		t.statuses[s].turns -= 1
		if int(t.statuses[s].turns) <= 0:
			t.statuses.erase(s)


func _is_debuffed(t: Dictionary) -> bool:
	for s in t.get("statuses", {}).keys():
		if Data.statuses.has(s) and Data.statuses[s].debuff and _has(t, s):
			return true
	return false


func _tick_statuses(t: Dictionary) -> void:
	var sc := _stack_scale(t)
	for s in t.statuses.keys().duplicate():
		var st: Dictionary = t.statuses[s]
		match s:
			"burn":
				_dot(t, 3 * st.stacks * sc, "burns")
				st.stacks -= 1
			"poison":
				_dot(t, st.stacks * sc, "suffers poison")
			"bleed":
				_dot(t, 2 * st.stacks * sc, "bleeds")
				st.stacks -= 1
			"regen":
				_heal(t, 3 * st.stacks * sc)
		if s in ["stun", "control"]:
			continue
		st.turns -= 1
		if int(st.turns) <= 0 or int(st.stacks) <= 0:
			t.statuses.erase(s)
	if not t.get("is_player", false):
		t.shield = int(t.shield * 0.5)


func _dot(t: Dictionary, amt: float, verb: String) -> void:
	var n := int(round(amt))
	if n <= 0:
		return
	t.hp -= n
	_log("%s %s for %d." % [t.name, verb, n], "dot")
	_fx({"type": "damage", "who": t.id, "amount": n, "dot": true})
	if t.hp <= 0:
		if t.get("is_player", false):
			t.hp = 0
			t.alive = false
		else:
			_check_dead(t)


func _tick_forms(t: Dictionary) -> void:
	for f in t.get("forms", {}).keys().duplicate():
		t.forms[f] -= 1
		if t.forms[f] <= 0:
			t.forms.erase(f)
			if t.get("is_player", false):
				_log("%s fades." % Data.forms[f].name, "info")


func _env_turn_effects() -> void:
	for e in env:
		if e.has("dot"):
			for c in [player] + _living_enemies():
				_dot(c, float(e.dot) * int(c.rank) * maxf(1.0, Data.DMG_BASE[int(c.rank) - 1] / 24.0), "chokes on miasma")
		if e.get("lightning", false):
			var all := [player] + _living_enemies()
			var t = all[rng.randi_range(0, all.size() - 1)]
			_dot(t, t.max_hp * 0.08, "is struck by lightning")
			_fx({"type": "lightning", "who": t.id})


func _summons_act(owner: Dictionary) -> void:
	for s in owner.summons.duplicate():
		var opp := _living_enemies()
		if opp.is_empty():
			return
		var t = opp[rng.randi_range(0, opp.size() - 1)]
		_deal(s, t, float(s.atk), {"path": "enslavement", "hit": 1.0})
		s.turns -= 1
		if s.turns <= 0:
			owner.summons.erase(s)
			_log("%s returns to the wild." % s.name, "info")


func _mimic(src: Dictionary) -> void:
	var last = null
	for e in enemies:
		if e.last != null:
			last = e.last
	if last == null:
		_log("There is nothing to mimic yet.", "info")
		return
	var effs := []
	for x in last.effects:
		var y: Dictionary = x.duplicate(true)
		if y.has("n") and y.v in ["damage", "shield", "heal"]:
			y.n = float(y.n) * Data.DMG_BASE[int(src.rank) - 1]
		if y.get("t", "") == "self":
			pass
		effs.append(y)
	var c := {"id": "mimic", "name": "Mimicked " + str(last.name), "path": "transformation", "rank": src.rank, "cost": 4 * int(src.rank),
			"effects": effs, "flags": ["temporary", "quick"], "power": 1.0, "tags": [], "icon": "mimic-chest", "upgrade": 0.0, "cuid": _next()}
	if src.hand.size() < HAND_MAX:
		src.hand.append(c)
	_log("You mimic %s." % last.name, "good")


func _draw(c: Dictionary, n: int) -> void:
	if not c.get("is_player", false):
		return
	for k in n:
		if c.hand.size() >= HAND_MAX:
			return
		if c.draw.is_empty():
			if c.discard.is_empty():
				return
			c.draw = c.discard
			c.discard = []
			_shuffle(c.draw)
			_log("You reshuffle your aperture.", "info")
		c.hand.append(c.draw.pop_back())


func _opponents_of(src: Dictionary) -> Array:
	if src.get("is_player", false) or src.get("is_summon", false):
		return _living_enemies()
	return [player]


func _living_enemies() -> Array:
	return enemies.filter(func(e): return e.alive)


func _check_end() -> bool:
	if result != "":
		return true
	if player.hp <= 0:
		player.hp = 0
		result = "lose"
		_log("You fall...", "head")
		return true
	if _living_enemies().is_empty():
		result = "win"
		_log("Victory!", "head")
		return true
	return false


# ------------------------------------------------------------------ bot -----
func auto_turn() -> void:
	## Simple greedy AI used by the scripted playthrough and the "Auto" button.
	var guard := 0
	while result == "" and guard < 30:
		guard += 1
		if float(player.hp) / player.max_hp < 0.15 and can_flee() == "" and ctx.get("bot_may_flee", true):
			if try_flee():
				return
			continue
		var target := _bot_target()
		var did := false
		for k in available_killers():
			if k.reason == "":
				use_killer(k.km.id, target)
				did = true
				break
		if did:
			continue
		var best := -1
		var best_v := -1.0
		for i in player.hand.size():
			if can_play(i) != "":
				continue
			var v := _card_value(player.hand[i])
			if v > best_v:
				best_v = v
				best = i
		if best < 0:
			break
		play_card(best, target)
	if result == "":
		end_turn()


func _bot_target() -> int:
	var living := _living_enemies()
	if living.is_empty():
		return -1
	var best = living[0]
	for e in living:
		if e.hp < best.hp:
			best = e
	return enemies.find(best)


func _card_value(card: Dictionary) -> float:
	var v := 1.0
	var incoming := 0.0
	for e in _living_enemies():
		if e.intent.get("kind", "") in ["attack", "killer"]:
			incoming += e.dmg_base
	for e in card.effects:
		match e.v:
			"damage", "dmg_combo", "dmg_essence", "dmg_missing_hp", "execute":
				v += float(e.get("n", e.get("base", 10))) * float(e.get("times", 1))
			"shield", "shield_pct_hp":
				v += (float(e.get("n", 20)) if incoming > player.shield else 4.0)
			"heal":
				v += float(e.n) if player.hp < player.max_hp * 0.6 else 2.0
			"status":
				v += 8.0 * int(e.stacks)
			"detonate", "multiply_status":
				var t = _living_enemies()[0]
				v += 4.0 * int(t.statuses.get(e.s, {"stacks": 0}).stacks)
			"dmg_shield":
				v += float(player.shield) * float(e.mult)
			"summon":
				v += float(e.atk) * 3
			"essence":
				v += 3.0 if player.essence < player.max_essence * 0.5 else 0.5
			_:
				v += 6.0
	return v / maxf(1.0, card_cost(card)) + (2.0 if "quick" in card.flags else 0.0)
