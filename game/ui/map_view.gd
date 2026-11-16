extends Control
## The world map, drawn in code as an ink sketch: brush-stroke routes, location seals and the
## traveller's marker. Hover shows details, click asks to travel.

signal location_clicked(id)

const MAP_W := 1040.0
const MAP_H := 640.0
const TYPE_COLORS := {
	"village": Color("63b392"), "city": Color("e0b45c"), "wild": Color("8fa060"), "danger": Color("c4473f"),
	"blessed": Color("a47ad6"), "region": Color("6fa8dc"),
}
const TYPE_ICONS := {"village": "huts-village", "city": "castle", "wild": "pine-tree", "danger": "death-skull", "blessed": "lotus", "region": "mountains"}

var hover := ""
var t := 0.0
var _icons := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _process(delta: float) -> void:
	t += delta
	if is_visible_in_tree():
		queue_redraw()


func _xf() -> Array:
	var pad := 50.0
	var sc := minf((size.x - pad * 2) / MAP_W, (size.y - pad * 2) / MAP_H)
	var off := (size - Vector2(MAP_W, MAP_H) * sc) / 2.0
	return [sc, off]


func pos_of(id: String) -> Vector2:
	var l: Dictionary = Data.locations[id]
	var x := _xf()
	return x[1] + Vector2(float(l.x) + 30.0, float(l.y) + 30.0) * x[0]


func _visible_locs() -> Array:
	if not Game.has_run():
		return []
	var pl: Dictionary = Game.p()
	var out := []
	for l in Data.locations.values():
		if l.id in pl.known_locs or l.id == pl.location:
			out.append(l.id)
	return out


func _icon(name: String) -> Texture2D:
	if not _icons.has(name):
		_icons[name] = Data.icon(name)
	return _icons[name]


func _draw() -> void:
	if not Game.has_run():
		return
	var pl: Dictionary = Game.p()
	var vis := _visible_locs()
	var sc: float = _xf()[0]
	# parchment sheet
	var r := Rect2(Vector2(14, 14), size - Vector2(28, 28))
	draw_rect(r, Color(0.16, 0.13, 0.10, 0.55))
	draw_rect(r, Color(UI.GOLD_DIM, 0.8), false, 2.0)
	draw_rect(r.grow(-6), Color(UI.GOLD_DIM, 0.35), false, 1.0)
	var font: Font = UI.font_head_bold
	draw_string(font, Vector2(34, 46), "THE SOUTHERN BORDER", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(UI.GOLD, 0.6))
	# routes
	var route_now: Array = pl.act.get("route", []) if pl.activity == "travel" else []
	for rt in Data.routes:
		if not (rt.a in vis and rt.b in vis):
			continue
		var a := pos_of(rt.a)
		var b := pos_of(rt.b)
		var on_route := false
		for i in range(route_now.size() - 1):
			if (route_now[i] == rt.a and route_now[i + 1] == rt.b) or (route_now[i] == rt.b and route_now[i + 1] == rt.a):
				on_route = true
		_brush_line(a, b, Color(UI.GOLD, 0.85) if on_route else Color(0.75, 0.66, 0.5, 0.35), 3.0 if on_route else 2.0, hash(rt.a + rt.b))
		var mid := (a + b) / 2.0
		draw_string(UI.font_body, mid + Vector2(-8, -4), "%dd" % int(rt.days), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(UI.TEXT_DIM, 0.7))
	# locations
	for id in vis:
		var l: Dictionary = Data.locations[id]
		var p := pos_of(id)
		var col: Color = TYPE_COLORS.get(l.type, UI.TEXT)
		var rad := 22.0 * clampf(sc * 1.1, 0.8, 1.3)
		var visited: bool = id in pl.visited
		var danger := int(l.get("danger", 1)) > int(pl.rank) * 2
		if id == hover:
			rad *= 1.15
		draw_circle(p + Vector2(2, 3), rad, Color(0, 0, 0, 0.45))
		draw_circle(p, rad, Color("1b1611"))
		draw_arc(p, rad, 0, TAU, 40, col if visited else Color(col, 0.55), 2.5, true)
		var ic := _icon(l.get("icon", TYPE_ICONS.get(l.type, "circle")))
		if ic == null or ic.get_width() <= 1:
			ic = _icon(TYPE_ICONS.get(l.type, "circle"))
		if ic:
			var s := rad * 1.25
			draw_texture_rect(ic, Rect2(p - Vector2(s, s) / 2.0, Vector2(s, s)), false, col.lightened(0.2) if visited else Color(col, 0.6))
		if id == pl.location and pl.activity != "travel":
			var pulse := 0.5 + 0.5 * sin(t * 3.0)
			draw_arc(p, rad + 6 + pulse * 4, 0, TAU, 48, Color(UI.GOLD, 0.9 - pulse * 0.5), 2.0, true)
		if danger:
			draw_string(UI.font_bold, p + Vector2(rad * 0.6, -rad * 0.6), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UI.CRIMSON)
		var name_col := UI.TEXT if visited else UI.TEXT_DIM
		var w := font.get_string_size(l.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(font, p + Vector2(-w / 2.0 + 1, rad + 19), l.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0, 0.7))
		draw_string(font, p + Vector2(-w / 2.0, rad + 18), l.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, name_col)
		if l.get("clan", "") == pl.clan:
			draw_string(UI.font_body, p + Vector2(-w / 2.0, rad + 34), "your clan", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.JADE)
	# traveller
	if pl.activity == "travel" and route_now.size() >= 2:
		var prog: float = Game.travel_progress()
		var pts := []
		for id in route_now:
			pts.append(pos_of(id))
		var total := 0.0
		for i in range(pts.size() - 1):
			total += pts[i].distance_to(pts[i + 1])
		var want := total * prog
		var at: Vector2 = pts[0]
		for i in range(pts.size() - 1):
			var seg: float = pts[i].distance_to(pts[i + 1])
			if want <= seg:
				at = pts[i].lerp(pts[i + 1], want / maxf(1.0, seg))
				break
			want -= seg
			at = pts[i + 1]
		draw_circle(at, 9, UI.GOLD)
		draw_circle(at, 5, UI.INK)
		draw_arc(at, 14 + 3 * sin(t * 4.0), 0, TAU, 32, Color(UI.GOLD, 0.6), 2.0, true)
	# legend
	var ly := size.y - 40
	var lx := 34.0
	for k in ["village", "city", "wild", "danger", "blessed", "region"]:
		draw_circle(Vector2(lx, ly), 6, TYPE_COLORS[k])
		draw_string(UI.font_body, Vector2(lx + 10, ly + 5), k.capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.TEXT_DIM)
		lx += 86


