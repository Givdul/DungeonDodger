extends Node

const SAVE_PATH := "user://highscore.save"
var high_score: int = 0

func _ready():
	load_high_score()

func save_high_score():
	# Written beside the save and renamed over it, so being killed mid-write keeps the old score.
	var temp_path := SAVE_PATH + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Couldn't save the high score: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_32(high_score)
	file.close()
	DirAccess.rename_absolute(temp_path, SAVE_PATH)

func load_high_score():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Couldn't load the high score: %s" % error_string(FileAccess.get_open_error()))
		return
	high_score = file.get_32()
	file.close()
