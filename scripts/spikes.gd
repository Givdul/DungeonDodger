class_name Spikes
extends AnimatedSprite2D
## A floor trap whose spikes rest, warn, then rise and sink on a loop. Raised, they are solid to the player
## and to spinners, and hurt only a player they rise under.
## The rest and the warning are long frames in the SpriteFrames, so a cycle is not evenly split by frame.

# Frames of the strip where the spikes are out.
const FIRST_UP_FRAME := 7
const LAST_UP_FRAME := 10

# Whether the player can still be hurt by this rise.
var _rise_hurts := false

@onready var _solid_shape: CollisionShape2D = $Solid/CollisionShape2D
# Sees the player and spinners. Its shape is smaller than the solid's, so a body stopped against the
# raised spikes doesn't count as standing on them.
@onready var _occupants: Area2D = $Occupants


func _ready() -> void:
	# A random phase keeps a row of traps from rising in lockstep. It is random over time, not over
	# frames, so the long rest gets its share of the starts.
	var start := _frame_at(randf() * _cycle_seconds())
	set_frame_and_progress(int(start.x), start.y)
	frame_changed.connect(_on_frame_changed)
	play()


# Raised spikes turn solid once nothing stands on them, so whoever they rose under can walk off.
func _physics_process(_delta: float) -> void:
	if not _is_up_frame(frame):
		_solid_shape.disabled = true
	elif _solid_shape.disabled and not _occupants.has_overlapping_bodies():
		_solid_shape.disabled = false


func _on_frame_changed() -> void:
	_rise_hurts = frame == FIRST_UP_FRAME


## Called every physics frame the player's feet are on the cell. Only the rise hurts.
func step_on(player) -> void:
	if _rise_hurts:
		_rise_hurts = false
		player.take_damage()


## Whether the spikes are up after this many seconds, if the trap keeps playing.
func is_up_in(seconds: float) -> bool:
	var now := _seconds_into_cycle() + seconds
	return _is_up_frame(int(_frame_at(fposmod(now, _cycle_seconds())).x))


func _is_up_frame(index: int) -> bool:
	return index >= FIRST_UP_FRAME and index <= LAST_UP_FRAME


func _frame_seconds(index: int) -> float:
	return sprite_frames.get_frame_duration(animation, index) / sprite_frames.get_animation_speed(animation)


func _cycle_seconds() -> float:
	var total := 0.0
	for index in sprite_frames.get_frame_count(animation):
		total += _frame_seconds(index)
	return total


func _seconds_into_cycle() -> float:
	var elapsed := frame_progress * _frame_seconds(frame)
	for index in frame:
		elapsed += _frame_seconds(index)
	return elapsed


## The frame playing this many seconds into the cycle, and how far through it, from 0 to 1.
func _frame_at(seconds: float) -> Vector2:
	var last := sprite_frames.get_frame_count(animation) - 1
	for index in last:
		var length := _frame_seconds(index)
		if seconds < length:
			return Vector2(index, seconds / length)
		seconds -= length
	return Vector2(last, clampf(seconds / _frame_seconds(last), 0.0, 1.0))
