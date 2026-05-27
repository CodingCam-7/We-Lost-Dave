extends Node2D

const WALL_T := 24.0
const HALF_C := 60.0   # half of 120px corridor width

const COLOR_FLOOR     := Color("#2a2a2a")
const COLOR_WALL      := Color("#3a3a3a")
const COLOR_WORKBENCH := Color(0.62, 0.44, 0.14)
const COLOR_CASEBOARD := Color(0.14, 0.30, 0.62)
const COLOR_REST      := Color(0.28, 0.52, 0.28)
const COLOR_STASH     := Color(0.44, 0.44, 0.44)
const COLOR_CHEST     := Color(0.62, 0.44, 0.08)

var _enemy_scene := preload("res://scenes/enemy.tscn")

func _ready() -> void:
	_build_darkness()
	_build_layout()
	_place_stations()
	_place_chests()
	_spawn_enemies()
	_start_ambient()

# ── Darkness ───────────────────────────────────────────────────────────────────

func _build_darkness() -> void:
	var mod := CanvasModulate.new()
	mod.name  = "AmbientDark"
	mod.color = Color(0.0, 0.0, 0.05)
	add_child(mod)

# ── Layout ─────────────────────────────────────────────────────────────────────
#
#  Hub:     600×500  centred on origin
#  Study:   320×280  north  (y: -680 → -400)
#  Kitchen: 280×280  east   (x:  450 →  730)
#  Bedroom: 280×280  west   (x: -730 → -450)
#  Garage:  320×280  south  (y:  400 →  680)
#  Corridors: 120px wide, 150px long, connecting each room to the hub

func _build_layout() -> void:
	_build_hub()
	_build_corridor(Rect2(-HALF_C, -400,    HALF_C * 2, 150), false)  # north
	_build_study()
	_build_corridor(Rect2( 300,    -HALF_C, 150, HALF_C * 2), true)   # east
	_build_kitchen()
	_build_corridor(Rect2(-450,    -HALF_C, 150, HALF_C * 2), true)   # west
	_build_bedroom()
	_build_corridor(Rect2(-HALF_C,  250,    HALF_C * 2, 150), false)  # south
	_build_garage()

func _build_hub() -> void:
	_floor_rect(Rect2(-300, -250, 600, 500))
	_wall_h(-300,    -HALF_C, -250);  _wall_h( HALF_C,  300, -250)  # top
	_wall_h(-300,    -HALF_C,  250);  _wall_h( HALF_C,  300,  250)  # bottom
	_wall_v(-250,    -HALF_C, -300);  _wall_v( HALF_C,  250, -300)  # left
	_wall_v(-250,    -HALF_C,  300);  _wall_v( HALF_C,  250,  300)  # right

func _build_corridor(rect: Rect2, horizontal: bool) -> void:
	_floor_rect(rect)
	if horizontal:
		_wall_h(rect.position.x, rect.end.x, rect.position.y)
		_wall_h(rect.position.x, rect.end.x, rect.end.y)
	else:
		_wall_v(rect.position.y, rect.end.y, rect.position.x)
		_wall_v(rect.position.y, rect.end.y, rect.end.x)

func _build_study() -> void:
	_floor_rect(Rect2(-160, -680, 320, 280))
	_wall_h(-160,    160,    -680)                             # top — full
	_wall_v(-680,   -400,   -160);  _wall_v(-680, -400, 160)  # sides — full
	_wall_h(-160,   -HALF_C, -400); _wall_h(HALF_C, 160, -400) # bottom — gapped

func _build_kitchen() -> void:
	_floor_rect(Rect2(450, -140, 280, 280))
	_wall_h( 450,  730, -140);  _wall_h( 450,  730, 140)     # top/bottom — full
	_wall_v(-140,  140,  730)                                  # right — full
	_wall_v(-140, -HALF_C, 450); _wall_v(HALF_C, 140, 450)   # left — gapped

func _build_bedroom() -> void:
	_floor_rect(Rect2(-730, -140, 280, 280))
	_wall_h(-730, -450, -140);  _wall_h(-730, -450, 140)     # top/bottom — full
	_wall_v(-140,  140, -730)                                  # left — full
	_wall_v(-140, -HALF_C, -450); _wall_v(HALF_C, 140, -450) # right — gapped

