extends Area2D

@export var speed := 150
@export var lock_time := 1.5

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimatedSprite2D
@onready var timer = $Timer

# Reference your game node to get the playable area
@onready var game = get_tree().get_first_node_in_group("Game")  # Add group "Game" to your main game Node2D

var state = "locking"
var rush_direction = Vector2.ZERO

func _ready():
	timer.wait_time = lock_time
	timer.connect("timeout", Callable(self, "_on_lock_timeout"))
	timer.start()

func _physics_process(delta):
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
	rush_direction = (player.global_position - global_position).normalized()
	
	if rush_direction.x > 0:
		anim.play("run_right")
	else:
		anim.play("run_left")

func _move_rush(delta):
	# Calculate new position
	var new_pos = position + rush_direction * speed * delta
	
	if game and not game.playable_area().has_point(new_pos):
		state = "locking"
		timer.start()
		return


	position = new_pos
