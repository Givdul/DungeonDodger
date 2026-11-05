extends Node
## Plays seeded runs of the game with the autopilot. Prints one JSON line per
## run, then a summary line. "Gameplay bot" in AGENTS.md says how to run it.

# Loaded at run time: a preload that fails, as in an unimported checkout, stops this script
# from parsing, and Godot then idles forever instead of exiting.
const GAME_SCENE_PATH := "res://scenes/game.tscn"
const Autopilot := preload("res://tools/bot/autopilot.gd")
const RunRecorder := preload("res://tools/bot/run_recorder.gd")

const DEFAULT_OPTIONS := {"runs": 30, "seed": 1, "skill": "casual", "max-seconds": 600.0}


func _ready() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	if options.is_empty():
		get_tree().quit(1)
		return

	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		push_error("Couldn't load %s. In a fresh checkout, run: godot --headless --path . --import" % GAME_SCENE_PATH)
		get_tree().quit(1)
		return

	var started := Time.get_ticks_msec()
	var results: Array[Dictionary] = []
	for run in options.runs:
		var run_seed: int = options.seed + run
		var result := {"type": "run", "run": run, "seed": run_seed, "skill": options.skill}
		result.merge(await _play(game_scene, run_seed, options.skill, options["max-seconds"]))
		print(JSON.stringify(result))
		results.append(result)
	var summary := _summarize(results)
	summary.merge({"type": "summary", "runs": options.runs, "first_seed": options.seed, "skill": options.skill,
		"wall_seconds": snappedf((Time.get_ticks_msec() - started) / 1000.0, 0.1)})
	print(JSON.stringify(summary))
	get_tree().quit()


# --name=value pairs over the defaults, or an empty dictionary after reporting a bad one.
func _parse_options(args: PackedStringArray) -> Dictionary:
	var options := DEFAULT_OPTIONS.duplicate()
	for arg in args:
		var pair := arg.trim_prefix("--").split("=", true, 1)
		var name := pair[0]
		if not arg.begins_with("--") or pair.size() != 2 or name not in options:
			push_error("Unknown option %s. Options: %s" % [arg, ", ".join(options.keys().map(func(key): return "--%s=" % key))])
			return {}
		match typeof(options[name]):
			TYPE_INT:
				options[name] = pair[1].to_int()
			TYPE_FLOAT:
				options[name] = pair[1].to_float()
			_:
				options[name] = pair[1]
	if options.skill not in Autopilot.SKILLS:
		push_error("Unknown skill %s. Skills: %s" % [options.skill, ", ".join(Autopilot.SKILLS.keys())])
		return {}
	return options


# Starts the game the way PLAY does, and lets the autopilot play it until the run ends.
func _play(game_scene: PackedScene, run_seed: int, skill: String, max_seconds: float) -> Dictionary:
	seed(run_seed)
	var game: Node2D = game_scene.instantiate()
	add_child(game)
	var recorder := RunRecorder.new()
	recorder.max_seconds = max_seconds
	game.add_child(recorder)
	var autopilot := Autopilot.new()
	autopilot.setup(skill, run_seed)
	game.add_child(autopilot)
	game.ui.start_playing()

	await recorder.finished
	var result := recorder.result()
	# The run ends inside a physics step; the game is freed outside it. Freeing it
	# before the death animation ends also keeps the run from saving a high score.
	await get_tree().process_frame
	game.free()
	# A press made on the last frame would still read as just pressed in the next run's first one.
	await get_tree().physics_frame
	await get_tree().process_frame
	return result


func _summarize(results: Array[Dictionary]) -> Dictionary:
	var survival := results.map(func(result): return result.survival_seconds)
	var scores := results.map(func(result): return result.score)
	var causes := {}
	for result in results:
		causes[result.death_cause] = causes.get(result.death_cause, 0) + 1
	for cause in causes:
		causes[cause] = snappedf(100.0 * causes[cause] / results.size(), 0.1)
	return {
		"survival_seconds": {
			"median": _percentile(survival, 0.5),
			"p10": _percentile(survival, 0.1),
			"p90": _percentile(survival, 0.9),
		},
		"score_median": _percentile(scores, 0.5),
		"hits_median": _percentile(results.map(func(result): return result.hits), 0.5),
		"death_causes_percent": causes,
		"max_plants_in_view": results.map(func(result): return result.max_plants_in_view).max(),
		"max_enemies_in_view": results.map(func(result): return result.max_enemies_in_view).max(),
		"longest_coin_gap_rows": results.map(func(result): return result.longest_coin_gap_rows).max(),
		"longest_coin_streak_rows": results.map(func(result): return result.longest_coin_streak_rows).max(),
	}


# Interpolated between the nearest ranks, so the median of an even count is the middle pair's mean.
func _percentile(values: Array, fraction: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var rank := fraction * (sorted.size() - 1)
	var below := floori(rank)
	var above := mini(below + 1, sorted.size() - 1)
	return snappedf(lerpf(sorted[below], sorted[above], rank - below), 0.01)
