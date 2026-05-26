extends Area2D

const SPEED     := 900.0
const MAX_RANGE := 700.0
const DAMAGE    := 100    # .44 Magnum — high damage, low volume

var _dir:  Vector2 = Vector2.RIGHT
var _dist: float   = 0.0

func init(spawn_pos: Vector2, direction: Vector2) -> void:
	global_position = spawn_pos
	_dir            = direction.normalized()
	rotation        = _dir.angle()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	var step := _dir * SPEED * delta
	global_position += step
	_dist += step.length()
	if _dist >= MAX_RANGE:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
	queue_free()
