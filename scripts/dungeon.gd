extends TileMapLayer
## The endless corridor: builds rows above the view as it scrolls up and drops
## the rows, and everything on them, that scroll off the bottom.
##
## A two-column safe path winds up the corridor and never holds a hazard, so
## the player can always get through. Coins run along it. The strip along each
## wall is an open lane too: the player's feet stop past the outermost floor
## column there, so its hazards never trigger, and nothing solid stands in it.

signal coin_picked_up

@export var coin_scene: PackedScene
@export var spikes_scene: PackedScene
@export var pit_scene: PackedScene
@export var bomberplant_scene: PackedScene
@export var chest_scene: PackedScene
@export var key_scene: PackedScene

const LEFT_WALL_COLUMN := -4
const RIGHT_WALL_COLUMN := 3
const FIRST_FLOOR_COLUMN := LEFT_WALL_COLUMN + 1
const LAST_FLOOR_COLUMN := RIGHT_WALL_COLUMN - 1
const LEFT_WALL_TILE := Vector2i(0, 9)
const RIGHT_WALL_TILE := Vector2i(5, 9)
const FLOOR_TILE := Vector2i(7, 11)
const FLOOR_DETAIL_TILES: Array[Vector2i] = [Vector2i(8, 11), Vector2i(8, 12), Vector2i(9, 12)]
const FLOOR_DETAIL_CHANCE := 0.08
# The hand-made floor of the old fixed room, under the player and the high score,
# so a run opens on it before the corridor takes over. One string per row from
# START_FLOOR_FIRST_ROW, one character per floor column.
const START_FLOOR_FIRST_ROW := -5
const START_FLOOR: Array[String] = [
	"......",
	"......",
	".a..b.",
	"......",
	"......",
	"..aa..",
	"cccccc",
	"cccccc",
	"....a.",
	".b....",
	"......",
	"......",
]
const LINE_TILE := Vector2i(9, 12)
const START_FLOOR_TILES := {".": FLOOR_TILE, "a": Vector2i(8, 11), "b": Vector2i(8, 12), "c": LINE_TILE}

const PATH_TURN_CHANCE := 0.25
# Rows ahead of the player's start with no hazards, so a run opens gently.
const ROWS_BEFORE_HAZARDS := 12
# Holes come in clusters: a few seed cells, which spread to the cells ahead of and
# beside them. The seed chance grows with each row past the opening, up to the max.
const HOLE_SEED_CHANCE_PER_ROW := 0.00025
const MAX_HOLE_SEED_CHANCE := 0.035
const HOLE_SPREAD_CHANCE := 0.55
# Spikes and cracked floor are scattered one cell at a time, and ramp up the same way.
const TRAP_CHANCE_PER_ROW := 0.0012
const MAX_TRAP_CHANCE := 0.18
const SPIKES_SHARE := 0.5
# Bomberplants are solid, so like hazards they stay off the safe path. Only one
# grows at a time, so the built rows, and the view, never hold two.
const ROWS_BEFORE_PLANTS := 30
const PLANT_CHANCE_PER_ROW := 0.025
const ROWS_BEFORE_ITEMS := 20
const CHEST_CHANCE_PER_ROW := 0.008
const KEY_CHANCE_PER_ROW := 0.008
# Pixels in from a hazard cell's edges where the player's feet set it off, so
# brushing a corner doesn't count.
const HAZARD_EDGE_GRACE := 3.0
# Pixels the feet must be from any floor to fall into an open hole. Wider than
# the trap grace, so the player can run along the rim with most of their body
# over the dark. Neighbouring holes count as one, so there is no rim between them.
const HOLE_EDGE_GRACE := 5.0

# Empty rows between one coin and the next, picked from these. The repeated 2
# makes short gaps likelier, for about 0.3 coins a row.
const ROWS_BETWEEN_COINS: Array[int] = [1, 2, 2, 3, 4]
# Rows ahead of the player's start before the first coin.
const ROWS_BEFORE_FIRST_COIN := 3

# Rows are built upward, from the bottom of the view. _next_row is the next one
# to build and _bottom_row the oldest one still built.
var _bottom_row: int
var _next_row: int
var _start_row: int
var _path_column := randi_range(FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN - 1)
# The safe path's columns in each built row.
var _path_columns: Dictionary[int, Array] = {}
var _hazards: Dictionary[Vector2i, Node2D] = {}
# Bomberplants and chests, which block the cell they stand on.
var _solids: Dictionary[Vector2i, Node2D] = {}
var _plant: Node2D
var _coin_path_side := 0
# Chests only spawn once a key has been picked up, so the first one is never unopenable.
var _key_found := false
var _rows_until_coin := ROWS_BEFORE_FIRST_COIN
# The rows of a line laid with lay_line() that are still to be built.
var _line_rows: Array[int] = []


