extends Node
## Optional live text generation with the Claude API (docs/AIGeneration.md).
## The game never needs it: every Gu, event and line of dialogue has an offline, procedural version.
## When the player enters an API key in Settings, this rewrites names and flavour text in the background
## and caches the results in user://ai_cache.json. Numbers and rules always stay procedural.

signal status_changed(text)

const URL := "https://api.anthropic.com/v1/messages"
const API_VERSION := "2026-10-21"
const CACHE_PATH := "user://ai_cache.json"
const SYSTEM := "You write short flavour text for a dark xianxia roguelike card game about Gu insects and Gu Masters, " + \
		"inspired by the web novel Reverend Insanity. Tone: grim, clever, terse, poetic. Keep every text suitable for all " + \
		"ages: no sexual, romantic-explicit or fanservice content, no slurs, no real people. Never mention game mechanics or numbers."

var cache := {"lines": {}, "events": {}, "gu": {}}
var _queue: Array = []
var _busy := false
var _http: HTTPRequest
var _current: Dictionary = {}
var last_status := "Offline (no API key): all content is procedural."
var calls_ok := 0
var calls_failed := 0


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 60.0
	add_child(_http)
	_http.request_completed.connect(_on_done)
	_load_cache()


func active() -> bool:
	return str(Meta.setting("api_key", "")).strip_edges() != "" and bool(Meta.setting("ai_enabled", true)) \
			and not Game.headless


func _load_cache() -> void:
	if not FileAccess.file_exists(CACHE_PATH):
		return
	var f := FileAccess.open(CACHE_PATH, FileAccess.READ)
	var v = JSON.parse_string(f.get_as_text()) if f else null
	if typeof(v) == TYPE_DICTIONARY:
		for k in ["lines", "events", "gu"]:
			if typeof(v.get(k)) == TYPE_DICTIONARY:
				cache[k] = v[k]


func _save_cache() -> void:
	var f := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cache))


func clear_cache() -> void:
	cache = {"lines": {}, "events": {}, "gu": {}}
	_save_cache()


# ------------------------------------------------------------ public API ----
func cached_line(npc: Dictionary) -> String:
	## Returns one AI-written line for this NPC (each is used once), and tops the pool up in the background.
	var key: String = "%s|%s" % [npc.get("id", ""), Game.world.band(int(npc.get("disp", 0))) if Game.world else ""]
	var pool: Array = cache.lines.get(key, [])
	var out := ""
	if pool.size() > 0:
		out = str(pool.pop_front())
		cache.lines[key] = pool
	if pool.size() < 2 and active() and not _queued("line", key):
		var arch: String = Data.archetypes.get(npc.get("arch", ""), {"name": "Gu Master"}).name
		_enqueue({"kind": "line", "key": key, "prompt": "Write 4 different single lines (max 18 words each) that %s, a %s with a %s personality who wants %s, might say to the player Gu Master. Their attitude to the player: %s." % [
				npc.get("name", "someone"), arch, npc.get("personality", "calm"), npc.get("desire", "power"), key.get_slice("|", 1)],
				"schema": {"type": "object", "properties": {"lines": {"type": "array", "items": {"type": "string"}}},
						"required": ["lines"], "additionalProperties": false}})
	return out


func cached_event_text(tid: String, title := "", text := "") -> String:
	## An atmospheric opening sentence for a procedural event template.
	var pool: Array = cache.events.get(tid, [])
	var out := ""
	if pool.size() > 0:
		out = str(pool[randi() % pool.size()])
	if pool.size() < 4 and active() and title != "" and not _queued("event", tid):
		_enqueue({"kind": "event", "key": tid, "prompt": "An event in the game is titled '%s' and reads: '%s'. Write 3 alternative atmospheric opening sentences (max 25 words each) that could precede it. Do not repeat its content or invent new facts." % [title, text],
				"schema": {"type": "object", "properties": {"sentences": {"type": "array", "items": {"type": "string"}}},
						"required": ["sentences"], "additionalProperties": false}})
	return out


func request_gu_flavor(id: String, gd: Dictionary) -> void:
	if not active():
		return
	var eff := []
	for e in gd.get("effects", []):
		eff.append(str(e.get("v", "")))
	_enqueue({"kind": "gu", "key": id, "prompt": "Invent a name and one-sentence flavour text (max 22 words) for a newly discovered Rank %d %s path Gu (a magical insect). Its abilities involve: %s. The name must be 2-4 words and end with 'Gu'." % [
			int(gd.rank), Data.path_name(gd.path), ", ".join(eff)],
			"schema": {"type": "object", "properties": {"name": {"type": "string"}, "flavor": {"type": "string"}},
					"required": ["name", "flavor"], "additionalProperties": false}})


