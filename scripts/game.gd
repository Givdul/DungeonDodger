extends Node2D
## Draw order: the floor tiles alone on z 0, then what lies on the floor (holes, traps, coins, keys, markers),
## then the text on the floor. Everything that stands (the player, walking enemies, plants, chests, landed
## bombs, raised gate bars) shares z 5, where the game and the dungeon y-sort it, so whatever stands lower on
## the screen draws in front. Each of those has y-sort on too and its sprite on its lowest opaque row, so it
## sorts by where it touches the floor, not by its origin. Bats fly over it on z 6, and what is in the air (thrown bombs, blasts, hopping
## potions) on z 7.

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
@onready var new_high_score_label: Label = $NewHighScoreLabel
@onready var ui = $UI
@onready var swipe_hint: Label = $SwipeHint

# The view holds still until the first swipe or key press of a run. Pausing and resuming do not reset it.
var run_started := false

# Static so it survives reload_current_scene(): a restart skips the start screen.
static var _restarting := false

var point_count := 0
# What this run adds to Progress when it ends, in game seconds while playing.
var run_stats := {"hits": 0, "holes": 0, "potions": 0, "chests": 0, "seconds": 0.0, "best_unhit_seconds": 0.0}
var _unhit_seconds := 0.0
var _lives: int
# Off for the gameplay bot, whose runs leave the high score and saved progress alone.
var saves_progress := true

# Inset from the side walls (the Bounds bodies) that enemies and bats keep to.
@export var padding_left := 6
@export var padding_right := 6

# Pixels per second the view scrolls up. It speeds up with the score, up to the max.
# Keep the max well below the phantoms' speed, or they fall behind and never catch up.
@export var start_scroll_speed := 20.0
@export var scroll_speed_per_point := 0.15
@export var max_scroll_speed := 27.0

# With this many enemies out, dying ones included, a score milestone spawns nothing.
@export var max_enemies := 7
# An enemy comes every this many points.
const POINTS_PER_ENEMY := 10

# How far inside the view's top and bottom edges the player's feet stay, and
# where bombs land. The top one keeps sprites below the hearts and score.
const VIEW_TOP_MARGIN := 44.0
const VIEW_BOTTOM_MARGIN := 8.0
# How far past the screen's top or bottom edge an enemy spawns: about half its sprite, so it
# starts out of sight. Keep it under a tile row, which the dungeon builds above the view.
const ENEMY_SPAWN_MARGIN := 12.0
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
	dungeon.chest_opened.connect(func(): run_stats.chests += 1)
	_lives = player.current_lives
	player.lives_changed.connect(_on_lives_changed)
	player.fell_into_hole.connect(func(): run_stats.holes += 1)
	player.died.connect(_on_player_died)
	player.fell.connect(_on_player_fell)
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
	run_stats.seconds += delta
	_unhit_seconds += delta
	run_stats.best_unhit_seconds = maxf(run_stats.best_unhit_seconds, _unhit_seconds)
	camera.position.y -= scroll_speed() * delta
	dungeon.follow(screen_rect(), delta)
	# The scroll edge and hazards leave a falling player alone until they are back on the floor.
	if player.is_falling:
		return
	_keep_player_in_view()
	var hazard = dungeon.hazard_at(player.position)
	if hazard is Pit:
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


# A heart lost is a hit, falls included; one gained is a potion drunk.
func _on_lives_changed(lives: int) -> void:
	if lives < _lives:
		run_stats.hits += 1
		_unhit_seconds = 0.0
	elif lives > _lives:
		run_stats.potions += 1
	_lives = lives


func _on_player_died():
	var is_new_best := point_count > ScoreManager.high_score
	var new_heroes: Array[String] = []
	if saves_progress:
		if is_new_best:
			ScoreManager.high_score = point_count
			ScoreManager.save_high_score()
		run_stats.crystals = point_count
		new_heroes = Progress.record_run(run_stats)
	ui.show_game_over(point_count, ScoreManager.high_score, is_new_best, new_heroes)


# Back on the safe path near the middle of the view, clear of the scroll edge.
func _on_player_fell():
	var middle: Vector2 = dungeon.to_local(floor_band().get_center())
	player.global_position = dungeon.to_global(dungeon.path_spot_near(middle))
	player.start_invulnerability()


