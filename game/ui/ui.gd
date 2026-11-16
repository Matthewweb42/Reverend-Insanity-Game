class_name UI
extends RefCounted
## Shared look and small widget builders. Everything in the interface is built in code from these,
## so the whole game shares one ink-and-parchment style.

const INK := Color("120f0d")
const PANEL := Color("1d1814")
const PANEL_2 := Color("2a221b")
const PANEL_3 := Color("3a2f24")
const GOLD := Color("c9a465")
const GOLD_DIM := Color("7d6643")
const TEXT := Color("ecdfc6")
const TEXT_DIM := Color("a8977b")
const JADE := Color("63b392")
const CRIMSON := Color("c4473f")
const AMBER := Color("e0a43c")
const SKY := Color("6fa8dc")
const VIOLET := Color("a47ad6")

const LOG_COLORS := {
	"head": GOLD, "great": Color("f2d16b"), "good": JADE, "bad": CRIMSON, "warn": AMBER, "info": TEXT,
	"player": Color("cfe3d6"), "enemy": Color("e6b7a6"), "killer": Color("ffcf5a"), "env": SKY, "dim": TEXT_DIM,
}
const RARITY_COLORS := {"common": Color("b9ad98"), "uncommon": Color("6fbf73"), "rare": Color("5aa6e8"), "legendary": Color("e8a33c")}

static var theme_obj: Theme
static var font_body: FontFile
static var font_bold: FontFile
static var font_italic: FontFile
static var font_head: FontFile
static var font_head_bold: FontFile


static func _font(path: String, fallbacks: Array) -> FontFile:
	var f: FontFile = load(path)
	if f == null:
		return null
	var ff: Array[Font] = []
	for x in fallbacks:
		if x != null:
			ff.append(x)
	f.fallbacks = ff
	return f


