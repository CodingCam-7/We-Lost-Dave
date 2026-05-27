class_name Chest
extends StaticBody2D

enum Facing { UP, DOWN, LEFT, RIGHT }

var facing: Facing = Facing.DOWN
var locked: bool   = false

const EJECT_SPEED := 180.0

var _opened:     bool      = false
var _lid:        Polygon2D = null
var _padlock:    Polygon2D = null

var _item_scene := preload("res://scenes/item_drop.tscn")

func _ready() -> void:
	_lid     = $Lid
	_padlock = $Padlock
	_padlock.visible = locked
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.register_interactable(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.unregister_interactable(self)

func get_prompt() -> String:
	return "[E]  Open  —  LOCKED" if locked else "[E]  Open"

func interact(player: Node) -> void:
	if _opened:
		return
	if locked:
		if not player.use_key():
			return
	_open(player)

func _open(player: Node) -> void:
	_opened          = true
	_padlock.visible = false
	player.unregister_interactable(self)

	# Animate lid sliding open
	var tween := create_tween()
	tween.tween_property(_lid, "position", _lid.position + Vector2(0.0, -18.0), 0.18)

	# Eject two items with a small spread angle
	var dir := _get_facing_dir()
	for i in range(2):
		var spread := -15.0 if i == 0 else 15.0
		var vel    := dir.rotated(deg_to_rad(spread)) * EJECT_SPEED
		var item   := _item_scene.instantiate()
		get_parent().add_child(item)
		item.global_position = global_position + dir * 24.0
		item.launch(vel)

func _get_facing_dir() -> Vector2:
	match facing:
		Facing.UP:    return Vector2.UP
		Facing.DOWN:  return Vector2.DOWN
		Facing.LEFT:  return Vector2.LEFT
		Facing.RIGHT: return Vector2.RIGHT
	return Vector2.DOWN
