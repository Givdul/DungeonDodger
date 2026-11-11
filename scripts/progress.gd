extends Node
## The player's saved progress: the crystal wallet, lifetime stats, the unlocked hero skins and the worn one.

signal worn_changed(id: String)

const SAVE_PATH := "user://progress.json"

var wallet := 0
# Totals over every run, and the bests of single runs. Heroes.ACHIEVEMENTS reads them, plus "heroes".
var stats := {
	"crystals": 0,
	"deaths": 0,
	"hits": 0,
	"holes": 0,
	"potions": 0,
	"chests": 0,
	"best_run_crystals": 0,
	"best_run_seconds": 0,
	"best_unhit_seconds": 0,
}
var unlocked: Array[String] = [Heroes.DEFAULT]
var worn := Heroes.DEFAULT


func _ready() -> void:
	_load()


func is_unlocked(id: String) -> bool:
	return id in unlocked


## Where the stat behind an achievement stands.
func stat(name: String) -> int:
	return unlocked.size() if name == "heroes" else stats[name]


## Spends the skin's price and unlocks it. Returns whether the wallet covered it.
func buy(id: String) -> bool:
	var rule := Heroes.unlock_rule(id)
	if rule.kind != "crystals" or is_unlocked(id) or wallet < rule.price:
		return false
	wallet -= rule.price
	unlocked.append(id)
	_unlock_achieved()
	_save()
	return true


func wear(id: String) -> void:
	if is_unlocked(id):
		worn = id
		_save()
		worn_changed.emit(id)


## Banks a finished run and returns the ids of the skins it unlocked. The run has crystals,
## hits, holes, potions and chests counts, and seconds and best_unhit_seconds in game time.
func record_run(run: Dictionary) -> Array[String]:
	wallet += run.crystals
	stats.crystals += run.crystals
	stats.deaths += 1
	for count in ["hits", "holes", "potions", "chests"]:
		stats[count] += run[count]
	stats.best_run_crystals = maxi(stats.best_run_crystals, run.crystals)
	stats.best_run_seconds = maxi(stats.best_run_seconds, floori(run.seconds))
	stats.best_unhit_seconds = maxi(stats.best_unhit_seconds, floori(run.best_unhit_seconds))
	var new_skins := _unlock_achieved()
	_save()
	return new_skins


# Unlocking one can reach the goal of another ("heroes"), so it goes round until none is left.
func _unlock_achieved() -> Array[String]:
	var new_skins: Array[String] = []
	var found := true
	while found:
		found = false
		for id: String in Heroes.ACHIEVEMENTS:
			var achievement: Dictionary = Heroes.ACHIEVEMENTS[id]
			if not is_unlocked(id) and stat(achievement.stat) >= achievement.goal:
				unlocked.append(id)
				new_skins.append(id)
				found = true
	return new_skins


func _save() -> void:
	# Written beside the save and renamed over it, so being killed mid-write keeps the old progress.
	var temp_path := SAVE_PATH + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Couldn't save progress: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({wallet = wallet, stats = stats, unlocked = unlocked, worn = worn}))
	file.close()
	DirAccess.rename_absolute(temp_path, SAVE_PATH)


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var saved = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not saved is Dictionary:
		push_error("Couldn't load progress from %s" % SAVE_PATH)
		return
	# JSON reads every number as a float.
	wallet = int(saved.get("wallet", 0))
	var saved_stats: Dictionary = saved.get("stats", {})
	for name in stats:
		stats[name] = int(saved_stats.get(name, 0))
	var known := Heroes.ids()
	for id in saved.get("unlocked", []):
		if id in known and not is_unlocked(id):
			unlocked.append(id)
	var saved_worn := str(saved.get("worn", Heroes.DEFAULT))
	worn = saved_worn if is_unlocked(saved_worn) else Heroes.DEFAULT
