extends Node
## Steers the player of the game it's added to the way a swipe does, through the
## move_* actions. Every few frames it plays each direction forward frame by
## frame a short way, then queues the one that runs into the least trouble. The
## press only reaches the player after a reaction delay, as a person's would.

const Enemies := preload("res://tools/bot/enemies.gd")
const BOMB_SCENE := "res://scenes/bomb.tscn"
const COIN_SCENE := "res://scenes/point.tscn"

const DIRECTIONS: Dictionary[StringName, Vector2] = {
	&"move_up": Vector2.UP,
	&"move_down": Vector2.DOWN,
	&"move_left": Vector2.LEFT,
	&"move_right": Vector2.RIGHT,
}

## plan_depth is how many turns it plans within the lookahead. A lapse skips a
## decision, like a player who looks away.
const SKILLS := {
	"casual": {reaction_seconds = 0.4, decision_frames = 8, lookahead_seconds = 0.6, plan_depth = 2, lapse_chance = 0.1},
	"good": {reaction_seconds = 0.2, decision_frames = 3, lookahead_seconds = 0.8, plan_depth = 2, lapse_chance = 0.0},
}

# A press made on one physics frame moves the player from the next one.
const INPUT_LATENCY_FRAMES := 1
const DEATH_COST := 1000.0
const HIT_COST := 200.0
const COIN_VALUE := 40.0
# The pickup circle in point.tscn.
const COIN_RADIUS := 3.0
# Pressures cost this much per second spent close to trouble that may not hit.
const ENEMY_COMFORT := 24.0
const ENEMY_PRESSURE := 6.0
const CONTACT_MARGIN := 3.0
const BLAST_MARGIN := 4.0
# How far off its guess of when a bomb blows can be.
const BLAST_TIMING_SLACK := 0.1
# How far off its guess of when spikes rise can be, which is a hit to whoever stands on the cell then.
const SPIKE_RISE_SLACK := 0.1
const BOMB_PRESSURE := 60.0
const TRAP_PRESSURE := 40.0
const EDGE_COMFORT := 30.0
const EDGE_PRESSURE := 2.0
# Farther than this from the walls and from solids, the player can't bump into
# them in one frame, so the imagined move skips the physics query.
const WALL_RANGE := 12.0
const SOLID_RANGE := 32.0
# A turn has to look at least this much better than going on, so ties don't jitter.
const TURN_THRESHOLD := 0.5


## One imagined future of the player's feet, and what it ran into.
class Sim:
	var position: Vector2
	# Frames after the one it started from, and the seconds they add up to.
	var frame := 0
	var time := 0.0
	var cost := 0.0
	# Dead, or fallen and put back somewhere it can't foresee.
	var ended := false
	var lives: int
	# Hits before this don't count, like the player's invulnerability after one.
	var safe_until := 0.0
	var coins_taken: Dictionary[Vector2, bool] = {}
	# When this future first stepped on each cracked tile that hadn't started to crumble.
	var cracks_stepped: Dictionary[Node, float] = {}
	# Where each seen enemy's hit shape is by now and how it's moving, in the order they were seen.
	var enemy_centers: Array[Vector2] = []
	var enemy_velocities: Array[Vector2] = []

	func copy() -> Sim:
		var sim := Sim.new()
		sim.position = position
		sim.frame = frame
		sim.time = time
		sim.cost = cost
		sim.ended = ended
		sim.lives = lives
		sim.safe_until = safe_until
		sim.coins_taken = coins_taken.duplicate()
		sim.cracks_stepped = cracks_stepped.duplicate()
		sim.enemy_centers = enemy_centers.duplicate()
		sim.enemy_velocities = enemy_velocities.duplicate()
		return sim


var reaction_seconds: float
var decision_frames: int
var lookahead_seconds: float
var plan_depth: int
var lapse_chance: float

var _rng := RandomNumberGenerator.new()
var _frame_seconds := 1.0 / Engine.physics_ticks_per_second
var _reaction_frames: int
var _lookahead_frames: int
var _frames := 0
var _now := 0.0
# Turns decided that haven't reached the player yet: {frame, direction}, where
# frame is the first one the player moves the new way on. Oldest first.
var _queue: Array[Dictionary] = []
var _bombs_explode_at: Dictionary[Node, float] = {}
var _enemy_centers: Dictionary[Node, Vector2] = {}
var _enemy_centers_time := 0.0
var _enemies_waiting_since: Dictionary[Node, float] = {}
var _was_invulnerable := false
var _invulnerable_until := 0.0

# What it sees at each decision.
var _band: Rect2
var _scroll_speed: float
var _enemies: Array[Dictionary] = []
var _bombs: Array[Dictionary] = []
var _coins: Array[Vector2] = []
var _solids: Array[Vector2] = []
var _spikes: Array[Spikes] = []

