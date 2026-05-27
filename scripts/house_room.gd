extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
#  HOUSE — FIRST FLOOR
#
#  Origin (0, 0) = centre of Living Room.
#  Y increases southward.  X increases eastward.
#
#  STEP 1:  front yard · gate · path · porch · foyer · living room
#  STEP 2:  kitchen · mudroom · pantry · garage  (west wing)
#  STEP 3:  dining room (east wing) · study · bedroom · bathroom · closet (south)
#  STEP 4:  backyard · pool · tool shed
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
const COLOR_DINING  := Color(0.14, 0.11, 0.08)   # warm dark — near living room
const COLOR_STUDY   := Color(0.10, 0.09, 0.08)   # dim, intimate
const COLOR_BEDROOM := Color(0.12, 0.09, 0.10)   # slightly mauve-dark
const COLOR_BATHROOM := Color(0.10, 0.11, 0.12)  # cool blue-dark
const COLOR_CLOSET   := Color(0.08, 0.07, 0.07)   # very dark
const COLOR_BACKYARD := Color(0.08, 0.12, 0.06)   # dark outdoor grass
const COLOR_POOL     := Color(0.05, 0.10, 0.18)   # dark water
const COLOR_SHED     := Color(0.10, 0.09, 0.08)   # dark wood

var _enemy_scene     := preload("res://scenes/enemy.tscn")
var _chest_scene     := preload("res://scenes/chest.tscn")
var _workbench_scene := preload("res://scenes/workbench.tscn")

func _ready() -> void:
	_build_darkness()
	_build_front_yard()
	_build_foyer()
	_build_living_room()
	_build_kitchen()
	_build_mudroom()
	_build_pantry()
	_build_garage()
	_build_backyard()
	_build_pool()
	_build_tool_shed()
	_build_dining_room()
	_build_study()
	_build_bedroom()
	_build_bathroom()
	_build_closet()
	_spawn_enemies()
	_spawn_furniture()
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
#    east   → Bedroom      gap y: 300 → 400
#    west   → Study        gap y: 300 → 400

func _build_foyer() -> void:
	_floor_rect(Rect2(-120, 250, 240, 220), COLOR_FOYER)

	# East wall — gap for Bedroom door (y:300→400)
	_wall_v(250, 300,  120)
	_wall_v(400, 470,  120)

	# West wall — gap for Study door (y:300→400)
	_wall_v(250, 300, -120)
	_wall_v(400, 470, -120)

	# South wall — front-door gap at x: -60 → 60
	_wall_h(-120, -60, 470)
	_wall_h(  60, 120, 470)

	# North wall is built by _build_living_room (shared boundary at y = 250)

# ── Living Room ────────────────────────────────────────────────────────────────
#
#  x: -300 → 300   y: -250 → 250   (600 × 500)
#  Connections:
#    south  → Foyer         gap x: -80 → 80
#    east   → Dining Room   gap y: -150 → -50
#    west   → Kitchen       gap y: -200 → -100
#    west   → Mudroom       gap y:   50 → 150
#    north  → Backyard      gap x: -60 → 60

func _build_living_room() -> void:
	_floor_rect(Rect2(-300, -250, 600, 500), COLOR_LIVING)

	# North wall — gap for back door at x: -60 → 60
	_wall_h(-300, -60, -250)
	_wall_h(  60, 300, -250)

	# East wall — gap for Dining Room door (y:-150→-50)
	_wall_v(-250, -150, 300)
	_wall_v( -50,  250, 300)

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

# ── Backyard ───────────────────────────────────────────────────────────────────
#
#  x: -800 → 800   y: -750 → -250   (1600 × 500)
#  Connections:
#    south → Living Room  gap x: -60 → 60  (owned by LR)
#    west  → Tool Shed    corridor at x: -920→-800, y: -720→-650

func _build_backyard() -> void:
	_floor_rect(Rect2(-800, -750, 1600, 500), COLOR_BACKYARD)

	# North wall — exterior
	_wall_h(-800, 800, -750)

	# East wall — exterior
	_wall_v(-750, -250, 800)

	# South wall — exterior beyond house width (LR north wall covers x:-300→300)
	_wall_h(-800, -300, -250)
	_wall_h( 300,  800, -250)

	# West wall — gap for tool shed corridor (y:-720→-650)
	_wall_v(-750, -720, -800)
	_wall_v(-650, -250, -800)

	# Corridor floor and walls bridging the 120px gap to the tool shed
	_floor_rect(Rect2(-920, -720, 120, 70), COLOR_BACKYARD)
	_wall_h(-920, -800, -720)   # corridor north
	_wall_h(-920, -800, -650)   # corridor south

# ── Pool ───────────────────────────────────────────────────────────────────────
#
#  x: -250 → 250   y: -720 → -380   (500 × 340)
#  Impassable obstacle inset within the backyard

func _build_pool() -> void:
	_floor_rect(Rect2(-250, -720, 500, 340), COLOR_POOL)

	# Full perimeter — no entry, players walk around it
	_wall_h(-250, 250, -720)   # north
	_wall_h(-250, 250, -380)   # south
	_wall_v(-720, -380, -250)  # west
	_wall_v(-720, -380,  250)  # east

# ── Tool Shed ──────────────────────────────────────────────────────────────────
#
#  x: -1100 → -920   y: -750 → -590   (180 × 160)
#  Connections:
#    east → backyard corridor  gap y: -720 → -650

