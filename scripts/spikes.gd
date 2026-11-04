class_name Spikes
extends AnimatedSprite2D
## A floor trap whose spikes rest, warn, then rise and sink on a loop. Raised, they are solid to the player
## and to spinners, and hurt only a player they rise under.
## The rest and the warning are long frames in the SpriteFrames, so a cycle is not evenly split by frame.

# Frames of the strip where the spikes are out.
const FIRST_UP_FRAME := 7
const LAST_UP_FRAME := 10
# The player's body sits above its feet. Just outside the cell, a body can overlap the solid so that
# Godot pushes it out through the spikes rather than back the way it came, so the cell holds those too.
const HOLD_MARGIN := 2.0

var _was_up := false
# Bodies that stood on the cell as the spikes rose. They pass through until they have left it.
var _held: Array[CharacterBody2D] = []

@onready var _solid: StaticBody2D = $Solid
@onready var _solid_shape: CollisionShape2D = $Solid/CollisionShape2D
# Sees the player and spinners. Its shape is smaller than the solid's, so a body stopped against the
# raised spikes doesn't count as standing on them.
@onready var _occupants: Area2D = $Occupants


func _ready() -> void:
	# A random phase keeps a row of traps from rising in lockstep. It is random over time, not over
	# frames, so the long rest gets its share of the starts.
	var start := _frame_at(randf() * _cycle_seconds())
	set_frame_and_progress(int(start.x), start.y)
	play()


func _physics_process(_delta: float) -> void:
	var up := _is_up_frame(frame)
	if up and not _was_up:
		_rise()
	elif _was_up and not up:
		_lower()
	_was_up = up
	_release_departed()


# A body whose origin is on the cell is let through until it has left, so it can walk off. Any other
# body is blocked at once. Only the player is hurt, and only if it stands where hazard_at counts it.
func _rise() -> void:
	var size: Vector2 = _solid_shape.shape.size
	var cell := Rect2(global_position - size / 2, size).grow(HOLD_MARGIN)
	for body: CharacterBody2D in _occupants.get_overlapping_bodies():
		if cell.has_point(body.global_position):
			body.add_collision_exception_with(_solid)
			_held.append(body)
		if body.is_in_group(&"Player") and get_parent().hazard_at(body.global_position) == self:
			body.take_damage()
	_solid_shape.disabled = false


func _lower() -> void:
	_solid_shape.disabled = true
	for body in _held:
		if is_instance_valid(body):
			body.remove_collision_exception_with(_solid)
	_held.clear()


func _release_departed() -> void:
	var present := _occupants.get_overlapping_bodies()
	for body in _held.duplicate():
		if not is_instance_valid(body):
			_held.erase(body)
		elif body not in present:
			body.remove_collision_exception_with(_solid)
			_held.erase(body)


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
