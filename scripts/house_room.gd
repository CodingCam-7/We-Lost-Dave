extends Node2D

const ROOM_W  := 800.0
const ROOM_H  := 600.0
const WALL_T  := 32.0

const COLOR_FLOOR := Color("#2a2a2a")
const COLOR_WALL  := Color("#3a3a3a")

# Convenience: half-extents used throughout
const HW := ROOM_W / 2.0  # 400
const HH := ROOM_H / 2.0  # 300

var _enemy_scene := preload("res://scenes/enemy.tscn")

func _ready() -> void:
	_build_darkness()
	_build_floor()
	_build_walls()
	_spawn_enemies()
	_start_ambient()

func _start_ambient() -> void:
	var stream := _try_load_audio("res://assets/audio/ambient_house.ogg")
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream    = stream
	player.volume_db = -14.0
	player.finished.connect(player.play)  # seamless loop
	add_child(player)
	player.play()

func _try_load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null

func _spawn_enemies() -> void:
	# Place lurkers in opposite dark corners, away from Dave's spawn at origin
	var spawn_points := [
		Vector2(-310, -210),
		Vector2( 310,  210),
	]
	for pos in spawn_points:
		var enemy := _enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = pos

func _build_darkness() -> void:
	var mod := CanvasModulate.new()
	mod.name = "AmbientDark"
	mod.color = Color(0.0, 0.0, 0.05)  # near-black with cold blue tint
	add_child(mod)

# Floor: visual only, no physics, centered on origin.
func _build_floor() -> void:
	var poly := Polygon2D.new()
	poly.name = "Floor"
	poly.color = COLOR_FLOOR
	poly.z_index = -1
	poly.polygon = PackedVector2Array([
		Vector2(-HW, -HH),
		Vector2( HW, -HH),
		Vector2( HW,  HH),
		Vector2(-HW,  HH),
	])
	add_child(poly)

func _build_walls() -> void:
	# Each wall defined by its center in world space and its full size.
	# Walls sit entirely outside the floor rect so the full 800x600 is walkable.
	var wall_defs: Array = [
		# center                              size
		[Vector2(0.0,  -(HH + WALL_T / 2.0)), Vector2(ROOM_W + WALL_T * 2.0, WALL_T)],  # top
		[Vector2(0.0,   (HH + WALL_T / 2.0)), Vector2(ROOM_W + WALL_T * 2.0, WALL_T)],  # bottom
		[Vector2(-(HW + WALL_T / 2.0), 0.0),  Vector2(WALL_T, ROOM_H)],                 # left
		[Vector2( (HW + WALL_T / 2.0), 0.0),  Vector2(WALL_T, ROOM_H)],                 # right
	]

	for def in wall_defs:
		add_child(_make_wall(def[0], def[1]))

# Body sits at `center`; both visual and collision are at local origin — no child offsets.
func _make_wall(center: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center

	var half := size / 2.0
	var vis := Polygon2D.new()
	vis.color = COLOR_WALL
	vis.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2( half.x, -half.y),
		Vector2( half.x,  half.y),
		Vector2(-half.x,  half.y),
	])
	body.add_child(vis)

	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	col.shape = box
	body.add_child(col)

	return body
