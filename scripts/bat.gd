extends Area2D

@export var speed := 104
@export var lock_time := 1.5
# The last part of the lock, when the bat flashes and marks its locked-in rush line.
@export var windup_time := 0.5
# The corridor has no top or bottom wall, so a rush along it may never reach a wall.
@export var max_rush_time := 1.5
# Closest two bats' centers can get. Their bodies touch here; the wings still overlap.
@export var bat_spacing := 14.0

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimatedSprite2D
@onready var timer = $Timer
@onready var marker: Line2D = $RushMarker

# Reference your game node to get the playable area
@onready var game = get_tree().get_first_node_in_group("Game")  # Add group "Game" to your main game Node2D

# A bat out of view, or too near the bottom edge to stay in view until its rush, is "entering":
# it flies at the player, and only locks, winds up and rushes once it's in view.
var state = "entering"
var rush_direction = Vector2.ZERO
var rush_time_left := 0.0
var flash_tween: Tween
var marker_tween: Tween

# Same flash as a bomb's fuse, so a red blink always means "about to hurt".
const WINDUP_FLASH := Color(4, 1, 1)
const WINDUP_BLINK_SECONDS := 0.1
const MARKER_FADE_SECONDS := 0.15
# A lock lasts lock_time, give or take this share of it.
const LOCK_TIME_SPREAD := 0.2

func _ready():
	add_to_group("Bats")
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))

# Bats that stop at the same spot on the same frame would otherwise rush in
# lockstep for the rest of the run, looking and acting like one bat.
func _start_lock_timer():
	timer.start(lock_time * randf_range(1.0 - LOCK_TIME_SPREAD, 1.0 + LOCK_TIME_SPREAD) - windup_time)

func _physics_process(delta):
	if state == "dead":
		return
	if not is_instance_valid(player):
		player = null
		state = "locking"  # Reset so it doesn't rush into a wall next round
		anim.play("idle_right")  # or idle_left depending on last known x direction
		return

	if not player or not player.is_inside_tree():
		return

	if player.is_dead:
		timer.stop()
		_clear_telegraph()
		state = "locking"
		anim.play("idle_right" if anim.animation.ends_with("right") else "idle_left")
		return

	# Polled rather than body_entered: contact that starts during the player's hit
	# animation never enters again, so a resting enemy would stop hurting.
	if overlaps_body(player):
		player.take_damage()

	match state:
		"entering":
			_fly_in(delta)
		"locking":
			_face_player()
		"rushing":
			_move_rush(delta)

			
# The view scrolls past a bat standing still, so it locks in the part of the floor band that is still in view when its lock ends.
func _locking_band() -> Rect2:
	return game.floor_band(lock_time * (1.0 + LOCK_TIME_SPREAD))

func _fly_in(delta):
	var band := _locking_band()
	if band.has_point(global_position):
		state = "locking"
		_start_lock_timer()
		return
	_face_player()
	# The player may stand below the locking band, where the bat would never lock.
	var inner := band.grow(-1.0)
	var target: Vector2 = player.global_position.clamp(inner.position, inner.end)
	global_position += global_position.direction_to(target) * speed * delta

func _face_player():
	if player.global_position.x >= global_position.x:
		anim.play("idle_right")
	else:
		anim.play("idle_left")

func _on_timer_timeout():
	match state:
		"locking":
			_start_windup()
		"winding_up":
			_start_rush()

func _start_windup():
	state = "winding_up"
	rush_direction = (player.global_position - global_position).normalized()
	_face_player()
	_show_marker()
	flash_tween = create_tween().set_loops()
	flash_tween.tween_property(anim, "modulate", WINDUP_FLASH, WINDUP_BLINK_SECONDS / 2)
	flash_tween.tween_property(anim, "modulate", Color.WHITE, WINDUP_BLINK_SECONDS / 2)
	timer.start(windup_time)

# The marker stays where it was drawn (top_level), so it marks the line, not the bat.
func _show_marker():
	if marker_tween:
		marker_tween.kill()
	marker.global_position = global_position
	marker.points = [Vector2.ZERO, rush_direction * _rush_length()]
	marker.modulate.a = 1.0
	marker.show()

# Ends where the rush would stop at a wall, so the marker never crosses one.
func _rush_length() -> float:
	var length := speed * max_rush_time
	if game and rush_direction.x != 0:
		var area: Rect2 = game.playable_area()
		var wall_x := area.end.x if rush_direction.x > 0 else area.position.x
		length = minf(length, (wall_x - position.x) / rush_direction.x)
	return length

func _stop_flash():
	if flash_tween:
		flash_tween.kill()
	anim.modulate = Color.WHITE

func _clear_telegraph():
	_stop_flash()
	if marker_tween:
		marker_tween.kill()
	marker.hide()

func _start_rush():
	_stop_flash()
	marker_tween = create_tween()
	marker_tween.tween_property(marker, "modulate:a", 0.0, MARKER_FADE_SECONDS)
	marker_tween.tween_callback(marker.hide)

	state = "rushing"
	rush_time_left = max_rush_time
	if rush_direction.x > 0:
		anim.play("run_right")
	else:
		anim.play("run_left")

func _move_rush(delta):
	# Calculate new position
	var new_pos = position + rush_direction * speed * delta
	
	rush_time_left -= delta
	var hits_wall = game and not game.is_between_walls(new_pos.x)
	if hits_wall or rush_time_left <= 0 or _bumps_bat(new_pos):
		state = "entering"
		return

	position = new_pos

# Only moving closer counts, so bats that spawn on top of each other can still separate.
func _bumps_bat(new_pos: Vector2) -> bool:
	for bat in get_tree().get_nodes_in_group("Bats"):
		if bat == self:
			continue
		var new_gap := new_pos.distance_to(bat.position)
		if new_gap < bat_spacing and new_gap < position.distance_to(bat.position):
			return true
	return false


func die():
	if state == "dead":
		return
	state = "dead"
	timer.stop()
	_clear_telegraph()
	$DeathSound.play_death()
	anim.play("death_right" if anim.animation.ends_with("right") else "death_left")
	await anim.animation_finished
	queue_free()