func test_connection() -> void:
	if str(Meta.setting("api_key", "")).strip_edges() == "":
		_status("No API key set.")
		return
	_enqueue({"kind": "test", "key": "test", "prompt": "Reply with the single word: ready",
			"schema": {"type": "object", "properties": {"word": {"type": "string"}}, "required": ["word"], "additionalProperties": false}}, true)


# -------------------------------------------------------------- internals ----
func _queued(kind: String, key: String) -> bool:
	if _current.get("kind") == kind and _current.get("key") == key:
		return true
	for q in _queue:
		if q.kind == kind and q.key == key:
			return true
	return false


func _enqueue(job: Dictionary, front := false) -> void:
	if _queue.size() > 20:
		return
	if front:
		_queue.push_front(job)
	else:
		_queue.append(job)
	_pump()


func _pump() -> void:
	if _busy or _queue.is_empty():
		return
	_current = _queue.pop_front()
	var body := {
		"model": str(Meta.setting("model", "claude-opus-5-5")),
		"max_tokens": 2000,
		"system": SYSTEM,
		"output_config": {"effort": "low", "format": {"type": "json_schema", "schema": _current.schema}},
		"messages": [{"role": "user", "content": _current.prompt}],
	}
	var headers := PackedStringArray(["content-type: application/json", "anthropic-version: " + API_VERSION,
			"x-api-key: " + str(Meta.setting("api_key", "")).strip_edges()])
	var err := _http.request(URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_fail("Could not start the request (%d)." % err)
		return
	_busy = true


func _on_done(result: int, code: int, _headers: PackedStringArray, raw: PackedByteArray) -> void:
	_busy = false
	var job := _current
	_current = {}
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail("Network error (%d). Using offline content." % result)
		return
	var v = JSON.parse_string(raw.get_string_from_utf8())
	if code != 200 or typeof(v) != TYPE_DICTIONARY:
		var msg := ""
		if typeof(v) == TYPE_DICTIONARY and typeof(v.get("error")) == TYPE_DICTIONARY:
			msg = str(v.error.get("message", ""))
		_fail("API error %d %s. Using offline content." % [code, msg.left(120)])
		return
	if str(v.get("stop_reason", "")) == "refusal":
		_pump()
		return
	var txt := ""
	for b in v.get("content", []):
		if typeof(b) == TYPE_DICTIONARY and b.get("type") == "text":
			txt += str(b.get("text", ""))
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		_fail("Unreadable reply. Using offline content.")
		return
	calls_ok += 1
	_apply(job, data)
	_status("Connected: %d texts generated this session." % calls_ok)
	_save_cache()
	_pump()


func _clean(s, max_len: int) -> String:
	var t := str(s).strip_edges().replace("\n", " ").replace("*", "")
	if t.length() > max_len:
		t = t.left(max_len).strip_edges() + "…"
	return t


func _apply(job: Dictionary, data: Dictionary) -> void:
	match str(job.kind):
		"line":
			var pool: Array = cache.lines.get(job.key, [])
			for l in data.get("lines", []):
				var t := _clean(l, 140)
				if t != "":
					pool.append(t)
			cache.lines[job.key] = pool
		"event":
			var pool: Array = cache.events.get(job.key, [])
			for l in data.get("sentences", []):
				var t := _clean(l, 180)
				if t != "":
					pool.append(t)
			cache.events[job.key] = pool.slice(maxi(0, pool.size() - 8))
		"gu":
			var nm := _clean(data.get("name", ""), 34)
			var fl := _clean(data.get("flavor", ""), 180)
			if nm == "" or not nm.ends_with("Gu"):
				return
			cache.gu[job.key] = {"name": nm, "flavor": fl}
			if Data.gu.has(job.key):
				Data.gu[job.key].name = nm
				Data.gu[job.key].flavor = fl
				Data.gu[job.key]["ai"] = true
				Game.emit_signal("state_changed")
		"test":
			_status("Connected to the Claude API. Live generation is on.")


func _fail(msg: String) -> void:
	calls_failed += 1
	_status(msg)
	# a failure means offline for the rest of the queue, to avoid spamming bad requests
	_queue.clear()


func _status(t: String) -> void:
	last_status = t
	emit_signal("status_changed", t)
