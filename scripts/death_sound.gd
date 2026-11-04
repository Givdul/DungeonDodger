class_name DeathSound
extends AudioStreamPlayer2D
## An enemy's death sound. One blast can kill several enemies on the same frame,
## so each later death on that frame plays quieter, and the burst stays close to
## one death's loudness instead of stacking over the explosion.

const STACKED_DEATH_DB := -6.0

static var _frame := -1
static var _played_on_frame := 0


## Call once per death: it lowers this player's volume for good.
func play_death() -> void:
	var frame := Engine.get_process_frames()
	if frame != _frame:
		_frame = frame
		_played_on_frame = 0
	volume_db += STACKED_DEATH_DB * _played_on_frame
	_played_on_frame += 1
	play()
