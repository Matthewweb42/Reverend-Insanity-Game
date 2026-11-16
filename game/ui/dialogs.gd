extends RefCounted
## Every modal dialog in the game: events, notices, markets, refinery, missions, people, travel,
## goals, tribulations, the pause menu, settings, the legacy vault, records, credits and the
## end-of-life summary.

var main


func _init(m) -> void:
	main = m


func _close_btn(dlg_ref: Array, text := "Close") -> Button:
	return UI.btn(text, func(): main.close_modal(dlg_ref[0]))


func _title(v: VBoxContainer, text: String, size := 28) -> void:
	var t := UI.heading(text, size)
	v.add_child(t)
	v.add_child(HSeparator.new())


# =================================================================== NOTICE ==
func notice(title: String, text: String, good := true) -> void:
	var v := UI.vbox(12)
	var ref := [null]
	var t := UI.heading(title, 28)
	t.add_theme_color_override("font_color", UI.GOLD if good else UI.CRIMSON)
	v.add_child(t)
	var r := UI.rich(text)
	r.custom_minimum_size.x = 520
	v.add_child(r)
	var b := _close_btn(ref, "Continue")
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size.x = 180
	v.add_child(b)
	ref[0] = main.modal(v, true, 600)
	ref[0].set_meta("bot_close", true)
	Sfx.play("gong" if good else "fail")


func confirm(title: String, text: String, yes_text: String, cb: Callable) -> void:
	var v := UI.vbox(12)
	var ref := [null]
	_title(v, title, 24)
	v.add_child(UI.wrap(text, 16))
	var h := UI.hbox()
	h.alignment = BoxContainer.ALIGNMENT_END
	h.add_child(_close_btn(ref, "Cancel"))
	h.add_child(UI.btn(yes_text, func():
		main.close_modal(ref[0])
		cb.call()))
	v.add_child(h)
	ref[0] = main.modal(v, true, 520)


# ==================================================================== EVENT ==
func event(inst: Dictionary) -> void:
	if inst.is_empty():
		return
	for m in main.modals:
		if is_instance_valid(m) and m.get_meta("event", false):
			return
	var v := UI.vbox(10)
	var ref := [null]
	var head := UI.hbox()
	var ev: Dictionary = inst.ev
	head.add_child(UI.icon(ev.get("icon", "scroll-unfurled"), 48, UI.GOLD))
	var tv := UI.vbox(0)
	tv.add_child(UI.heading(inst.title, 26))
	var tags := []
	if ev.has("storyline"):
		tags.append("Storyline")
	if ev.get("tier", "") != "":
		tags.append(str(ev.tier).capitalize())
	if ev.has("proc") or inst.q.has("proc"):
		tags.append("Rumour")
	if tags.size() > 0:
		tv.add_child(UI.lbl(" · ".join(tags), 13, UI.TEXT_DIM))
	head.add_child(tv)
	v.add_child(head)
	v.add_child(HSeparator.new())
	var body := UI.rich(inst.text)
	body.custom_minimum_size.x = 620
	v.add_child(body)
	var choices := UI.vbox(6)
	v.add_child(choices)
	for i in inst.choices.size():
		var ch: Dictionary = inst.choices[i]
		var label: String = ch.text
		if ch.odds != "":
			label += "   [%s]" % ch.odds
		var b := UI.btn(label, func(): _choose(ref, i))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(620, 40)
		if ch.reason != "":
			b.disabled = true
			b.text = "%s   (%s)" % [ch.text, ch.reason]
		if ch.hint != "":
			b.tooltip_text = ch.hint
		choices.add_child(b)
	var foot := UI.hbox()
	foot.add_child(UI.lbl("Your wisdom decides how clearly you read the odds.", 12, UI.TEXT_DIM))
	foot.add_child(UI.expand(UI.spacer()))
	foot.add_child(UI.btn("Decide later", func():
		Game.defer_event()
		main.close_modal(ref[0]), "The event waits a day or so; some expire."))
	foot.add_child(UI.btn("Ignore", func():
		Game.dismiss_event()
		main.close_modal(ref[0])))
	v.add_child(foot)
	ref[0] = main.modal(v, false, 700)
	ref[0].set_meta("event", true)


func _choose(ref: Array, idx: int) -> void:
	var r: Dictionary = Game.resolve_event_choice(idx)
	if r.get("blocked", false):
		main.toast(r.text, "warn")
		return
	main.close_modal(ref[0])
	if r.get("combat", false):
		return
	var txt: String = str(r.get("text", ""))
	if txt.strip_edges() == "":
		txt = "So it goes."
	notice("Outcome", txt, r.get("ok", true))


