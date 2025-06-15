extends Node2D

@export var point: PackedScene
@export var phantom_scene: PackedScene
@export var bat_scene: PackedScene
@onready var player = $Player
@onready var camera = $Camera2D
@export var debug := false
@export var tilemap: TileMap  # Drag your TileMap node into this slot in the editor
@onready var score_label = $ScoreLabel
@onready var high_score_var_label = $HighScoreVarLabel


var current_point = null
@export var SAFE_DISTANCE_POINT := 50
@export var SAFE_DISTANCE_ENEMY := 100  # Minimum distance from player (pixels)
var point_count := 0

@export var padding_top := 30
@export var padding_bottom := 12
@export var padding_left := 5
@export var padding_right := 5

func _ready():
	if debug and tilemap:
		tilemap.modulate.a = 0.3

	high_score_var_label.text = str(ScoreManager.high_score)
	spawn_point()

func _process(_delta):
	if debug:
		queue_redraw()

	if(player.is_dead):
		if point_count > ScoreManager.high_score:
			ScoreManager.high_score = point_count
			ScoreManager.save_high_score()


func _draw():
	if not debug:
		return

	var viewport_rect = get_viewport_rect()
	var cam_pos = camera.global_position
	var half_screen = Vector2(viewport_rect.size.x, viewport_rect.size.y) * 0.5 / camera.zoom

	# Existing debug rectangles
	var rect_min = cam_pos - half_screen
	var rect_max = cam_pos + half_screen
	var full_rect = Rect2(rect_min, rect_max - rect_min)

	var padded_min = rect_min + Vector2(padding_left, padding_top)
	var padded_max = rect_max - Vector2(padding_right, padding_bottom)
	var padded_rect = Rect2(padded_min, padded_max - padded_min)

	# Draw existing debug rects
	draw_rect(full_rect, Color(1, 0, 0, 0.3), false, 3)
	draw_rect(padded_rect, Color(0, 1, 0, 0.3), false, 3)

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

	current_point.connect("picked_up", Callable(self, "_on_point_picked_up"))


func get_random_point_away_from_player(distance) -> Vector2:
	var viewport_rect = get_viewport_rect()
	var cam_pos = camera.global_position
	var half_screen = Vector2(viewport_rect.size.x, viewport_rect.size.y) * 0.5 / camera.zoom

	# Calculate camera visible rect in world coords
	var rect_min = cam_pos - half_screen
	var rect_max = cam_pos + half_screen

	# Apply padding
	rect_min.x += padding_left
	rect_max.x -= padding_right
	rect_min.y += padding_top      # exclude top part
	rect_max.y -= padding_bottom   # exclude bottom part

	# Try to find a spawn pos away from player
	for i in range(999):
		var x = randf_range(rect_min.x, rect_max.x)
		var y = randf_range(rect_min.y, rect_max.y)
		var spawn_pos = Vector2(x, y)

		if spawn_pos.distance_to(player.global_position) > distance:
			return spawn_pos

	# fallback position if none found after attempts
	return Vector2(
		clamp(cam_pos.x, rect_min.x, rect_max.x),
		clamp(cam_pos.y, rect_min.y, rect_max.y)
	)

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
