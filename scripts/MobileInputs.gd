extends Node
# Script name: mobile_inputs.gd

const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]
# Two presses of the same direction this close together, from separate touches
# or key presses, also press dodge.
const DODGE_WINDOW_MSEC := 300

# Keyed by touch index, so a second finger on the screen can't turn the first
# finger's small movements into a swipe.
var swipe_starts: Dictionary[int, Vector2] = {}
var minimum_drag: int    = 50
# Counts every touch and key press, so the re-anchored segments of one drag share
# a press and can't make a dodge between them.
var _press_count := 0
var _touch_presses: Dictionary[int, int] = {}
var _last_move: StringName
var _last_move_press := -1
var _last_move_msec := 0

func _ready() -> void:
	# Keeps anchors current while the tree is paused, so a thumb resting during the
	# resume countdown can swipe the moment play starts.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_starts[event.index] = event.position
			_press_count += 1
			_touch_presses[event.index] = _press_count
		else:
			swipe_starts.erase(event.index)
			_touch_presses.erase(event.index)
	elif event is InputEventScreenDrag and swipe_starts.has(event.index):
		if get_tree().paused:
			swipe_starts[event.index] = event.position
			return
		var swipe: Vector2 = event.position - swipe_starts[event.index]
		if swipe.length() >= minimum_drag:
			_press_swipe_action(swipe, _touch_presses[event.index])
			# Re-anchor so one continuous drag can chain turns without lifting.
			swipe_starts[event.index] = event.position
	elif event is InputEventKey and event.pressed and not event.echo and not get_tree().paused:
		# The input map already presses the move action, this only watches for a double press.
		for action in MOVE_ACTIONS:
			if event.is_action(action, true):
				_press_count += 1
				_watch_for_dodge(action, _press_count)

func _press_swipe_action(swipe: Vector2, press: int) -> void:
	var action: StringName
	if abs(swipe.x) > abs(swipe.y):
		action = &"move_right" if swipe.x > 0 else &"move_left"
	else:
		action = &"move_down" if swipe.y > 0 else &"move_up"

	# player.gd reads these with is_action_just_pressed, which still fires when
	# the press and release land in the same frame.
	Input.action_press(action)
	Input.action_release(action)
	_watch_for_dodge(action, press)

# The move action goes first, so the player turns before the dodge rolls them.
func _watch_for_dodge(action: StringName, press: int) -> void:
	var now := Time.get_ticks_msec()
	var is_double := action == _last_move and press != _last_move_press \
		and now - _last_move_msec <= DODGE_WINDOW_MSEC
	if is_double:
		Input.action_press(&"dodge")
		Input.action_release(&"dodge")
		# A third press starts a new pair rather than chaining another dodge.
		_last_move = &""
		return
	_last_move = action
	_last_move_press = press
	_last_move_msec = now
