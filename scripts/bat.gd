extends Area2D

@export var speed := 150
@export var lock_time := 1.5
# The level is endless downward, so a rush along it may never reach a wall.
@export var max_rush_time := 1.5
# Closest two bats' centers can get. Their bodies touch here; the wings still overlap.
@export var bat_spacing := 14.0

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimatedSprite2D
@onready var timer = $Timer

# Reference your game node to get the playable area
@onready var game = get_tree().get_first_node_in_group("Game")  # Add group "Game" to your main game Node2D

var state = "locking"
var rush_direction = Vector2.ZERO
var rush_time_left := 0.0

func _ready():
	add_to_group("Bats")
	timer.connect("timeout", Callable(self, "_on_lock_timeout"))
	_start_lock_timer()

# Bats that stop at the same spot on the same frame would otherwise rush in
# lockstep for the rest of the run, looking and acting like one bat.
func _start_lock_timer():
	timer.start(lock_time * randf_range(0.8, 1.2))

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

	# Polled rather than body_entered: contact that starts during the player's hit
	# animation never enters again, so a resting enemy would stop hurting.
	if overlaps_body(player):
		player.take_damage()

	match state:
		"locking":
			_face_player()
		"rushing":
			_move_rush(delta)

			
func _face_player():
	if player.global_position.x >= global_position.x:
		anim.play("idle_right")
	else:
		anim.play("idle_left")

func _on_lock_timeout():
	state = "rushing"
	rush_time_left = max_rush_time
	rush_direction = (player.global_position - global_position).normalized()
	
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
		state = "locking"
		_start_lock_timer()
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
	anim.play("death_right" if anim.animation.ends_with("right") else "death_left")
	await anim.animation_finished
	queue_free()
