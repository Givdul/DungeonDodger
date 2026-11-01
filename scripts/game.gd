extends Node2D

@export var point: PackedScene
@export var phantom_scene: PackedScene
@export var bat_scene: PackedScene
@onready var player = $Player
@export var debug := false
@export var tilemap: TileMap  # Drag your TileMap node into this slot in the editor
@onready var score_label = $ScoreLabel
@onready var high_score_var_label = $HighScoreVarLabel
@onready var ui = $UI

# Static so it survives reload_current_scene(): a restart skips the start screen.
static var _restarting := false


var current_point = null
@export var SAFE_DISTANCE_POINT := 50
@export var SAFE_DISTANCE_ENEMY := 100  # Minimum distance from player (pixels)
var point_count := 0

# Inset from the room's walls (the Bounds bodies) where points and enemies may spawn.
@export var padding_top := 9
@export var padding_bottom := 0
@export var padding_left := 6
@export var padding_right := 6

@onready var room := _room_rect()

func _ready():
	if debug and tilemap:
		tilemap.modulate.a = 0.3

	high_score_var_label.text = str(ScoreManager.high_score)
	spawn_point()

	player.died.connect(_on_player_died)
	ui.restart_requested.connect(_restart)
	if _restarting:
		_restarting = false
		ui.start_playing()
	else:
		ui.show_start(ScoreManager.high_score)

func _process(_delta):
	if debug:
		queue_redraw()

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

	draw_rect(room, Color(1, 0, 0, 0.3), false, 3)
	draw_rect(playable_area(), Color(0, 1, 0, 0.3), false, 3)

	# Draw safe distance circles
	# Enemy circle (blue, larger, behind)
	draw_arc(player.global_position, SAFE_DISTANCE_ENEMY, 0, TAU, 32, Color(0, 0, 1, 0.3), 2.0, true)

	# Point circle (yellow, smaller, in front)
	draw_arc(player.global_position, SAFE_DISTANCE_POINT, 0, TAU, 32, Color(1, 1, 0, 0.3), 2.0, true)

func spawn_point():
	var spawn_pos = get_random_point_away_from_player(SAFE_DISTANCE_POINT)

	current_point = point.instantiate()
	add_child(current_point)
	current_point.position = spawn_pos

	current_point.z_as_relative = false
	current_point.z_index = 1

	var sprite = current_point.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.z_index = 1

	# Deferred: picked_up fires inside a physics callback, where spawning new bodies is refused.
	current_point.connect("picked_up", Callable(self, "_on_point_picked_up"), CONNECT_DEFERRED)


func _room_rect() -> Rect2:
	var top_left := Vector2($Bounds/LeftWourldBound.position.x, $Bounds/TopWorldBound.position.y)
	var bottom_right := Vector2($Bounds/RightWorldBound.position.x, $Bounds/BottomWorldBound.position.y)
	return Rect2(top_left, bottom_right - top_left)


func playable_area() -> Rect2:
	return room.grow_individual(-padding_left, -padding_top, -padding_right, -padding_bottom)


func get_random_point_away_from_player(distance) -> Vector2:
	var area := playable_area()
	var rect_min := area.position
	var rect_max := area.end

	# Try to find a spawn pos away from player
	for i in range(999):
		var x = randf_range(rect_min.x, rect_max.x)
		var y = randf_range(rect_min.y, rect_max.y)
		var spawn_pos = Vector2(x, y)

		if spawn_pos.distance_to(player.global_position) > distance:
			return spawn_pos

	# fallback position if none found after attempts
	return area.get_center()

func _on_point_picked_up():			
	point_count += 1
	score_label.text = str(point_count)
	spawn_point()

	if(point_count == 1):
		spawn_enemy(phantom_scene)
		return

	if(point_count == 10):
		# Spawn a bat after the first 10 points
		spawn_enemy(bat_scene)
		return

	if point_count % 10 == 0:
		var enemy_scene = phantom_scene
		if randi() % 2 == 0:
			enemy_scene = bat_scene
		spawn_enemy(enemy_scene)


func spawn_enemy(enemy_scene: PackedScene):
	var spawn_pos = get_random_point_away_from_player(SAFE_DISTANCE_ENEMY)
	var enemy = enemy_scene.instantiate()
# Add enemy as the first child so it's drawn below existing enemies:
	add_child(enemy)
	move_child(enemy, 0)  # Move to the bottom of draw order (drawn first = behind)
	enemy.global_position = spawn_pos
	enemy.z_as_relative = false # same z-index for all
	enemy.z_index = 6
