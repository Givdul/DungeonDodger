extends CharacterBody2D

signal lives_changed(lives)

@onready var anim = $AnimatedSprite2D
@onready var audio_stream_player_2d = $hit_sound
@onready var death_sound = $death_sound


@export var max_lives := 3
var current_lives : int
var direction := Vector2.ZERO
var last_direction := Vector2.DOWN  # Default facing down

const SPEED := 130
var is_dead := false
var is_hit := false  # Flag to know if hit anim is playing

func _physics_process(_delta):
	if is_dead:
		# Dead, keep death animation, no movement
		return
	
	# Update direction based on last key pressed
	if Input.is_action_just_pressed("move_up"):
		direction = Vector2.UP
		last_direction = Vector2.UP
		if not is_hit:
			anim.play("run_up")
	elif Input.is_action_just_pressed("move_down"):
		direction = Vector2.DOWN
		last_direction = Vector2.DOWN
		if not is_hit:
			anim.play("run_down")
	elif Input.is_action_just_pressed("move_left"):
		direction = Vector2.LEFT
		last_direction = Vector2.LEFT
		if not is_hit:
			anim.play("run_left")
	elif Input.is_action_just_pressed("move_right"):
		direction = Vector2.RIGHT
		last_direction = Vector2.RIGHT
		if not is_hit:
			anim.play("run_right")

	# Move player
	velocity = direction * SPEED
	move_and_slide()

func _ready():
	current_lives = max_lives
	emit_signal("lives_changed", current_lives)

func take_damage():
	if current_lives <= 0 or is_hit or is_dead:
		return
	
	current_lives -= 1
	emit_signal("lives_changed", current_lives)
	
	if current_lives <= 0:
		die()
		return
		
	audio_stream_player_2d.play()
	
	# Play hit animation in the correct direction
	is_hit = true
	
	if last_direction == Vector2.UP:
		anim.play("hit_up")
	elif last_direction == Vector2.DOWN:
		anim.play("hit_down")
	elif last_direction == Vector2.LEFT:
		anim.play("hit_left")
	elif last_direction == Vector2.RIGHT:
		anim.play("hit_right")
	else:
		# fallback
		anim.play("hit_down")
	
	# Wait for hit animation to finish before resuming normal state
	await anim.animation_finished
	is_hit = false
	
	if current_lives <= 0:
		die()
	else:
		# Resume last movement animation or idle
		if direction == Vector2.ZERO:
			anim.play("idle_down")  # or whichever idle you want as default
		else:
			if direction == Vector2.UP:
				anim.play("run_up")
			elif direction == Vector2.DOWN:
				anim.play("run_down")
			elif direction == Vector2.LEFT:
				anim.play("run_left")
			elif direction == Vector2.RIGHT:
				anim.play("run_right")

func die():
	is_dead = true
	anim.play("death")
	death_sound.play()
	# Wait for animation to finish
	await anim.animation_finished
	set_physics_process(false)
	set_process(false)
	collision_layer = 0
	collision_mask = 0