func _build_tool_shed() -> void:
	_floor_rect(Rect2(-1100, -750, 180, 160), COLOR_SHED)

	# North wall — exterior (collinear with backyard north at y=-750)
	_wall_h(-1100, -920, -750)

	# West wall — exterior
	_wall_v(-750, -590, -1100)

	# South wall — exterior
	_wall_h(-1100, -920, -590)

	# East wall — gap for corridor (y:-720→-650)
	_wall_v(-750, -720, -920)
	_wall_v(-650, -590, -920)

# ── Dining Room ────────────────────────────────────────────────────────────────
#
#  x: 300 → 760   y: -380 → 50   (460 × 430)
#  Connections:
#    west → Living Room  gap y: -150 → -50  (wall owned by LR)

func _build_dining_room() -> void:
	_floor_rect(Rect2(300, -380, 460, 430), COLOR_DINING)

	# North wall — exterior
	_wall_h(300, 760, -380)

	# East wall — exterior
	_wall_v(-380, 50, 760)

	# South wall — exterior
	_wall_h(300, 760, 50)

	# West wall owned by Living Room

# ── Study ──────────────────────────────────────────────────────────────────────
#
#  x: -420 → -120   y: 250 → 560   (300 × 310)
#  Connections:
#    east → Foyer  gap y: 300 → 400  (wall owned by Foyer)

func _build_study() -> void:
	_floor_rect(Rect2(-420, 250, 300, 310), COLOR_STUDY)

	# North wall — exterior west of LR (LR south wall covers x:-300→-120)
	_wall_h(-420, -300, 250)

	# West wall — exterior
	_wall_v(250, 560, -420)

	# South wall — exterior
	_wall_h(-420, -120, 560)

	# East wall below Foyer (Foyer owns y:250→470 with door gap; Study owns below)
	_wall_v(470, 560, -120)

# ── Bedroom ────────────────────────────────────────────────────────────────────
#
#  x: 120 → 500   y: 250 → 570   (380 × 320)
#  Connections:
#    west → Foyer     gap y: 300 → 400  (wall owned by Foyer)
#    east → Bathroom  gap y: 280 → 360
#    east → Closet    gap y: 460 → 530

func _build_bedroom() -> void:
	_floor_rect(Rect2(120, 250, 380, 320), COLOR_BEDROOM)

	# North wall — exterior east of LR (LR south wall covers x:80→300)
	_wall_h(300, 500, 250)

	# South wall — exterior
	_wall_h(120, 500, 570)

	# West wall below Foyer (Foyer owns y:250→470 with door gap; Bedroom owns below)
	_wall_v(470, 570, 120)

	# East wall — gaps for Bathroom (y:280→360) and Closet (y:460→530)
	_wall_v(250, 280, 500)
	_wall_v(360, 460, 500)
	_wall_v(530, 570, 500)

# ── Bathroom ───────────────────────────────────────────────────────────────────
#
#  x: 500 → 710   y: 250 → 430   (210 × 180)
#  Connections:
#    west → Bedroom  gap y: 280 → 360  (wall owned by Bedroom)
#    south → Closet  gap x: 540 → 610

func _build_bathroom() -> void:
	_floor_rect(Rect2(500, 250, 210, 180), COLOR_BATHROOM)

	# North wall — exterior
	_wall_h(500, 710, 250)

	# East wall — exterior
	_wall_v(250, 430, 710)

	# South wall — gap for Closet door at x: 540 → 610
	_wall_h(500, 540, 430)
	_wall_h(610, 710, 430)

	# West wall owned by Bedroom

# ── Closet ─────────────────────────────────────────────────────────────────────
#
#  x: 500 → 630   y: 430 → 570   (130 × 140)
#  Connections:
#    north → Bathroom  gap x: 540 → 610  (wall owned by Bathroom)
#    west  → Bedroom   gap y: 460 → 530  (wall owned by Bedroom)

func _build_closet() -> void:
	_floor_rect(Rect2(500, 430, 130, 140), COLOR_CLOSET)

	# East wall — exterior
	_wall_v(430, 570, 630)

	# South wall — exterior
	_wall_h(500, 630, 570)

	# North wall owned by Bathroom; west wall owned by Bedroom

# ── Enemies ────────────────────────────────────────────────────────────────────

func _spawn_enemies() -> void:
	for pos in [
		Vector2( 200,  130),   # living room — east corner
		Vector2(-180,  -90),   # living room — west area
		Vector2(-480, -200),   # kitchen
		Vector2(-540,  100),   # mudroom
		Vector2(-950,  250),   # garage
		Vector2(-720,  -25),   # pantry
		Vector2(  40,  360),   # foyer
		Vector2( 300,  820),   # front yard
	]:
		var enemy := _enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = pos

# ── Furniture ──────────────────────────────────────────────────────────────────

func _spawn_furniture() -> void:
	for pos in [
		Vector2(-580, -340),   # kitchen   — north-west corner
		Vector2( 690, -300),   # dining    — north-east corner
		Vector2(-370,  510),   # study     — south-west corner
		Vector2( 310,  520),   # bedroom   — south corner
		Vector2(-1150, 400),   # garage    — far corner
		Vector2(-1010, -640),  # tool shed — inside
	]:
		var chest := _chest_scene.instantiate()
		add_child(chest)
		chest.global_position = pos

	for pos in [
		Vector2(-850,  180),   # garage — north wall
		Vector2(-230,  490),   # study  — south wall desk
		Vector2(-390, -300),   # kitchen — counter
	]:
		var bench := _workbench_scene.instantiate()
		add_child(bench)
		bench.global_position = pos

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