# =================================================================== MARKET ==
func market(kind: String) -> void:
	var v := UI.vbox(10)
	var ref := [null]
	var names := {"market": "Market", "black_market": "Black Market", "caravan": "Travelling Caravan", "auction": "Auction House", "treasure_yellow_heaven": "Treasure Yellow Heaven"}
	_title(v, names.get(kind, "Market"))
	var money := UI.lbl("", 16, UI.AMBER)
	v.add_child(money)
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(780, 520)
	v.add_child(tabs)
	var buy_sc := UI.scroll(UI.vbox(6))
	buy_sc.name = "Buy"
	var sell_sc := UI.scroll(UI.vbox(6))
	sell_sc.name = "Sell"
	tabs.add_child(buy_sc)
	tabs.add_child(sell_sc)
	var rebuild := [null]
	rebuild[0] = func():
		var pl: Dictionary = Game.p()
		money.text = "You have ◈ %s primeval stones%s" % [UI.num(pl.stones), ("   ✦ %s immortal essence stones" % UI.num(pl.istones)) if int(pl.istones) > 0 or kind == "treasure_yellow_heaven" else ""]
		var bl: VBoxContainer = buy_sc.get_child(0)
		UI.clear(bl)
		var m: Dictionary = Game.econ.market(kind)
		if kind == "black_market":
			bl.add_child(UI.lbl("Dealing here darkens your reputation.", 13, UI.CRIMSON))
		for i in m.items.size():
			var it: Dictionary = m.items[i]
			bl.add_child(_market_row(it, i, kind, rebuild))
		if m.items.is_empty():
			bl.add_child(UI.lbl("Sold out. Stock refreshes weekly.", 14, UI.TEXT_DIM))
		var sl: VBoxContainer = sell_sc.get_child(0)
		UI.clear(sl)
		sl.add_child(UI.lbl("Gu", 16, UI.GOLD, true))
		for gi in pl.gu:
			var gd: Dictionary = Data.gu[gi.id]
			var h := UI.hbox()
			h.add_child(UI.icon(gd.icon, 28, Data.path_color(gd.path).lightened(0.3)))
			var nl := UI.lbl("%s (R%d%s)" % [gd.name, int(gd.rank), ", equipped" if gi.eq else ""], 15)
			UI.expand(nl)
			h.add_child(nl)
			h.tooltip_text = Data.gu_description(gd, Game.gu_power(gi))
			var price: int = Game.econ.sell_price_gu(gi)
			h.add_child(UI.btn("Sell for %d" % price, func():
				var r: String = Game.econ.sell_gu(int(gi.uid))
				if r != "":
					main.toast(r, "warn")
				rebuild[0].call()))
			sl.add_child(h)
		sl.add_child(UI.lbl("Materials", 16, UI.GOLD, true))
		for mid in pl.mats.keys():
			if int(pl.mats[mid]) <= 0:
				continue
			var md: Dictionary = Data.materials[mid]
			var h2 := UI.hbox()
			h2.add_child(UI.icon(md.get("icon", "stone-pile"), 24, UI.RARITY_COLORS.get(md.tier, UI.TEXT)))
			var nl2 := UI.lbl("%s ×%d (%s)" % [md.name, int(pl.mats[mid]), md.tier], 15)
			UI.expand(nl2)
			h2.add_child(nl2)
			h2.add_child(UI.btn("Sell one for %d" % Game.econ.sell_price_mat(mid), func():
				var r: String = Game.econ.sell_mat(mid)
				if r != "":
					main.toast(r, "warn")
				rebuild[0].call()))
			sl.add_child(h2)
	rebuild[0].call()
	var foot := UI.hbox()
	foot.add_child(UI.expand(UI.spacer()))
	foot.add_child(_close_btn(ref))
	v.add_child(foot)
	ref[0] = main.modal(v, true, 820)
	ref[0].set_meta("bot_close", true)


func _market_row(it: Dictionary, i: int, kind: String, rebuild: Array) -> Control:
	var p := UI.panel(UI.PANEL_2, UI.GOLD_DIM, 6)
	var h := UI.hbox()
	p.add_child(h)
	var cur := "✦" if it.cur == "istones" else "◈"
	if it.type == "gu":
		var gd: Dictionary = Data.gu[it.id]
		h.add_child(UI.icon(gd.icon, 40, Data.path_color(gd.path).lightened(0.3)))
		var v := UI.vbox(0)
		UI.expand(v)
		var nm := UI.rich("[b][color=#%s]%s[/color][/b]  R%d · %s · %s%s" % [UI.hex(UI.RARITY_COLORS.get(gd.rarity, UI.TEXT)), gd.name, int(gd.rank), UI.path_tag(gd.path), gd.rarity, "  · clan Gu" if it.get("clan", false) else ""])
		v.add_child(nm)
		v.add_child(UI.wrap(Data.gu_description(gd), 13, UI.TEXT_DIM))
		h.add_child(v)
		p.tooltip_text = "%s\n%s\nUpkeep: %d stones/week. %s" % [gd.name, Data.gu_description(gd), int(gd.get("feed", 1)), gd.get("flavor", "")]
	else:
		var md: Dictionary = Data.materials[it.id]
		h.add_child(UI.icon(md.get("icon", "stone-pile"), 34, UI.RARITY_COLORS.get(md.tier, UI.TEXT)))
		var l := UI.lbl("%s  (%s material)" % [md.name, md.tier], 15)
		UI.expand(l)
		h.add_child(l)
	h.add_child(UI.lbl("%s %s" % [cur, UI.num(it.price)], 16, UI.AMBER))
	if not it.haggled and it.cur == "stones":
		h.add_child(UI.btn("Haggle", func():
			main.toast(Game.econ.haggle(kind, i), "info")
			rebuild[0].call(), "Wisdom attainment and rank improve your odds."))
	h.add_child(UI.btn("Buy", func():
		var r: String = Game.econ.buy(kind, i)
		if r != "":
			main.toast(r, "warn")
		else:
			main.toast("Bought.", "good")
		rebuild[0].call()))
	return p


# ================================================================ REFINERY ==
func refinery() -> void:
	var v := UI.vbox(10)
	var ref := [null]
	_title(v, "Refinery")
	v.add_child(UI.wrap("Refining takes days and materials; failure loses some of them. Refinement attainment and a refinement room in your blessed land raise the odds.", 14, UI.TEXT_DIM))
	var list := UI.vbox(6)
	var pl: Dictionary = Game.p()
	var fl: Array = pl.formulas.duplicate()
	fl.sort_custom(func(a, b): return int(Data.formulas[a].rank) < int(Data.formulas[b].rank))
	for fid in fl:
		if not Data.formulas.has(fid):
			continue
		var f: Dictionary = Data.formulas[fid]
		var gd: Dictionary = Data.gu.get(f.id, {"name": f.id, "icon": "cauldron", "path": "none", "rank": 1})
		var why: String = Game.econ.can_refine(fid)
		var p := UI.panel(UI.PANEL_2, UI.GOLD_DIM, 6)
		var h := UI.hbox()
		p.add_child(h)
		h.add_child(UI.icon(gd.icon, 36, Data.path_color(gd.path).lightened(0.3)))
		var tv := UI.vbox(0)
		UI.expand(tv)
		tv.add_child(UI.rich("[b]%s[/b]  R%d · %s" % [gd.name, int(gd.rank), UI.path_tag(gd.path)]))
		var mats := []
		for t in f.mats.keys():
			mats.append("%d %s" % [int(f.mats[t]), "%s-path" % Data.path_name(f.path) if t == "path" else t])
		tv.add_child(UI.lbl("%d stones, %s materials, %d days · %d%% success" % [int(f.stones), ", ".join(mats), int(f.days), int(Game.econ.refine_chance(fid) * 100)], 13, UI.TEXT_DIM))
		h.add_child(tv)
		var b := UI.btn("Refine", func():
			var r: String = Game.set_activity("refine", {"formula": fid})
			if r != "":
				main.toast(r, "warn")
			else:
				main.close_modal(ref[0])
				Game.paused = false)
		if why != "":
			b.disabled = true
			b.tooltip_text = why
		h.add_child(b)
		p.tooltip_text = Data.gu_description(gd)
		list.add_child(p)
	v.add_child(UI.scroll(list, 420))
	var foot := UI.hbox()
	foot.add_child(UI.btn("Experiment", func():
		var r: String = Game.econ.experiment()
		main.toast(r, "info")
		main.close_modal(ref[0]), "Combine random materials and hope. Might discover a formula."))
	foot.add_child(UI.expand(UI.spacer()))
	foot.add_child(_close_btn(ref))
	v.add_child(foot)
	ref[0] = main.modal(v, true, 760)
	ref[0].set_meta("bot_close", true)


