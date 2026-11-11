class_name Heroes
## The hero skins, how each one unlocks, and the SpriteFrames the player wears them with.
## Each skin's atlas comes from export.py: one row per entry in ROWS, frames FRAME_SIZE apart.

const FRAME_SIZE := Vector2i(16, 20)

# The atlas rows, top to bottom, as export.py writes them.
enum Row { IDLE_DOWN, IDLE_RIGHT, IDLE_UP, IDLE_LEFT, RUN_DOWN, RUN_RIGHT, RUN_UP, RUN_LEFT,
	HIT_DOWN, HIT_RIGHT, HIT_UP, HIT_LEFT, FALL, DEATH }

# The player's animations: atlas row, frame count, frames per second, and whether it loops.
const ANIMATIONS := {
	&"idle": [Row.IDLE_DOWN, 6, 6.0, true],
	&"run_down": [Row.RUN_DOWN, 6, 10.0, true],
	&"run_right": [Row.RUN_RIGHT, 6, 10.0, true],
	&"run_up": [Row.RUN_UP, 6, 10.0, true],
	&"run_left": [Row.RUN_LEFT, 6, 10.0, true],
	&"hit_down": [Row.HIT_DOWN, 3, 10.0, false],
	&"hit_right": [Row.HIT_RIGHT, 3, 10.0, false],
	&"hit_up": [Row.HIT_UP, 3, 10.0, false],
	&"hit_left": [Row.HIT_LEFT, 3, 10.0, false],
	&"fall": [Row.FALL, 6, 10.0, false],
	&"death": [Row.DEATH, 10, 10.0, false],
}

const DEFAULT := "original"

# Crystal prices. First-pass numbers: the casual bot banks about 97 crystals a run.
const PRICES := {
	100: ["sunny", "copper", "ranger", "rogue", "pirate", "cat", "monk", "bee"],
	300: ["knight", "witch", "viking", "necromancer", "pumpkin", "frost_mage", "fox", "bear_hood", "owl",
		"druid", "jester", "ronin", "gingerbread", "bard"],
	750: ["vampire", "plague_doctor", "executioner", "mushroom", "demon", "cultist", "golem"],
	1500: ["candle_head", "ember", "ice_spirit"],
}

# Skins earned by reaching a goal in one of Progress's stats.
const ACHIEVEMENTS := {
	"royal": {stat = "best_run_crystals", goal = 100, text = "Get 100 crystals in one run"},
	"golden_statue": {stat = "best_run_crystals", goal = 250, text = "Get 250 crystals in one run"},
	"ghost": {stat = "best_run_seconds", goal = 180, text = "Survive 3 minutes in one run"},
	"shadow": {stat = "best_unhit_seconds", goal = 60, text = "Survive 60s without a hit"},
	"zombie": {stat = "deaths", goal = 25, text = "Die 25 times"},
	"skeleton": {stat = "deaths", goal = 100, text = "Die 100 times"},
	"frog": {stat = "holes", goal = 10, text = "Fall into 10 holes"},
	"slime_kid": {stat = "crystals", goal = 1000, text = "Get 1000 crystals in all"},
	"angel": {stat = "potions", goal = 10, text = "Drink 10 potions"},
	"mummy": {stat = "chests", goal = 10, text = "Open 10 chests"},
	"bucket_knight": {stat = "hits", goal = 100, text = "Take 100 hits"},
	"lich": {stat = "heroes", goal = 30, text = "Unlock 30 heroes"},
}

# Every skin in the HEROES grid's order, by atlas file name and shown name.
const SKINS: Array[Array] = [
	["original", "Original"], ["ranger", "Ranger"], ["knight", "Knight"], ["witch", "Witch"],
	["rogue", "Rogue"], ["viking", "Viking"], ["necromancer", "Necromancer"], ["royal", "Royal"],
	["pumpkin", "Pumpkin"], ["frost_mage", "Frost Mage"], ["pirate", "Pirate"], ["sunny", "Sunny"],
	["copper", "Copper"], ["skeleton", "Skeleton"], ["zombie", "Zombie"], ["mummy", "Mummy"],
	["vampire", "Vampire"], ["ghost", "Ghost"], ["lich", "Lich"], ["plague_doctor", "Plague Doctor"],
	["executioner", "Executioner"], ["frog", "Frog"], ["cat", "Cat"], ["fox", "Fox"],
	["bear_hood", "Bear Hood"], ["bee", "Bee"], ["mushroom", "Mushroom"], ["slime_kid", "Slime Kid"],
	["owl", "Owl"], ["druid", "Druid"], ["demon", "Demon"], ["angel", "Angel"], ["ember", "Ember"],
	["ice_spirit", "Ice Spirit"], ["shadow", "Shadow"], ["golden_statue", "Golden Statue"],
	["cultist", "Cultist"], ["ronin", "Ronin"], ["monk", "Monk"], ["jester", "Jester"], ["bard", "Bard"],
	["bucket_knight", "Bucket Knight"], ["candle_head", "Candle Head"], ["gingerbread", "Gingerbread"],
	["golem", "Golem"],
]


static func ids() -> Array:
	return SKINS.map(func(skin: Array) -> String: return skin[0])


static func display_name(id: String) -> String:
	for skin in SKINS:
		if skin[0] == id:
			return skin[1]
	return id


## How the skin unlocks: {kind = "free"}, {kind = "crystals", price = ...} or
## {kind = "achievement", stat = ..., goal = ..., text = ...}.
static func unlock_rule(id: String) -> Dictionary:
	if id == DEFAULT:
		return {kind = "free"}
	for price: int in PRICES:
		if id in PRICES[price]:
			return {kind = "crystals", price = price}
	var rule: Dictionary = ACHIEVEMENTS[id].duplicate()
	rule.kind = "achievement"
	return rule


static func atlas(id: String) -> Texture2D:
	return load("res://assets/sprites/skins/%s.png" % id)


## One frame of the skin standing still, facing down.
static func portrait(id: String) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = atlas(id)
	frame.region = Rect2(Vector2.ZERO, FRAME_SIZE)
	return frame


static func sprite_frames(id: String) -> SpriteFrames:
	var texture := atlas(id)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation: StringName in ANIMATIONS:
		var row: int = ANIMATIONS[animation][0]
		frames.add_animation(animation)
		frames.set_animation_speed(animation, ANIMATIONS[animation][2])
		frames.set_animation_loop(animation, ANIMATIONS[animation][3])
		for column in ANIMATIONS[animation][1]:
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(Vector2(column, row) * Vector2(FRAME_SIZE), FRAME_SIZE)
			frames.add_frame(animation, frame)
	return frames
