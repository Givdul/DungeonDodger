extends StaticBody2D
## A plant rooted in the floor. It's solid, and while the player is in range it
## lobs bombs onto the floor in the upper part of the screen.

@export var bomb_scene: PackedScene
@export var fire_range := 110.0
@export var fire_interval := 3.0

# Frame of the attack animation where the bomb leaves the plant.
const LAUNCH_FRAME := 7
const MOUTH_OFFSET := Vector2(0, -12)
# Bombs land between this far below the view top, plus however far the floor
# scrolls before they blow, and this far down the view. So they explode below
# the hearts and score, where the player can still lead enemies onto them.
const LANDING_TOP_MARGIN := 48.0
const LANDING_LOWEST := 0.6

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var game = get_tree().get_first_node_in_group("Game")
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
	get_parent().add_child(bomb)
	bomb.launch(global_position + MOUTH_OFFSET, _landing_spot(bomb.flight_time + bomb.fuse_time))


func _landing_spot(seconds_to_explode: float) -> Vector2:
	var view: Rect2 = game.view_rect()
	var top: float = view.position.y + game.scroll_speed() * seconds_to_explode + LANDING_TOP_MARGIN
	# At top scroll speed the top limit passes the lowest one, so keep two rows of room.
	var bottom := maxf(view.position.y + view.size.y * LANDING_LOWEST, top + 32)
	return get_parent().free_spot_between(top, bottom)