# ================================================================ MISSIONS ==
func missions() -> void:
	var v := UI.vbox(10)
	var ref := [null]
	_title(v, "Clan Hall — %s" % Data.clans[Game.p().clan].name)
	v.add_child(UI.lbl("Standing: %s (%d contribution). Monthly stipend: %d stones." % [Game.standing_name(), int(Game.p().standing), int(Data.stipend.get(Game.standing_name(), 0))], 15, UI.TEXT))
	for a in Game.world.available_missions():
		var m: Dictionary = a.m
		var h := UI.hbox()
		var tv := UI.vbox(0)
		UI.expand(tv)
		tv.add_child(UI.lbl(m.name, 16, UI.TEXT, true))
		var st: Array = m.stones
		tv.add_child(UI.lbl("%d days · %d-%d stones × rank · +%d contribution%s%s" % [int(m.days), int(st[0]), int(st[1]), int(m.contrib),
				" · may fight (%d%%)" % int(float(m.get("combat", 0)) * 100) if float(m.get("combat", 0)) > 0 else "", " · materials" if m.get("mats", false) else ""], 13, UI.TEXT_DIM))
		h.add_child(tv)
		var b := UI.btn("Accept", func():
			var r: String = Game.set_activity("mission", {"mission": m.id})
			if r != "":
				main.toast(r, "warn")
			else:
				main.close_modal(ref[0])
				Game.paused = false)
		if not a.ok:
			b.disabled = true
			b.tooltip_text = a.reason
		h.add_child(b)
		v.add_child(h)
	var foot := UI.hbox()
	foot.add_child(UI.expand(UI.spacer()))
	foot.add_child(_close_btn(ref))
	v.add_child(foot)
	ref[0] = main.modal(v, true, 680)


func tutor() -> void:
	var v := UI.vbox(10)
	var ref := [null]
	_title(v, "Hire a Tutor (%d stones)" % Game.econ.tutor_cost())
	var f := HFlowContainer.new()
	for path in Data.path_list:
		var pid: String = path.id if path is Dictionary else str(path)
		if pid == "none":
			continue
		f.add_child(UI.btn(Data.path_name(pid), func():
			var r: String = Game.econ.tutor(pid)
			main.toast(r if r != "" else "Three days of hard drills in %s." % Data.path_name(pid), "warn" if r != "" else "good")
			main.close_modal(ref[0])))
	v.add_child(f)
	v.add_child(_close_btn(ref))
	ref[0] = main.modal(v, true, 640)


# ===================================================================== NPC ===
func npc(id: String) -> void:
	var n: Dictionary = Game.s.npcs[id]
	var v := UI.vbox(10)
	var ref := [null]
	var arch: Dictionary = Data.archetypes.get(n.arch, {"name": n.arch})
	var head := UI.hbox()
	head.add_child(UI.icon(n.get("icon", "hood"), 64, Data.path_color(n.get("path", "none")).lightened(0.3)))
	var hv := UI.vbox(0)
	hv.add_child(UI.heading(n.name, 26))
	hv.add_child(UI.lbl("%s · Rank %d %s · %s · age %d" % [arch.name, int(n.rank), Data.path_name(n.get("path", "none")), n.get("personality", ""), int(n.get("age", 30))], 14, UI.TEXT_DIM))
	hv.add_child(UI.lbl("%s (%+d) · %s%s" % [Game.world.band(int(n.disp)), int(n.disp), n.relation, " · your rival" if n.get("rival", false) else ""], 14, UI.JADE if int(n.disp) >= 20 else (UI.CRIMSON if int(n.disp) < -20 else UI.TEXT)))
	head.add_child(hv)
	v.add_child(head)
	var line := UI.rich("[i]\"%s\"[/i]" % Game.world.line(n))
	line.custom_minimum_size.x = 560
	v.add_child(line)
	var out := UI.rich("")
	v.add_child(out)
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 6)
	f.add_theme_constant_override("v_separation", 6)
	var acts := [["talk", "Talk", "Build rapport."], ["gift", "Give a gift (%d)" % (10 * int(n.rank)), "Spend stones to raise disposition."],
			["ask_info", "Ask for information", "Needs some trust."], ["ask_help", "Ask for help", "Allies (50+) will lend aid once."],
			["mentor", "Ask to mentor you", "Elders at 50+ disposition."], ["spar", "Spar", "A friendly bout."],
			["challenge", "Challenge to a duel", "A real fight. They will resent it."], ["threaten", "Threaten", "Extort stones. Darkens your name."]]
	for a in acts:
		f.add_child(UI.btn(a[1], func():
			var r: String = Game.world.interact(id, a[0])
			if Game.combat != null:
				main.close_modal(ref[0])
				return
			out.text = r
			main.world.refresh(), a[2]))
	v.add_child(f)
	v.add_child(_close_btn(ref))
	ref[0] = main.modal(v, true, 640)