func _restart():
	_restarting = true
	get_tree().reload_current_scene()


func _draw():
	if not debug:
		return

	draw_rect(playable_area(), Color(0, 1, 0, 0.3), false, 3)


func is_between_walls(x: float) -> bool:
	return x > $Bounds/LeftWorldBound.position.x + padding_left \
		and x < $Bounds/RightWorldBound.position.x - padding_right


# Between the walls, in the floor band: where bats rush, and the x range enemies spawn in.
func playable_area() -> Rect2:
	var band := floor_band()
	var left: float = $Bounds/LeftWorldBound.position.x + padding_left
	var right: float = $Bounds/RightWorldBound.position.x - padding_right
	return Rect2(left, band.position.y, right - left, band.size.y)


func _on_point_picked_up():
	point_count += 1
	score_label.text = str(point_count)
	ui.speed_up_for_score(point_count)
	# ScoreManager.high_score is the old best until the run ends.
	if ScoreManager.high_score > 0 and point_count == ScoreManager.high_score + 1:
		_lay_new_high_score_line()

	if get_tree().get_node_count_in_group("Enemies") >= max_enemies:
		return
	if point_count % POINTS_PER_ENEMY != 0:
		return
	@warning_ignore("integer_division")
	spawn_enemy(_enemy_scene_for_milestone(point_count / POINTS_PER_ENEMY))


# Milestones 1 to 6 follow the opening order, a skipped one included. After that, the scarcest kind.
func _enemy_scene_for_milestone(milestone: int) -> PackedScene:
	var opening: Array[PackedScene] = [phantom_scene, phantom_scene, bat_scene, phantom_scene, bat_scene, spinner_scene]
	if milestone <= opening.size():
		return opening[milestone - 1]
	return _scarcest_enemy_scene()


# The kind with the fewest out, dying ones included, ties broken at random, so the mix stays even.
# Bats hit hardest, so only one is out at a time.
func _scarcest_enemy_scene() -> PackedScene:
	var enemies := get_tree().get_nodes_in_group("Enemies")
	var alive := func(scene: PackedScene) -> int:
		return enemies.filter(func(enemy): return enemy.scene_file_path == scene.resource_path).size()
	var scenes: Array[PackedScene] = [phantom_scene, spinner_scene]
	if alive.call(bat_scene) == 0:
		scenes.append(bat_scene)
	scenes.shuffle()
	var counts := scenes.map(alive)
	return scenes[counts.find(counts.min())]


func _lay_new_high_score_line() -> void:
	var center: Vector2 = dungeon.to_global(dungeon.lay_line())
	new_high_score_label.global_position = center - new_high_score_label.size / 2
	new_high_score_label.show()


# Just past the top or bottom edge of the screen, whichever is further from the player,
# between the walls and on free floor where the dungeon has built the row. A spinner starts flush
# against a wall instead, in the lane along it that no hazard reaches, so its first run doesn't take
# it into a hole and the lanes aren't safe from it.
func _enemy_spawn_point(enemy: Node2D) -> Vector2:
	var screen := screen_rect()
	var from_top: bool = player.global_position.y > screen.get_center().y
	var y := screen.position.y - ENEMY_SPAWN_MARGIN if from_top else screen.end.y + ENEMY_SPAWN_MARGIN
	if enemy.scene_file_path == spinner_scene.resource_path:
		# A pixel short of touching the wall, so a run along it doesn't scrape the wall and stop as a crash.
		var radius: float = enemy.get_node(^"CollisionShape2D").shape.radius * enemy.scale.x + 1.0
		var left: float = $Bounds/LeftWorldBound.position.x + radius
		var right: float = $Bounds/RightWorldBound.position.x - radius
		return Vector2([left, right].pick_random(), y)
	var spots: Array = dungeon.free_spots_on_row_at(y)
	if spots.is_empty():
		var area := playable_area()
		return Vector2(randf_range(area.position.x, area.end.x), y)
	return Vector2(spots.pick_random().x, y)


func spawn_enemy(enemy_scene: PackedScene):
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = _enemy_spawn_point(enemy)