func start(view: Rect2) -> void:
	_bottom_row = _row_at(view.end.y)
	_next_row = _bottom_row
	_start_row = _row_at(view.get_center().y)
	_rows_until_coin += _bottom_row - _start_row
	follow(view)


func follow(view: Rect2) -> void:
	while _next_row >= _row_at(view.position.y):
		_build_row(_next_row)
		_next_row -= 1
	while _bottom_row > _row_at(view.end.y):
		_drop_row(_bottom_row)
		_bottom_row -= 1


## Lays a line like the start floor's across the next two rows to scroll into
## view, clear of hazards and solids, and returns its center in local coordinates.
func lay_line() -> Vector2:
	_line_rows = [_next_row, _next_row - 1]
	return Vector2(0, _next_row * tile_set.tile_size.y)


## The hazard whose cell the point stands well inside, if any.
func hazard_at(point: Vector2) -> Node2D:
	var local := to_local(point)
	var cell := local_to_map(local)
	var hazard: Node2D = _hazards.get(cell)
	if hazard == null:
		return null
	if _is_open_hole(cell):
		var feet := Rect2(local, Vector2.ZERO).grow(HOLE_EDGE_GRACE)
		return hazard if _is_over_open_holes(feet) else null
	var tile_size := Vector2(tile_set.tile_size)
	var cell_rect := Rect2(map_to_local(cell) - tile_size / 2, tile_size)
	return hazard if cell_rect.grow(-HAZARD_EDGE_GRACE).has_point(local) else null


## Whether the point is on plain floor, with no hazard or solid in its cell.
func is_free(point: Vector2) -> bool:
	return _is_free_cell(local_to_map(to_local(point)))


## A random spot of plain floor within a few rows of the point, in local
## coordinates, for things that land on the floor.
func free_spot_near(point: Vector2) -> Vector2:
	var origin := local_to_map(point)
	var cells := _free_cells(origin.y - 3, origin.y + 2).filter(func(cell): return cell != origin)
	return map_to_local(cells.pick_random()) if not cells.is_empty() else point


## A random spot on the safe path within a few rows of the point, in local
## coordinates, so whoever is put there can always get through.
func path_spot_near(point: Vector2) -> Vector2:
	var origin := local_to_map(point)
	var cells := _free_cells(origin.y - 3, origin.y + 2).filter(func(cell): return cell.x in _path_columns.get(cell.y, []))
	return map_to_local(cells.pick_random()) if not cells.is_empty() else point


## The centers of plain floor cells inside the band, in global coordinates.
func free_spots_in(band: Rect2) -> Array:
	var cells := _free_cells(_row_at(to_local(band.position).y), _row_at(to_local(band.end).y))
	return cells.map(func(cell): return to_global(map_to_local(cell))) \
		.filter(func(spot): return spot.y >= band.position.y and spot.y <= band.end.y)


