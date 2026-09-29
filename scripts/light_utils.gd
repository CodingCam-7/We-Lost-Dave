class_name LightUtils

# Shared helpers for PointLight2D lamps (street lights, house lights, car lights).

static var _radial: GradientTexture2D = null

# Soft round glow: white in the centre fading to transparent at the edge.
# 256px wide, so texture_scale 1.0 ≈ 128px radius. Built once and reused.
static func radial_texture() -> GradientTexture2D:
	if _radial == null:
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 1, 1, 1))
		grad.set_color(1, Color(1, 1, 1, 0))
		_radial = GradientTexture2D.new()
		_radial.gradient  = grad
		_radial.fill      = GradientTexture2D.FILL_RADIAL
		_radial.fill_from = Vector2(0.5, 0.5)
		_radial.fill_to   = Vector2(1.0, 0.5)
		_radial.width     = 256
		_radial.height    = 256
	return _radial

static func make_light(color: Color, energy: float, scale: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture       = radial_texture()
	light.color         = color
	light.energy        = energy
	light.texture_scale = scale
	return light
