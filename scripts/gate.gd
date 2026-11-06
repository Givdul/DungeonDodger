class_name Gate
extends Spikes
## An iron gate: a trap with other frames, whose bars block but never hurt. The bars reach a tile above
## the gate's own, so they draw over a player standing behind them.

# Frames of the strip where the bars stick up out of the gate's tile.
const FIRST_TALL_FRAME := 3
const LAST_TALL_FRAME := 11
# One above coins and keys, which can lie behind the bars.
const OVER_ITEMS_Z_INDEX := 2
# One above the player's.
const OVER_PLAYER_Z_INDEX := 6

@onready var _player: Node2D = get_tree().get_first_node_in_group(&"Player")


func _process(_delta: float) -> void:
	if frame < FIRST_TALL_FRAME or frame > LAST_TALL_FRAME:
		z_index = 0
	elif _player.global_position.y < global_position.y:
		z_index = OVER_PLAYER_Z_INDEX
	else:
		z_index = OVER_ITEMS_Z_INDEX
