extends StaticBody2D
## A plant rooted in the floor. It's solid, and while the player is in range it
## lobs bombs onto a random spot of floor on screen, one at a time. After its bomb
## blows it waits a moment before it lobs the next.

@export var bomb_scene: PackedScene
@export var fire_range := 110.0
@export var reload_delay := 1.0

# Frame of the attack animation where the bomb leaves the plant.
const LAUNCH_FRAME := 7
const MOUTH_OFFSET := Vector2(0, -12)

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var game = get_tree().get_first_node_in_group("Game")
@onready var dungeon = get_parent()
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _cooldown := randf_range(reload_delay, 3.0)
var _bomb_out := false


func _ready() -> void:
	anim.frame_changed.connect(_on_frame_changed)
	anim.animation_finished.connect(anim.play.bind(&"idle"))


func _physics_process(delta: float) -> void:
	# The dungeon builds a row above the view: a plant there waits, unseen, until it scrolls in.
	if _bomb_out or not game.screen_rect().has_point(global_position):
		return
	_cooldown -= delta
	if _cooldown > 0 or player.is_dead:
		return
	if global_position.distance_to(player.global_position) > fire_range:
		return
	_bomb_out = true
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
		_reload()
		return
	bomb.exploded.connect(_reload)
	dungeon.add_child(bomb)
	bomb.launch(global_position + MOUTH_OFFSET, spots.pick_random())


func _reload() -> void:
	_bomb_out = false
	_cooldown = reload_delay
