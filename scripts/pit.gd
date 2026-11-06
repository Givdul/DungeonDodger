class_name Pit
extends AnimatedSprite2D
## A hole in the floor. A crumbling one starts as cracked floor and collapses
## shortly after the player or a spinner first steps on it. A failing one also
## collapses by itself once it scrolls into the lower half of the screen, so the
## floor falls away behind a player who hangs back. Under the tile, a brick wall going
## down from the hole's top edge fades in as the tile collapses, and out again as
## the hole opens further above it.

const TILE_HEIGHT := 16.0

@export var crumbles := false
@export var failing := false

@onready var _game = get_tree().get_first_node_in_group("Game")
@onready var _wall: Sprite2D = $Wall


func _ready() -> void:
	if not crumbles:
		frame = _last_frame()
	set_physics_process(failing)


func _physics_process(_delta: float) -> void:
	if global_position.y > _game.screen_rect().get_center().y:
		play()
		set_physics_process(false)


func _process(_delta: float) -> void:
	var above: float = get_parent().collapse_at(global_position + Vector2.UP * TILE_HEIGHT)
	_wall.modulate.a = collapse() * (1.0 - above)


## The walker is the player or a spinner. Both fall in with fall_into().
func step_on(walker) -> void:
	if is_open():
		walker.fall_into(global_position)
	elif not is_playing():
		play()


func is_open() -> bool:
	return frame == _last_frame()


## How far the tile has fallen away, from 0 for whole floor to 1 for an open hole.
func collapse() -> float:
	return minf((frame + frame_progress) / _last_frame(), 1.0)


func _last_frame() -> int:
	return sprite_frames.get_frame_count(animation) - 1
