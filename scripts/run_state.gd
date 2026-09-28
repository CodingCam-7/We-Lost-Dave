extends Node

# RunState — autoload singleton (Project Settings → Autoload, name "RunState").
# Autoloads live outside the current scene, so they survive the scene reload
# that happens on death. Anything Dave should keep between runs goes here.
# Note: this is in-memory only — quitting the game still resets it.

var scrap:          int        = 0
var upgrade_levels: Dictionary = {}   # upgrade id -> times purchased

func get_level(id: String) -> int:
	return upgrade_levels.get(id, 0)
