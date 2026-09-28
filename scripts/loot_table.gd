class_name LootTable

# Every item that can drop, plus weighted random rolls.
# Items are referenced everywhere by their id (the dictionary key).
#
# kind:   "consumable" — used up with F from the active hotbar slot (see item_effects.gd)
#         "fragment"   — memory fragment; F reads its lore, never used up
# scrap:  how much scrap the item gives when salvaged at a workbench
# weight: relative drop chance — higher = more common

const COMMON   := 10
const UNCOMMON := 5
const RARE     := 2

const ITEMS := {
	# ── Consumables ──────────────────────────────────────────────────────────
	"med_gel": {
		"name": "Med-gel", "short": "MED-GEL", "kind": "consumable",
		"scrap": 1, "weight": COMMON, "color": Color(0.30, 0.90, 0.45, 0.95),
		"desc": "Restores 1 hull segment.",
	},
	"speed_loader": {
		"name": "Speed loader", "short": "LOADER", "kind": "consumable",
		"scrap": 1, "weight": COMMON, "color": Color(0.90, 0.80, 0.20, 0.95),
		"desc": "Instantly refills the cylinder.",
	},
	"stim_patch": {
		"name": "Stim patch", "short": "STIM", "kind": "consumable",
		"scrap": 2, "weight": UNCOMMON, "color": Color(1.00, 0.35, 0.30, 0.95),
		"desc": "Move faster for 8 seconds.",
	},
	"static_charge": {
		"name": "Static charge", "short": "CHARGE", "kind": "consumable",
		"scrap": 2, "weight": RARE, "color": Color(0.30, 0.55, 1.00, 0.95),
		"desc": "Stuns nearby enemies.",
	},

	# ── Memory fragments ─────────────────────────────────────────────────────
	"hospital_wristband": {
		"name": "Hospital wristband", "short": "WRISTBAND", "kind": "fragment",
		"scrap": 2, "weight": UNCOMMON, "color": Color(0.85, 0.85, 0.90, 0.95),
		"desc": "The name is smudged. You can make out a D.",
	},
	"cracked_photograph": {
		"name": "Cracked photograph", "short": "PHOTO", "kind": "fragment",
		"scrap": 2, "weight": UNCOMMON, "color": Color(0.70, 0.60, 0.45, 0.95),
		"desc": "A man standing at this house's front door. His face is torn away.",
	},
	"wedding_band": {
		"name": "Wedding band", "short": "RING", "kind": "fragment",
		"scrap": 3, "weight": RARE, "color": Color(0.95, 0.85, 0.55, 0.95),
		"desc": "It fits your finger perfectly.",
	},
	"voice_recorder": {
		"name": "Voice recorder", "short": "RECORDER", "kind": "fragment",
		"scrap": 3, "weight": RARE, "color": Color(0.70, 0.30, 1.00, 0.95),
		"desc": "\"...if you find this, don't trust the house. Don't trust—\" Static.",
	},
}

# Picks a random item id, weighted by each item's "weight".
static func roll() -> String:
	var total := 0
	for id in ITEMS:
		total += ITEMS[id]["weight"]
	var pick := randi() % total
	for id in ITEMS:
		pick -= ITEMS[id]["weight"]
		if pick < 0:
			return id
	return ITEMS.keys()[0]  # unreachable, keeps the parser happy

static func get_def(id: String) -> Dictionary:
	return ITEMS.get(id, {})

# The dictionary stored in the backpack/hotbar for one item.
static func make_item(id: String) -> Dictionary:
	var def := get_def(id)
	return {"id": id, "name": def["name"], "short": def["short"], "color": def["color"]}