# ===================================================================== GU ====
func gu_options(gi: Dictionary) -> void:
	var gd: Dictionary = Data.gu[gi.id]
	var v := UI.vbox(10)
	var ref := [null]
	var h := UI.hbox(16)
	h.add_child(UI.gu_card(gd, Game.gu_power(gi), 200, 280))
	var info := UI.vbox(6)
	UI.expand(info)
	info.add_child(UI.heading(gd.name, 24))
	info.add_child(UI.rich("%s · Rank %d · %s · %s" % [UI.path_tag(gd.path), int(gd.rank), gd.rarity, gd.kind]))
	info.add_child(UI.wrap(Data.gu_description(gd, Game.gu_power(gi)), 15))
	var fl := UI.lbl(gd.get("flavor", ""), 14, UI.TEXT_DIM)
	fl.add_theme_font_override("font", UI.font_italic)
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(fl)
	info.add_child(UI.lbl("Upkeep %d stones/week · %s · power ×%.2f%s" % [int(gd.get("feed", 1)), Game.feed_state(gi), Game.gu_power(gi), (" · refined +%d%%" % int(round(float(gi.get("refined", 0)) * 100))) if float(gi.get("refined", 0)) > 0 else ""], 13, UI.TEXT_DIM))
	var acts := HFlowContainer.new()
	acts.add_theme_constant_override("h_separation", 6)
	acts.add_theme_constant_override("v_separation", 6)
	if gd.kind == "consumable" or gd.has("consumable"):
		acts.add_child(UI.btn("Use", func():
			var r: String = Game.use_consumable(int(gi.uid))
			main.toast(r if r != "" else "Used.", "warn" if r != "" and not r.begins_with("You") else "good")
			main.close_modal(ref[0])))
	elif gi.eq:
		acts.add_child(UI.btn("Unequip", func():
			var r: String = Game.equip(int(gi.uid), false)
			if r != "":
				main.toast(r, "warn")
			main.close_modal(ref[0])))
	else:
		var why: String = Game.can_equip(gi)
		var b := UI.btn("Equip", func():
			var r: String = Game.equip(int(gi.uid), true)
			if r != "":
				main.toast(r, "warn")
			main.close_modal(ref[0]))
		if why != "":
			b.disabled = true
			b.tooltip_text = why
		acts.add_child(b)
	var uc: Dictionary = Game.econ.upgrade_cost(gi)
	acts.add_child(UI.btn("Refine further (%d ◈ + %d %s)" % [int(uc.stones), int(uc.n), uc.tier], func():
		var r: String = Game.econ.upgrade_gu(int(gi.uid))
		main.toast(r if r != "" else "Refined: +10% power.", "warn" if r != "" else "good")
		main.close_modal(ref[0]), "+10% power, up to +30%. Takes a day."))
	if Game.econ.market_kinds_here().size() > 0:
		acts.add_child(UI.btn("Sell (%d)" % Game.econ.sell_price_gu(gi), func():
			confirm("Sell %s?" % gd.name, "You will receive %d stones." % Game.econ.sell_price_gu(gi), "Sell", func():
				var r: String = Game.econ.sell_gu(int(gi.uid))
				if r != "":
					main.toast(r, "warn"))
			main.close_modal(ref[0])))
	info.add_child(acts)
	h.add_child(info)
	v.add_child(h)
	v.add_child(_close_btn(ref))
	ref[0] = main.modal(v, true, 680)


# ================================================================== TRAVEL ==
func travel(id: String) -> void:
	var pl: Dictionary = Game.p()
	var l: Dictionary = Data.locations[id]
	var v := UI.vbox(10)
	var ref := [null]
	_title(v, l.name, 26)
	v.add_child(UI.lbl("%s · danger %d · suits Rank %d-%d" % [l.type.capitalize(), int(l.get("danger", 1)), int(l.rank[0]), int(l.rank[1])], 14, UI.TEXT_DIM))
	v.add_child(UI.wrap(l.get("desc", ""), 15))
	if id == pl.location:
		v.add_child(UI.lbl("You are here.", 15, UI.JADE))
	else:
		var plan: Dictionary = Game.travel_plan(id)
		if plan.has("error"):
			v.add_child(UI.lbl(plan.error, 15, UI.CRIMSON))
		else:
			var names := []
			for x in plan.route:
				names.append(Data.locations[x].name)
			v.add_child(UI.wrap("Route: %s" % " → ".join(names), 14, UI.TEXT_DIM))
			v.add_child(UI.lbl("%d days on the road. You keep cultivating slowly and may meet events." % int(plan.days), 15))
			if int(l.get("danger", 1)) > int(pl.rank) * 2:
				v.add_child(UI.lbl("This place is far beyond your strength.", 15, UI.CRIMSON))
			var b := UI.btn("Set out", func():
				var r: String = Game.start_travel(id)
				if r != "":
					main.toast(r, "warn")
				else:
					Game.paused = false
				main.close_modal(ref[0]))
			b.custom_minimum_size = Vector2(200, 42)
			if pl.activity in ["refine", "mission"]:
				b.disabled = true
				b.tooltip_text = "Finish your %s first." % pl.activity
			v.add_child(b)
	v.add_child(_close_btn(ref))
	ref[0] = main.modal(v, true, 560)


func travel_list() -> void:
	var pl: Dictionary = Game.p()
	var v := UI.vbox(8)
	var ref := [null]
	_title(v, "Where to?", 26)
	var rows := []
	for id in pl.known_locs:
		if id == pl.location:
			continue
		var plan: Dictionary = Game.travel_plan(id)
		rows.append([id, plan])
	rows.sort_custom(func(a, b): return int(a[1].get("days", 999)) < int(b[1].get("days", 999)))
	var list := UI.vbox(4)
	for r in rows:
		var l: Dictionary = Data.locations[r[0]]
		var h := UI.hbox()
		var nl := UI.lbl("%s  (%s, danger %d)" % [l.name, l.type, int(l.get("danger", 1))], 15, UI.TEXT if not r[1].has("error") else UI.TEXT_DIM)
		UI.expand(nl)
		h.add_child(nl)
		if r[1].has("error"):
			h.add_child(UI.lbl(r[1].error, 13, UI.CRIMSON))
		else:
			var id: String = r[0]
			h.add_child(UI.btn("%d days" % int(r[1].days), func():
				main.close_modal(ref[0])
				travel(id)))
		list.add_child(h)
	v.add_child(UI.scroll(list, 420))
	v.add_child(_close_btn(ref))
	ref[0] = main.modal(v, true, 600)


