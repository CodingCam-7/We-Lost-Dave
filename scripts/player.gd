extends CharacterBody2D

# Movement
const SPEED        := 200.0
const ACCELERATION := 800.0
const FRICTION     := 600.0

# .44 Magnum — slow, deliberate, devastating
const CYLINDER_CAPACITY := 6
const FIRE_RATE         := 0.5
const RELOAD_TIME       := 2.75

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
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	_ammo_label = Label.new()
	_ammo_label.position = Vector2(30, 670)
	_ammo_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	_ammo_label.add_theme_font_size_override("font_size", 18)
	canvas.add_child(_ammo_label)
	_update_hud()

func _update_hud() -> void:
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

func _try_load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null
