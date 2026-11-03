extends Node2D

@export var phantom_scene: PackedScene
@export var bat_scene: PackedScene
@export var spinner_scene: PackedScene
@onready var player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var dungeon = $Dungeon
@export var debug := false
@onready var score_label = $Camera2D/Hud/ScoreLabel
@onready var held_key: Sprite2D = $Camera2D/Hud/ItemBox/HeldKey
@onready var high_score_var_label = $HighScoreVarLabel
@onready var ui = $UI
@onready var swipe_hint: Label = $SwipeHint

# The view holds still until the first swipe or key press of a run. Pausing and resuming leave it set.
var run_started := false

# Static so it survives reload_current_scene(): a restart skips the start screen.
static var _restarting := false

@export var SAFE_DISTANCE_ENEMY := 100  # Minimum distance from player (pixels)
var point_count := 0

# Inset from the side walls (the Bounds bodies) where enemies may spawn.
@export var padding_left := 6
@export var padding_right := 6

# Pixels per second the view scrolls up. It speeds up with the score, up to the max.
@export var start_scroll_speed := 14.0
@export var scroll_speed_per_point := 0.25
@export var max_scroll_speed := 40.0

# How far inside the view's top and bottom edges the player's feet stay, and
# where enemies spawn and bombs land. The top one keeps sprites below the hearts and score.
const VIEW_TOP_MARGIN := 44.0
const VIEW_BOTTOM_MARGIN := 8.0
# A push the player can't follow by more than this means something solid is in
# the way, and the scroll edge crushes them.
const CRUSH_TOLERANCE := 1.0


func _ready():
	# Runs after the player's physics step, so the scroll edge corrects where they moved this frame.
	process_physics_priority = 1
	camera.position = Vector2(0, player.position.y)
	_place_hud()
	dungeon.start(screen_rect())

	if debug:
		dungeon.modulate.a = 0.3

	high_score_var_label.text = str(ScoreManager.high_score)

	dungeon.coin_picked_up.connect(_on_point_picked_up)
	player.died.connect(_on_player_died)
	player.key_changed.connect(held_key.set_visible)
	ui.restart_requested.connect(_restart)
	if _restarting:
		_restarting = false
		ui.start_playing()
	else:
		ui.show_start(ScoreManager.high_score)


func _process(_delta):
	if debug:
		queue_redraw()


func _physics_process(delta):
	if player.is_dead:
		return
	if not run_started:
		# The player runs first, so the swipe that sets their direction scrolls this same frame.
		run_started = player.direction != Vector2.ZERO
		swipe_hint.visible = not run_started
		if not run_started:
			return
	camera.position.y -= scroll_speed() * delta
	dungeon.follow(screen_rect())
	_keep_player_in_view()
	var hazard = dungeon.hazard_at(player.position)
	if hazard:
		hazard.step_on(player)


func scroll_speed() -> float:
	return minf(start_scroll_speed + point_count * scroll_speed_per_point, max_scroll_speed)


# The whole part of the world on screen, including what the notch and home indicator cover.
func screen_rect() -> Rect2:
	var size := get_viewport().get_visible_rect().size / camera.zoom.y
	return Rect2(camera.position - size / 2, size)


# The part of the world on screen, minus what the notch and home indicator cover.
func view_rect() -> Rect2:
	var zoom := camera.zoom.y
	var safe := SafeArea.in_viewport(get_viewport())
	return Rect2(screen_rect().position + safe.position / zoom, safe.size / zoom)


## Where something on the floor is in view and below the hearts and score, both
## now and after the floor has scrolled for seconds_ahead.
func floor_band(seconds_ahead := 0.0) -> Rect2:
	var view := view_rect()
	var top := view.position.y + VIEW_TOP_MARGIN
	var bottom := view.end.y - VIEW_BOTTOM_MARGIN - scroll_speed() * seconds_ahead
	return Rect2(view.position.x, top, view.size.x, bottom - top)


# The hearts and score ride along with the camera, just under the safe area.
func _place_hud() -> void:
	$Camera2D/Hud.position.y = view_rect().position.y - camera.position.y


func _keep_player_in_view() -> void:
	var band := floor_band()
	if player.position.y > band.end.y:
		var collision: KinematicCollision2D = player.move_and_collide(Vector2(0, band.end.y - player.position.y))
		if collision and collision.get_remainder().length() > CRUSH_TOLERANCE:
			player.die()
	player.position.y = maxf(player.position.y, band.position.y)


func _on_player_died():
	var is_new_best := point_count > ScoreManager.high_score
	if is_new_best:
		ScoreManager.high_score = point_count
		ScoreManager.save_high_score()
	ui.show_game_over(point_count, ScoreManager.high_score, is_new_best)


func _restart():
	_restarting = true
	get_tree().reload_current_scene()


func _draw():
	if not debug:
		return

	draw_rect(playable_area(), Color(0, 1, 0, 0.3), false, 3)
	draw_arc(player.global_position, SAFE_DISTANCE_ENEMY, 0, TAU, 32, Color(0, 0, 1, 0.3), 2.0, true)


func is_between_walls(x: float) -> bool:
	return x > $Bounds/LeftWorldBound.position.x + padding_left \
		and x < $Bounds/RightWorldBound.position.x - padding_right


# Where enemies may spawn: between the walls, in the floor band.
func playable_area() -> Rect2:
	var band := floor_band()
	var left: float = $Bounds/LeftWorldBound.position.x + padding_left
	var right: float = $Bounds/RightWorldBound.position.x - padding_right
	return Rect2(left, band.position.y, right - left, band.size.y)


func get_random_point_away_from_player(distance) -> Vector2:
	var area := playable_area()
	var rect_min := area.position
	var rect_max := area.end

	# Try to find a spawn pos away from player
	for i in range(999):
		var x = randf_range(rect_min.x, rect_max.x)
		var y = randf_range(rect_min.y, rect_max.y)
		var spawn_pos = Vector2(x, y)

		if spawn_pos.distance_to(player.global_position) > distance and dungeon.is_free(spawn_pos):
			return spawn_pos

	# fallback position if none found after attempts
	return area.get_center()

func _on_point_picked_up():
	point_count += 1
	score_label.text = str(point_count)

	if point_count == 1:
		spawn_enemy(phantom_scene)
	elif point_count == 10:
		spawn_enemy(bat_scene)
	elif point_count == 20:
		spawn_enemy(spinner_scene)
	elif point_count % 10 == 0:
		spawn_enemy([phantom_scene, bat_scene, spinner_scene].pick_random())


func spawn_enemy(enemy_scene: PackedScene):
	var spawn_pos = get_random_point_away_from_player(SAFE_DISTANCE_ENEMY)
	var enemy = enemy_scene.instantiate()
# Add enemy as the first child so it's drawn below existing enemies:
	add_child(enemy)
	move_child(enemy, 0)  # Move to the bottom of draw order (drawn first = behind)
	enemy.global_position = spawn_pos
	enemy.z_as_relative = false # same z-index for all
	enemy.z_index = 6
