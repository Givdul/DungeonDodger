extends Node

signal muted_changed(muted: bool)

const SAVE_PATH := "user://settings.cfg"

var muted := false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		muted = config.get_value("audio", "muted", false)
	_apply_mute()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mute"):
		toggle_mute()


func toggle_mute() -> void:
	muted = not muted
	_apply_mute()
	muted_changed.emit(muted)
	var config := ConfigFile.new()
	config.set_value("audio", "muted", muted)
	config.save(SAVE_PATH)


func _apply_mute() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), muted)