# =================================================================== GOALS ==
func add_goal(gt: Dictionary) -> void:
	var v := UI.vbox(10)
	var ref := [null]
	_title(v, "New goal", 24)
	var pl: Dictionary = Game.p()
	var add := func(params: Dictionary):
		var r: String = Game.world.add_goal(gt.id, params, Game.s.goals.filter(func(g): return not g.done).is_empty())
		if r != "":
			main.toast(r, "warn")
		main.close_modal(ref[0])
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 6)
	f.add_theme_constant_override("v_separation", 6)
	match str(gt.id):
		"seek_path_gu", "path_training":
			v.add_child(UI.lbl("Which path?", 15))
			for path in Data.path_list:
				var pid: String = path.id if path is Dictionary else str(path)
				if pid == "none":
					continue
				f.add_child(UI.btn(Data.path_name(pid), func(): add.call({"path": pid})))
		"seek_type_gu":
			v.add_child(UI.lbl("What kind of Gu?", 15))
			var kinds := {}
			for g in Data.gu_list:
				kinds[str(g.kind)] = true
			for k in kinds.keys():
				if k == "consumable":
					continue
				f.add_child(UI.btn(k.capitalize(), func(): add.call({"kind": k})))
		"prepare":
			for e in Game.world.upcoming_epochs():
				f.add_child(UI.btn(e.name, func(): add.call({"event": e.name, "n": mini(5, int(pl.rank) + 1)})))
		_:
			v.add_child(UI.wrap(gt.desc.format({"n": "a set number of", "path": "", "kind": "", "event": ""}), 15))
			f.add_child(UI.btn("Pursue this goal", func(): add.call({})))
	v.add_child(f)
	v.add_child(_close_btn(ref, "Cancel"))
	ref[0] = main.modal(v, true, 560)


# ====================================================== BREAKTHROUGH CHOICES ==
func specialize() -> void:
	var v := UI.vbox(10)
	var ref := [null]
	_title(v, "Choose a Specialization", 26)
	v.add_child(UI.wrap("Before Rank 5, a Gu Master commits to one path. It earns +50 attainment and shapes your immortal tribulation.", 15))
	var pl: Dictionary = Game.p()
	var keys: Array = pl.attain.keys().filter(func(k): return k != "none")
	keys.sort_custom(func(a, b): return float(pl.attain[a]) > float(pl.attain[b]))
	var f := HFlowContainer.new()
	for path in keys:
		f.add_child(UI.btn("%s %s (%d)" % [Data.path_symbol(path), Data.path_name(path), int(pl.attain[path])], func():
			Game.choose_specialization(path)
			main.close_modal(ref[0])
			if main.world:
				main.world._breakthrough()))
	v.add_child(f)
	v.add_child(_close_btn(ref, "Not yet"))
	ref[0] = main.modal(v, true, 620)


func tribulation() -> void:
	var pl: Dictionary = Game.p()
	var t = pl.get("trib", {})
	if not (t is Dictionary) or str(t.get("stage", "")) != "prepare":
		return
	for m in main.modals:
		if is_instance_valid(m) and m.get_meta("trib", false):
			return
	var v := UI.vbox(10)
	var ref := [null]
	_title(v, "The Immortal Tribulation", 30)
	var f: Dictionary = Game.immortal.ascension_factors()
	v.add_child(UI.wrap("Three calamities test a Rank 5 Peak Gu Master. Survive two of the three, including heaven's, to ascend as a Gu Immortal. Fail, and your aperture shatters.", 15))
	v.add_child(UI.rich("[b]Heaven:[/b] %s" % f.heaven))
	var offer_lbl := UI.rich("")
	v.add_child(offer_lbl)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = maxi(0, int(pl.stones))
	slider.step = 10
	slider.value = mini(int(pl.stones), 400)
	v.add_child(slider)
	var upd := func(_x = 0):
		offer_lbl.text = "[b]Earth:[/b] offer %d stones to the land: %d%% chance it accepts you." % [int(slider.value), int(Game.immortal.earth_chance(int(slider.value)) * 100)]
	slider.value_changed.connect(upd)
	upd.call()
	v.add_child(UI.rich("[b]Human:[/b] %d allies (disposition 50+) · %d%% chance others stand with you." % [int(f.allies), int(f.human_chance * 100)]))
	var b := UI.btn("Face the Tribulation", func():
		var r: String = Game.immortal.start_heaven(int(slider.value))
		if r != "":
			main.toast(r, "warn")
			return
		main.close_modal(ref[0]))
	b.custom_minimum_size = Vector2(260, 48)
	b.add_theme_font_override("font", UI.font_head_bold)
	v.add_child(b)
	v.add_child(UI.lbl("There is no fleeing heaven's lightning.", 13, UI.TEXT_DIM))
	ref[0] = main.modal(v, false, 620)
	ref[0].set_meta("trib", true)
	ref[0].set_meta("bot_close", true)
	Sfx.play("thunder")


