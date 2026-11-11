extends Node2D
## A bomb lobbed in an arc. A marker shows where it will land. It sits there on a
## burning fuse, then explodes, hurting the player and killing the enemies in the
## 3x3 tiles around it, so the player can lure enemies onto it. Spinners shrug it off.

signal exploded

@export var flight_time := 0.9
@export var fuse_time := 2.5
@export var arc_height := 40.0
@export var blast_half_extent := 24.0

@onready var bomb: AnimatedSprite2D = $Bomb
@onready var explosion: AnimatedSprite2D = $Explosion

# The fuse blinks the bomb red, faster as it burns down. The bomb is near black,
# so the flash has to push past 1 to show.
const FUSE_FLASH := Color(4, 1, 1)
const FIRST_BLINK_SECONDS := 0.5
const LAST_BLINK_SECONDS := 0.1
const BLINK_SPEEDUP := 0.8
# On the floor it stands and sorts with the player, the enemies and the plants.
const LANDED_Z_INDEX := 5
# Where the bomb sprite rests: its base, which it sorts by.
const REST_POSITION := Vector2(0, 4)


## Call after adding the bomb to the tree.
func launch(from: Vector2, target: Vector2) -> void:
	global_position = target
	var start := to_local(from) + REST_POSITION
	bomb.play(&"up")
	var tween := create_tween()
	tween.tween_method(_fly.bind(start), 0.0, 1.0, flight_time)
	tween.tween_callback(_land)
	_tween_fuse(tween)
	tween.tween_callback(_explode)


func _land() -> void:
	bomb.z_index = LANDED_Z_INDEX
	bomb.play(&"landed")
	# The sound lasts as long as fuse_time, and audio ignores the time scale.
	$FuseSound.pitch_scale = Engine.time_scale
	$FuseSound.play()


func _tween_fuse(tween: Tween) -> void:
	var left := fuse_time
	var blink := FIRST_BLINK_SECONDS
	while left > blink:
		tween.tween_property(bomb, "modulate", FUSE_FLASH, blink / 2)
		tween.tween_property(bomb, "modulate", Color.WHITE, blink / 2)
		left -= blink
		blink = maxf(blink * BLINK_SPEEDUP, LAST_BLINK_SECONDS)
	tween.tween_interval(left)


func _fly(progress: float, start: Vector2) -> void:
	var height := arc_height * 4 * progress * (1 - progress)
	bomb.position = start.lerp(REST_POSITION, progress) + Vector2(0, -height)
	if progress > 0.5:
		bomb.play(&"down")


func _explode() -> void:
	$FuseSound.stop()
	$ExplosionSound.play()
	Haptics.explosion()
	bomb.hide()
	$Marker.hide()
	explosion.show()
	explosion.play()
	# Spinners have no die(): blasts don't hurt them.
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if enemy.has_method("die") and _in_blast(enemy.global_position):
			enemy.die()
	var player = get_tree().get_first_node_in_group("Player")
	if _in_blast(player.global_position):
		player.take_damage()
	exploded.emit()
	await explosion.animation_finished
	queue_free()


## The blast is a square, so it reaches the corner tiles.
func _in_blast(point: Vector2) -> bool:
	var offset := (point - global_position).abs()
	return maxf(offset.x, offset.y) <= blast_half_extent
