extends StaticBody2D
## A locked chest. Touching it with a key opens it, and a health potion hops out
## onto the floor nearby.

signal opened

@export var potion_scene: PackedScene

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _opened := false


func _physics_process(_delta: float) -> void:
	if _opened or not player.has_key or not $Reach.overlaps_body(player):
		return
	_opened = true
	player.has_key = false
	opened.emit()
	anim.play(&"open")
	await anim.animation_finished
	var dungeon := get_parent()
	var potion = potion_scene.instantiate()
	potion.position = position
	dungeon.add_child(potion)
	potion.hop_to(dungeon.free_spot_near(position))
