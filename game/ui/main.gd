extends Control
## Root of the interface: owns the backdrop, the current screen, modal dialogs and toasts,
## and routes the Game's signals (events, battles, notices, death) to the right screen.

const MenuScreen := preload("res://ui/menu_screen.gd")
const NewGameScreen := preload("res://ui/new_game_screen.gd")
const WorldScreen := preload("res://ui/world_screen.gd")
const CombatScreen := preload("res://ui/combat_screen.gd")
const Dialogs = preload("res://ui/dialogs.gd")

var bg: ColorRect
var bg_mat: ShaderMaterial
var screen_root: Control
var overlay: Control
var toast_box: VBoxContainer
var current: Control = null
var world: Control = null
var combat_ui: Control = null
var dialogs
var modals: Array = []
var bot = null            # auto-play
var bot_timer := 0.0


func _ready() -> void:
	theme = UI.make_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_mat = ShaderMaterial.new()
	bg_mat.shader = load("res://assets/shaders/ink_wash.gdshader")
	bg.material = bg_mat
	add_child(bg)
	screen_root = Control.new()
	screen_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_root)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	toast_box = UI.vbox(6)
	toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_box.position = Vector2(-220, 70)
	toast_box.custom_minimum_size = Vector2(440, 0)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_box)
	dialogs = Dialogs.new(self)
	Game.event_ready.connect(_on_event)
	Game.combat_started.connect(_on_combat)
	Game.notice.connect(func(t, txt): dialogs.notice(t, txt))
	Game.run_ended.connect(_on_run_ended)
	Game.market_requested.connect(func(kind, _d): dialogs.market(kind))
	Game.toast.connect(func(t, k = "info"): toast(t, k))
	_apply_window_settings()
	show_menu()


func _apply_window_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if bool(Meta.setting("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_F11:
			Meta.set_setting("fullscreen", not bool(Meta.setting("fullscreen", false)))
			_apply_window_settings()
		elif ev.keycode == KEY_ESCAPE and modals.size() > 0:
			var m: Control = modals[-1]
			if m.get_meta("closable", true):
				close_modal(m)
		elif current == world and modals.is_empty() and Game.has_run():
			world.hotkey(ev)
		elif current == combat_ui and modals.is_empty():
			combat_ui.hotkey(ev)


# ---------------------------------------------------------------- screens --
func _set_screen(c: Control) -> void:
	if current != null:
		current.queue_free()
	current = c
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_root.add_child(c)
	if c == world or c == combat_ui:
		pass


func show_menu() -> void:
	_stop_bot()
	world = null
	combat_ui = null
	_close_all_modals()
	_set_backdrop(1.0, 0.18)
	Sfx.music("menu")
	var m = MenuScreen.new()
	m.main = self
	_set_screen(m)


func show_new_game() -> void:
	_set_backdrop(1.0, 0.12)
	var n = NewGameScreen.new()
	n.main = self
	_set_screen(n)


func show_world() -> void:
	_set_backdrop(0.0, 0.06)
	combat_ui = null
	var w = WorldScreen.new()
	w.main = self
	world = w
	_set_screen(w)
	Sfx.music("immortal" if Game.is_immortal() else "world")
	if Game.combat != null:
		_on_combat()
	elif not Game.current_event.is_empty():
		_on_event(Game.current_event)


func start_run(opts: Dictionary) -> void:
	Game.new_game(opts)
	Game.save_game()
	show_world()
	if bool(Meta.setting("tutorial", true)):
		dialogs.tutorial()


func _set_backdrop(mountains: float, glow: float) -> void:
	bg_mat.set_shader_parameter("mountains", mountains)
	bg_mat.set_shader_parameter("glow_amount", glow)


# ------------------------------------------------------------- game hooks --
func _on_event(inst: Dictionary) -> void:
	if world == null:
		return
	dialogs.event(inst)


func _on_combat() -> void:
	if world == null:
		return
	world.visible = false
	var c = CombatScreen.new()
	c.main = self
	combat_ui = c
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_root.add_child(c)
	current = c


func combat_finished(res: Dictionary) -> void:
	## Called by the combat screen when the player closes the results.
	if combat_ui:
		combat_ui.queue_free()
		combat_ui = null
	if not Game.has_run():
		return   # run_ended already showed the summary
	current = world
	world.visible = true
	world.refresh(true)
	if Game.combat != null:   # chained battles (venerable trials, mission ambush)
		_on_combat()
		return
	if not Game.current_event.is_empty():
		dialogs.event(Game.current_event)
	_maybe_tribulation()


func _maybe_tribulation() -> void:
	var pl: Dictionary = Game.p()
	var t = pl.get("trib", {})
	if t is Dictionary and str(t.get("stage", "")) == "prepare":
		dialogs.tribulation()


func _on_run_ended(summary: Dictionary) -> void:
	_stop_bot()
	if combat_ui:
		combat_ui.queue_free()
		combat_ui = null
	_close_all_modals()
	dialogs.life_summary(summary)


# --------------------------------------------------------------- modals ----
func modal(content: Control, closable := true, width := 640) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_meta("closable", closable)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(cc)
	var p := UI.panel(UI.PANEL, UI.GOLD, 18, 10)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel")
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 18
	sb.set_border_width_all(2)
	p.custom_minimum_size.x = width
	cc.add_child(p)
	p.add_child(content)
	overlay.add_child(dim)
	modals.append(dim)
	dim.modulate.a = 0.0
	create_tween().tween_property(dim, "modulate:a", 1.0, 0.15)
	if closable:
		dim.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				if not p.get_global_rect().has_point(ev.global_position):
					close_modal(dim))
	return dim


func close_modal(m: Control) -> void:
	if m == null or not is_instance_valid(m):
		return
	modals.erase(m)
	m.queue_free()
	if world and is_instance_valid(world):
		world.refresh()


func _close_all_modals() -> void:
	for m in modals.duplicate():
		if is_instance_valid(m):
			m.queue_free()
	modals.clear()


func has_modal() -> bool:
	return modals.size() > 0


func toast(text: String, kind := "info") -> void:
	var p := UI.panel(Color(0.08, 0.065, 0.05, 0.94), UI.LOG_COLORS.get(kind, UI.GOLD), 10, 6)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.wrap(text, 16, UI.LOG_COLORS.get(kind, UI.TEXT))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	toast_box.add_child(p)
	while toast_box.get_child_count() > 4:
		var old := toast_box.get_child(0)
		toast_box.remove_child(old)
		old.queue_free()
	var tw := create_tween()
	tw.tween_interval(2.8)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)


# ------------------------------------------------------------- auto-play ---
func toggle_bot() -> void:
	if bot == null:
		bot = load("res://core/bot.gd").new(Game)
		toast("Auto-play on: the game plays itself. Press A or the button again to stop.", "warn")
	else:
		_stop_bot()
		toast("Auto-play off.", "info")
	if world:
		world.refresh()


func _stop_bot() -> void:
	bot = null


func _process(delta: float) -> void:
	if bot == null or not Game.has_run():
		return
	bot_timer += delta
	if bot_timer < 0.06:
		return
	bot_timer = 0.0
	# close info dialogs so the bot is never stuck behind one
	if combat_ui != null and is_instance_valid(combat_ui):
		combat_ui.bot_step()
		return
	for m in modals.duplicate():
		if is_instance_valid(m) and (m.get_meta("bot_close", false) or m.get_meta("event", false)):
			close_modal(m)
	if Game.combat != null:
		return
	bot.step()
	if world and Game.has_run():
		world.refresh()