func _build_garage() -> void:
	_floor_rect(Rect2(-160, 400, 320, 280))
	_wall_h(-160,  160,  680)                                  # bottom — full
	_wall_v( 400,  680, -160);  _wall_v(400, 680, 160)        # sides — full
	_wall_h(-160, -HALF_C, 400); _wall_h(HALF_C, 160, 400)   # top — gapped

# ── Stations ───────────────────────────────────────────────────────────────────

func _place_stations() -> void:
	_make_station(Vector2(  0, -560), Vector2(80, 40), COLOR_CASEBOARD, "case_board")
	_make_station(Vector2(590,    0), Vector2(50, 70), COLOR_WORKBENCH, "workbench")
	_make_station(Vector2(-590,   0), Vector2(90, 50), COLOR_REST,      "rest_point")
	_make_station(Vector2(  0,  560), Vector2(70, 50), COLOR_STASH,     "stash")

func _make_station(center: Vector2, size: Vector2, color: Color, station_id: String) -> void:
	var body := StaticBody2D.new()
	body.name = station_id
	body.position = center
	body.add_to_group("station")

	var half := size / 2.0
	var vis  := Polygon2D.new()
	vis.color   = color
	vis.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2( half.x,  half.y), Vector2(-half.x, half.y),
	])
	body.add_child(vis)

	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size  = size
	col.shape = box
	body.add_child(col)
	add_child(body)

# ── Chests ─────────────────────────────────────────────────────────────────────

func _place_chests() -> void:
	for pos in [
		Vector2(-240,  200),  # hub SW corner
		Vector2( 240, -200),  # hub NE corner
		Vector2(  80, -630),  # study
		Vector2( 680,  100),  # kitchen
		Vector2(-680, -100),  # bedroom
		Vector2( 100,  630),  # garage
	]:
		_make_chest(pos)

func _make_chest(pos: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "Chest"
	body.position = pos
	body.add_to_group("chest")

	var vis := Polygon2D.new()
	vis.color   = COLOR_CHEST
	vis.polygon = PackedVector2Array([
		Vector2(-16, -11), Vector2(16, -11),
		Vector2( 16,  11), Vector2(-16,  11),
	])
	body.add_child(vis)

	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size  = Vector2(32, 22)
	col.shape = box
	body.add_child(col)
	add_child(body)

# ── Enemies ────────────────────────────────────────────────────────────────────

func _spawn_enemies() -> void:
	for pos in [
		Vector2( 240,  180),  # hub — far corner
		Vector2(-100, -500),  # study
		Vector2( 640,    0),  # kitchen
		Vector2(-640,    0),  # bedroom
		Vector2(   0,  530),  # garage
		Vector2(  90,  610),  # garage — second lurker
	]:
		var enemy := _enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = pos

# ── Ambient audio ──────────────────────────────────────────────────────────────

func _start_ambient() -> void:
	var stream := _try_load_audio("res://assets/audio/ambient_house.ogg")
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream    = stream
	player.volume_db = -14.0
	player.finished.connect(player.play)
	add_child(player)
	player.play()

# ── Primitives ─────────────────────────────────────────────────────────────────

func _floor_rect(rect: Rect2) -> void:
	var poly := Polygon2D.new()
	poly.color   = COLOR_FLOOR
	poly.z_index = -1
	poly.polygon = PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])
	add_child(poly)

func _wall_h(x1: float, x2: float, y: float) -> void:
	if abs(x2 - x1) < 1.0:
		return
	add_child(_make_wall(Vector2((x1 + x2) / 2.0, y), Vector2(abs(x2 - x1), WALL_T)))

func _wall_v(y1: float, y2: float, x: float) -> void:
	if abs(y2 - y1) < 1.0:
		return
	add_child(_make_wall(Vector2(x, (y1 + y2) / 2.0), Vector2(WALL_T, abs(y2 - y1))))

func _make_wall(center: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center

	var half := size / 2.0
	var vis  := Polygon2D.new()
	vis.color   = COLOR_WALL
	vis.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2( half.x,  half.y), Vector2(-half.x, half.y),
	])
	body.add_child(vis)

	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size  = size
	col.shape = box
	body.add_child(col)
	return body

func _try_load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null
