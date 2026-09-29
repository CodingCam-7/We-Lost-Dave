extends Node
class_name IntroSequence

# Opening cutscene. Added by house_room.gd after the level is built.
#
#   1. Fade in on a brightly lit street. A car drives Dave in and stops at the gate.
#   2. Dave steps out, the car pulls away, Dave walks up to the gate.
#   3. Every lamp flickers 5 times and dies. The gate shuts behind him.
#   4. Darkness — then his flashlight clicks on and the player takes control.
#
# Esc / Space skips. Plays once per launch (RunState.intro_played), so
# reloading after death drops straight into the finished state.

const CAR_START_X   := -1800.0
const CAR_END_X     := 2600.0
const CAR_Y         := 1222.0            # near lane of the road
const DROP_OFF      := Vector2(0, 1168)  # where Dave steps out (sidewalk side of the car)
const GATE_POS      := Vector2(0, 1050)  # just inside the gate — also the skip spawn
const BRIGHT_AMBIENT := Color(0.55, 0.55, 0.62)  # world tint while the lamps are on

const INTRO_ZOOM    := Vector2(0.8, 0.8)     # zoomed out to show off the house
const INTRO_OFFSET  := Vector2(0, -330)      # camera looks north of Dave, framing the house
const GAME_ZOOM     := Vector2(2.0, 2.0)     # matches Camera2D in player.tscn

# (off seconds, on seconds) for each of the 5 flickers — irregular on purpose
const FLICKERS := [[0.08, 0.30], [0.14, 0.12], [0.05, 0.45], [0.20, 0.08], [0.10, 0.25]]

var _player:  Node2D
var _camera:  Camera2D
var _ambient: CanvasModulate
var _car:     Node2D
var _fade:    ColorRect
var _tweens:  Array = []
var _done     := false
var _in_car   := false

func _ready() -> void:
	_player  = get_tree().get_first_node_in_group("player")
	_camera  = _player.get_node("Camera2D")
	_ambient = get_parent().get_node("AmbientDark")

	if RunState.intro_played:
		_finish()
		return

	_player.set_controls_enabled(false)
	_player.get_node("Polygon2D").visible = false   # Dave is inside the car
	_in_car = true
	_camera.zoom   = INTRO_ZOOM
	_camera.offset = INTRO_OFFSET
	_set_lamps(true)

	_car = _build_car()
	_car.position = Vector2(CAR_START_X, CAR_Y)
	get_parent().add_child(_car)
	_player.global_position = _car.position

	_build_fade()
	_run()

# Camera is a child of the player, so keeping Dave glued to the car makes
# the camera ride along with it.
func _process(_delta: float) -> void:
	if _in_car:
		_player.global_position = _car.global_position

func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode in [KEY_ESCAPE, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_finish()

# ── The sequence ──────────────────────────────────────────────────────────────

func _run() -> void:
	# 1. Fade in while the car drives in and slows to a stop at the gate
	_track(create_tween()).tween_property(_fade, "color:a", 0.0, 2.0)
	var drive := _track(create_tween())
	drive.tween_property(_car, "position:x", 0.0, 7.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await drive.finished
	if not await _wait(0.9): return

	# 2. Dave steps out; car pulls away while he walks to the gate
	_in_car = false
	_player.get_node("Polygon2D").visible = true
	_player.global_position = DROP_OFF
	if not await _wait(0.6): return
	_track(create_tween()).tween_property(_car, "position:x", CAR_END_X, 4.0) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if not await _wait(0.5): return
	var walk := _track(create_tween())
	walk.tween_property(_player, "global_position", GATE_POS, 2.8)
	await walk.finished
	if not await _wait(1.0): return

	# 3. Lamps flicker 5 times, then die
	for f in FLICKERS:
		_set_lamps(false)
		if not await _wait(f[0]): return
		_set_lamps(true)
		if not await _wait(f[1]): return
	_set_lamps(false)
	get_parent().close_gate()

	# 4. A long beat of darkness, then the flashlight clicks on
	if not await _wait(1.8): return
	_finish()

# Waits, then reports whether the intro is still running (false = skipped)
func _wait(seconds: float) -> bool:
	await get_tree().create_timer(seconds).timeout
	return not _done

func _track(t: Tween) -> Tween:
	_tweens.append(t)
	return t

# Puts the world into its post-intro state. Used at the natural end, on skip,
# and when the scene reloads after death.
func _finish() -> void:
	_done = true
	_in_car = false
	for t: Tween in _tweens:
		if t.is_valid(): t.kill()
	RunState.intro_played = true

	_set_lamps(false)
	get_parent().close_gate()
	if is_instance_valid(_car):
		_car.queue_free()
	_car = null
	if is_instance_valid(_fade):
		_fade.get_parent().queue_free()

	_player.get_node("Polygon2D").visible = true
	_player.global_position = GATE_POS
	_player.set_controls_enabled(true)

	# Ease the camera back to gameplay framing (instant on a reload)
	if _camera.zoom == GAME_ZOOM:
		_camera.offset = Vector2.ZERO
	else:
		var cam := create_tween().set_parallel()
		cam.tween_property(_camera, "zoom", GAME_ZOOM, 1.4).set_trans(Tween.TRANS_SINE)
		cam.tween_property(_camera, "offset", Vector2.ZERO, 1.4).set_trans(Tween.TRANS_SINE)

# ── Lamps ─────────────────────────────────────────────────────────────────────

# Every lamp built by house_room.gd is in the "intro_lamps" group: a Node2D with
# a "Light" (PointLight2D) and optionally a "Bulb" (Polygon2D) child.
func _set_lamps(on: bool) -> void:
	for lamp in get_tree().get_nodes_in_group("intro_lamps"):
		lamp.get_node("Light").enabled = on
		var bulb := lamp.get_node_or_null("Bulb")
		if bulb:
			bulb.color = lamp.get_meta("bulb_color") if on else Color(0.12, 0.12, 0.12)
	# While the lamps are on the whole world is lit; when they die it drops
	# back to the level's normal darkness
	_ambient.color = BRIGHT_AMBIENT if on else get_parent().AMBIENT_DARK

# ── Visual builders ───────────────────────────────────────────────────────────

func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	add_child(layer)

# Top-down sedan facing east (+x), with headlights and tail lights
func _build_car() -> Node2D:
	var car := Node2D.new()
	car.name = "IntroCar"
	car.z_index = 1

	var body := Polygon2D.new()
	body.color   = Color(0.22, 0.06, 0.07)   # dark maroon
	body.polygon = PackedVector2Array([
		Vector2(-60, -24), Vector2(48, -24), Vector2(60, -14),
		Vector2(60, 14), Vector2(48, 24), Vector2(-60, 24),
	])
	car.add_child(body)

	var cabin := Polygon2D.new()
	cabin.color   = Color(0.08, 0.09, 0.11)  # tinted glass roof
	cabin.polygon = PackedVector2Array([
		Vector2(-30, -18), Vector2(22, -18), Vector2(30, -12),
		Vector2(30, 12), Vector2(22, 18), Vector2(-30, 18),
	])
	car.add_child(cabin)

	for y in [-15.0, 15.0]:
		var head := LightUtils.make_light(Color(1.0, 0.97, 0.85), 1.4, 1.3)
		head.position = Vector2(150, y * 2.0)   # pool of light on the road ahead
		car.add_child(head)
		var tail := LightUtils.make_light(Color(1.0, 0.1, 0.05), 0.9, 0.25)
		tail.position = Vector2(-62, y)
		car.add_child(tail)
	return car
