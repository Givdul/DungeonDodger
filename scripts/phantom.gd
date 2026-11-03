extends CharacterBody2D

@export var speed := 60
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimatedSprite2D

var last_facing_right := true  # Track direction for idle animation
var is_dead := false

func _physics_process(delta):
	if is_dead:
		return
	if not is_instance_valid(player):
		player = null
		velocity = Vector2.ZERO
		anim.play("idle_right")  # or left depending on last dir
		return
	
	if player and player.is_inside_tree():
		if player.is_dead:
			velocity = Vector2.ZERO
			anim.play("idle_right" if last_facing_right else "idle_left")
			return

		# Polled rather than body_entered: contact that starts during the player's hit
		# animation never enters again, so a resting enemy would stop hurting.
		if $HitArea.overlaps_body(player):
			player.take_damage()

		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_collide(velocity * delta)

		if player.global_position.x > global_position.x:
			anim.play("run_right")
			last_facing_right = true
		else:
			anim.play("run_left")
			last_facing_right = false


func die():
	if is_dead:
		return
	is_dead = true
	anim.play("death_right" if last_facing_right else "death_left")
	await anim.animation_finished
	queue_free()
