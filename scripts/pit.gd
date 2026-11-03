extends AnimatedSprite2D
## A hole in the floor. A crumbling one starts as cracked floor and collapses
## shortly after the player first steps on it.

@export var crumbles := false


func _ready() -> void:
	if not crumbles:
		frame = _last_frame()


func step_on(player) -> void:
	if frame == _last_frame():
		player.die(&"fall")
	elif not is_playing():
		play()


func _last_frame() -> int:
	return sprite_frames.get_frame_count(animation) - 1