@onready var game: Node2D = get_parent()
@onready var player: CharacterBody2D = game.player
@onready var dungeon: TileMapLayer = game.dungeon
@onready var _body: CollisionShape2D = player.get_node("CollisionShape2D")
@onready var _walls_x := Vector2(game.get_node("Bounds/LeftWorldBound").position.x,
	game.get_node("Bounds/RightWorldBound").position.x)


func setup(skill: String, rng_seed: int) -> void:
	for setting in SKILLS[skill]:
		set(setting, SKILLS[skill][setting])
	_reaction_frames = roundi(reaction_seconds / _frame_seconds)
	_lookahead_frames = roundi(lookahead_seconds / _frame_seconds)
	_rng.seed = rng_seed


func _ready() -> void:
	# After the game's step, so it sees each frame finished and imagines the next ones whole.
	process_physics_priority = 2
	dungeon.child_entered_tree.connect(_on_dungeon_child_added)


func _physics_process(_delta: float) -> void:
	_frames += 1
	_now = _frames * _frame_seconds
	# The player blinks while hits don't count, so a person knows how long that lasts.
	if player.is_invulnerable and not _was_invulnerable:
		_invulnerable_until = _now + player.INVULNERABLE_SECONDS
	_was_invulnerable = player.is_invulnerable
	# A falling player ignores presses and stands still once back on the floor.
	if player.is_falling:
		_queue.clear()
		return
	while not _queue.is_empty() and _queue.front().frame <= _frames:
		_queue.pop_front()
	for turn in _queue:
		if turn.frame == _frames + INPUT_LATENCY_FRAMES:
			_press(turn.direction)
	if player.is_dead or _frames % decision_frames != 0:
		return
	if _rng.randf() < lapse_chance:
		return
	_decide()


# The same press and release a swipe makes in MobileInputs.gd.
func _press(direction: Vector2) -> void:
	var action: StringName = DIRECTIONS.find_key(direction)
	Input.action_press(action)
	Input.action_release(action)


func _on_dungeon_child_added(child: Node) -> void:
	if child.scene_file_path == BOMB_SCENE:
		_bombs_explode_at[child] = _now + child.flight_time + child.fuse_time
		child.tree_exiting.connect(func(): _bombs_explode_at.erase(child))


func _decide() -> void:
	_observe()
	# Until the reaction delay is up, the player follows what's already been pressed.
	var start := Sim.new()
	start.position = player.global_position
	start.lives = player.current_lives
	start.safe_until = _invulnerable_until - _now if player.is_invulnerable else 0.0
	start.enemy_centers.assign(_enemies.map(func(enemy): return enemy.center))
	start.enemy_velocities.assign(_enemies.map(func(enemy): return enemy.velocity))
	var heading: Vector2 = player.direction
	for turn in _queue:
		_advance(start, heading, turn.frame - _frames - 1)
		heading = turn.direction
	_advance(start, heading, _reaction_frames - 1)
	var plan_end := start.frame + _lookahead_frames

	var best_direction := heading
	var best_cost := _plan_cost(start, heading, plan_depth, plan_end) - TURN_THRESHOLD \
		if heading in DIRECTIONS.values() else INF
	for direction in DIRECTIONS.values():
		if direction == heading:
			continue
		var cost := _plan_cost(start, direction, plan_depth, plan_end)
		if cost < best_cost:
			best_cost = cost
			best_direction = direction
	if best_direction != heading:
		_queue.append({frame = _frames + _reaction_frames, direction = best_direction})


# The lowest cost of heading this way, then taking the best turns that are left.
func _plan_cost(start: Sim, direction: Vector2, depth: int, end_frame: int) -> float:
	var sim := start.copy()
	_advance(sim, direction, start.frame + (end_frame - start.frame) / depth)
	if depth == 1 or sim.ended:
		return sim.cost
	var best := INF
	for next in DIRECTIONS.values():
		best = minf(best, _plan_cost(sim, next, depth - 1, end_frame))
	return best


