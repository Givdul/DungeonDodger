extends TileMapLayer
## The endless corridor: builds rows above the view as it scrolls up and drops
## the rows, and everything on them, that scroll off the bottom.
##
## Hazards come in hand-made patterns with plain floor between them. A two-column
## safe path winds up the corridor and never holds a hazard: it is planned
## through each pattern's gaps before the pattern is built, so the player can
## always get through. Coins sit on it or on the free floor beside it. The strip along each wall is an open
## lane too: the player's feet stop past the outermost floor column there, so
## its hazards never trigger, and nothing solid stands in it. Patterns keep
## their hazards off those columns, so every hazard drawn can trigger.

signal coin_picked_up
signal chest_opened

@export var coin_scene: PackedScene
@export var spikes_scene: PackedScene
@export var gate_scene: PackedScene
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
const LINE_TILE := Vector2i(10, 12)
const START_FLOOR_TILES := {".": FLOOR_TILE, "a": Vector2i(8, 11), "b": Vector2i(8, 12), "c": LINE_TILE}

const PATH_TURN_CHANCE := 0.25
# Rows ahead of the player's start with no hazards, so a run opens gently.
const ROWS_BEFORE_HAZARDS := 12

# Hazard patterns, one string per row from the top, one character per floor column: . plain floor,
# o hole, c cracked floor, x failing floor, which collapses by itself low on the screen, s spikes on
# their own phase, 1 2 3 4 spikes rising in that order, g h gates rising half a cycle apart. A pattern
# may be mirrored. Every row leaves two adjacent plain columns, and the safe path steers through
# them. It turns one column a row, only where both its old and new columns are plain, so a pattern
# that moves the only gap across the corridor needs plain rows to turn in.
# The corridor is six columns wide, so shapes come in twos and fours, in both directions, to line
# up with it. A gate's bars fill the tile above it as well, so a single row of gates is two tall.
const PLAIN := "."
const PLAIN_ROW := "......"
const HOLE: Array[String] = [
	"..oo..",
	"..oo..",
]
const SPIKE_BLOCK: Array[String] = [
	"..ss..",
	"..ss..",
]
const HOLE_SIDES: Array[String] = [
	"oo..oo",
	"oo..oo",
]
const CRACK_STEPS: Array[String] = [
	"...cc.",
	"...cc.",
	"......",
	"......",
	".cc...",
	".cc...",
]
const SPIKE_SIDES: Array[String] = [
	"ss..ss",
	"ss..ss",
]
const SPIKE_CHECKER: Array[String] = [
	"ss..ss",
	"ss..ss",
	"......",
	"......",
	"..ss..",
	"..ss..",
]
const HOLE_STAGGER: Array[String] = [
	"...oo.",
	"...oo.",
	"......",
	"......",
	".oo...",
	".oo...",
]
const SPIKE_WAVE: Array[String] = [
	"1122..",
	"1122..",
]
const CRACKED_FIELD: Array[String] = [
	"cccc..",
	"cccc..",
	"cccc..",
	"cccc..",
]
const HOLE_BLOCK: Array[String] = [
	"oooo..",
	"oooo..",
]
const GATE_BARRIER: Array[String] = [
	"gggg..",
]
const CRACK_LANES: Array[String] = [
	"cc..cc",
	"cc..cc",
	"cc..cc",
	"cc..cc",
]
const SPIKE_RIPPLE: Array[String] = [
	"22..11",
	"22..11",
]
const FAILING_STRIP: Array[String] = [
	"..xx..",
	"..xx..",
	"..xx..",
	"..xx..",
]
const CRACKED_RIM_HOLE: Array[String] = [
	"cccc..",
	"cooc..",
	"cooc..",
	"cccc..",
]
const SPIKE_SWEEP: Array[String] = [
	"1234..",
	"1234..",
]
const SPIKE_SLALOM: Array[String] = [
	"ssss..",
	"ssss..",
	"......",
	"......",
	"......",
	"......",
	"..ssss",
	"..ssss",
]
const SPIKE_MARCH: Array[String] = [
	"2222..",
	"2222..",
	"......",
	"......",
	"1111..",
	"1111..",
]
const GATE_ZIPPER: Array[String] = [
	"hhgg..",
	"......",
	"gghh..",
	"......",
]
const HOLE_BRIDGE: Array[String] = [
	"oooo..",
	"oooo..",
	"cccc..",
	"cccc..",
]
const FAILING_RUN: Array[String] = [
	"xxxx..",
	"xxxx..",
	"xxxx..",
	"xxxx..",
]
const GATE_SLALOM: Array[String] = [
	"gggg..",
	"......",
	"......",
	"......",
	"......",
	"..gggg",
]
const SPIKE_SLAM: Array[String] = [
	"1111..",
	"1111..",
	"1111..",
	"1111..",
]
const FAILING_RIM: Array[String] = [
	"xxxx..",
	"xoox..",
	"xoox..",
	"xxxx..",
]
const HOLE_SLALOM: Array[String] = [
	"oooo..",
	"oooo..",
	"......",
	"......",
	"......",
	"......",
	"..oooo",
	"..oooo",
]
const GAUNTLET: Array[String] = [
	"ss..ss",
	"ss..ss",
	"......",
	"......",
	"..oo..",
	"..oo..",
	"......",
	"......",
	"......",
	"gg..gg",
]
# Gentlest first. The patterns on offer grow from the first FIRST_PATTERN_COUNT to all of
# them, and the plain rows before each one shrink from the longest gap to the shortest,
# over the ROWS_TO_FULL_DEPTH rows after the opening. A random 0 to GAP_JITTER_ROWS is added.
const PATTERNS: Array[Array] = [
	HOLE, SPIKE_BLOCK, HOLE_SIDES, CRACK_STEPS, SPIKE_SIDES, SPIKE_CHECKER, HOLE_STAGGER, SPIKE_WAVE, CRACKED_FIELD,
	HOLE_BLOCK, GATE_BARRIER, CRACK_LANES, SPIKE_RIPPLE, FAILING_STRIP, CRACKED_RIM_HOLE, SPIKE_SWEEP, SPIKE_SLALOM,
	SPIKE_MARCH, GATE_ZIPPER, HOLE_BRIDGE, FAILING_RUN, GATE_SLALOM, SPIKE_SLAM, FAILING_RIM, HOLE_SLALOM, GAUNTLET,
]
const FIRST_PATTERN_COUNT := 2
const ROWS_TO_FULL_DEPTH := 150
const LONGEST_GAP_ROWS := 24
const SHORTEST_GAP_ROWS := 10
const GAP_JITTER_ROWS := 4
# Bomberplants are solid, so like hazards they stay off the safe path. The next one comes
# a random time in this range after the last, in game seconds, so there's always a plant to
# lead enemies to before long. Only one grows at a time, so the built rows, and the view,
# never hold two.
const PLANT_MIN_SECONDS := 15.0
const PLANT_MAX_SECONDS := 25.0
# Keys and chests each come a random time in their range after the last of their kind, in game seconds,
# so neither is ever long in coming. Chests come a little oftener, so some find the player without a
# key, which teaches them to save one for when they need a heart.
const KEY_MIN_SECONDS := 50.0
const KEY_MAX_SECONDS := 90.0
const CHEST_MIN_SECONDS := 40.0
const CHEST_MAX_SECONDS := 70.0
# Pixels in from a hazard cell's edges where the player's feet set it off, so
# brushing a corner doesn't count.
const HAZARD_EDGE_GRACE := 3.0
# Pixels the feet must be from any floor to fall into an open hole. Wider than
# the trap grace, so the player can run along the rim with most of their body
# over the dark. Neighbouring holes count as one, so there is no rim between them.
const HOLE_EDGE_GRACE := 5.0
# Seconds between the spikes of a wave rising, 1 first, and a g gate rising and an h gate rising.
const SPIKE_WAVE_STEP_SECONDS := 0.3
const GATE_PHASE_GAP_SECONDS := 2.4

