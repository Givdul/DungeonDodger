extends Area2D
## A health potion. It hops out of an opened chest, and picking it up restores a heart.
## At full health the player walks over it and it stays.

# Lands just over the floor, under the player and enemies. Until then it hops over the chest it came from.
const LANDED_Z_INDEX := 1

@export var hop_time := 0.6
@export var hop_height := 24.0

@onready var player = get_tree().get_first_node_in_group("Player")


func hop_to(target: Vector2) -> void:
	set_physics_process(false)
	var from := position
	var tween := create_tween()
	tween.tween_method(func(progress: float):
		position = from.lerp(target, progress) + Vector2(0, -hop_height * 4 * progress * (1 - progress)),
		0.0, 1.0, hop_time)
	tween.tween_callback(_land)


func _land() -> void:
	z_index = LANDED_Z_INDEX
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if overlaps_body(player) and player.heal():
		queue_free()
