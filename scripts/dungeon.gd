extends TileMapLayer
## The endless corridor: builds rows below the view as it scrolls down and drops
## the rows, and everything on them, that scroll off the top.
##
## A two-column safe path winds down the corridor and never holds a hazard, so
## the player can always get through. Coins run along it.

signal coin_picked_up

@export var coin_scene: PackedScene
@export var spikes_scene: PackedScene
@export var pit_scene: PackedScene

const LEFT_WALL_COLUMN := -4
const RIGHT_WALL_COLUMN := 3
const FIRST_FLOOR_COLUMN := LEFT_WALL_COLUMN + 1
const LAST_FLOOR_COLUMN := RIGHT_WALL_COLUMN - 1
const LEFT_WALL_TILE := Vector2i(0, 9)
const RIGHT_WALL_TILE := Vector2i(5, 9)
const FLOOR_TILE := Vector2i(7, 11)
const FLOOR_DETAIL_TILES: Array[Vector2i] = [Vector2i(8, 11), Vector2i(8, 12), Vector2i(9, 12)]
const FLOOR_DETAIL_CHANCE := 0.08

const PATH_TURN_CHANCE := 0.25
# Rows below the player's start with no hazards, so a run opens gently.
const ROWS_BEFORE_HAZARDS := 12
# Chance that a floor cell off the safe path holds a hazard. It grows with each
# row past the opening, up to the max.
const HAZARD_CHANCE_PER_ROW := 0.004
const MAX_HAZARD_CHANCE := 0.45
const CRUMBLING_PIT_SHARE := 0.3
const SPIKES_SHARE := 0.3
# Pixels in from a hazard cell's edges where the player's feet set it off, so
# brushing a corner doesn't count.
const HAZARD_EDGE_GRACE := 3.0

const COIN_RUN_LENGTH := Vector2i(3, 5)
const ROWS_BETWEEN_COIN_RUNS := Vector2i(2, 6)
# Keeps the first coins out from under the player at the start of a run.
const ROWS_BEFORE_FIRST_COIN_RUN := 3

var _top_row: int
var _next_row: int
var _first_hazard_row: int
var _path_column := randi_range(FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN - 1)
var _hazards: Dictionary[Vector2i, Node2D] = {}
var _coin_path_side := 0
var _coins_left_in_run := 0
var _rows_until_coin_run := ROWS_BEFORE_FIRST_COIN_RUN


func start(view: Rect2) -> void:
	_top_row = _row_at(view.position.y)
	_next_row = _top_row
	var start_row := _row_at(view.get_center().y)
	_first_hazard_row = start_row + ROWS_BEFORE_HAZARDS
	_rows_until_coin_run += start_row - _top_row
	follow(view)


func follow(view: Rect2) -> void:
	while _next_row <= _row_at(view.end.y):
		_build_row(_next_row)
		_next_row += 1
	while _top_row < _row_at(view.position.y):
		_drop_row(_top_row)
		_top_row += 1


## The hazard whose cell the point stands well inside, if any.
func hazard_at(point: Vector2) -> Node2D:
	var local := to_local(point)
	var cell := local_to_map(local)
	var hazard: Node2D = _hazards.get(cell)
	if hazard == null:
		return null
	var tile_size := Vector2(tile_set.tile_size)
	var cell_rect := Rect2(map_to_local(cell) - tile_size / 2, tile_size)
	return hazard if cell_rect.grow(-HAZARD_EDGE_GRACE).has_point(local) else null


func _row_at(y: float) -> int:
	return floori(y / tile_set.tile_size.y)


func _build_row(row: int) -> void:
	set_cell(Vector2i(LEFT_WALL_COLUMN, row), 0, LEFT_WALL_TILE)
	set_cell(Vector2i(RIGHT_WALL_COLUMN, row), 0, RIGHT_WALL_TILE)
	for column in range(FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN + 1):
		var tile := FLOOR_TILE
		if randf() < FLOOR_DETAIL_CHANCE:
			tile = FLOOR_DETAIL_TILES.pick_random()
		set_cell(Vector2i(column, row), 0, tile)

	var path := _advance_path()
	var hazard_chance := clampf((row - _first_hazard_row) * HAZARD_CHANCE_PER_ROW, 0.0, MAX_HAZARD_CHANCE)
	for column in range(FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN + 1):
		if column not in path and randf() < hazard_chance:
			_place_hazard(Vector2i(column, row))
	_place_coins(row)


# Returns the columns this row keeps clear. When the path shifts a column, the row
# it shifts on keeps both the old and the new columns clear, so the path stays
# two tiles wide through the turn.
func _advance_path() -> Array:
	var from := _path_column
	if randf() < PATH_TURN_CHANCE:
		_path_column = clampi(_path_column + [-1, 1].pick_random(), FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN - 1)
	return range(mini(from, _path_column), maxi(from, _path_column) + 2)


func _place_hazard(cell: Vector2i) -> void:
	var roll := randf()
	var hazard: Node2D
	if roll < SPIKES_SHARE:
		hazard = spikes_scene.instantiate()
	else:
		hazard = pit_scene.instantiate()
		hazard.crumbles = roll < SPIKES_SHARE + CRUMBLING_PIT_SHARE
	hazard.position = map_to_local(cell)
	add_child(hazard)
	_hazards[cell] = hazard


# Coins come in short runs along the safe path, like the lines of coins in Subway Surfers.
func _place_coins(row: int) -> void:
	if _coins_left_in_run == 0:
		_rows_until_coin_run -= 1
		if _rows_until_coin_run > 0:
			return
		_coins_left_in_run = randi_range(COIN_RUN_LENGTH.x, COIN_RUN_LENGTH.y)
		_rows_until_coin_run = randi_range(ROWS_BETWEEN_COIN_RUNS.x, ROWS_BETWEEN_COIN_RUNS.y)
		_coin_path_side = randi_range(0, 1)

	var coin := coin_scene.instantiate()
	coin.position = map_to_local(Vector2i(_path_column + _coin_path_side, row))
	coin.z_as_relative = false
	coin.z_index = 1
	# Deferred: picked_up fires inside a physics callback, where spawning new bodies is refused.
	coin.picked_up.connect(coin_picked_up.emit, CONNECT_DEFERRED)
	add_child(coin)
	_coins_left_in_run -= 1


func _drop_row(row: int) -> void:
	for column in range(LEFT_WALL_COLUMN, RIGHT_WALL_COLUMN + 1):
		erase_cell(Vector2i(column, row))
		_hazards.erase(Vector2i(column, row))
	var row_bottom := (row + 1) * tile_set.tile_size.y
	for child in get_children():
		if child.position.y < row_bottom:
			child.queue_free()
