extends CharacterBody2D

@export var speed := 60
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimatedSprite2D

var last_facing_right := true  # Track direction for idle animation

func _ready():
	$HitArea.connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	if not is_instance_valid(player):
		player = null
		velocity = Vector2.ZERO
		anim.play("idle_right")  # or left depending on last dir
		return
	
	if player and player.is_inside_tree():
		if player.has_method("is_dead") and player.is_dead:
			velocity = Vector2.ZERO
			anim.play("idle_right" if last_facing_right else "idle_left")
			return

		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_collide(velocity * delta)

		if player.global_position.x > global_position.x:
			anim.play("run_right")
			last_facing_right = true
		else:
			anim.play("run_left")
			last_facing_right = false

func _on_body_entered(body):
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage()
