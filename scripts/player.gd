extends CharacterBody2D

# ── Movement ──────────────────────────────────────────────────────────────────
const SPEED        := 200.0
const ACCELERATION := 800.0
const FRICTION     := 600.0

# ── Health ────────────────────────────────────────────────────────────────────
const SEGMENT_W      := 22.0
const SEGMENT_H      := 10.0
const SEGMENT_GAP    := 5.0
const INVINCIBLE_T   := 0.8
const COLOR_HP_FULL  := Color(0.85, 0.60, 0.10)
const COLOR_HP_EMPTY := Color(0.18, 0.12, 0.04)
const COLOR_HIT      := Color(0.90, 0.15, 0.10)
const BASE_COLOR     := Color(0.109804, 1.0, 0.6, 1.0)

# ── Weapon ────────────────────────────────────────────────────────────────────
const CYLINDER_CAPACITY := 6
const FIRE_RATE         := 0.5
const RELOAD_TIME       := 2.75

# ── Inventory UI ──────────────────────────────────────────────────────────────
const SLOT_W   := 52
const SLOT_H   := 52
const SLOT_GAP := 6
const COL_SLOT_EMPTY    := Color(0.12, 0.12, 0.14, 0.90)
const COL_SLOT_FILLED   := Color(0.20, 0.18, 0.12, 0.92)
const COL_SLOT_SELECTED := Color(0.38, 0.30, 0.10, 0.95)
const COL_SLOT_ACTIVE   := Color(0.45, 0.35, 0.10, 0.95)
const COL_PANEL_BG      := Color(0.08, 0.08, 0.10, 0.88)

# ── State ─────────────────────────────────────────────────────────────────────
var _max_segments: int         = 3
var _current_hp:   int         = 3
var _hp_rects:     Array       = []
var _hud_canvas:   CanvasLayer = null
var _visual:       Polygon2D   = null
var _invincible:   float       = 0.0

var _ammo:         int   = CYLINDER_CAPACITY
var _fire_timer:   float = 0.0
var _reloading:    bool  = false
var _reload_timer: float = 0.0
var _ammo_label:   Label = null

var _key_count:    int   = 0
var _key_label:    Label = null

var _interactables: Array = []
var _prompt_label:  Label = null

# Backpack — Array of {"name": String, "color": Color} or null per slot
var _inventory:          Array = []
var _inventory_max:      int   = 4
var _backpack_open:      bool  = false
var _backpack_selected:  int   = -1
var _backpack_panel:     ColorRect = null
var _backpack_slots:     Array     = []   # ColorRect nodes
var _backpack_swatches:  Array     = []   # small ColorRect per slot
var _backpack_labels:    Array     = []   # Label per slot

# Hotbar — 3 slots
var _hotbar:             Array = [null, null, null]
var _hotbar_active:      int   = 0
var _hotbar_slots:       Array = []   # ColorRect nodes
var _hotbar_swatches:    Array = []
var _hotbar_labels:      Array = []

@onready var _bullet_scene     := preload("res://scenes/bullet.tscn")
@onready var _item_drop_scene  := preload("res://scenes/item_drop.tscn")
var _sfx_shot:   AudioStreamPlayer
var _sfx_reload: AudioStreamPlayer

# ── Init ──────────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("player")
	_visual = $Polygon2D
	_setup_audio()
	_setup_hud()

func _setup_audio() -> void:
	_sfx_shot = AudioStreamPlayer.new()
	_sfx_shot.volume_db = 4.0
	add_child(_sfx_shot)
	var s := _try_load_audio("res://assets/audio/sfx_gunshot.mp3")
	if s: _sfx_shot.stream = s

	_sfx_reload = AudioStreamPlayer.new()
	_sfx_reload.volume_db = -2.0
	add_child(_sfx_reload)
	var r := _try_load_audio("res://assets/audio/sfx_reload.ogg")
	if r: _sfx_reload.stream = r

# ── Process ───────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _invincible > 0.0:
		_invincible -= delta
	_handle_movement(delta)
	_handle_weapon(delta)
	if not _interactables.is_empty():
		_refresh_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	var k   := key.physical_keycode
	var h   := Input.is_physical_key_pressed(KEY_H)
	match k:
		KEY_E:       _try_interact()
		KEY_I:       _toggle_backpack()
		KEY_DELETE:  _drop_selected_item()
		KEY_1:
			if h: _equip_to_hotbar(0)
			else: _set_hotbar_active(0)
		KEY_2:
			if h: _equip_to_hotbar(1)
			else: _set_hotbar_active(1)
		KEY_3:
			if h: _equip_to_hotbar(2)
			else: _set_hotbar_active(2)

# ── Movement ──────────────────────────────────────────────────────────────────

