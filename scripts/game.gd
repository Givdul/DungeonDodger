extends Node2D

@export var point: PackedScene
@export var phantom_scene: PackedScene
@export var bat_scene: PackedScene
@onready var player = $Player
@onready var camera: Camera2D = $Camera2D
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

const TILE_SIZE := 16
# Rows of the room as authored for the 9:16 design viewport. The hearts and score
# sit on the row above the top wall's base.
const TOP_WALL_BASE_ROW := -6
const BOTTOM_WALL_ROW := 6
const FLOOR_TILE := Vector2i(7, 11)
const LEFT_WALL_TILE := Vector2i(0, 9)
const RIGHT_WALL_TILE := Vector2i(5, 9)

@onready var walls_and_floor: TileMap = $"WorldTiles/all but last floor"
@onready var floor_under_bottom_wall: TileMap = $"WorldTiles/last floor"

var room: Rect2

func _ready():
	_fit_room_to_screen()
	room = _room_rect()

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


# Taller screens get a taller room: whole floor rows go in above and below the
# authored floor, and the camera puts the hearts and score just under the safe area.
func _fit_room_to_screen() -> void:
	var zoom := camera.zoom.y
	var view_height := get_viewport_rect().size.y / zoom
	var safe_top := SafeArea.in_viewport(get_viewport()).position.y / zoom
	var hud_row_top := (TOP_WALL_BASE_ROW - 1) * TILE_SIZE
	var authored_height := (BOTTOM_WALL_ROW + 1) * TILE_SIZE - hud_row_top
	var extra_rows := maxi(0, floori((view_height - safe_top - authored_height) / TILE_SIZE))
	var rows_above := floori(extra_rows / 2.0)
	var rows_below := extra_rows - rows_above

	_add_floor_rows(rows_above, rows_below)
	var shift_up := rows_above * TILE_SIZE
	$Bounds/TopWorldBound.position.y -= shift_up
	$Bounds/BottomWorldBound.position.y += rows_below * TILE_SIZE
	score_label.position.y -= shift_up
	$HealthContainer.position.y -= shift_up
	# Any leftover height below the bottom wall shows more wall.
	camera.position.y = hud_row_top - shift_up - safe_top + view_height / 2


func _add_floor_rows(above: int, below: int) -> void:
	if above == 0 and below == 0:
		return
	for tiles: TileMap in [walls_and_floor, floor_under_bottom_wall]:
		var moved := {}
		for cell in tiles.get_used_cells(0):
			var shift := 0
			if cell.y <= TOP_WALL_BASE_ROW:
				shift = -above
			elif cell.y >= BOTTOM_WALL_ROW:
				shift = below
			if shift != 0:
				moved[cell + Vector2i(0, shift)] = [tiles.get_cell_source_id(0, cell), tiles.get_cell_atlas_coords(0, cell)]
				tiles.erase_cell(0, cell)
		for cell: Vector2i in moved:
			tiles.set_cell(0, cell, moved[cell][0], moved[cell][1])

	var columns := walls_and_floor.get_used_rect()
	var new_rows := range(TOP_WALL_BASE_ROW + 1 - above, TOP_WALL_BASE_ROW + 1) \
		+ range(BOTTOM_WALL_ROW, BOTTOM_WALL_ROW + below)
	for y: int in new_rows:
		for x in range(columns.position.x, columns.end.x):
			var tile := FLOOR_TILE
			if x == columns.position.x:
				tile = LEFT_WALL_TILE
			elif x == columns.end.x - 1:
				tile = RIGHT_WALL_TILE
			walls_and_floor.set_cell(0, Vector2i(x, y), 0, tile)


func _room_rect() -> Rect2:
	var top_left := Vector2($Bounds/LeftWorldBound.position.x, $Bounds/TopWorldBound.position.y)
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
