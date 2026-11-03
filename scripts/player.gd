extends CharacterBody2D

signal lives_changed(lives)
signal died
signal key_changed(has_key: bool)

@onready var anim = $AnimatedSprite2D
@onready var audio_stream_player_2d = $hit_sound
@onready var death_sound = $death_sound


@export var max_lives := 3
var current_lives : int
var direction := Vector2.ZERO
var last_direction := Vector2.DOWN  # Default facing down

const SPEED := 130
# Enemies deal damage on every frame of contact, so this is what spaces hits apart.
const BLINKS := 6
const BLINK_SECONDS := 0.25
const INVULNERABLE_SECONDS := BLINKS * BLINK_SECONDS
const BLINK_FADED_ALPHA := 0.2
const FALL_SLIDE_SECONDS := 0.12
# The fall strip shrinks toward the bottom of its frame, this far above the feet.
const FALL_SPRITE_RISE := 2.0
var is_dead := false
var is_hit := false  # Flag to know if hit anim is playing
var is_invulnerable := false
var invulnerability_tween: Tween
var has_key := false:
	set(value):
		has_key = value
		key_changed.emit(value)

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

func heal():
	if is_dead:
		return
	current_lives = mini(current_lives + 1, max_lives)
	lives_changed.emit(current_lives)

func take_damage():
	if current_lives <= 0 or is_invulnerable or is_dead:
		return
	
	current_lives -= 1
	emit_signal("lives_changed", current_lives)
	
	if current_lives <= 0:
		die()
		return
		
	start_invulnerability()
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
	# Falling or being crushed mid-hit replaces the hit animation, which still finishes this wait.
	if is_dead:
		return

	# Resume last movement animation or idle
	if direction == Vector2.UP:
		anim.play("run_up")
	elif direction == Vector2.DOWN:
		anim.play("run_down")
	elif direction == Vector2.LEFT:
		anim.play("run_left")
	elif direction == Vector2.RIGHT:
		anim.play("run_right")
	else:
		anim.play("idle")

## Makes the player immune for INVULNERABLE_SECONDS and blinks the sprite until it ends.
func start_invulnerability():
	if is_dead:
		return
	_stop_invulnerability()
	is_invulnerable = true
	# A tween belongs to the player, so it freezes with the game and a restart frees it.
	invulnerability_tween = create_tween().set_loops(BLINKS)
	invulnerability_tween.tween_callback(func(): anim.modulate.a = BLINK_FADED_ALPHA)
	invulnerability_tween.tween_interval(BLINK_SECONDS / 2)
	invulnerability_tween.tween_callback(func(): anim.modulate.a = 1.0)
	invulnerability_tween.tween_interval(BLINK_SECONDS / 2)
	invulnerability_tween.finished.connect(_stop_invulnerability)

func _stop_invulnerability():
	is_invulnerable = false
	if invulnerability_tween:
		invulnerability_tween.kill()
	anim.modulate.a = 1.0

## Pulls the player into the hole and plays the fall.
func fall_into(hole_center: Vector2):
	if is_dead:
		return
	var feet := hole_center + Vector2(0, FALL_SPRITE_RISE)
	create_tween().tween_property(self, "global_position", feet, FALL_SLIDE_SECONDS)
	die(&"fall")

func die(animation := &"death"):
	if is_dead:
		return
	is_dead = true
	_stop_invulnerability()
	anim.play(animation)
	death_sound.play()
	# Wait for animation to finish
	await anim.animation_finished
	set_physics_process(false)
	set_process(false)
	collision_layer = 0
	collision_mask = 0
	died.emit()