func _handle_movement(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_axis("move_left",  "move_right"),
		Input.get_axis("move_up",    "move_down")
	)
	if input_dir.length() > 0:
		velocity = velocity.move_toward(input_dir.normalized() * SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()

# ── Weapon ────────────────────────────────────────────────────────────────────

func _handle_weapon(delta: float) -> void:
	if _reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_reloading = false
			_ammo      = CYLINDER_CAPACITY
		_update_ammo_label()
		return
	_fire_timer -= delta
	if Input.is_action_just_pressed("reload") or \
	   (Input.is_action_just_pressed("shoot") and _ammo == 0):
		_start_reload()
		return
	if Input.is_action_pressed("shoot") and _fire_timer <= 0.0 and _ammo > 0:
		_fire_timer  = FIRE_RATE
		_ammo       -= 1
		_spawn_bullet()
		_update_ammo_label()

func _start_reload() -> void:
	if _reloading or _ammo == CYLINDER_CAPACITY:
		return
	_reloading    = true
	_reload_timer = RELOAD_TIME
	if _sfx_reload.stream: _sfx_reload.play()
	_update_ammo_label()

func _spawn_bullet() -> void:
	var dir    := (get_global_mouse_position() - global_position).normalized()
	var bullet := _bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.init(global_position + dir * 20.0, dir)
	if _sfx_shot.stream:
		_sfx_shot.pitch_scale = randf_range(0.93, 1.07)
		_sfx_shot.play()

# ── HUD setup ─────────────────────────────────────────────────────────────────

func _setup_hud() -> void:
	_hud_canvas = CanvasLayer.new()
	_hud_canvas.layer = 10
	add_child(_hud_canvas)

	# HULL label + health segments — top left
	var hull_lbl := Label.new()
	hull_lbl.text     = "HULL"
	hull_lbl.position = Vector2(20, 16)
	hull_lbl.add_theme_color_override("font_color", Color(0.6, 0.55, 0.4))
	hull_lbl.add_theme_font_size_override("font_size", 13)
	_hud_canvas.add_child(hull_lbl)
	_build_hp_segments()

	# Key count
	_key_label = Label.new()
	_key_label.position = Vector2(20, 36)
	_key_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.10))
	_key_label.add_theme_font_size_override("font_size", 13)
	_hud_canvas.add_child(_key_label)

	# Interaction prompt — above ammo
	_prompt_label = Label.new()
	_prompt_label.position = Vector2(20, 612)
	_prompt_label.add_theme_color_override("font_color", Color(0.85, 0.80, 0.60))
	_prompt_label.add_theme_font_size_override("font_size", 15)
	_prompt_label.visible = false
	_hud_canvas.add_child(_prompt_label)

	# Ammo — bottom left
	_ammo_label = Label.new()
	_ammo_label.position = Vector2(20, 636)
	_ammo_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	_ammo_label.add_theme_font_size_override("font_size", 18)
	_hud_canvas.add_child(_ammo_label)

	# Hotbar + backpack — built after canvas exists
	var vp := get_viewport().get_visible_rect().size
	_build_hotbar(vp)
	_build_backpack(vp)

	_update_ammo_label()
	_update_key_label()
	_refresh_hotbar()

# ── HP segments ───────────────────────────────────────────────────────────────

func _build_hp_segments() -> void:
	for r in _hp_rects: r.queue_free()
	_hp_rects.clear()
	for i in range(_max_segments):
		var seg     := ColorRect.new()
		seg.size     = Vector2(SEGMENT_W, SEGMENT_H)
		seg.position = Vector2(60.0 + i * (SEGMENT_W + SEGMENT_GAP), 18.0)
		seg.color    = COLOR_HP_FULL if i < _current_hp else COLOR_HP_EMPTY
		_hud_canvas.add_child(seg)
		_hp_rects.append(seg)

# ── Hotbar ────────────────────────────────────────────────────────────────────

func _build_hotbar(vp: Vector2) -> void:
	var total_w := 3 * SLOT_W + 2 * SLOT_GAP
	var sx      := (vp.x - total_w) / 2.0
	var sy      := vp.y - SLOT_H - 12.0

	for i in range(3):
		var slot := _make_slot(Vector2(sx + i * (SLOT_W + SLOT_GAP), sy))
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(func(e, idx = i): _on_hotbar_clicked(idx, e))
		_hud_canvas.add_child(slot)
		_hotbar_slots.append(slot)

		var swatch := _make_swatch(slot)
		_hotbar_swatches.append(swatch)

		var lbl := _make_slot_label(slot)
		_hotbar_labels.append(lbl)

		# Slot number badge
		var num := Label.new()
		num.text     = str(i + 1)
		num.position = Vector2(SLOT_W - 14, SLOT_H - 17)
		num.add_theme_font_size_override("font_size", 11)
		num.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(num)