static func make_theme() -> Theme:
	if theme_obj != null:
		return theme_obj
	var sym1: FontFile = load("res://assets/fonts/noto-sans-symbols-symbols-400-normal.woff2")
	var sym2: FontFile = load("res://assets/fonts/noto-sans-symbols-2-symbols-400-normal.woff2")
	var math: FontFile = load("res://assets/fonts/noto-sans-symbols-2-math-400-normal.woff2")
	var emo: FontFile = load("res://assets/fonts/noto-emoji-fist.woff2")
	var fb := [sym1, sym2, math, emo]
	font_body = _font("res://assets/fonts/noto-serif-latin-400-normal.woff2", fb)
	font_bold = _font("res://assets/fonts/noto-serif-latin-700-normal.woff2", fb)
	font_italic = _font("res://assets/fonts/noto-serif-latin-400-italic.woff2", fb)
	font_head = _font("res://assets/fonts/cinzel-latin-400-normal.woff2", [font_body] + fb)
	font_head_bold = _font("res://assets/fonts/cinzel-latin-700-normal.woff2", [font_bold] + fb)
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = 17
	# Panels
	t.set_stylebox("panel", "Panel", box(PANEL, GOLD_DIM, 1, 6))
	t.set_stylebox("panel", "PanelContainer", box(PANEL, GOLD_DIM, 1, 6, 10))
	t.set_stylebox("panel", "PopupPanel", box(PANEL_2, GOLD, 2, 8, 12))
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.09, 0.075, 0.06, 0.97), GOLD, 1, 4, 8))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font("font", "TooltipLabel", font_body)
	t.set_font_size("font_size", "TooltipLabel", 15)
	# Labels
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font("normal_font", "RichTextLabel", font_body)
	t.set_font("bold_font", "RichTextLabel", font_bold)
	t.set_font("italics_font", "RichTextLabel", font_italic)
	t.set_font_size("normal_font_size", "RichTextLabel", 16)
	t.set_font_size("bold_font_size", "RichTextLabel", 16)
	t.set_font_size("italics_font_size", "RichTextLabel", 16)
	# Buttons
	t.set_stylebox("normal", "Button", box(PANEL_2, GOLD_DIM, 1, 5, 8, 5))
	t.set_stylebox("hover", "Button", box(PANEL_3, GOLD, 1, 5, 8, 5))
	t.set_stylebox("pressed", "Button", box(Color("4a3a28"), GOLD, 2, 5, 8, 5))
	t.set_stylebox("disabled", "Button", box(Color("1a1612"), Color("3a3127"), 1, 5, 8, 5))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), Color(GOLD, 0.5), 1, 5, 8, 5))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color("fff3d6"))
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color("6b5f4f"))
	t.set_font("font", "Button", font_body)
	t.set_font_size("font_size", "Button", 16)
	for k in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(k, "OptionButton", t.get_stylebox(k, "Button"))
		t.set_stylebox(k, "CheckBox", box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 4, 4, 2))
	t.set_color("font_color", "OptionButton", TEXT)
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_hover_color", "CheckBox", Color("fff3d6"))
	t.set_stylebox("panel", "PopupMenu", box(PANEL_2, GOLD, 1, 4, 6))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", GOLD)
	t.set_stylebox("hover", "PopupMenu", box(PANEL_3, Color(0, 0, 0, 0), 0, 3))
	# Inputs
	t.set_stylebox("normal", "LineEdit", box(Color("15110e"), GOLD_DIM, 1, 4, 8, 6))
	t.set_stylebox("focus", "LineEdit", box(Color("15110e"), GOLD, 1, 4, 8, 6))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", GOLD)
	# Progress
	t.set_stylebox("background", "ProgressBar", box(Color("100d0b"), GOLD_DIM, 1, 4))
	t.set_stylebox("fill", "ProgressBar", box(JADE, Color(0, 0, 0, 0), 0, 4))
	t.set_color("font_color", "ProgressBar", TEXT)
	t.set_font_size("font_size", "ProgressBar", 13)
	# Sliders
	t.set_stylebox("slider", "HSlider", box(Color("100d0b"), GOLD_DIM, 1, 3, 0, 3))
	t.set_stylebox("grabber_area", "HSlider", box(GOLD_DIM, Color(0, 0, 0, 0), 0, 3, 0, 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(GOLD, Color(0, 0, 0, 0), 0, 3, 0, 3))
	# Tabs
	t.set_stylebox("tab_selected", "TabContainer", box(PANEL_3, GOLD, 1, 5, 10, 5))
	t.set_stylebox("tab_unselected", "TabContainer", box(PANEL, GOLD_DIM, 1, 5, 10, 5))
	t.set_stylebox("tab_hovered", "TabContainer", box(PANEL_2, GOLD, 1, 5, 10, 5))
	t.set_stylebox("panel", "TabContainer", box(Color(PANEL, 0.92), GOLD_DIM, 1, 6, 10))
	t.set_color("font_selected_color", "TabContainer", GOLD)
	t.set_color("font_unselected_color", "TabContainer", TEXT_DIM)
	t.set_color("font_hovered_color", "TabContainer", TEXT)
	t.set_font("font", "TabContainer", font_head_bold)
	t.set_font_size("font_size", "TabContainer", 14)
	# Scroll
	t.set_stylebox("scroll", "VScrollBar", box(Color(0, 0, 0, 0.2), Color(0, 0, 0, 0), 0, 3, 4))
	t.set_stylebox("grabber", "VScrollBar", box(GOLD_DIM, Color(0, 0, 0, 0), 0, 3, 4))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(GOLD, Color(0, 0, 0, 0), 0, 3, 4))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(GOLD, Color(0, 0, 0, 0), 0, 3, 4))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	t.set_constant("separation", "HBoxContainer", 8)
	t.set_constant("separation", "VBoxContainer", 6)
	t.set_stylebox("separator", "HSeparator", line_box())
	theme_obj = t
	return t


static func line_box() -> StyleBoxLine:
	var l := StyleBoxLine.new()
	l.color = Color(GOLD_DIM, 0.6)
	l.thickness = 1
	return l


