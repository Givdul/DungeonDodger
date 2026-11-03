class_name Pit
extends AnimatedSprite2D
## A hole in the floor. A crumbling one starts as cracked floor and collapses
## shortly after the player or a spinner first steps on it.

@export var crumbles := false


func _ready() -> void:
	if not crumbles:
		frame = _last_frame()


## The walker is the player or a spinner. Both fall in with fall_into().
func step_on(walker) -> void:
	if is_open():
		walker.fall_into(global_position)
	elif not is_playing():
		play()


func is_open() -> bool:
	return frame == _last_frame()


func _last_frame() -> int:
	return sprite_frames.get_frame_count(animation) - 1
