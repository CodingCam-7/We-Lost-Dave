extends CanvasLayer
class_name DeathScreen

# Narrative death screen — shown when Dave's hull hits 0.
# Pauses the game, fades to black, types out a cold system readout line by
# line, then waits for [R] to reload the run from the front gate.

const FADE_T        := 1.2    # seconds for the black fade-in
const LINE_DELAY    := 0.55   # pause between readout lines
const CHAR_DELAY    := 0.03   # typewriter speed per character
const TEXT_COLOR    := Color(0.75, 0.72, 0.62)
const DIM_COLOR     := Color(0.45, 0.43, 0.38)
const PROMPT_COLOR  := Color(0.85, 0.65, 0.10)

const READOUT := [
	"SIGNAL LOST",
	"SUBJECT: UNIDENTIFIED",
	"FRAGMENT INTEGRITY: 0%",
]

var _backdrop:     ColorRect
var _lines_box:    VBoxContainer
var _prompt_label: Label
var _can_restart   := false

func _ready() -> void:
	layer = 100  # draw above the HUD
	# Keep running while the rest of the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_build_ui()
	_play_sequence()

func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_lines_box = VBoxContainer.new()
	_lines_box.add_theme_constant_override("separation", 10)
	center.add_child(_lines_box)

	_prompt_label = _make_label("[R] REINITIALIZE", PROMPT_COLOR, 16)
	_prompt_label.modulate.a = 0.0

func _make_label(text: String, color: Color, size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", size)
	return lbl

func _play_sequence() -> void:
	# Fade to black
	var fade := create_tween()
	fade.tween_property(_backdrop, "color:a", 1.0, FADE_T)
	await fade.finished

	# Type out each readout line — first line larger, the rest dimmer
	for i in READOUT.size():
		var lbl := _make_label("", TEXT_COLOR if i == 0 else DIM_COLOR, 28 if i == 0 else 16)
		_lines_box.add_child(lbl)
		await _type_line(lbl, READOUT[i])
		await get_tree().create_timer(LINE_DELAY).timeout

	# Gap, then the restart prompt pulses in and out
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	_lines_box.add_child(spacer)
	_lines_box.add_child(_prompt_label)
	var pulse := create_tween().set_loops()
	pulse.tween_property(_prompt_label, "modulate:a", 1.0, 0.8)
	pulse.tween_property(_prompt_label, "modulate:a", 0.25, 0.8)
	_can_restart = true

func _type_line(lbl: Label, text: String) -> void:
	for c in text:
		lbl.text += c
		await get_tree().create_timer(CHAR_DELAY).timeout

func _unhandled_input(event: InputEvent) -> void:
	if not _can_restart:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_R:
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		# Reloading world.tscn resets everything, including Dave at the front gate
		get_tree().reload_current_scene()