static func box(bg: Color, border: Color, bw := 1, radius := 4, pad := 6, pad_v := -1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad if pad_v < 0 else pad_v
	s.content_margin_bottom = pad if pad_v < 0 else pad_v
	s.anti_aliasing = true
	return s


# ------------------------------------------------------------------ widgets --
static func lbl(text: String, size := 17, color := TEXT, head := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if head:
		l.add_theme_font_override("font", font_head_bold)
	return l


static func wrap(text: String, size := 16, color := TEXT) -> Label:
	var l := lbl(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 60
	return l


static func heading(text: String, size := 26) -> Label:
	return lbl(text, size, GOLD, true)


static func rich(bb := "", fit := true) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = bb
	r.fit_content = fit
	r.scroll_active = not fit
	r.selection_enabled = false
	r.custom_minimum_size.x = 80
	return r


static func btn(text: String, cb: Callable = Callable(), tip := "", min_w := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	if min_w > 0:
		b.custom_minimum_size.x = min_w
	if cb.is_valid():
		b.pressed.connect(func():
			Sfx.play("click")
			cb.call())
	return b


static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep := 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func panel(bg := PANEL, border := GOLD_DIM, pad := 10, radius := 6) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border, 1, radius, pad))
	return p


static func spacer(w := 0, h := 0, expand := false) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func expand(c: Control, h := true, v := false) -> Control:
	if h:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if v:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func icon(name: String, size := 32, tint := TEXT) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Data.icon(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.modulate = tint
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func bar(value: float, max_v: float, fill: Color, h := 16, show_text := true) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = maxf(1.0, max_v)
	b.value = value
	b.custom_minimum_size.y = h
	b.show_percentage = false
	b.add_theme_stylebox_override("fill", box(fill, Color(0, 0, 0, 0), 0, 3))
	if show_text:
		var l := lbl("%d / %d" % [int(value), int(max_v)], 12, TEXT)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.name = "Text"
		b.add_child(l)
	return b


static func set_bar(b: ProgressBar, value: float, max_v: float, text := "") -> void:
	b.max_value = maxf(1.0, max_v)
	b.value = value
	var l := b.get_node_or_null("Text")
	if l:
		l.text = text if text != "" else "%d / %d" % [int(value), int(max_v)]


static func clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


static func hex(c: Color) -> String:
	return c.to_html(false)


static func col(text: String, c: Color) -> String:
	return "[color=#%s]%s[/color]" % [c.to_html(false), text]


static func path_tag(path: String) -> String:
	return col("%s %s" % [Data.path_symbol(path), Data.path_name(path)], Data.path_color(path).lightened(0.15))


static func num(n) -> String:
	## 12345 -> "12,345"
	var s := str(int(n))
	var neg := s.begins_with("-")
	if neg:
		s = s.substr(1)
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if neg else "") + s + out


static func scroll(child: Control, min_h := 0) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.custom_minimum_size.y = min_h
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	return s


static func gu_card(gd: Dictionary, power := 1.0, w := 150, h := 210, cost_override := -1, dim := false) -> PanelContainer:
	## A Gu drawn as a card: path-coloured frame, icon, cost, name and effect text.
	var pc: Color = Data.path_color(gd.get("path", "none"))
	var rc: Color = RARITY_COLORS.get(gd.get("rarity", "common"), TEXT)
	var p := PanelContainer.new()
	var sb := box(Color("1b1611").lerp(pc, 0.10), rc.lerp(pc, 0.4), 2, 8, 6)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 4
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(w, h)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	var v := vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var top := hbox(4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cost := int(gd.get("cost", 0)) if cost_override < 0 else cost_override
	var cl := lbl(str(cost), 15, Color("9fd3ff"), true)
	cl.tooltip_text = "Essence cost"
	top.add_child(cl)
	top.add_child(expand(spacer()))
	top.add_child(lbl(Data.path_symbol(gd.get("path", "none")), 15, pc.lightened(0.2)))
	top.add_child(lbl("R%d" % int(gd.get("rank", 1)), 13, TEXT_DIM))
	v.add_child(top)
	var ic := icon(gd.get("icon", "circle"), int(h * 0.26), pc.lightened(0.35))
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var nm := lbl(gd.get("name", "?"), 14 if w >= 140 else 12, rc.lightened(0.2), true)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size.x = w - 16
	v.add_child(nm)
	var desc := UI.wrap(Data.gu_description(gd, power), 12 if w >= 140 else 11, TEXT)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(desc)
	p.tooltip_text = "%s (%s, %s)\n%s\n\n%s" % [gd.get("name", ""), Data.path_name(gd.get("path", "none")), gd.get("rarity", "common"),
			Data.gu_description(gd, power), gd.get("flavor", "")]
	if dim:
		p.modulate = Color(1, 1, 1, 0.5)
	return p