func _observe() -> void:
	_band = game.floor_band()
	_scroll_speed = game.scroll_speed()

	_enemies.clear()
	var centers: Dictionary[Node, Vector2] = {}
	var waiting_since: Dictionary[Node, float] = {}
	var body_radius := _radius(_body)
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if not Enemies.is_alive(enemy):
			continue
		var shape := Enemies.hit_shape(enemy)
		var center := shape.global_position
		var velocity := Vector2.ZERO
		if _enemy_centers.has(enemy):
			velocity = (center - _enemy_centers[enemy]) / (_now - _enemy_centers_time)
		centers[enemy] = center
		# A waiting rusher charges at the player once it's waited as long as they usually do.
		# Once a bat winds up, its marker shows when and which way it goes.
		var rushes_in := INF
		var rush_direction := Vector2.ZERO
		if Enemies.waits_to_rush(enemy):
			waiting_since[enemy] = _enemies_waiting_since.get(enemy, _now)
			rushes_in = maxf(waiting_since[enemy] + Enemies.wait_seconds(enemy) - _now, 0.0)
			velocity = Vector2.ZERO
		elif Enemies.winds_up(enemy):
			rushes_in = enemy.timer.time_left
			rush_direction = enemy.rush_direction
			velocity = Vector2.ZERO
		_enemies.append({node = enemy, center = center, velocity = velocity, reach = _radius(shape) + body_radius,
			origin_offset = enemy.global_position - center, chases = Enemies.chases(enemy), speed = enemy.get("speed"),
			rushes_in = rushes_in, rush_direction = rush_direction})
	_enemy_centers = centers
	_enemies_waiting_since = waiting_since
	_enemy_centers_time = _now

	_bombs.clear()
	for bomb in _bombs_explode_at:
		if _bombs_explode_at[bomb] > _now:
			_bombs.append({position = bomb.global_position, explodes_in = _bombs_explode_at[bomb] - _now,
				radius = bomb.blast_radius})

	_coins.clear()
	_solids.clear()
	_spikes.clear()
	var reach: float = (reaction_seconds + lookahead_seconds) * player.SPEED + SOLID_RANGE
	for child in dungeon.get_children():
		if child.global_position.distance_to(player.global_position) > reach:
			continue
		if child is StaticBody2D:
			_solids.append(child.global_position)
		elif child is Spikes:
			_spikes.append(child)
		elif child.scene_file_path == COIN_SCENE and not child.picked_up_already:
			_coins.append(child.get_node("CollisionShape2D").global_position)


func _radius(shape: CollisionShape2D) -> float:
	return shape.shape.radius * absf(shape.global_scale.x)


# Moves the imagined player this way until the given frame, the way the player
# and the game's scroll edge would.
func _advance(sim: Sim, direction: Vector2, end_frame: int) -> void:
	var motion: Vector2 = direction * player.SPEED * _frame_seconds
	while sim.frame < end_frame and not sim.ended:
		sim.frame += 1
		sim.time = sim.frame * _frame_seconds
		var collision := _test_move(sim.position, motion)
		var next := sim.position + (collision.get_travel() if collision else motion)
		if not _enters_raised_spikes(sim.position, next, sim.time):
			sim.position = next
		_follow_scroll(sim)
		if not sim.ended:
			_add_costs(sim)


func _test_move(from: Vector2, motion: Vector2) -> KinematicCollision2D:
	if not _may_collide(from):
		return null
	var transform := player.global_transform
	transform.origin = from
	var collision := KinematicCollision2D.new()
	if not player.test_move(transform, motion, collision):
		return null
	# Spikes are weighed by when they're up in the imagined future, not by whether they are up now.
	return null if collision.get_collider().get_parent() is Spikes else collision


func _may_collide(from: Vector2) -> bool:
	if from.x - _walls_x.x < WALL_RANGE or _walls_x.y - from.x < WALL_RANGE:
		return true
	return _solids.any(func(solid): return from.distance_to(solid) < SOLID_RANGE)


# Spikes that will be up by then stop the player's body at their edge, and push it back out if it
# overlaps them. Only a player standing on the cell, as the game sees it, walks through.
func _enters_raised_spikes(from: Vector2, to: Vector2, time: float) -> bool:
	for spikes in _spikes:
		if not spikes.is_up_in(time) or _cell(spikes).grow(Spikes.HOLD_MARGIN).has_point(from):
			continue
		var gap := _gap_to(spikes, to)
		if gap < 0.0 and gap < _gap_to(spikes, from):
			return true
	return false


func _cell(spikes: Spikes) -> Rect2:
	var tile_size := Vector2(dungeon.tile_set.tile_size)
	return Rect2(spikes.global_position - tile_size / 2, tile_size)


# How far the player's body is from the spikes' cell, below zero while they overlap.
func _gap_to(spikes: Spikes, feet: Vector2) -> float:
	var cell := _cell(spikes)
	var body := feet + _body.position * player.scale
	return body.distance_to(body.clamp(cell.position, cell.end)) - _radius(_body)


func _follow_scroll(sim: Sim) -> void:
	var shift := _scroll_speed * sim.time
	var bottom := _band.end.y - shift
	if sim.position.y > bottom:
		var push := Vector2(0, bottom - sim.position.y)
		var collision := _test_move(sim.position, push)
		var blocked := _enters_raised_spikes(sim.position, sim.position + push, sim.time)
		if (blocked and push.length() > game.CRUSH_TOLERANCE) \
				or (collision and collision.get_remainder().length() > game.CRUSH_TOLERANCE):
			_die(sim)
			return
		if not blocked:
			sim.position += collision.get_travel() if collision else push
	sim.position.y = maxf(sim.position.y, _band.position.y - shift)


