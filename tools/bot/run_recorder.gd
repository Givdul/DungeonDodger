extends Node
## Watches one run of the game it's added to and records how it went. Emits
## finished on the frame the player dies, or when the run reaches max_seconds.

signal finished

const Enemies := preload("res://tools/bot/enemies.gd")
const BOMBERPLANT_SCENE := "res://scenes/bomberplant.tscn"
const COIN_SCENE := "res://scenes/point.tscn"

var max_seconds := INF
var survival_seconds := 0.0
var hits := 0
var end_cause := ""
var max_plants_in_view := 0
var max_enemies_in_view := 0

var _lives: int
var _last_hit_cause := ""
var _coin_rows: Dictionary[int, bool] = {}

@onready var game: Node2D = get_parent()
@onready var player: CharacterBody2D = game.player
@onready var dungeon: TileMapLayer = game.dungeon


func _ready() -> void:
	# After the game's step, which moves the scroll edge and sets off hazards.
	process_physics_priority = 2
	_lives = player.current_lives
	player.lives_changed.connect(_on_lives_changed)
	for child in dungeon.get_children():
		_on_dungeon_child_added(child)
	dungeon.child_entered_tree.connect(_on_dungeon_child_added)


func _physics_process(delta: float) -> void:
	if end_cause:
		return
	if player.is_dead:
		# A fall on the last life ends the run without taking that life.
		if player.anim.animation == &"fall":
			hits += 1
		_end(_death_cause())
		return
	# The view holds still until the first move.
	if not game.run_started:
		return
	survival_seconds += delta
	var view: Rect2 = game.view_rect()
	var plants := dungeon.get_children().filter(func(child): return child.scene_file_path == BOMBERPLANT_SCENE \
		and view.has_point(child.global_position))
	var enemies := get_tree().get_nodes_in_group("Enemies").filter(func(enemy): return Enemies.is_alive(enemy) \
		and view.has_point(enemy.global_position))
	max_plants_in_view = maxi(max_plants_in_view, plants.size())
	max_enemies_in_view = maxi(max_enemies_in_view, enemies.size())
	if survival_seconds >= max_seconds:
		_end("timeout")


func result() -> Dictionary:
	var coin_rows := _coin_row_stats()
	return {
		"survival_seconds": snappedf(survival_seconds, 0.01),
		"score": game.point_count,
		"hits": hits,
		"death_cause": end_cause,
		"max_plants_in_view": max_plants_in_view,
		"max_enemies_in_view": max_enemies_in_view,
		"longest_coin_gap_rows": coin_rows.x,
		"longest_coin_streak_rows": coin_rows.y,
	}


func _end(cause: String) -> void:
	end_cause = cause
	finished.emit()


func _on_lives_changed(lives: int) -> void:
	if lives < _lives:
		hits += 1
		_last_hit_cause = _hit_cause()
	_lives = lives


# Runs inside player.take_damage(), so it sees the same overlaps the attacker did.
func _hit_cause() -> String:
	# Bombs blow up from a tween, on the idle step; everything else hurts on the physics step.
	if not Engine.is_in_physics_frame():
		return "bomb"
	# A player on an open pit is falling in, whatever else touches them.
	var hazard: Node2D = dungeon.hazard_at(player.global_position)
	if hazard is Pit and hazard.is_open():
		return _pit_kind(hazard)
	# Enemies step before the game, which sets off the spikes, so on a tie the enemy hit first.
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if Enemies.is_alive(enemy) and Enemies.hit_area(enemy).overlaps_body(player):
			return Enemies.kind(enemy)
	return "spikes" if hazard != null and not hazard is Pit else "unknown"


func _death_cause() -> String:
	if player.anim.animation == &"fall":
		return _pit_kind(dungeon.hazard_at(player.global_position))
	if player.current_lives > 0:
		return "crush"
	return _last_hit_cause


func _pit_kind(pit: Pit) -> String:
	return "crumbling_floor" if pit.crumbles else "hole"


func _on_dungeon_child_added(child: Node) -> void:
	if child.scene_file_path == COIN_SCENE:
		_coin_rows[floori(child.position.y / dungeon.tile_set.tile_size.y)] = true


# The most rows in a row without a coin, and with one, between the first coin and the last.
func _coin_row_stats() -> Vector2i:
	var rows := _coin_rows.keys()
	rows.sort()
	var longest_gap := 0
	var longest_streak := mini(rows.size(), 1)
	var streak := 1
	for i in range(1, rows.size()):
		var step: int = rows[i] - rows[i - 1]
		if step == 1:
			streak += 1
			longest_streak = maxi(longest_streak, streak)
		else:
			streak = 1
			longest_gap = maxi(longest_gap, step - 1)
	return Vector2i(longest_gap, longest_streak)
