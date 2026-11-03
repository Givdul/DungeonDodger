extends Node2D
## A bomb lobbed in an arc. A marker shows where it will land. It sits there on a
## burning fuse, then explodes, hurting the player and killing every enemy in the
## blast, so the player can lure enemies onto it.

@export var flight_time := 0.9
@export var fuse_time := 2.5
@export var arc_height := 40.0
@export var blast_radius := 20.0

@onready var bomb: AnimatedSprite2D = $Bomb
@onready var explosion: AnimatedSprite2D = $Explosion

# The fuse blinks the bomb red, faster as it burns down. The bomb is near black,
# so the flash has to push past 1 to show.
const FUSE_FLASH := Color(4, 1, 1)
const FIRST_BLINK_SECONDS := 0.5
const LAST_BLINK_SECONDS := 0.1
const BLINK_SPEEDUP := 0.8
# On the floor it draws under the player and enemies, like the plants.
const LANDED_Z_INDEX := 4


## Call after adding the bomb to the tree.
func launch(from: Vector2, target: Vector2) -> void:
	global_position = target
	var start := to_local(from)
	bomb.play(&"up")
	var tween := create_tween()
	tween.tween_method(_fly.bind(start), 0.0, 1.0, flight_time)
	tween.tween_callback(func(): bomb.z_index = LANDED_Z_INDEX)
	_tween_fuse(tween)
	tween.tween_callback(_explode)


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
	bomb.position = start.lerp(Vector2.ZERO, progress) + Vector2(0, -height)
	if progress > 0.5:
		bomb.play(&"down")


func _explode() -> void:
	bomb.hide()
	$Marker.hide()
	explosion.show()
	explosion.play()
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if global_position.distance_to(enemy.global_position) <= blast_radius:
			enemy.die()
	var player = get_tree().get_first_node_in_group("Player")
	if global_position.distance_to(player.global_position) <= blast_radius:
		player.take_damage()
	await explosion.animation_finished
	queue_free()
