extends RigidBody2D

var is_key:    bool   = false
var item_name: String = "???"

const KEY_COLOR := Color(0.95, 0.75, 0.10)
const COLORS    := [
	Color(0.70, 0.30, 1.00, 0.95),
	Color(0.30, 0.90, 0.45, 0.95),
	Color(0.30, 0.55, 1.00, 0.95),
	Color(1.00, 0.35, 0.30, 0.95),
	Color(0.90, 0.80, 0.20, 0.95),
]

var _orb_color: Color = Color(0, 0, 0, 0)  # alpha=0 = not preset; set before add_child() to override

func _ready() -> void:
	collision_layer = 4
	collision_mask  = 1
	gravity_scale   = 0.0
	linear_damp     = 4.0

	var mat    := PhysicsMaterial.new()
	mat.bounce  = 0.45
	mat.friction = 0.6
	physics_material_override = mat

	if _orb_color.a == 0.0:
		_orb_color = KEY_COLOR if is_key else COLORS[randi() % COLORS.size()]

	# Octagonal visual
	var vis := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(8):
		var a := TAU * i / 8.0
		pts.append(Vector2(cos(a), sin(a)) * 10.0)
	vis.polygon = pts
	vis.color   = _orb_color
	add_child(vis)

	# Collision circle for wall bouncing
	var col  := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 8.0
	col.shape   = circ
	add_child(col)

	# Proximity area — player must be close to see E prompt
	var area  := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 1
	var acol  := CollisionShape2D.new()
	var acirc := CircleShape2D.new()
	acirc.radius = 22.0
	acol.shape   = acirc
	area.add_child(acol)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

func launch(vel: Vector2) -> void:
	linear_velocity = vel

func get_prompt() -> String:
	return "[E]  Pick up KEY" if is_key else "[E]  Pick up item"

func interact(player: Node) -> void:
	player.unregister_interactable(self)
	if is_key:
		player.add_key()
	else:
		player.add_to_inventory({"name": item_name, "color": _orb_color})
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.register_interactable(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.unregister_interactable(self)