# ============================================================= PAUSE MENU ==
func pause_menu() -> void:
	var v := UI.vbox(8)
	var ref := [null]
	_title(v, "Paused", 28)
	Game.paused = true
	var add := func(text: String, cb: Callable):
		var b := UI.btn(text, cb)
		b.custom_minimum_size = Vector2(320, 42)
		v.add_child(b)
	add.call("Resume", func(): main.close_modal(ref[0]))
	for n in [1, 2, 3]:
		add.call("Save to slot %d" % n, func():
			Game.slot = n
			var r: String = Game.save_game(n)
			main.toast(r if r != "" else "Saved to slot %d." % n, "warn" if r != "" else "good")
			main.close_modal(ref[0]))
	add.call("Settings", func(): settings())
	add.call("Records", func(): records())
	add.call("How to play", func(): tutorial())
	add.call("Retire (end this life)", func():
		confirm("Retire?", "This life ends now and you earn inheritance points for it.", "Retire", func():
			main.close_modal(ref[0])
			Game.retire()))
	add.call("Save and return to title", func():
		Game.save_game()
		main.show_menu())
	add.call("Save and quit", func():
		Game.save_game()
		main.get_tree().quit())
	ref[0] = main.modal(v, true, 380)


func load_dialog() -> void:
	var v := UI.vbox(8)
	var ref := [null]
	_title(v, "Load a life", 26)
	for s in Game.list_saves():
		var h := UI.hbox()
		var l := UI.lbl("%s · %s · %s Rank %d · %s%s" % ["Autosave" if int(s.slot) == 0 else "Slot %d" % int(s.slot), s.name,
				Data.clans.get(s.clan, {"name": s.clan}).name, int(s.rank), s.date, "  (%s)" % s.mode if s.mode != "normal" else ""], 15)
		UI.expand(l)
		h.add_child(l)
		var slot := int(s.slot)
		h.add_child(UI.btn("Load", func():
			var r: String = Game.load_game(slot)
			if r != "":
				main.toast(r, "bad")
				return
			main.close_modal(ref[0])
			main.show_world()))
		h.add_child(UI.btn("Delete", func():
			confirm("Delete this save?", "This cannot be undone.", "Delete", func():
				Game.delete_save(slot)
				main.close_modal(ref[0])
				main.show_menu())))
		v.add_child(h)
	v.add_child(_close_btn(ref))
	ref[0] = main.modal(v, true, 720)


# =============================================================== SETTINGS ==
func settings() -> void:
	var v := UI.vbox(10)
	var ref := [null]
	_title(v, "Settings", 28)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	var slider := func(label: String, key: String):
		grid.add_child(UI.lbl(label, 15))
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = float(Meta.setting(key, 0.7))
		s.custom_minimum_size.x = 300
		s.value_changed.connect(func(x):
			Meta.set_setting(key, x)
			Sfx.refresh_volume()
			if key == "sfx":
				Sfx.play("click"))
		grid.add_child(s)
	slider.call("Music volume", "music")
	slider.call("Effects volume", "sfx")
	var check := func(label: String, getter: Callable, setter: Callable, tip := ""):
		grid.add_child(UI.lbl(label, 15))
		var c := CheckBox.new()
		c.button_pressed = getter.call()
		c.tooltip_text = tip
		c.focus_mode = Control.FOCUS_NONE
		c.toggled.connect(func(on): setter.call(on))
		grid.add_child(c)
	check.call("Fullscreen (F11)", func(): return bool(Meta.setting("fullscreen", false)), func(on):
		Meta.set_setting("fullscreen", on)
		main._apply_window_settings())
	var ap: Dictionary = Meta.setting("autopause", {})
	for k in [["travel", "Pause when you arrive somewhere"], ["breakthrough", "Pause when your aperture is full"], ["mission", "Pause when a mission ends"]]:
		check.call(k[1], func(): return bool(ap.get(k[0], true)), func(on):
			ap[k[0]] = on
			Meta.set_setting("autopause", ap))
	check.call("Show the how-to-play guide on new lives", func(): return bool(Meta.setting("tutorial", true)), func(on): Meta.set_setting("tutorial", on))
	check.call("Sandbox: unlock all clans, starts and modes", func(): return Meta.sandbox(), func(on): Meta.set_setting("sandbox", on),
			"For trying everything at once. Legacies cost nothing while it is on.")
	v.add_child(HSeparator.new())
	v.add_child(UI.lbl("Live AI writing (optional)", 18, UI.GOLD, true))
	v.add_child(UI.wrap("The game is complete offline. With your own Anthropic API key, Claude also writes fresh NPC lines, event openings and names for newly discovered Gu. Rules and numbers never change. The key is stored only on this computer in your user folder.", 14, UI.TEXT_DIM))
	var kh := UI.hbox()
	var key := LineEdit.new()
	key.secret = true
	key.placeholder_text = "sk-ant-..."
	key.text = str(Meta.setting("api_key", ""))
	UI.expand(key)
	key.text_changed.connect(func(t): Meta.set_setting("api_key", t.strip_edges()))
	kh.add_child(UI.lbl("API key", 15))
	kh.add_child(key)
	v.add_child(kh)
	var mh := UI.hbox()
	mh.add_child(UI.lbl("Model", 15))
	var model := LineEdit.new()
	model.text = str(Meta.setting("model", "claude-opus-5-5"))
	UI.expand(model)
	model.text_changed.connect(func(t): Meta.set_setting("model", t.strip_edges()))
	mh.add_child(model)
	var en := CheckBox.new()
	en.text = "Enabled"
	en.button_pressed = bool(Meta.setting("ai_enabled", true))
	en.toggled.connect(func(on): Meta.set_setting("ai_enabled", on))
	mh.add_child(en)
	v.add_child(mh)
	var status := UI.lbl(AIGen.last_status, 14, UI.TEXT_DIM)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(status)
	var cb := func(t):
		if is_instance_valid(status):
			status.text = t
	AIGen.status_changed.connect(cb)
	var ah := UI.hbox()
	ah.add_child(UI.btn("Test connection", func():
		status.text = "Contacting the Claude API…"
		AIGen.test_connection()))
	ah.add_child(UI.btn("Clear generated text", func():
		AIGen.clear_cache()
		status.text = "Cache cleared."))
	v.add_child(ah)
	v.add_child(HSeparator.new())
	var foot := UI.hbox()
	foot.add_child(UI.btn("Reset all progress…", func():
		confirm("Reset everything?", "Deletes inheritance points, unlocks, records and settings. Saves are kept.", "Reset", func():
			var keep_key = Meta.setting("api_key", "")
			Meta.d = Meta.defaults()
			Meta.d.settings.api_key = keep_key
			Meta.save_meta()
			main.close_modal(ref[0])
			if not Game.has_run():
				main.show_menu())))
	foot.add_child(UI.expand(UI.spacer()))
	foot.add_child(UI.btn("Done", func():
		if AIGen.status_changed.is_connected(cb):
			AIGen.status_changed.disconnect(cb)
		main.close_modal(ref[0])
		if not Game.has_run() and main.current and main.current.get_script() == main.MenuScreen:
			main.show_menu()))
	v.add_child(foot)
	ref[0] = main.modal(v, false, 720)


