extends Node
# Script name: mobile_inputs.gd

var swipe_start: Vector2 = Vector2.ZERO
var minimum_drag: int    = 50

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		swipe_start = event.position
	elif event is InputEventScreenDrag:
		var swipe: Vector2 = event.position - swipe_start
		if swipe.length() >= minimum_drag:
			_press_swipe_action(swipe)
			# Re-anchor so one continuous drag can chain turns without lifting.
			swipe_start = event.position

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
