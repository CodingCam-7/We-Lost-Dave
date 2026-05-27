extends CharacterBody2D

# Movement
const SPEED        := 200.0
const ACCELERATION := 800.0
const FRICTION     := 600.0

# Health segments
const SEGMENT_W      := 22.0
const SEGMENT_H      := 10.0
const SEGMENT_GAP    := 5.0
const INVINCIBLE_T   := 0.8
const COLOR_HP_FULL  := Color(0.85, 0.60, 0.10)
const COLOR_HP_EMPTY := Color(0.18, 0.12, 0.04)
const COLOR_HIT      := Color(0.90, 0.15, 0.10)
const BASE_COLOR     := Color(0.109804, 1.0, 0.6, 1.0)

# .44 Magnum — slow, deliberate, devastating
const CYLINDER_CAPACITY := 6
const FIRE_RATE         := 0.5
const RELOAD_TIME       := 2.75

var _max_segments: int         = 3
var _current_hp:   int         = 3
var _hp_rects:     Array       = []
var _hud_canvas:   CanvasLayer = null
var _visual:       Polygon2D   = null
var _invincible:   float       = 0.0

var _ammo:         int   = CYLINDER_CAPACITY
var _fire_timer:   float = 0.0
var _reloading:    bool  = false
var _reload_timer: float = 0.0
var _ammo_label:   Label
var _sfx_shot:     AudioStreamPlayer
var _sfx_reload:   AudioStreamPlayer

@onready var _bullet_scene := preload("res://scenes/bullet.tscn")

func _ready() -> void:
	add_to_group("player")
	_visual = $Polygon2D
	_setup_audio()
	_setup_hud()

func _setup_audio() -> void:
	_sfx_shot = AudioStreamPlayer.new()
	_sfx_shot.volume_db = 4.0
	add_child(_sfx_shot)
	var shot_stream := _try_load_audio("res://assets/audio/sfx_gunshot.mp3")
	if shot_stream:
		_sfx_shot.stream = shot_stream

	_sfx_reload = AudioStreamPlayer.new()
	_sfx_reload.volume_db = -2.0
	add_child(_sfx_reload)
	var reload_stream := _try_load_audio("res://assets/audio/sfx_reload.ogg")
	if reload_stream:
		_sfx_reload.stream = reload_stream

func _physics_process(delta: float) -> void:
	if _invincible > 0.0:
		_invincible -= delta
	_handle_movement(delta)
	_handle_weapon(delta)

func _handle_movement(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up",   "move_down")
	)
	if input_dir.length() > 0:
		velocity = velocity.move_toward(input_dir.normalized() * SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()

func _handle_weapon(delta: float) -> void:
	if _reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_reloading = false
			_ammo      = CYLINDER_CAPACITY
		_update_hud()
		return

	_fire_timer -= delta

	if Input.is_action_just_pressed("reload") or \
	   (Input.is_action_just_pressed("shoot") and _ammo == 0):
		_start_reload()
		return

	if Input.is_action_pressed("shoot") and _fire_timer <= 0.0 and _ammo > 0:
		_fire_timer  = FIRE_RATE
		_ammo       -= 1
		_spawn_bullet()
		_update_hud()

func _start_reload() -> void:
	if _reloading or _ammo == CYLINDER_CAPACITY:
		return
	_reloading    = true
	_reload_timer = RELOAD_TIME
	if _sfx_reload.stream:
		_sfx_reload.play()
	_update_hud()

func _spawn_bullet() -> void:
	var dir    := (get_global_mouse_position() - global_position).normalized()
	var bullet := _bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.init(global_position + dir * 20.0, dir)
	if _sfx_shot.stream:
		_sfx_shot.pitch_scale = randf_range(0.93, 1.07)
		_sfx_shot.play()

# ── HUD ───────────────────────────────────────────────────────────────────────

func _setup_hud() -> void:
	_hud_canvas = CanvasLayer.new()
	_hud_canvas.layer = 10
	add_child(_hud_canvas)

	# Health bar — top left
	var hull_label := Label.new()
	hull_label.text     = "HULL"
	hull_label.position = Vector2(20, 16)
	hull_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.4))
	hull_label.add_theme_font_size_override("font_size", 13)
	_hud_canvas.add_child(hull_label)
	_build_hp_segments()

	# Ammo label — bottom left
	_ammo_label = Label.new()
	_ammo_label.position = Vector2(30, 670)
	_ammo_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	_ammo_label.add_theme_font_size_override("font_size", 18)
	_hud_canvas.add_child(_ammo_label)
	_update_hud()

func _build_hp_segments() -> void:
	for rect in _hp_rects:
		rect.queue_free()
	_hp_rects.clear()
	for i in range(_max_segments):
		var seg      := ColorRect.new()
		seg.size      = Vector2(SEGMENT_W, SEGMENT_H)
		seg.position  = Vector2(60.0 + i * (SEGMENT_W + SEGMENT_GAP), 18.0)
		seg.color     = COLOR_HP_FULL if i < _current_hp else COLOR_HP_EMPTY
		_hud_canvas.add_child(seg)
		_hp_rects.append(seg)

func _update_hud() -> void:
	for i in range(_hp_rects.size()):
		_hp_rects[i].color = COLOR_HP_FULL if i < _current_hp else COLOR_HP_EMPTY
	if _reloading:
		var progress := 1.0 - (_reload_timer / RELOAD_TIME)
		var filled   := int(progress * 10)
		var bar      := "▓".repeat(filled) + "░".repeat(10 - filled)
		_ammo_label.text = "RELOADING  [" + bar + "]"
	else:
		var pips := ""
		for i in range(CYLINDER_CAPACITY):
			pips += "● " if i < _ammo else "○ "
		_ammo_label.text = ".44 MAG   " + pips.strip_edges()

# ── Health ────────────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if _invincible > 0.0:
		return
	_current_hp = max(0, _current_hp - amount)
	_invincible = INVINCIBLE_T
	_update_hud()
	_flash_hit()
	if _current_hp == 0:
		_die()

func add_segment() -> void:
	_max_segments += 1
	_current_hp    = min(_current_hp + 1, _max_segments)
	_build_hp_segments()

func _die() -> void:
	pass  # TODO: death screen / respawn

func _flash_hit() -> void:
	if not is_instance_valid(_visual):
		return
	_visual.color = COLOR_HIT
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self):
		_visual.color = BASE_COLOR

func _try_load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null
