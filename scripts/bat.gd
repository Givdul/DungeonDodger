extends Area2D

@export var speed := 150
@export var lock_time := 1.5

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimatedSprite2D
@onready var timer = $Timer

# Reference your game node to get camera and padding info
@onready var game = get_tree().get_first_node_in_group("Game")  # Add group "Game" to your main game Node2D

var state = "locking"
var rush_direction = Vector2.ZERO

func _ready():
	timer.wait_time = lock_time
	timer.connect("timeout", Callable(self, "_on_lock_timeout"))
	timer.start()
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	if not is_instance_valid(player):
		player = null
		state = "locking"  # Reset so it doesn't rush into a wall next round
		anim.play("idle_right")  # or idle_left depending on last known x direction
		return

	if not player or not player.is_inside_tree():
		return

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
	
	# Get camera bounds and padding from game script
	if game:
		var cam_pos = game.camera.global_position
		var viewport_rect = game.get_viewport_rect()
		var half_screen = Vector2(viewport_rect.size.x, viewport_rect.size.y) * 0.5 / game.camera.zoom

		# Calculate padded bounds like in game script
		var left_bound = cam_pos.x - half_screen.x + game.padding_left
		var right_bound = cam_pos.x + half_screen.x - game.padding_right
		var top_bound = cam_pos.y - half_screen.y + game.padding_top
		var bottom_bound = cam_pos.y + half_screen.y - game.padding_bottom

		if new_pos.x < left_bound or new_pos.x > right_bound \
		or new_pos.y < top_bound or new_pos.y > bottom_bound:
			state = "locking"
			timer.start()
			return


	position = new_pos

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage()

