extends RefCounted

const MAP_WIDTH := 20
const MAP_HEIGHT := 10
const MAP_TILE_COUNT := MAP_WIDTH * MAP_HEIGHT
const TILE_SOURCE_ID := 0
const PLAYER_OWNER := "player"
const NEUTRAL_OWNER := "neutral"
const ICON_GRID_SIZE := Vector2i(3, 3)
const BUILDING_ICON_DISPLAY_SIZE := Vector2(64, 64)

const BUILDING_ICONS := {
	"castle": Vector2i(0, 0),
	"village": Vector2i(1, 0),
	"mine": Vector2i(2, 0),
	"farm": Vector2i(0, 1),
	"fishing": Vector2i(1, 1),
	"sawmill": Vector2i(2, 1),
}

const BUILDING_LABELS := {
	"castle": "Castle",
	"village": "Village",
	"mine": "Mine",
	"farm": "Farm",
	"fishing": "Fishing",
	"sawmill": "Sawmill",
}

const TERRAIN_ATLAS_COORDS := {
	"grass": Vector2i(0, 0),
	"forest": Vector2i(1, 0),
	"mountain": Vector2i(2, 0),
	"lake": Vector2i(3, 0),
	"desert": Vector2i(0, 1),
	"rocks": Vector2i(1, 1),
	"swamp": Vector2i(2, 1),
	"wheat": Vector2i(3, 1),
	"silver": Vector2i(0, 2),
	"gold": Vector2i(1, 2),
}

const TERRAIN_LABELS := {
	"grass": "Field of grass",
	"wheat": "Field of wheat",
	"forest": "Field of forest",
	"rocks": "Field of rocks",
	"mountain": "Field of mountain",
	"lake": "Field of lake",
	"gold": "Field of gold",
	"silver": "Field of silver",
	"desert": "Field of desert",
	"swamp": "Field of swamp",
}

const TERRAIN_WEIGHTS := [
	{"terrain": "grass", "weight": 45},
	{"terrain": "forest", "weight": 15},
	{"terrain": "lake", "weight": 10},
	{"terrain": "wheat", "weight": 13},
	{"terrain": "swamp", "weight": 6},
	{"terrain": "rocks", "weight": 8},
	{"terrain": "mountain", "weight": 5},
	{"terrain": "silver", "weight": 4},
	{"terrain": "gold", "weight": 2},
]

const MINEABLE_TERRAINS := ["rocks", "silver", "gold"]
const RESOURCE_TERRAINS := ["rocks", "silver", "gold"]

const ALLOWED_BUILDINGS_BY_TERRAIN := {
	"grass": ["village", "castle"],
	"wheat": ["farm"],
	"forest": ["sawmill"],
	"lake": ["fishing"],
	"gold": ["mine"],
	"silver": ["mine"],
	"rocks": ["mine"],
	"swamp": [],
	"mountain": [],
	"desert": [],
}

const MAX_BUILDINGS_BY_TERRAIN := {
	"grass": 3,
}

const STARTER_BUILDINGS := ["castle", "village", "village"]