# Empty rows between one coin and the next, picked from these. The repeated 2
# makes short gaps likelier, for about a third of a coin a row.
const ROWS_BETWEEN_COINS: Array[int] = [1, 2, 2, 2, 3]
# Rows ahead of the player's start before the first coin.
const ROWS_BEFORE_FIRST_COIN := 3
const NO_CELL := Vector2i(LEFT_WALL_COLUMN, 0)

# Rows built above the view's top edge, so what spawns just above the view stands on a built row.
const ROWS_BUILT_ABOVE_VIEW := 1

# Rows are built upward, from the bottom of the view. _next_row is the next one
# to build and _bottom_row the oldest one still built.
var _bottom_row: int
var _next_row: int
var _start_row: int
var _path_column := randi_range(FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN - 1)
# The safe path's columns in each built row.
var _path_columns: Dictionary[int, Array] = {}
# The rows still to build, in build order, planned a pattern at a time: plain rows,
# then the pattern. _planned_path holds the safe path's left column in each.
var _planned_rows: Array[String] = []
var _planned_path: Array[int] = []
var _hazards: Dictionary[Vector2i, Node2D] = {}
# Bomberplants and chests, which block the cell they stand on.
var _solids: Dictionary[Vector2i, Node2D] = {}
var _plant: Node2D
var _plant_seconds_left := randf_range(PLANT_MIN_SECONDS, PLANT_MAX_SECONDS)
# Game seconds of play, which traps set to rise in step start from, whichever row they are built on.
var _trap_clock := 0.0
# Where the latest coin went, so the next one picks another column and a key another cell.
var _last_coin_cell := NO_CELL
var _key_seconds_left := randf_range(KEY_MIN_SECONDS, KEY_MAX_SECONDS)
var _chest_seconds_left := randf_range(CHEST_MIN_SECONDS, CHEST_MAX_SECONDS)
# A due chest waits until a key has been picked up, so the first one is never unopenable.
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


