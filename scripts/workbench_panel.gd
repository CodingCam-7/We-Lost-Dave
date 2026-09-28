extends CanvasLayer
class_name WorkbenchPanel

# Workbench UI — salvage backpack items into scrap, spend scrap on upgrades.
# Pauses the game while open so Dave can't be hit at the bench.
#
# Controls:  S = salvage backpack   1-4 = buy upgrade   E / Esc = close

# Each upgrade costs base_cost + times already bought, up to max_level purchases
const UPGRADES := [
	{"id": "hull",   "name": "Reinforce hull", "desc": "+1 hull segment",       "base_cost": 3, "max_level": 3},
	{"id": "pack",   "name": "Expand pack",    "desc": "+1 backpack slot",      "base_cost": 2, "max_level": 4},
	{"id": "reload", "name": "Oil cylinder",   "desc": "-0.4s reload",          "base_cost": 2, "max_level": 3},
	{"id": "fire",   "name": "Hair trigger",   "desc": "-0.08s between shots",  "base_cost": 2, "max_level": 3},
]

const TITLE_COLOR  := Color(0.85, 0.65, 0.10)
const TEXT_COLOR   := Color(0.80, 0.75, 0.60)
const DIM_COLOR    := Color(0.40, 0.38, 0.34)
const SCRAP_COLOR  := Color(0.60, 0.65, 0.70)
const PANEL_BG     := Color(0.06, 0.06, 0.08, 0.95)

var player: Node = null   # set by workbench.gd before add_child()

var _scrap_label:   Label
var _status_label:  Label
var _upgrade_labels: Array = []   # one Label per UPGRADES entry
var _accepts_input  := false

func _ready() -> void:
	layer = 50  # above HUD (10), below death screen (100)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_build_ui()
	_refresh()
	# Skip the frame the panel opened on, so the same E press doesn't close it
	await get_tree().process_frame
	_accepts_input = true

func _build_ui() -> void:
	# Dim the world behind the panel
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.5)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var bg := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = DIM_COLOR
	style.set_border_width_all(1)
	style.set_content_margin_all(20)
	bg.add_theme_stylebox_override("panel", style)
	center.add_child(bg)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	bg.add_child(box)

	box.add_child(_make_label("WORKBENCH", TITLE_COLOR, 20))
	_scrap_label = _make_label("", SCRAP_COLOR, 15)
	box.add_child(_scrap_label)
	box.add_child(_spacer(6))
	box.add_child(_make_label("[S]  Salvage backpack  (+1 scrap per item)", TEXT_COLOR, 14))
	box.add_child(_spacer(6))

	for i in UPGRADES.size():
		var lbl := _make_label("", TEXT_COLOR, 14)
		box.add_child(lbl)
		_upgrade_labels.append(lbl)

	box.add_child(_spacer(6))
	_status_label = _make_label("", DIM_COLOR, 13)
	box.add_child(_status_label)
	box.add_child(_make_label("[E]  Close", DIM_COLOR, 13))

func _make_label(text: String, color: Color, size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", size)
	return lbl

func _spacer(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c

# ── State ─────────────────────────────────────────────────────────────────────

func _level(id: String) -> int:
	return RunState.get_level(id)

func _cost(upgrade: Dictionary) -> int:
	return upgrade["base_cost"] + _level(upgrade["id"])

func _refresh() -> void:
	_scrap_label.text = "SCRAP  ×%d" % player.get_scrap()
	for i in UPGRADES.size():
		var u: Dictionary = UPGRADES[i]
		var lvl := _level(u["id"])
		var lbl: Label = _upgrade_labels[i]
		var line := "[%d]  %-15s %-22s  %d/%d" % [i + 1, u["name"], u["desc"], lvl, u["max_level"]]
		if lvl >= u["max_level"]:
			lbl.text = line + "   MAXED"
			lbl.add_theme_color_override("font_color", DIM_COLOR)
		else:
			var cost := _cost(u)
			lbl.text = line + "   cost %d" % cost
			# Grey out what Dave can't afford right now
			var affordable: bool = player.get_scrap() >= cost
			lbl.add_theme_color_override("font_color", TEXT_COLOR if affordable else DIM_COLOR)

# ── Actions ───────────────────────────────────────────────────────────────────

func _salvage() -> void:
	var n: int = player.salvage_backpack()
	_status_label.text = "Nothing to salvage." if n == 0 else "Salvaged %d item(s)." % n

func _buy(index: int) -> void:
	var u: Dictionary = UPGRADES[index]
	var lvl := _level(u["id"])
	if lvl >= u["max_level"]:
		_status_label.text = "%s is already maxed." % u["name"]
		return
	if not player.spend_scrap(_cost(u)):
		_status_label.text = "Not enough scrap."
		return
	RunState.upgrade_levels[u["id"]] = lvl + 1
	player.apply_upgrade(u["id"])
	_status_label.text = "%s installed." % u["name"]

func _close() -> void:
	get_tree().paused = false
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not _accepts_input:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	get_viewport().set_input_as_handled()
	match event.physical_keycode:
		KEY_E, KEY_ESCAPE: _close(); return
		KEY_S: _salvage()
		KEY_1: _buy(0)
		KEY_2: _buy(1)
		KEY_3: _buy(2)
		KEY_4: _buy(3)
	_refresh()
