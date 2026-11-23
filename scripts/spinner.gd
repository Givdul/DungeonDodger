extends CharacterBody2D
## Moves like a rook: picks the straight line, across or along the corridor, that
## brings it closest to the player, and spins down it until it crashes into
## something solid or runs out of time. Bombs don't hurt it; only a hole kills it.

@export var speed := 76.0
# The corridor has no top or bottom wall, so a run along it may never reach anything solid.
@export var max_run_time := 3.0
@export var pause_time := 0.7
const FALL_SLIDE_SECONDS := 0.1
const FALL_SECONDS := 0.5

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var game = get_tree().get_first_node_in_group("Game")
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

	# It walks on the floor, so it cracks crumbling tiles and falls into holes, even while paused.
	var hazard = game.dungeon.hazard_at(global_position)
	if hazard is Pit:
		hazard.step_on(self)
		if is_dead:
			return

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
	# The fireball's run rolls right; along the corridor it has a drawing for each way.
	anim.flip_h = _run_direction.x < 0
	if _run_direction.y != 0:
		anim.play(&"run_down" if _run_direction.y > 0 else &"run_up")
	else:
		anim.play(&"run")


# The spinner has no fall animation, so it slides into the hole and shrinks into the dark.
func fall_into(hole_center: Vector2) -> void:
	is_dead = true
	$DeathSound.play_death()
	var tween := create_tween()
	tween.tween_property(self, "global_position", hole_center, FALL_SLIDE_SECONDS)
	tween.tween_property(self, "scale", Vector2.ZERO, FALL_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(self, "modulate", Color.BLACK, FALL_SECONDS)
	tween.tween_callback(queue_free)
