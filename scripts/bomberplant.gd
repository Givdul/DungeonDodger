extends StaticBody2D
## A plant rooted in the floor. It's solid, and while the player is in range it
## lobs bombs onto a random spot of floor on screen.

@export var bomb_scene: PackedScene
@export var fire_range := 110.0
@export var fire_interval := 3.0

# Frame of the attack animation where the bomb leaves the plant.
const LAUNCH_FRAME := 7
const MOUTH_OFFSET := Vector2(0, -12)

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var game = get_tree().get_first_node_in_group("Game")
@onready var dungeon = get_parent()
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _cooldown := randf_range(1.0, fire_interval)


func _ready() -> void:
	anim.frame_changed.connect(_on_frame_changed)
	anim.animation_finished.connect(anim.play.bind(&"idle"))


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0 or player.is_dead:
		return
	if global_position.distance_to(player.global_position) > fire_range:
		return
	_cooldown = fire_interval
	anim.play(&"attack")


func _on_frame_changed() -> void:
	if anim.animation != &"attack" or anim.frame != LAUNCH_FRAME:
		return
	var bomb = bomb_scene.instantiate()
	# Anywhere on the floor that's still in view when the bomb blows, so the
	# player can lead enemies onto it.
	var spots: Array = dungeon.free_spots_in(game.floor_band(bomb.flight_time + bomb.fuse_time))
	if spots.is_empty():
		bomb.free()
		return
	dungeon.add_child(bomb)
	bomb.launch(global_position + MOUTH_OFFSET, spots.pick_random())