func follow(view: Rect2, delta := 0.0) -> void:
	_plant_seconds_left -= delta
	_key_seconds_left -= delta
	_chest_seconds_left -= delta
	_trap_clock += delta
	while _next_row >= _row_at(view.position.y) - ROWS_BUILT_ABOVE_VIEW:
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


## The centers of plain floor cells in the built row the global y falls in, in global
## coordinates. Empty when that row isn't built.
func free_spots_on_row_at(y: float) -> Array:
	var row := _row_at(to_local(Vector2(0, y)).y)
	return _free_cells(row, row).map(func(cell): return to_global(map_to_local(cell)))


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

	var hazards := PLAIN_ROW
	var from := _path_column
	# A line waits on the planned rows, and the path holds its column through it.
	if not on_line:
		hazards = _take_planned_row(row)
	var path := range(mini(from, _path_column), maxi(from, _path_column) + 2)
	_path_columns[row] = path
	for column in range(FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN + 1):
		var symbol := hazards[column - FIRST_FLOOR_COLUMN]
		if symbol != PLAIN:
			_place_hazard(Vector2i(column, row), symbol)
	# A line or a pattern keeps its whole row clear of solids, like the path does its columns.
	var clear := range(FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN + 1) if on_line or hazards != PLAIN_ROW else path
	if _plant_seconds_left <= 0 and not is_instance_valid(_plant):
		_plant = _place_solid(bomberplant_scene, row, _solid_columns(row, clear))
		# A row with no room leaves the plant due, so the next row tries again.
		if _plant:
			_plant_seconds_left = randf_range(PLANT_MIN_SECONDS, PLANT_MAX_SECONDS)
	if _key_found and _chest_seconds_left <= 0:
		# Right beside the path, so the player can always reach it.
		var beside_path := [path.front() - 1, path.back() + 1]
		var chest := _place_solid(chest_scene, row, _solid_columns(row, clear).filter(func(column): return column in beside_path))
		if chest:
			chest.opened.connect(chest_opened.emit)
			_chest_seconds_left = randf_range(CHEST_MIN_SECONDS, CHEST_MAX_SECONDS)
	# Coins and keys would draw over the line's label. The coin countdown waits, so the coin due here lands after the line.
	if on_line:
		return
	_place_coins(row)
	if _key_seconds_left <= 0:
		_key_seconds_left = randf_range(KEY_MIN_SECONDS, KEY_MAX_SECONDS)
		# On the path, in a cell without a coin.
		var key_columns := path.filter(func(column): return Vector2i(column, row) != _last_coin_cell)
		var key := key_scene.instantiate()
		key.position = map_to_local(Vector2i(key_columns.pick_random(), row))
		key.picked_up.connect(func(): _key_found = true)
		add_child(key)


