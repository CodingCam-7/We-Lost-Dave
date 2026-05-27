extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
#  HOUSE — FIRST FLOOR
#
#  Origin (0, 0) = centre of Living Room.
#  Y increases southward.  X increases eastward.
#
#  STEP 1:  front yard · gate · path · porch · foyer · living room
#  STEP 2:  kitchen · mudroom · pantry · garage  (west wing)
#  Remaining rooms will be added in subsequent steps.
# ─────────────────────────────────────────────────────────────────────────────

const WALL_T := 24.0

const COLOR_WALL    := Color(0.22, 0.22, 0.22)
const COLOR_OUTDOOR := Color(0.10, 0.15, 0.08)   # dark grass
const COLOR_PATH    := Color(0.21, 0.19, 0.16)   # dark stone path / porch slab
const COLOR_FOYER   := Color(0.18, 0.14, 0.09)   # warm amber-dark
const COLOR_LIVING  := Color(0.15, 0.11, 0.07)   # warm brown-dark
const COLOR_KITCHEN := Color(0.13, 0.10, 0.07)   # warm amber-green
const COLOR_MUDROOM := Color(0.11, 0.10, 0.08)   # neutral dark
const COLOR_PANTRY  := Color(0.09, 0.08, 0.06)   # very dark storage
const COLOR_GARAGE  := Color(0.09, 0.09, 0.11)   # cold concrete grey

var _enemy_scene := preload("res://scenes/enemy.tscn")

func _ready() -> void:
	_build_darkness()
	_build_front_yard()
	_build_foyer()
	_build_living_room()
	_build_kitchen()
	_build_mudroom()
	_build_pantry()
	_build_garage()
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
#    east   → Dining Room   stub (step 3)
#    west   → Kitchen       gap y: -200 → -100
#    west   → Mudroom       gap y:   50 → 150
#    north  → exterior wall (backyard step later)

func _build_living_room() -> void:
	_floor_rect(Rect2(-300, -250, 600, 500), COLOR_LIVING)

	# North wall — full (exterior for now)
	_wall_h(-300, 300, -250)

	# East wall — full (Dining Room stub)
	_wall_v(-250, 250, 300)

	# West wall — gaps for Kitchen door (y:-200→-100) and Mudroom door (y:50→150)
	_wall_v(-250, -200, -300)
	_wall_v(-100,   50, -300)
	_wall_v( 150,  250, -300)

	# South wall — gap at x: -80 → 80 for Foyer door
	# (this also covers the foyer north-wall flanks at x: ±80 → ±120)
	_wall_h(-300, -80, 250)
	_wall_h(  80, 300, 250)

# ── Kitchen ────────────────────────────────────────────────────────────────────
#
#  x: -660 → -300   y: -380 → -50   (360 × 330)
#  Connections:
#    east  → Living Room  gap y: -200 → -100  (wall owned by LR)
#    south → Mudroom      gap x: -520 → -440

func _build_kitchen() -> void:
	_floor_rect(Rect2(-660, -380, 360, 330), COLOR_KITCHEN)

	# North wall — exterior
	_wall_h(-660, -300, -380)

	# West wall — exterior
	_wall_v(-380, -50, -660)

	# South wall (boundary with Mudroom) — door gap at x: -520 → -440
	_wall_h(-660, -520, -50)
	_wall_h(-440, -300, -50)

# ── Mudroom / Laundry ──────────────────────────────────────────────────────────
#
#  x: -630 → -300   y: -50 → 200   (330 × 250)
#  Connections:
#    north → Kitchen       gap x: -520 → -440  (owned by Kitchen)
#    east  → Living Room   gap y: 50 → 150     (owned by LR)
#    west  → Pantry        gap y: -30 → 30
#    west  → Garage        gap y: 80 → 160

func _build_mudroom() -> void:
	_floor_rect(Rect2(-630, -50, 330, 250), COLOR_MUDROOM)

	# South wall — exterior
	_wall_h(-630, -300, 200)

	# West wall — gaps for Pantry (y:-30→30) and Garage (y:80→160)
	_wall_v(-50, -30, -630)
	_wall_v(  30,  80, -630)
	_wall_v( 160, 200, -630)

# ── Pantry ─────────────────────────────────────────────────────────────────────
#
#  x: -820 → -630   y: -100 → 50   (190 × 150)
#  Connections:
#    east → Mudroom  gap y: -30 → 30  (wall owned by Mudroom)

func _build_pantry() -> void:
	_floor_rect(Rect2(-820, -100, 190, 150), COLOR_PANTRY)

	# North wall — exterior
	_wall_h(-820, -630, -100)

	# West wall — exterior
	_wall_v(-100, 50, -820)

	# South wall — exterior
	_wall_h(-820, -630, 50)

	# East wall — upper stub above Mudroom (y:-100→-50); Mudroom owns the rest
	_wall_v(-100, -50, -630)

# ── Garage ─────────────────────────────────────────────────────────────────────
#
#  x: -1260 → -630   y: 50 → 470   (630 × 420)
#  Connections:
#    east  → Mudroom    gap y: 80 → 160  (wall owned by Mudroom)
#    south → exterior   garage door gap x: -1060 → -840

func _build_garage() -> void:
	_floor_rect(Rect2(-1260, 50, 630, 420), COLOR_GARAGE)

	# North wall — exterior (Pantry south wall at y=50 covers x:-820→-630)
	_wall_h(-1260, -820, 50)

	# West wall — exterior
	_wall_v(50, 470, -1260)

	# South wall — garage door gap at x: -1060 → -840
	_wall_h(-1260, -1060, 470)
	_wall_h( -840,  -630, 470)

	# East wall below Mudroom — Mudroom owns y:50→200, Garage owns y:200→470
	_wall_v(200, 470, -630)

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
