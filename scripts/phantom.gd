extends CharacterBody2D

@export var speed := 60
# Phantoms closer than this push each other apart, so a group fans out around the player.
const SEPARATION_RADIUS := 24.0
# How far to the side of the player a phantom aims when far away; the offset is gone
# within FLANK_END_DISTANCE, so the last stretch is a straight run at full speed.
const FLANK_WIDTH := 60.0
const FLANK_END_DISTANCE := 40.0
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimatedSprite2D

var last_facing_right := true  # Track direction for idle animation
var is_dead := false
# Where, from -1 (left) to 1 (right), this phantom aims across the approach, so a group arrives from different angles.
var flank := randf_range(-1.0, 1.0)

func _ready():
	motion_mode = MOTION_MODE_FLOATING
	wall_min_slide_angle = 0.0  # A near head-on bump slides past instead of stopping.

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

		var direction = ((aim_point() - global_position).normalized() + separation()).normalized()
		velocity = direction * speed
		move_and_slide()

		if player.global_position.x > global_position.x:
			anim.play("run_right")
			last_facing_right = true
		else:
			anim.play("run_left")
			last_facing_right = false


# Beside the player while far off, narrowing to the player and gone by FLANK_END_DISTANCE.
func aim_point() -> Vector2:
	var to_player: Vector2 = player.global_position - global_position
	var side := to_player.orthogonal().normalized() * flank * clampf(to_player.length() - FLANK_END_DISTANCE, 0.0, FLANK_WIDTH)
	return player.global_position + side


func separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("Phantoms"):
		if other == self or other.is_dead:
			continue
		var away: Vector2 = global_position - other.global_position
		var distance := away.length()
		if distance >= SEPARATION_RADIUS:
			continue
		push += away.normalized() * (1.0 - distance / SEPARATION_RADIUS)
	return push


func die():
	if is_dead:
		return
	is_dead = true
	anim.play("death_right" if last_facing_right else "death_left")
	await anim.animation_finished
	queue_free()