func _floor_tile(column: int, row: int) -> Vector2i:
	var start_floor_row := row - START_FLOOR_FIRST_ROW
	if start_floor_row >= 0 and start_floor_row < START_FLOOR.size():
		return START_FLOOR_TILES[START_FLOOR[start_floor_row][column - FIRST_FLOOR_COLUMN]]
	if randf() < FLOOR_DETAIL_CHANCE:
		return FLOOR_DETAIL_TILES.pick_random()
	return FLOOR_TILE


# Takes the next planned row, planning the next pattern first if none is left, and
# moves the safe path to its column.
func _take_planned_row(row: int) -> String:
	if _planned_rows.is_empty():
		_plan_pattern(row)
	_path_column = _planned_path.pop_front()
	return _planned_rows.pop_front()


# Plans the plain rows and then a pattern, from the bottom up, with the safe path
# through all of them. Before the opening ends the plain rows run up to it.
func _plan_pattern(row: int) -> void:
	var depth := _start_row - row - ROWS_BEFORE_HAZARDS
	var progress := clampf(float(depth) / ROWS_TO_FULL_DEPTH, 0.0, 1.0)
	var gap := -depth if depth < 0 else roundi(lerpf(LONGEST_GAP_ROWS, SHORTEST_GAP_ROWS, progress)) + randi_range(0, GAP_JITTER_ROWS)
	_planned_rows.resize(gap)
	_planned_rows.fill(PLAIN_ROW)
	var pattern: Array = PATTERNS.slice(0, mini(floori(lerpf(FIRST_PATTERN_COUNT, PATTERNS.size() + 1, progress)), PATTERNS.size())).pick_random()
	var mirrored := randi_range(0, 1) == 1
	# A pattern is written from its top row, and built from its bottom row.
	for index in range(pattern.size() - 1, -1, -1):
		var pattern_row: String = pattern[index]
		_planned_rows.append(_mirror(pattern_row) if mirrored else pattern_row)
	var plan: Array[int] = [_path_column]
	var found := _extend_path(plan, {})
	assert(found, "A pattern leaves no safe path through it.")
	_planned_path = plan.slice(1)


func _mirror(pattern_row: String) -> String:
	var mirrored := ""
	for index in range(pattern_row.length() - 1, -1, -1):
		mirrored += pattern_row[index]
	return mirrored


# Appends to the path, which starts as its column before the first planned row, a
# left column for every planned row, each within a step of the one before. It stays on plain
# floor, and so does every column it turns across. Returns false if the planned rows
# leave it no way through. dead_ends holds the rows and columns already found to lead nowhere.
func _extend_path(path: Array[int], dead_ends: Dictionary) -> bool:
	var row := path.size() - 1
	if row == _planned_rows.size():
		return true
	var from: int = path.back()
	if dead_ends.has(Vector2i(row, from)):
		return false
	for to in _path_moves(from):
		if _is_lane_plain(_planned_rows[row], from, to):
			path.append(to)
			if _extend_path(path, dead_ends):
				return true
			path.pop_back()
	dead_ends[Vector2i(row, from)] = true
	return false


