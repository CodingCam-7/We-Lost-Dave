extends RigidBody2D

var is_key:  bool   = false
var item_id: String = ""   # LootTable id — left empty, a random item is rolled in _ready()

const KEY_COLOR := Color(0.95, 0.75, 0.10)

var _orb_color: Color = Color(0, 0, 0, 0)

func _ready() -> void:
	collision_layer = 4
	collision_mask  = 1
	gravity_scale   = 0.0
	linear_damp     = 4.0

	var mat    := PhysicsMaterial.new()
	mat.bounce  = 0.45
	mat.friction = 0.6
	physics_material_override = mat

	# Each item type has its own orb color, so players learn to recognise them
	if is_key:
		_orb_color = KEY_COLOR
	else:
		if item_id == "":
			item_id = LootTable.roll()
		_orb_color = LootTable.get_def(item_id)["color"]

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
	return "[E]  Pick up KEY" if is_key else "[E]  Pick up " + LootTable.get_def(item_id)["name"]

func interact(player: Node) -> void:
	if is_key:
		player.add_key()
	elif not player.add_to_inventory(LootTable.make_item(item_id)):
		# Backpack full — leave the orb on the floor instead of deleting it
		player.show_message("Backpack full.")
		return
	player.unregister_interactable(self)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.register_interactable(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.unregister_interactable(self)
