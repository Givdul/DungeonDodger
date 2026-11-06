extends Area2D
## A key on the floor. The player carries one at a time, to open a chest.

signal picked_up

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


# Polled rather than body_entered, so a player who walks over it with a key in
# hand can still pick it up once they've used theirs.
func _physics_process(_delta: float) -> void:
	if player.has_key or not overlaps_body(player):
		return
	player.has_key = true
	picked_up.emit()
	set_physics_process(false)
	$PickupSound.play()
	anim.play(&"collected")
	await anim.animation_finished
	queue_free()
