class_name Gate
extends Spikes
## An iron gate: a trap with other frames, whose bars block but never hurt. They block phantoms too, which
## pass through everything else. The bars reach a tile above the gate's own, so while they do, the gate
## stands and sorts with the player and enemies instead of lying on the floor.

# Frames of the strip where the bars stick up out of the gate's tile.
const FIRST_TALL_FRAME := 3
const LAST_TALL_FRAME := 11
const FLOOR_Z_INDEX := 1
const STANDING_Z_INDEX := 5


func _process(_delta: float) -> void:
	z_index = STANDING_Z_INDEX if frame >= FIRST_TALL_FRAME and frame <= LAST_TALL_FRAME else FLOOR_Z_INDEX
