extends Node
# Script name: mobile_inputs.gd

var swipe_start: Vector2     = Vector2.ZERO
var minimum_drag: int        = 50
var swipe_direction: Vector2 = Vector2.ZERO

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
		else:
			_calculate_swipe(event.position)

func _calculate_swipe(swipe_end) -> void:
	swipe_direction = swipe_end - swipe_start

	if swipe_direction.length() < minimum_drag:
		return

	swipe_direction = swipe_direction.normalized()

	# Determine swipe direction
	if abs(swipe_direction.x) > abs(swipe_direction.y):
		if swipe_direction.x > 0:
			Input.action_press("ui_right")
			Input.action_release("ui_right")
		else:
			Input.action_press("ui_left")
			Input.action_release("ui_left")
	else:
		if swipe_direction.y > 0:
			Input.action_press("ui_down")
			Input.action_release("ui_down")
		else:
			Input.action_press("ui_up")
			Input.action_release("ui_up")