# ================================================================== VAULT ===
func vault(on_close: Callable = Callable()) -> void:
	var v := UI.vbox(10)
	var ref := [null]
	_title(v, "Legacy Vault", 28)
	var pts := UI.lbl("", 18, UI.AMBER)
	v.add_child(pts)
	v.add_child(UI.wrap("Each life earns inheritance points. Spend them on up to %d legacies that the next life begins with. Unspent points carry over; you can refund a legacy before you begin." % Meta.MAX_LEGACY, 14, UI.TEXT_DIM))
	var pend := UI.vbox(4)
	v.add_child(pend)
	var list := UI.vbox(4)
	v.add_child(UI.scroll(list, 380))
	var rebuild := [null]
	rebuild[0] = func():
		pts.text = "%s points%s" % [UI.num(Meta.d.points), "  (sandbox: free)" if Meta.sandbox() else ""]
		UI.clear(pend)
		pend.add_child(UI.lbl("Chosen for the next life (%d / %d)" % [Meta.d.pending.size(), Meta.MAX_LEGACY], 16, UI.GOLD, true))
		for i in Meta.d.pending.size():
			var d: Dictionary = Meta.inheritance_def(Meta.d.pending[i])
			var h := UI.hbox()
			var l := UI.lbl("• %s" % d.get("name", "?"), 15, UI.JADE)
			UI.expand(l)
			h.add_child(l)
			var idx = i
			h.add_child(UI.btn("Refund", func():
				Meta.refund(idx)
				rebuild[0].call()))
			pend.add_child(h)
		UI.clear(list)
		for d in Data.inheritance:
			var h2 := UI.hbox()
			var tv := UI.vbox(0)
			UI.expand(tv)
			tv.add_child(UI.lbl("%s  —  %d points" % [d.name, int(d.cost)], 15, UI.TEXT, true))
			tv.add_child(UI.wrap(d.desc, 13, UI.TEXT_DIM))
			h2.add_child(tv)
			var why: String = Meta.can_buy(d.id)
			var b := UI.btn("Choose", func():
				var r: String = Meta.buy(d.id)
				if r != "":
					main.toast(r, "warn")
				else:
					Sfx.play("coin")
				rebuild[0].call())
			if why != "":
				b.disabled = true
				b.tooltip_text = why
			h2.add_child(b)
			list.add_child(h2)
	rebuild[0].call()
	v.add_child(UI.btn("Done", func():
		main.close_modal(ref[0])
		if on_close.is_valid():
			on_close.call()
		elif not Game.has_run() and main.current and main.current.get_script() == main.MenuScreen:
			main.show_menu()))
	ref[0] = main.modal(v, false, 720)


# ================================================================ RECORDS ===
func records() -> void:
	var v := UI.vbox(10)
	var ref := [null]
	_title(v, "Records", 28)
	var st: Dictionary = Meta.d.stats
	var t := "[b]Lives:[/b] %d   [b]Venerables:[/b] %d   [b]Best rank:[/b] %d   [b]Days lived:[/b] %s   [b]Best score:[/b] %s\n" % [int(st.runs), int(st.victories), int(st.best_rank), UI.num(st.total_days), UI.num(st.best_points)]
	var deaths := []
	for k in st.deaths.keys():
		deaths.append("%s %d" % [k, int(st.deaths[k])])
	if deaths.size() > 0:
		t += "[b]Endings:[/b] %s\n" % ", ".join(deaths)
	var best := []
	for k in st.clan_best.keys():
		if Data.clans.has(k):
			best.append("%s R%d" % [Data.clans[k].name, int(st.clan_best[k])])
	if best.size() > 0:
		t += "[b]Best by clan:[/b] %s\n" % ", ".join(best)
	t += "\n[b][color=#%s]Achievements[/color][/b]\n" % UI.hex(UI.GOLD)
	for aid in Data.achievements.keys():
		var a: Dictionary = Data.achievements[aid]
		var got: bool = Meta.d.achievements.has(aid)
		t += "%s %s — %s\n" % [UI.col("✓", UI.JADE) if got else UI.col("·", UI.TEXT_DIM), UI.col(a.name, UI.TEXT if got else UI.TEXT_DIM), UI.col(a.desc, UI.TEXT_DIM)]
	t += "\n[b][color=#%s]Past lives[/color][/b]\n" % UI.hex(UI.GOLD)
	var hist: Array = st.history.duplicate()
	hist.reverse()
	for h in hist:
		t += "%s of the %s · Rank %d · age %d · %s · %d pts\n" % [h.name, Data.clans.get(h.clan, {"name": h.clan}).name, int(h.rank), int(h.age), h.cause, int(h.points)]
	if hist.is_empty():
		t += UI.col("None yet.", UI.TEXT_DIM)
	var r := UI.rich(t)
	v.add_child(UI.scroll(r, 480))
	v.add_child(_close_btn(ref))
	ref[0] = main.modal(v, true, 760)


