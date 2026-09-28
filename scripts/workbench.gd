extends StaticBody2D

# Workbench — when Dave is close, E opens the salvage/upgrade panel.
# The panel itself (UI + upgrade list) lives in workbench_panel.gd.

const INTERACT_SIZE := Vector2(120, 80)  # a bit larger than the 80x36 bench body

func _ready() -> void:
	# Proximity area built in code (same pattern as item_drop.gd)
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 1
	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = INTERACT_SIZE
	col.shape = rect
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.register_interactable(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.unregister_interactable(self)

func get_prompt() -> String:
	return "[E]  Use workbench"

func interact(player: Node) -> void:
	var panel := WorkbenchPanel.new()
	panel.player = player
	# Added to the current scene so it's cleaned up if the scene reloads
	get_tree().current_scene.add_child(panel)