func _brush_line(a: Vector2, b: Vector2, c: Color, w: float, seed_v: int) -> void:
	## A slightly wobbly dashed stroke, like a brush route on a scroll map.
	var n := int(a.distance_to(b) / 14.0) + 2
	var dir := (b - a).normalized()
	var nrm := Vector2(-dir.y, dir.x)
	var prev := a
	for i in range(1, n + 1):
		var f := float(i) / n
		var wob := sin(f * PI * 3.0 + seed_v % 7) * 4.0 * sin(f * PI)
		var pt := a.lerp(b, f) + nrm * wob
		if i % 2 == 1:
			draw_line(prev, pt, c, w, true)
		prev = pt


func _loc_at(pos: Vector2) -> String:
	var best := ""
	var bd := 34.0
	for id in _visible_locs():
		var d := pos.distance_to(pos_of(id))
		if d < bd:
			bd = d
			best = id
	return best


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var h := _loc_at(ev.position)
		if h != hover:
			hover = h
			tooltip_text = _tip(h) if h != "" else ""
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if h != "" else Control.CURSOR_ARROW
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var id := _loc_at(ev.position)
		if id != "":
			Sfx.play("click")
			location_clicked.emit(id)


func _tip(id: String) -> String:
	var l: Dictionary = Data.locations[id]
	var pl: Dictionary = Game.p()
	var s := "%s  (%s)\n%s\nDanger %d · Suits Rank %d-%d" % [l.name, l.type.capitalize(), l.get("desc", ""), int(l.get("danger", 1)), int(l.rank[0]), int(l.rank[1])]
	var sv: Array = l.get("services", [])
	if sv.size() > 0:
		s += "\nServices: " + ", ".join(sv.map(func(x): return str(x).replace("_", " ")))
	if id == pl.location:
		s += "\nYou are here."
	else:
		var plan: Dictionary = Game.travel_plan(id)
		s += "\n" + (plan.error if plan.has("error") else "Travel: %d days. Click to set out." % int(plan.days))
	return s
