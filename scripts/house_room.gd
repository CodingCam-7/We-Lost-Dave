extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
#  HOUSE — FIRST FLOOR
#
#  Origin (0, 0) = centre of Living Room.
#  Y increases southward.  X increases eastward.
#
#  STEP 1 (this file):  front yard · gate · path · porch · foyer · living room
#  Remaining rooms will be added in subsequent steps.
# ─────────────────────────────────────────────────────────────────────────────

const WALL_T := 24.0

const COLOR_WALL    := Color(0.22, 0.22, 0.22)
const COLOR_OUTDOOR := Color(0.10, 0.15, 0.08)   # dark grass
const COLOR_PATH    := Color(0.21, 0.19, 0.16)   # dark stone path / porch slab
const COLOR_FOYER   := Color(0.18, 0.14, 0.09)   # warm amber-dark
const COLOR_LIVING  := Color(0.15, 0.11, 0.07)   # warm brown-dark

var _enemy_scene := preload("res://scenes/enemy.tscn")

func _ready() -> void:
	_build_darkness()
	_build_front_yard()
	_build_foyer()
	_build_living_room()
	_spawn_enemies()
	_start_ambient()

# ── Darkness ───────────────────────────────────────────────────────────────────

func _build_darkness() -> void:
	var mod := CanvasModulate.new()
	mod.name  = "AmbientDark"
	mod.color = Color(0.0, 0.0, 0.05)
	add_child(mod)

# ── Front Yard · Gate · Path · Covered Porch ──────────────────────────────────
#
#  Property south fence:  y = 1100   gate opening at x: -90 → 90
#  Gate pillars:          x = ±115,  y ≈ 1058
#  Front path:            x: -90 → 90,    y: 590 → 1060   (180 × 470)
#  Covered porch slab:    x: -200 → 200,  y: 470 → 590    (400 × 120)
#  Side fences:           x = ±700,       y: 470 → 1100

func _build_front_yard() -> void:
	# Full outdoor ground (rendered first so path/porch overlay it)
	_floor_rect(Rect2(-700, 470, 1400, 630), COLOR_OUTDOOR)

	# Stone path up to porch
	_floor_rect(Rect2(-90, 590, 180, 470), COLOR_PATH)

	# Covered front porch slab
	_floor_rect(Rect2(-200, 470, 400, 120), COLOR_PATH)

	# Property south fence — gap at x: -90 → 90 for gate
	_wall_h(-700, -90, 1100)
	_wall_h(  90, 700, 1100)

	# Gate pillars
	add_child(_make_wall(Vector2(-115, 1058), Vector2(28, 84)))
	add_child(_make_wall(Vector2( 115, 1058), Vector2(28, 84)))

	# Property side fences (south portion — extended northward each step)
	_wall_v(470, 1100, -700)   # west
	_wall_v(470, 1100,  700)   # east

# ── Foyer ──────────────────────────────────────────────────────────────────────
#
#  x: -120 → 120   y: 250 → 470   (240 × 220)
#  Connections:
#    north  → Living Room  gap x: -80 → 80  (wall owned by _build_living_room)
#    south  → front door   gap x: -60 → 60

func _build_foyer() -> void:
	_floor_rect(Rect2(-120, 250, 240, 220), COLOR_FOYER)

	# East / west walls — full foyer height
	_wall_v(250, 470,  120)
	_wall_v(250, 470, -120)

	# South wall — front-door gap at x: -60 → 60
	_wall_h(-120, -60, 470)
	_wall_h(  60, 120, 470)

	# North wall is built by _build_living_room (shared boundary at y = 250)

# ── Living Room ────────────────────────────────────────────────────────────────
#
#  x: -300 → 300   y: -250 → 250   (600 × 500)
#  Connections:
#    south  → Foyer         gap x: -80 → 80
#    east   → Dining Room   stub (step 2)
#    west   → Kitchen       stub (step 2)
#    north  → exterior wall (backyard step later)

func _build_living_room() -> void:
	_floor_rect(Rect2(-300, -250, 600, 500), COLOR_LIVING)

	# North wall — full (exterior for now)
	_wall_h(-300, 300, -250)

	# East wall — full (Dining Room stub)
	_wall_v(-250, 250, 300)

	# West wall — full (Kitchen / Mudroom stub)
	_wall_v(-250, 250, -300)

	# South wall — gap at x: -80 → 80 for Foyer door
	# (this also covers the foyer north-wall flanks at x: ±80 → ±120)
	_wall_h(-300, -80, 250)
	_wall_h(  80, 300, 250)

# ── Enemies ────────────────────────────────────────────────────────────────────

func _spawn_enemies() -> void:
	for pos in [
		Vector2( 200,  130),   # living room — east corner
		Vector2(-180,  -90),   # living room — west area
	]:
		var enemy := _enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = pos

# ── Ambient Audio ──────────────────────────────────────────────────────────────

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

func _floor_rect(rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.color   = color
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