func _add_costs(sim: Sim) -> void:
	_add_hazard_cost(sim)
	if sim.ended:
		return
	var body := sim.position + _body.position * player.scale
	for i in _enemies.size():
		var enemy := _enemies[i]
		# Chasers turn after the player, and rushers set off along their marked line, or else at
		# where the player is when they charge. The rest keep going the way they're seen moving.
		if enemy.chases:
			var origin: Vector2 = sim.enemy_centers[i] + enemy.origin_offset
			sim.enemy_velocities[i] = Enemies.chase_direction(enemy.node, origin, sim.position) * enemy.speed
		elif sim.time >= enemy.rushes_in and sim.enemy_velocities[i] == Vector2.ZERO:
			var rush_direction: Vector2 = enemy.rush_direction if enemy.rush_direction \
				else Enemies.rush_direction(enemy.node, sim.enemy_centers[i] + enemy.origin_offset, sim.position)
			sim.enemy_velocities[i] = rush_direction * enemy.speed
		sim.enemy_centers[i] += sim.enemy_velocities[i] * _frame_seconds
		var gap: float = body.distance_to(sim.enemy_centers[i]) - enemy.reach
		if gap < CONTACT_MARGIN:
			_hit(sim)
		# Even while a hit doesn't count, staying close means another one soon.
		sim.cost += maxf(ENEMY_COMFORT - gap, 0.0) * ENEMY_PRESSURE * _frame_seconds
	for bomb in _bombs:
		if sim.position.distance_to(bomb.position) > bomb.radius + BLAST_MARGIN:
			continue
		if absf(sim.time - bomb.explodes_in) <= BLAST_TIMING_SLACK:
			_hit(sim)
		elif sim.time < bomb.explodes_in:
			sim.cost += BOMB_PRESSURE * _frame_seconds
	for coin in _coins:
		if not sim.coins_taken.has(coin) and body.distance_to(coin) < _radius(_body) + COIN_RADIUS:
			sim.coins_taken[coin] = true
			# Sooner coins are surer coins.
			sim.cost -= COIN_VALUE * (1.0 - sim.time / (2.0 * (reaction_seconds + lookahead_seconds)))
	# The scroll edges leave no room to dodge: the top one holds the player back, the bottom one pushes.
	var shift := _scroll_speed * sim.time
	var to_edge := minf(sim.position.y - (_band.position.y - shift), _band.end.y - shift - sim.position.y)
	sim.cost += maxf(EDGE_COMFORT - to_edge, 0.0) * EDGE_PRESSURE * _frame_seconds


func _add_hazard_cost(sim: Sim) -> void:
	var hazard: Node2D = dungeon.hazard_at(sim.position)
	if hazard == null:
		return
	if hazard is Pit:
		if sim.time >= _opens_in(hazard, sim):
			_fall(sim)
		else:
			sim.cost += TRAP_PRESSURE * _frame_seconds
	elif hazard.is_up_in(sim.time + SPIKE_RISE_SLACK) and not hazard.is_up_in(sim.time - SPIKE_RISE_SLACK):
		_hit(sim)
	else:
		sim.cost += TRAP_PRESSURE * _frame_seconds


# Seconds from now until the pit is open, if this future keeps standing on it.
func _opens_in(pit: Pit, sim: Sim) -> float:
	if pit.is_open():
		return 0.0
	var frames := pit.sprite_frames.get_frame_count(pit.animation)
	var seconds_per_frame := 1.0 / pit.sprite_frames.get_animation_speed(pit.animation)
	if pit.is_playing():
		return (frames - 1 - pit.frame - pit.frame_progress) * seconds_per_frame
	return sim.cracks_stepped.get_or_add(pit, sim.time) + (frames - 1) * seconds_per_frame


func _hit(sim: Sim) -> void:
	if sim.time < sim.safe_until:
		return
	_lose_life(sim)
	sim.safe_until = sim.time + player.INVULNERABLE_SECONDS


# Falls cost a life even while hits don't count.
func _fall(sim: Sim) -> void:
	_lose_life(sim)
	sim.ended = true


func _lose_life(sim: Sim) -> void:
	sim.lives -= 1
	# On the last heart, it ends the run.
	sim.cost += (DEATH_COST if sim.lives <= 0 else HIT_COST) * _urgency(sim)


func _die(sim: Sim) -> void:
	sim.cost += DEATH_COST * _urgency(sim)
	sim.ended = true


# Trouble that comes sooner weighs more, so when every way ends in a hit it takes the latest one.
func _urgency(sim: Sim) -> float:
	return 1.5 - sim.time / (reaction_seconds + lookahead_seconds)
