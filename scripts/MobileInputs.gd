extends Node
# Script name: mobile_inputs.gd

# Keyed by touch index, so a second finger on the screen can't turn the first
# finger's small movements into a swipe.
var swipe_starts: Dictionary[int, Vector2] = {}
var minimum_drag: int    = 50

func _ready() -> void:
	# Keeps anchors current while the tree is paused, so a thumb resting during the
	# resume countdown can swipe the moment play starts.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_starts[event.index] = event.position
		else:
			swipe_starts.erase(event.index)
	elif event is InputEventScreenDrag and swipe_starts.has(event.index):
		if get_tree().paused:
			swipe_starts[event.index] = event.position
			return
		var swipe: Vector2 = event.position - swipe_starts[event.index]
		if swipe.length() >= minimum_drag:
			_press_swipe_action(swipe)
			# Re-anchor so one continuous drag can chain turns without lifting.
			swipe_starts[event.index] = event.position

func _press_swipe_action(swipe: Vector2) -> void:
	var action: StringName
	if abs(swipe.x) > abs(swipe.y):
		action = &"move_right" if swipe.x > 0 else &"move_left"
	else:
		action = &"move_down" if swipe.y > 0 else &"move_up"

	# player.gd reads these with is_action_just_pressed, which still fires when
	# the press and release land in the same frame.
	Input.action_press(action)
	Input.action_release(action)
