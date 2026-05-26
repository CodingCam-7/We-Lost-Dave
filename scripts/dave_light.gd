extends Node2D

const AMBIENT_ENERGY   := 0.7
const AMBIENT_SCALE    := 1.0   # ~128px soft glow radius

const CONE_BASE_ENERGY := 2.8
const CONE_FLICKER     := 0.08
const CONE_SCALE       := 2.5   # ~320px beam reach
const CONE_HALF_ANGLE  := 32.0  # degrees — 64° total beam width

var _cone: PointLight2D
var _detection_area: Area2D

func _ready() -> void:
	var ambient := PointLight2D.new()
	ambient.texture       = _radial_texture(128)
	ambient.texture_scale = AMBIENT_SCALE
	ambient.energy        = AMBIENT_ENERGY
	ambient.color         = Color(1.0, 0.95, 0.85)
	add_child(ambient)

	_cone = PointLight2D.new()
	_cone.texture       = _cone_texture(128, CONE_HALF_ANGLE)
	_cone.texture_scale = CONE_SCALE
	_cone.energy        = CONE_BASE_ENERGY
	_cone.color         = Color(0.9, 0.96, 1.0)  # cool flashlight white
	add_child(_cone)

	_detection_area = _build_detection_area()
	add_child(_detection_area)

func _process(_delta: float) -> void:
	var angle := (get_global_mouse_position() - global_position).angle()
	_cone.rotation           = angle
	_detection_area.rotation = angle
	_cone.energy = CONE_BASE_ENERGY + randf_range(-CONE_FLICKER, CONE_FLICKER)

# ── Detection area ─────────────────────────────────────────────────────────────
# Enemy scripts call get_overlapping_bodies() on this area each frame.
# If they appear in the list, they increment an exposure timer.
# At 1.0s exposure they become aware of Dave.

func _build_detection_area() -> Area2D:
	var area := Area2D.new()
	area.name = "DetectionCone"

	var col := CollisionPolygon2D.new()
	col.polygon = _cone_polygon(CONE_SCALE * 128.0, CONE_HALF_ANGLE)
	area.add_child(col)

	return area

func _cone_polygon(length: float, half_angle_deg: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	var steps := 10
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var a := deg_to_rad(lerp(-half_angle_deg, half_angle_deg, t))
		pts.append(Vector2(cos(a), sin(a)) * length)
	return pts

# ── Texture generators ─────────────────────────────────────────────────────────

func _radial_texture(radius: int) -> ImageTexture:
	var size := radius * 2
	var img  := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rf   := float(radius)
	for y in range(size):
		for x in range(size):
			var dx := x - radius
			var dy := y - radius
			var d  := sqrt(float(dx * dx + dy * dy))
			if d <= rf:
				var t := 1.0 - d / rf
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, t * t))
	return ImageTexture.create_from_image(img)

func _cone_texture(radius: int, half_angle_deg: float) -> ImageTexture:
	var size       := radius * 2
	var img        := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half_angle := deg_to_rad(half_angle_deg)
	var rf         := float(radius)
	for y in range(size):
		for x in range(size):
			var dx := x - radius
			var dy := y - radius
			if dx == 0 and dy == 0:
				img.set_pixel(x, y, Color.WHITE)
				continue
			var dist  : float = sqrt(float(dx * dx + dy * dy))
			var angle : float = absf(atan2(float(dy), float(dx)))
			if angle <= half_angle and dist <= rf:
				var alpha : float = (1.0 - dist / rf) * (1.0 - angle / half_angle)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(img)
