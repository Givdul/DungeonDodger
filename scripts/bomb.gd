extends Node2D
## A bomb lobbed in an arc. A marker shows where it will land; there it explodes,
## hurting the player and killing every enemy in the blast.

@export var flight_time := 0.9
@export var arc_height := 40.0
@export var blast_radius := 20.0

@onready var bomb: AnimatedSprite2D = $Bomb
@onready var explosion: AnimatedSprite2D = $Explosion


## Call after adding the bomb to the tree.
func launch(from: Vector2, target: Vector2) -> void:
	global_position = target
	var start := to_local(from)
	bomb.play(&"up")
	var tween := create_tween()
	tween.tween_method(_fly.bind(start), 0.0, 1.0, flight_time)
	tween.tween_callback(_explode)


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