# Free cells in the built rows between first_row and last_row, inclusive.
func _free_cells(first_row: int, last_row: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row in range(maxi(first_row, _next_row + 1), mini(last_row, _bottom_row) + 1):
		for column in range(FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN + 1):
			var cell := Vector2i(column, row)
			if _is_free_cell(cell):
				cells.append(cell)
	return cells


func _is_free_cell(cell: Vector2i) -> bool:
	return not _hazards.has(cell) and not _solids.has(cell)


func _row_at(y: float) -> int:
	return floori(y / tile_set.tile_size.y)


func _build_row(row: int) -> void:
	set_cell(Vector2i(LEFT_WALL_COLUMN, row), 0, LEFT_WALL_TILE)
	set_cell(Vector2i(RIGHT_WALL_COLUMN, row), 0, RIGHT_WALL_TILE)
	var on_line := row in _line_rows
	for column in range(FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN + 1):
		set_cell(Vector2i(column, row), 0, LINE_TILE if on_line else _floor_tile(column, row))

	var path := _advance_path()
	_path_columns[row] = path
	# A line keeps its whole row clear, like the path does its columns.
	var clear := range(FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN + 1) if on_line else path
	var rows_ahead := _start_row - row
	var depth := rows_ahead - ROWS_BEFORE_HAZARDS
	var hole_seed_chance := clampf(depth * HOLE_SEED_CHANCE_PER_ROW, 0.0, MAX_HOLE_SEED_CHANCE)
	var trap_chance := clampf(depth * TRAP_CHANCE_PER_ROW, 0.0, MAX_TRAP_CHANCE)
	for column in range(FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN + 1):
		if column in clear:
			continue
		var cell := Vector2i(column, row)
		var beside_hole := _is_hole(cell + Vector2i.DOWN) or _is_hole(cell + Vector2i.LEFT)
		if randf() < (HOLE_SPREAD_CHANCE if beside_hole else hole_seed_chance):
			_place_hole(cell)
		elif randf() < trap_chance:
			_place_trap(cell)
	if rows_ahead >= ROWS_BEFORE_PLANTS and not is_instance_valid(_plant) and randf() < PLANT_CHANCE_PER_ROW:
		_plant = _place_solid(bomberplant_scene, row, _solid_columns(row, clear))
	if _key_found and rows_ahead >= ROWS_BEFORE_ITEMS and randf() < CHEST_CHANCE_PER_ROW:
		# Right beside the path, so the player can always reach it.
		var beside_path := [path.front() - 1, path.back() + 1]
		_place_solid(chest_scene, row, _solid_columns(row, clear).filter(func(column): return column in beside_path))
	_place_coins(row)
	if rows_ahead >= ROWS_BEFORE_ITEMS and randf() < KEY_CHANCE_PER_ROW:
		# On the path column the coins aren't using.
		var key := key_scene.instantiate()
		key.position = map_to_local(Vector2i(_path_column + 1 - _coin_path_side, row))
		key.picked_up.connect(func(): _key_found = true)
		add_child(key)


func _floor_tile(column: int, row: int) -> Vector2i:
	var start_floor_row := row - START_FLOOR_FIRST_ROW
	if start_floor_row >= 0 and start_floor_row < START_FLOOR.size():
		return START_FLOOR_TILES[START_FLOOR[start_floor_row][column - FIRST_FLOOR_COLUMN]]
	if randf() < FLOOR_DETAIL_CHANCE:
		return FLOOR_DETAIL_TILES.pick_random()
	return FLOOR_TILE


# Returns the columns this row keeps clear. When the path shifts a column, the row
# it shifts on keeps both the old and the new columns clear, so the path stays
# two tiles wide through the turn.
func _advance_path() -> Array:
	var from := _path_column
	if randf() < PATH_TURN_CHANCE:
		_path_column = clampi(_path_column + [-1, 1].pick_random(), FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN - 1)
	return range(mini(from, _path_column), maxi(from, _path_column) + 2)


# Off the path and the outermost floor columns, so solids never block the wall lanes.
func _solid_columns(row: int, path: Array) -> Array:
	return range(FIRST_FLOOR_COLUMN + 1, LAST_FLOOR_COLUMN).filter(func(column):
		var cell := Vector2i(column, row)
		return column not in path and _is_free_cell(cell))


func _place_solid(scene: PackedScene, row: int, columns: Array) -> Node2D:
	if columns.is_empty():
		return null
	var cell := Vector2i(columns.pick_random(), row)
	var solid: Node2D = scene.instantiate()
	solid.position = map_to_local(cell)
	add_child(solid)
	_solids[cell] = solid
	return solid


func _is_hole(cell: Vector2i) -> bool:
	var hazard = _hazards.get(cell)
	return hazard is Pit and not hazard.crumbles


func _is_open_hole(cell: Vector2i) -> bool:
	var hazard = _hazards.get(cell)
	return hazard is Pit and hazard.is_open()


func _is_over_open_holes(rect: Rect2) -> bool:
	var first := local_to_map(rect.position)
	var last := local_to_map(rect.end)
	for column in range(first.x, last.x + 1):
		for row in range(first.y, last.y + 1):
			if not _is_open_hole(Vector2i(column, row)):
				return false
	return true


func _place_hole(cell: Vector2i) -> void:
	_place_hazard(cell, pit_scene.instantiate())


func _place_trap(cell: Vector2i) -> void:
	if randf() < SPIKES_SHARE:
		_place_hazard(cell, spikes_scene.instantiate())
	else:
		var cracked_floor: Pit = pit_scene.instantiate()
		cracked_floor.crumbles = true
		_place_hazard(cell, cracked_floor)


func _place_hazard(cell: Vector2i, hazard: Node2D) -> void:
	hazard.position = map_to_local(cell)
	add_child(hazard)
	_hazards[cell] = hazard


# Coins are spread out one at a time along the safe path, on either of its columns.
func _place_coins(row: int) -> void:
	if _rows_until_coin > 0:
		_rows_until_coin -= 1
		return
	_rows_until_coin = ROWS_BETWEEN_COINS.pick_random()
	_coin_path_side = randi_range(0, 1)

	var coin := coin_scene.instantiate()
	coin.position = map_to_local(Vector2i(_path_column + _coin_path_side, row))
	coin.z_as_relative = false
	coin.z_index = 1
	# Deferred: picked_up fires inside a physics callback, where spawning new bodies is refused.
	coin.picked_up.connect(coin_picked_up.emit, CONNECT_DEFERRED)
	add_child(coin)


func _drop_row(row: int) -> void:
	_path_columns.erase(row)
	for column in range(LEFT_WALL_COLUMN, RIGHT_WALL_COLUMN + 1):
		erase_cell(Vector2i(column, row))
		_hazards.erase(Vector2i(column, row))
		_solids.erase(Vector2i(column, row))
	var row_top := row * tile_set.tile_size.y
	for child in get_children():
		if child.position.y >= row_top:
			child.queue_free()
