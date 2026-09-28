class_name ItemEffects

# What happens when Dave presses F with an item in the active hotbar slot.
# use() returns true if the item should be used up (removed from the hotbar).
# Item data (names, kinds, lore text) lives in loot_table.gd.

const STIM_DURATION   := 8.0
const STIM_MULTIPLIER := 1.5
const STUN_RADIUS     := 220.0
const STUN_DURATION   := 3.0

static func use(id: String, player: Node) -> bool:
	var def := LootTable.get_def(id)
	if def.is_empty():
		return false

	# Memory fragments are never used up — F just shows the lore line
	if def["kind"] == "fragment":
		player.show_message(def["desc"], 5.0)
		return false

	match id:
		"med_gel":
			if not player.heal(1):
				player.show_message("Hull already intact.")
				return false
			player.show_message("Hull patched.")
		"speed_loader":
			if not player.instant_reload():
				player.show_message("Cylinder already full.")
				return false
			player.show_message("Cylinder loaded.")
		"stim_patch":
			player.apply_speed_boost(STIM_MULTIPLIER, STIM_DURATION)
			player.show_message("Your heart is racing.")
		"static_charge":
			var stunned := 0
			for enemy in player.get_tree().get_nodes_in_group("enemy"):
				if enemy.global_position.distance_to(player.global_position) <= STUN_RADIUS:
					enemy.stun(STUN_DURATION)
					stunned += 1
			player.show_message("Static discharge — %d stunned." % stunned)
	return true
