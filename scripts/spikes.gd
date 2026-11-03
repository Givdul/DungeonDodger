extends AnimatedSprite2D
## A floor trap whose spikes rise and sink on a loop. Hurts the player while they're up.

# Frames of the strip where the spikes are out.
const FIRST_UP_FRAME := 7
const LAST_UP_FRAME := 10


func _ready() -> void:
	# A random phase keeps a row of traps from rising in lockstep.
	frame = randi() % sprite_frames.get_frame_count(animation)
	play()


func step_on(player) -> void:
	if frame >= FIRST_UP_FRAME and frame <= LAST_UP_FRAME:
		player.take_damage()
