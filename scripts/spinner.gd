extends CharacterBody2D
## Moves like a rook: picks the straight line, across or along the corridor, that
## brings it closest to the player, and spins down it until it crashes into
## something solid or runs out of time.

@export var speed := 110.0
# The level is endless downward, so a run along it may never reach anything solid.
@export var max_run_time := 3.0
@export var pause_time := 0.7

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_dead := false
var _run_direction := Vector2.ZERO
var _run_time_left := 0.0
var _pause_left := pause_time


func _physics_process(delta: float) -> void:
	if is_dead or not is_instance_valid(player) or player.is_dead:
		return

	# Polled rather than body_entered, like the other enemies: contact that starts
	# during the player's hit animation never enters again.
	if $HitArea.overlaps_body(player):
		player.take_damage()

	if _run_direction == Vector2.ZERO:
		_pause_left -= delta
		if _pause_left <= 0:
			_start_run()
		return

	_run_time_left -= delta
	var crashed := move_and_collide(_run_direction * speed * delta) != null
	if crashed or _run_time_left <= 0:
		_run_direction = Vector2.ZERO
		_pause_left = pause_time
		anim.play(&"idle")


func _start_run() -> void:
	var to_player: Vector2 = player.global_position - global_position
	if absf(to_player.x) > absf(to_player.y):
		_run_direction = Vector2(signf(to_player.x), 0)
	else:
		_run_direction = Vector2(0, signf(to_player.y))
	_run_time_left = max_run_time
	anim.play(&"run")


func die() -> void:
	if is_dead:
		return
	is_dead = true
	anim.play(&"death")
	await anim.animation_finished
	queue_free()