# The columns the path may take from here, the one it would most likely take first.
func _path_moves(from: int) -> Array[int]:
	var turn := clampi(from + [-1, 1].pick_random(), FIRST_FLOOR_COLUMN, LAST_FLOOR_COLUMN - 1)
	var likeliest := [turn, from] if randf() < PATH_TURN_CHANCE else [from, turn]
	var moves: Array[int] = []
	for column in likeliest + [from - 1, from + 1]:
		if column not in moves and column >= FIRST_FLOOR_COLUMN and column < LAST_FLOOR_COLUMN:
			moves.append(column)
	return moves


# Whether the path can step from one column to another across this row. Both pairs of columns it
# covers have to be plain, as a turn row keeps both old and new columns clear.
func _is_lane_plain(row: String, from: int, to: int) -> bool:
	for column in range(mini(from, to), maxi(from, to) + 2):
		if row[column - FIRST_FLOOR_COLUMN] != PLAIN:
			return false
	return true


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


## How far the floor at the point has collapsed, from 0 to 1. Anything but a pit counts as whole.
func collapse_at(point: Vector2) -> float:
	var hazard = _hazards.get(local_to_map(to_local(point)))
	return hazard.collapse() if hazard is Pit else 0.0


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


func _place_hazard(cell: Vector2i, symbol: String) -> void:
	var hazard: Node2D
	match symbol:
		"s":
			hazard = spikes_scene.instantiate()
		"1", "2", "3", "4":
			hazard = spikes_scene.instantiate()
			hazard.start_seconds = _trap_clock + (4 - symbol.to_int()) * SPIKE_WAVE_STEP_SECONDS
		"g":
			hazard = gate_scene.instantiate()
			hazard.start_seconds = _trap_clock
		"h":
			hazard = gate_scene.instantiate()
			hazard.start_seconds = _trap_clock + GATE_PHASE_GAP_SECONDS
		"o":
			hazard = pit_scene.instantiate()
		"c", "x":
			var cracked_floor: Pit = pit_scene.instantiate()
			cracked_floor.crumbles = true
			cracked_floor.failing = symbol == "x"
			hazard = cracked_floor
	hazard.position = map_to_local(cell)
	add_child(hazard)
	_hazards[cell] = hazard


# Coins are spread out one at a time, each in a different column than the last.
func _place_coins(row: int) -> void:
	if _rows_until_coin > 0:
		_rows_until_coin -= 1
		return
	var columns := _coin_columns(row)
	# With no cell to put it in, the coin is due again on the next row.
	if columns.is_empty():
		return
	_rows_until_coin = ROWS_BETWEEN_COINS.pick_random()
	_last_coin_cell = Vector2i(columns.pick_random(), row)

	var coin := coin_scene.instantiate()
	coin.position = map_to_local(_last_coin_cell)
	coin.z_as_relative = false
	coin.z_index = 1
	# Deferred: picked_up fires inside a physics callback, where spawning new bodies is refused.
	coin.picked_up.connect(coin_picked_up.emit, CONNECT_DEFERRED)
	add_child(coin)


# The columns a coin may take in the row: free cells on the path or right beside
# it, short of the wall lane and not in the last coin's column.
func _coin_columns(row: int) -> Array:
	var path := _path_columns[row]
	return range(path.front() - 1, path.back() + 2).filter(func(column): return \
		column > FIRST_FLOOR_COLUMN and column < LAST_FLOOR_COLUMN and column != _last_coin_cell.x \
		and _is_free_cell(Vector2i(column, row)))


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
