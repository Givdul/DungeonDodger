extends Area2D

@export var speed := 104
# Time from one wind-up start to the next, however the rush ended. Keep it longer than
# windup_time + max_rush_time, or a beat would come during a rush.
@export var charge_interval := 3.0
# The bat blinks, then rushes the way it locked in when the blink started.
@export var windup_time := 0.5
# The corridor has no top or bottom wall, so a rush along it may never reach a wall.
@export var max_rush_time := 1.5
# Bats that aren't rushing drift apart until their centers are this far apart. Their bodies
# touch here; the wings still overlap. A rush ignores other bats, so it's never cut short.
@export var bat_spacing := 14.0
@export var drift_speed := 30.0

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimatedSprite2D
@onready var timer = $Timer

# Reference your game node to get the playable area
@onready var game = get_tree().get_first_node_in_group("Game")  # Add group "Game" to your main game Node2D

# A bat holds still in the world where its last rush ended, winds up on its beat, and rushes.
# The scroll may carry it off the bottom, and a rush brings it back: keep a rush's distance per
# charge_interval well over max_scroll_speed in game.gd, or a bat left behind never catches up.
var state = "locking"
# Seconds until the next beat, when the bat winds up. It runs through every state, so a rush
# that ends early just waits longer.
var beat_left := 0.0
var rush_direction = Vector2.ZERO
var rush_time_left := 0.0
var flash_tween: Tween

# A softer, slower take on a bomb's fuse flash, so a red blink still means "about to hurt".
const WINDUP_FLASH := Color(2.5, 1, 1)
const WINDUP_BLINK_SECONDS := 0.2

func _ready():
	add_to_group("Bats")
	timer.connect("timeout", Callable(self, "_start_rush"))
	# Bats that spawn together would otherwise charge in lockstep for the rest of the run.
	beat_left = randf() * charge_interval

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
		_stop_flash()
		state = "locking"
		anim.play("idle_right" if anim.animation.ends_with("right") else "idle_left")
		return

	# Polled rather than body_entered: contact that starts during the player's hit
	# animation never enters again, so a resting enemy would stop hurting.
	if overlaps_body(player):
		player.take_damage()

	match state:
		"locking":
			_face_player()
			_drift_off_bats(delta)
		"rushing":
			_move_rush(delta)
	_tick_beat(delta)

func _tick_beat(delta):
	beat_left -= delta
	if beat_left > 0:
		return
	beat_left += charge_interval
	_start_windup()

func _face_player():
	if player.global_position.x >= global_position.x:
		anim.play("idle_right")
	else:
		anim.play("idle_left")

func _start_windup():
	state = "winding_up"
	rush_direction = (player.global_position - global_position).normalized()
	_face_player()
	flash_tween = create_tween().set_loops()
	flash_tween.tween_property(anim, "modulate", WINDUP_FLASH, WINDUP_BLINK_SECONDS / 2)
	flash_tween.tween_property(anim, "modulate", Color.WHITE, WINDUP_BLINK_SECONDS / 2)
	timer.start(windup_time)

func _stop_flash():
	if flash_tween:
		flash_tween.kill()
	anim.modulate = Color.WHITE

func _start_rush():
	_stop_flash()
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
	if hits_wall or rush_time_left <= 0:
		state = "locking"
		return

	position = new_pos

# Not during a wind-up: the rush line is already locked in. A rushing bat isn't drifted from,
# so it passes through without shoving the bats it crosses.
func _drift_off_bats(delta):
	for bat in get_tree().get_nodes_in_group("Bats"):
		if bat == self or bat.state == "rushing" or bat.state == "dead":
			continue
		var away: Vector2 = position - bat.position
		if away.length() >= bat_spacing:
			continue
		# Bats on the exact same spot have no direction between them.
		var direction := away.normalized() if away != Vector2.ZERO else Vector2.from_angle(randf() * TAU)
		var new_pos: Vector2 = position + direction * drift_speed * delta
		if not game or game.is_between_walls(new_pos.x):
			position = new_pos


func die():
	if state == "dead":
		return
	state = "dead"
	timer.stop()
	_stop_flash()
	$DeathSound.play_death()
	anim.play("death_right" if anim.animation.ends_with("right") else "death_left")
	await anim.animation_finished
	queue_free()
