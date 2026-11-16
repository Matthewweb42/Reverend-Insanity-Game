extends Node
## Sound effects and music. All audio is synthesized by tools/gen_assets.py (see CREDITS.md).

var _players: Array[AudioStreamPlayer] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current := ""
var _cache := {}
var enabled := true


func _ready() -> void:
	enabled = DisplayServer.get_name() != "headless"
	if not enabled:
		return
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	add_child(_music_a)
	add_child(_music_b)


func _load(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var path := "res://assets/audio/%s.ogg" % name
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	_cache[name] = s
	return s


func _db(v: float) -> float:
	return linear_to_db(clampf(v, 0.0001, 1.0))


func play(name: String) -> void:
	if not enabled:
		return
	var s := _load("sfx_" + name)
	if s == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = s
			p.volume_db = _db(float(Meta.setting("sfx", 0.8)))
			p.pitch_scale = randf_range(0.96, 1.04)
			p.play()
			return


func music(name: String) -> void:
	if not enabled or name == _current:
		return
	_current = name
	var s := _load("music_" + name)
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		s.loop = true
	var old := _music_a if _music_a.playing else _music_b
	var nw := _music_b if old == _music_a else _music_a
	nw.stream = s
	nw.volume_db = -40.0
	nw.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(nw, "volume_db", _db(float(Meta.setting("music", 0.6))), 1.5)
	if old.playing:
		tw.tween_property(old, "volume_db", -40.0, 1.5)
		tw.chain().tween_callback(old.stop)


func refresh_volume() -> void:
	if not enabled:
		return
	for m in [_music_a, _music_b]:
		if m.playing and m.volume_db > -39.0:
			m.volume_db = _db(float(Meta.setting("music", 0.6)))