func _refresh_hotbar() -> void:
	for i in range(3):
		var item: Variant = _hotbar[i]
		var slot: ColorRect = _hotbar_slots[i]
		var sw:   ColorRect = _hotbar_swatches[i]
		var lbl:  Label     = _hotbar_labels[i]
		if item == null:
			slot.color  = COL_SLOT_ACTIVE if i == _hotbar_active else COL_SLOT_EMPTY
			sw.visible  = false
			lbl.text    = ""
		else:
			slot.color  = COL_SLOT_ACTIVE if i == _hotbar_active else COL_SLOT_FILLED
			sw.color    = item["color"]
			sw.visible  = true
			lbl.text    = item["name"]

func _set_hotbar_active(slot: int) -> void:
	_hotbar_active = slot
	_refresh_hotbar()

func _on_hotbar_clicked(idx: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
	   and event.button_index == MOUSE_BUTTON_LEFT:
		_set_hotbar_active(idx)

# ── Backpack ──────────────────────────────────────────────────────────────────

func _build_backpack(vp: Vector2) -> void:
	var cols    := 2
	var rows    := ceili(float(_inventory_max) / cols)
	var panel_w := cols * SLOT_W + (cols - 1) * SLOT_GAP + 16
	var panel_h := rows * SLOT_H + (rows - 1) * SLOT_GAP + 16
	var hotbar_y := vp.y - SLOT_H - 12.0
	var px := (vp.x - panel_w) / 2.0
	var py := hotbar_y - panel_h - 8.0

	_backpack_panel = ColorRect.new()
	_backpack_panel.size     = Vector2(panel_w, panel_h)
	_backpack_panel.position = Vector2(px, py)
	_backpack_panel.color    = COL_PANEL_BG
	_backpack_panel.visible  = false
	_backpack_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud_canvas.add_child(_backpack_panel)

	for i in range(_inventory_max):
		var col := i % cols
		var row := i / cols
		var lx  := 8.0 + col * (SLOT_W + SLOT_GAP)
		var ly  := 8.0 + row * (SLOT_H + SLOT_GAP)

		var slot := _make_slot(Vector2(lx, ly))
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(func(e, idx = i): _on_backpack_clicked(idx, e))
		_backpack_panel.add_child(slot)
		_backpack_slots.append(slot)

		var swatch := _make_swatch(slot)
		_backpack_swatches.append(swatch)

		var lbl := _make_slot_label(slot)
		_backpack_labels.append(lbl)

func _refresh_backpack() -> void:
	if _backpack_panel == null:
		return
	for i in range(_backpack_slots.size()):
		var slot:  ColorRect = _backpack_slots[i]
		var sw:    ColorRect = _backpack_swatches[i]
		var lbl:   Label     = _backpack_labels[i]
		var item: Variant    = _inventory[i] if i < _inventory.size() else null
		if item == null:
			slot.color = COL_SLOT_EMPTY
			sw.visible = false
			lbl.text   = ""
		else:
			slot.color = COL_SLOT_SELECTED if i == _backpack_selected else COL_SLOT_FILLED
			sw.color   = item["color"]
			sw.visible = true
			lbl.text   = item["name"]

func _toggle_backpack() -> void:
	_backpack_open = not _backpack_open
	_backpack_panel.visible  = _backpack_open
	if not _backpack_open:
		_backpack_selected = -1
		_refresh_backpack()

func _on_backpack_clicked(idx: int, event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	_backpack_selected = idx if (_backpack_selected != idx and idx < _inventory.size()) else -1
	_refresh_backpack()

func _equip_to_hotbar(slot: int) -> void:
	if _backpack_selected < 0 or _backpack_selected >= _inventory.size():
		return
	var item: Dictionary = _inventory[_backpack_selected]
	# Swap hotbar ↔ backpack slot
	if _hotbar[slot] != null:
		_inventory[_backpack_selected] = _hotbar[slot]
	else:
		_inventory.remove_at(_backpack_selected)
	_hotbar[slot]      = item
	_backpack_selected = -1
	_refresh_hotbar()
	_refresh_backpack()

func _drop_selected_item() -> void:
	if _backpack_selected < 0 or _backpack_selected >= _inventory.size():
		return
	var item: Dictionary = _inventory[_backpack_selected]
	_inventory.remove_at(_backpack_selected)
	_backpack_selected = -1

	var drop           := _item_drop_scene.instantiate()
	drop.item_name      = item["name"]
	drop._orb_color     = item["color"]
	get_parent().add_child(drop)
	drop.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	drop.launch(Vector2(randf_range(-120, 120), randf_range(-120, 120)))

	_refresh_backpack()
	_update_key_label()

# ── Slot helpers ──────────────────────────────────────────────────────────────

func _make_slot(pos: Vector2) -> ColorRect:
	var slot      := ColorRect.new()
	slot.size      = Vector2(SLOT_W, SLOT_H)
	slot.position  = pos
	slot.color     = COL_SLOT_EMPTY
	return slot

func _make_swatch(parent: ColorRect) -> ColorRect:
	var sw      := ColorRect.new()
	sw.size      = Vector2(12, 12)
	sw.position  = Vector2(4, 4)
	sw.visible   = false
	sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(sw)
	return sw

func _make_slot_label(parent: ColorRect) -> Label:
	var lbl := Label.new()
	lbl.position = Vector2(4, 18)
	lbl.size     = Vector2(SLOT_W - 8, SLOT_H - 22)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	lbl.clip_text    = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl

# ── Label updates ─────────────────────────────────────────────────────────────

func _update_ammo_label() -> void:
	if not _ammo_label:
		return
	if _reloading:
		var progress := 1.0 - (_reload_timer / RELOAD_TIME)
		var filled   := int(progress * 10)
		_ammo_label.text = "RELOADING  [" + "▓".repeat(filled) + "░".repeat(10 - filled) + "]"
	else:
		var pips := ""
		for i in range(CYLINDER_CAPACITY):
			pips += "● " if i < _ammo else "○ "
		_ammo_label.text = ".44 MAG   " + pips.strip_edges()

func _update_key_label() -> void:
	if _key_label:
		_key_label.text = "KEY  ×%d" % _key_count

# ── Interaction ───────────────────────────────────────────────────────────────

func register_interactable(node: Node) -> void:
	if not _interactables.has(node):
		_interactables.append(node)
	_refresh_prompt()

func unregister_interactable(node: Node) -> void:
	_interactables.erase(node)
	_refresh_prompt()

func _try_interact() -> void:
	_interactables = _interactables.filter(func(n): return is_instance_valid(n))
	if _interactables.is_empty():
		return
	var best:   Node  = _interactables[0]
	var best_d: float = global_position.distance_squared_to(best.global_position)
	for node: Node in _interactables:
		var d := global_position.distance_squared_to(node.global_position)
		if d < best_d:
			best   = node
			best_d = d
	best.interact(self)
	_refresh_prompt()

func _refresh_prompt() -> void:
	if not _prompt_label:
		return
	_interactables = _interactables.filter(func(n): return is_instance_valid(n))
	if _interactables.is_empty():
		_prompt_label.visible = false
		return
	var best:   Node  = _interactables[0]
	var best_d: float = global_position.distance_squared_to(best.global_position)
	for node: Node in _interactables:
		var d := global_position.distance_squared_to(node.global_position)
		if d < best_d:
			best   = node
			best_d = d
	_prompt_label.text    = best.get_prompt()
	_prompt_label.visible = true

# ── Inventory ─────────────────────────────────────────────────────────────────

func add_to_inventory(item: Dictionary) -> bool:
	if _inventory.size() >= _inventory_max:
		return false
	_inventory.append(item)
	_refresh_backpack()
	_update_key_label()
	return true

func add_key() -> void:
	_key_count += 1
	_update_key_label()

func use_key() -> bool:
	if _key_count <= 0:
		return false
	_key_count -= 1
	_update_key_label()
	return true

func upgrade_inventory() -> void:
	_inventory_max += 1
	# Rebuild backpack with new slot count
	for s in _backpack_slots:  s.queue_free()
	_backpack_slots.clear()
	_backpack_swatches.clear()
	_backpack_labels.clear()
	if _backpack_panel:
		_backpack_panel.queue_free()
	_build_backpack(get_viewport().get_visible_rect().size)
	_refresh_backpack()

# ── Health ────────────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if _invincible > 0.0:
		return
	_current_hp = max(0, _current_hp - amount)
	_invincible = INVINCIBLE_T
	_build_hp_segments()
	_flash_hit()
	if _current_hp == 0:
		_die()

func add_segment() -> void:
	_max_segments += 1
	_current_hp    = min(_current_hp + 1, _max_segments)
	_build_hp_segments()

func _die() -> void:
	# Added to the current scene (not root) so it's freed when the scene reloads
	get_tree().current_scene.add_child(DeathScreen.new())

func _flash_hit() -> void:
	if not is_instance_valid(_visual):
		return
	_visual.color = COLOR_HIT
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self):
		_visual.color = BASE_COLOR

# ── Audio util ────────────────────────────────────────────────────────────────

func _try_load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null
