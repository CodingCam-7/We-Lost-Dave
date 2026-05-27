extends CharacterBody2D

enum State { DORMANT, AWARE }

const MAX_HP               := 150.0
const SPEED                := 280.0
const ACCELERATION         := 1200.0
const EXPOSURE_THRESHOLD   := 1.0
const CONTACT_RANGE        := 28.0

const DORMANT_COLOR := Color(0.35, 0.1,  0.12)
const AWARE_COLOR   := Color(1.0,  0.15, 0.08)
const HIT_COLOR     := Color(1.0,  1.0,  1.0)
const DEAD_COLOR    := Color(0.4,  0.4,  0.4, 0.5)

var _hp:             float = MAX_HP
var _state:          State = State.DORMANT
var _exposure:       float = 0.0
var _contact_timer:  float = 0.0
var _player:         CharacterBody2D
var _detection_cone: Area2D
var _visual:         Polygon2D
var _sfx_alert:      AudioStreamPlayer
var _sfx_death:      AudioStreamPlayer

func _ready() -> void:
	add_to_group("enemy")
	_visual = $Polygon2D
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_detection_cone = _player.get_node_or_null("DaveLight/DetectionCone")
	_setup_audio()

func _setup_audio() -> void:
	_sfx_alert = AudioStreamPlayer.new()
	_sfx_alert.volume_db = 2.0
	add_child(_sfx_alert)
	var alert_stream := _try_load_audio("res://assets/audio/sfx_enemy_alert.wav")
	if alert_stream:
		_sfx_alert.stream = alert_stream

	_sfx_death = AudioStreamPlayer.new()
	_sfx_death.volume_db = 0.0
	_sfx_death.finished.connect(queue_free)  # free node after death sound finishes
	add_child(_sfx_death)
	var death_stream := _try_load_audio("res://assets/audio/sfx_enemy_death.ogg")
	if death_stream:
		_sfx_death.stream = death_stream

func _physics_process(delta: float) -> void:
	_update_exposure(delta)
	_update_behaviour(delta)

func _update_exposure(delta: float) -> void:
	if _state == State.AWARE or not _detection_cone:
		return
	if _detection_cone.overlaps_body(self):
		_exposure += delta
		if _exposure >= EXPOSURE_THRESHOLD:
			_become_aware()
	else:
		_exposure = max(0.0, _exposure - delta * 0.5)

func _become_aware() -> void:
	_state = State.AWARE
	_visual.color = AWARE_COLOR
	if _sfx_alert.stream:
		_sfx_alert.play()

func _update_behaviour(delta: float) -> void:
	match _state:
		State.DORMANT:
			velocity = Vector2.ZERO
		State.AWARE:
			if _player:
				var dir := (_player.global_position - global_position).normalized()
				velocity = velocity.move_toward(dir * SPEED, ACCELERATION * delta)
				_check_contact(delta)
	move_and_slide()

func _check_contact(delta: float) -> void:
	_contact_timer -= delta
	if _contact_timer > 0.0 or not _player:
		return
	if global_position.distance_to(_player.global_position) < CONTACT_RANGE:
		_contact_timer = 0.8
		_player.take_damage(1)

func take_damage(amount: float) -> void:
	_hp -= amount
	if _hp <= 0.0:
		_die()
		return
	_flash_hit()

func _die() -> void:
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	_visual.color = DEAD_COLOR
	if _sfx_death.stream:
		_sfx_death.play()  # queue_free fires when sound finishes
	else:
		queue_free()

func _flash_hit() -> void:
	_visual.color = HIT_COLOR
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		_visual.color = AWARE_COLOR if _state == State.AWARE else DORMANT_COLOR

func _try_load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null