# ================================================================ CREDITS ===
const CREDITS_TEXT := """[b]Reverend Insanity: Path of the Gu Master[/b] — a fan-made MVP inspired by the web novel [i]Reverend Insanity[/i] by Gu Zhen Ren. Not affiliated with or endorsed by the author or publishers.

[b]Design, code and procedural audio[/b]: built with Claude (Anthropic) on Godot Engine 4.5 (MIT licence, godotengine.org).

[b]Icons[/b]: game-icons.net, by Lorc, Delapouite, Skoll, sbed, Faithtoken, Willdabeast, Carl Olsen, Cathelineau, DarkZaitzev, Lord Berandas, Viscious Speed, Zeromancer, Quoting and other contributors. Licensed CC BY 3.0 (creativecommons.org/licenses/by/3.0). Recoloured in game.

[b]Fonts[/b]: Cinzel by Natanael Gama; Noto Serif, Noto Sans Symbols, Noto Sans Symbols 2 and Noto Emoji by Google. All under the SIL Open Font License 1.1.

[b]Music and sound effects[/b]: synthesized from scratch by tools/gen_assets.py in this repository (no samples), released with the game.

[b]Backgrounds and map[/b]: drawn procedurally by shaders and code at runtime. No AI-generated images are used anywhere.

Full licence texts are in CREDITS.md and assets/fonts/*-LICENSE.txt."""


func credits() -> void:
	var v := UI.vbox(10)
	var ref := [null]
	_title(v, "Credits", 28)
	var r := UI.rich(CREDITS_TEXT)
	r.custom_minimum_size.x = 660
	v.add_child(r)
	v.add_child(_close_btn(ref))
	ref[0] = main.modal(v, true, 720)


# =============================================================== TUTORIAL ===
const GUIDE := [
	["Your life", "You are a young Gu Master with a lifespan of about a hundred years. Cultivate, survive and climb from Rank 1 toward Rank 9 Venerable before age or a blade ends you. Death is permanent, but every life earns inheritance points for the next."],
	["Time", "Time flows on its own. Space pauses, 1/2/3 change speed. Events, battles and full apertures pause automatically. Closed-door cultivation makes years pass quickly."],
	["Cultivation", "Choose Cultivate on the Cultivate tab and pick an intensity: higher intensity is faster but burns primeval stones every day. When the aperture is full, attempt a breakthrough (B). Rank breakthroughs above Rank 2 first summon a heart demon to fight."],
	["Gu and upkeep", "Your equipped Gu are your combat deck. Every Gu must be fed stones each week or it starves and dies. Earn stones from your clan stipend, missions, hunting, events and selling materials."],
	["Combat", "Click an enemy to target it and click cards to activate Gu. Essence pays for cards and refills a little each turn. Your attainment in each path limits how many of its Gu you can use per turn. Killer moves combine several Gu into one devastating technique."],
	["The world", "Click places on the map to travel. Markets sell Gu and materials, refineries turn formulas into new Gu, and your clan hall offers missions that raise your standing. Set goals to steer what you find."],
	["Immortality", "At Rank 5 Peak you face three tribulations. Survive them to become a Gu Immortal with your own blessed land, then gather dao marks to rise through Rank 7 and 8 and finally face the Venerable tribulation."],
]


func tutorial() -> void:
	var v := UI.vbox(10)
	var ref := [null]
	var page := [0]
	var title := UI.heading("", 26)
	var body := UI.wrap("", 16)
	body.custom_minimum_size = Vector2(600, 130)
	var count := UI.lbl("", 13, UI.TEXT_DIM)
	var show := func():
		title.text = GUIDE[page[0]][0]
		body.text = GUIDE[page[0]][1]
		count.text = "%d / %d" % [page[0] + 1, GUIDE.size()]
	v.add_child(title)
	v.add_child(HSeparator.new())
	v.add_child(body)
	var h := UI.hbox()
	h.add_child(count)
	h.add_child(UI.expand(UI.spacer()))
	h.add_child(UI.btn("Back", func():
		page[0] = maxi(0, page[0] - 1)
		show.call()))
	h.add_child(UI.btn("Next", func():
		if page[0] >= GUIDE.size() - 1:
			main.close_modal(ref[0])
			return
		page[0] += 1
		show.call()))
	h.add_child(UI.btn("Close", func(): main.close_modal(ref[0])))
	v.add_child(h)
	show.call()
	ref[0] = main.modal(v, true, 660)
	ref[0].set_meta("bot_close", true)


# ============================================================ LIFE SUMMARY ==
func life_summary(sm: Dictionary) -> void:
	var v := UI.vbox(10)
	var ref := [null]
	var victory: bool = sm.get("victory", false)
	var t := UI.heading("Venerable!" if victory else ("Retired" if sm.cause == "retired" else "Your life has ended"), 36)
	t.add_theme_color_override("font_color", UI.GOLD if victory else UI.TEXT)
	v.add_child(t)
	v.add_child(UI.wrap(str(sm.text), 17))
	v.add_child(HSeparator.new())
	var clan: String = Data.clans.get(sm.clan, {"name": sm.clan}).name
	var body := "[b]%s[/b] of the %s · reached Rank %d · lived to %d (%d years as a cultivator)\n" % [sm.name, clan, int(sm.max_rank), int(sm.age), int(sm.days) / Data.YEAR]
	var stt: Dictionary = sm.stats
	body += "Battles won %d of %d · bosses %d · events %d · Gu refined %d · killer moves %d\n\n" % [int(stt.wins), int(stt.battles), int(stt.bosses), int(stt.events), int(stt.gu_refined), int(stt.killers)]
	body += "[font_size=22][color=#%s]+%s inheritance points[/color][/font_size]   (vault now holds %s)\n" % [UI.hex(UI.AMBER), UI.num(sm.points), UI.num(Meta.d.points)]
	if sm.achieved.size() > 0:
		var names := []
		for a in sm.achieved:
			names.append(Data.achievements.get(a, {"name": a}).name)
		body += "\nAchievements this life: %s" % ", ".join(names)
	var r := UI.rich(body)
	r.custom_minimum_size.x = 640
	v.add_child(r)
	var h := UI.hbox()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(UI.btn("Spend points in the vault", func(): vault(func(): pass)))
	h.add_child(UI.btn("Begin a new life", func():
		main.close_modal(ref[0])
		main.show_new_game()))
	h.add_child(UI.btn("Return to title", func():
		main.close_modal(ref[0])
		main.show_menu()))
	v.add_child(h)
	ref[0] = main.modal(v, false, 720)
	Sfx.play("victory" if victory else "defeat")
	Sfx.music("menu")
