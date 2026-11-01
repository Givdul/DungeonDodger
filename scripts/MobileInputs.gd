extends Node
# Script name: mobile_inputs.gd

var swipe_start: Vector2 = Vector2.ZERO
var minimum_drag: int    = 50

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
		else:
			_calculate_swipe(event.position)

func _calculate_swipe(swipe_end: Vector2) -> void:
	var swipe := swipe_end - swipe_start

	if swipe.length() < minimum_drag:
		return

	var action: StringName
	if abs(swipe.x) > abs(swipe.y):
		action = &"move_right" if swipe.x > 0 else &"move_left"
	else:
		action = &"move_down" if swipe.y > 0 else &"move_up"

	# player.gd reads these with is_action_just_pressed, which still fires when
	# the press and release land in the same frame.
	Input.action_press(action)
	Input.action_release(action)
