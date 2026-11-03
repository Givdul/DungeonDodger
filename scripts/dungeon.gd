extends TileMapLayer
## The endless corridor: builds rows below the view as it scrolls down and drops
## the rows, and the coins on them, that scroll off the top.

signal coin_picked_up

@export var coin_scene: PackedScene

const LEFT_WALL_COLUMN := -4
const RIGHT_WALL_COLUMN := 3
const LEFT_WALL_TILE := Vector2i(0, 9)
const RIGHT_WALL_TILE := Vector2i(5, 9)
const FLOOR_TILE := Vector2i(7, 11)
const FLOOR_DETAIL_TILES: Array[Vector2i] = [Vector2i(8, 11), Vector2i(8, 12), Vector2i(9, 12)]
const FLOOR_DETAIL_CHANCE := 0.08
const COIN_RUN_LENGTH := Vector2i(3, 5)
const ROWS_BETWEEN_COIN_RUNS := Vector2i(2, 6)
# Keeps the first coins out from under the player at the start of a run.
const ROWS_BEFORE_FIRST_COIN_RUN := 3

var _top_row: int
var _next_row: int
var _coin_column := 0
var _coins_left_in_run := 0
var _rows_until_coin_run := ROWS_BEFORE_FIRST_COIN_RUN


func start(view: Rect2) -> void:
	_top_row = _row_at(view.position.y)
	_next_row = _top_row
	_rows_until_coin_run += _row_at(view.get_center().y) - _top_row
	follow(view)


func follow(view: Rect2) -> void:
	while _next_row <= _row_at(view.end.y):
		_build_row(_next_row)
		_next_row += 1
	while _top_row < _row_at(view.position.y):
		_drop_row(_top_row)
		_top_row += 1


func _row_at(y: float) -> int:
	return floori(y / tile_set.tile_size.y)


func _build_row(row: int) -> void:
	set_cell(Vector2i(LEFT_WALL_COLUMN, row), 0, LEFT_WALL_TILE)
	set_cell(Vector2i(RIGHT_WALL_COLUMN, row), 0, RIGHT_WALL_TILE)
	for column in range(LEFT_WALL_COLUMN + 1, RIGHT_WALL_COLUMN):
		var tile := FLOOR_TILE
		if randf() < FLOOR_DETAIL_CHANCE:
			tile = FLOOR_DETAIL_TILES.pick_random()
		set_cell(Vector2i(column, row), 0, tile)
	_place_coins(row)


# Coins come in short runs down one column, like the lines of coins in Subway Surfers.
func _place_coins(row: int) -> void:
	if _coins_left_in_run == 0:
		_rows_until_coin_run -= 1
		if _rows_until_coin_run > 0:
			return
		_coins_left_in_run = randi_range(COIN_RUN_LENGTH.x, COIN_RUN_LENGTH.y)
		_rows_until_coin_run = randi_range(ROWS_BETWEEN_COIN_RUNS.x, ROWS_BETWEEN_COIN_RUNS.y)
		_coin_column = randi_range(LEFT_WALL_COLUMN + 1, RIGHT_WALL_COLUMN - 1)

	var coin := coin_scene.instantiate()
	coin.position = map_to_local(Vector2i(_coin_column, row))
	coin.z_as_relative = false
	coin.z_index = 1
	# Deferred: picked_up fires inside a physics callback, where spawning new bodies is refused.
	coin.picked_up.connect(coin_picked_up.emit, CONNECT_DEFERRED)
	add_child(coin)
	_coins_left_in_run -= 1


func _drop_row(row: int) -> void:
	for column in range(LEFT_WALL_COLUMN, RIGHT_WALL_COLUMN + 1):
		erase_cell(Vector2i(column, row))
	var row_bottom := (row + 1) * tile_set.tile_size.y
	for child in get_children():
		if child.position.y < row_bottom:
			child.queue_free()
