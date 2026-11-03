extends CanvasLayer

signal restart_requested

enum State { START, CREDITS, PLAYING, PAUSED, GAME_OVER }

const ASSET_CREDITS := """ART
TOP-DOWN Adventure Pack by o_lobster
o-lobster.itch.io
License: CC BY 4.0
creativecommons.org/licenses/by/4.0

MUSIC
"Track 12" and "July 27th" by Abstraction
abstractionmusic.com

FONT
Pixel Operator by Jayvee Enaguas
License: CC0 1.0"""

# Root lays the UI out at a quarter of the viewport's size and draws it 4x.
const UI_SCALE := 4.0

var state := State.START

@onready var root: Control = $Root
@onready var hud_area: Control = %HudArea
@onready var pause_button: Button = %PauseButton
@onready var mute_button: Button = %MuteButton
@onready var dim: ColorRect = %Dim
@onready var start_screen: Control = %StartScreen
@onready var pause_screen: Control = %PauseScreen
@onready var game_over_screen: Control = %GameOverScreen
@onready var credits_screen: Control = %CreditsScreen
@onready var credits_text: Label = %CreditsText


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_to_screen)
	_fit_to_screen()
	%PlayButton.pressed.connect(start_playing)
	%ResumeButton.pressed.connect(start_playing)
	%RestartButton.pressed.connect(restart_requested.emit)
	%CreditsButton.pressed.connect(_set_state.bind(State.CREDITS))
	%BackButton.pressed.connect(_set_state.bind(State.START))
	pause_button.pressed.connect(_set_state.bind(State.PAUSED))
	mute_button.pressed.connect(Settings.toggle_mute)
	Settings.muted_changed.connect(_show_muted)
	_show_muted(Settings.muted)


func _fit_to_screen() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	root.size = viewport_size / UI_SCALE
	# The game puts the room's top wall, where the hearts and score sit, at the top of the safe area.
	var safe := SafeArea.in_viewport(get_viewport())
	hud_area.offset_left = safe.position.x / UI_SCALE
	hud_area.offset_top = safe.position.y / UI_SCALE
	hud_area.offset_right = (safe.end.x - viewport_size.x) / UI_SCALE
	hud_area.offset_bottom = (safe.end.y - viewport_size.y) / UI_SCALE


func _notification(what: int) -> void:
	var app_backgrounded := what == NOTIFICATION_APPLICATION_PAUSED \
		or what == NOTIFICATION_APPLICATION_FOCUS_OUT
	if app_backgrounded and state == State.PLAYING:
		_set_state(State.PAUSED)


func show_start(high_score: int) -> void:
	%StartBestLabel.text = "BEST %d" % high_score
	_set_state(State.START)


func start_playing() -> void:
	_set_state(State.PLAYING)


func show_game_over(score: int, high_score: int, is_new_best: bool) -> void:
	%FinalScoreLabel.text = "SCORE %d" % score
	%GameOverBestLabel.text = "BEST %d" % high_score
	%NewBestLabel.visible = is_new_best
	_set_state(State.GAME_OVER)


func _set_state(new_state: State) -> void:
	state = new_state
	var playing := state == State.PLAYING
	get_tree().paused = not playing
	pause_button.visible = playing
	mute_button.visible = not playing and state != State.CREDITS
	dim.visible = not playing
	start_screen.visible = state == State.START
	pause_screen.visible = state == State.PAUSED
	game_over_screen.visible = state == State.GAME_OVER
	credits_screen.visible = state == State.CREDITS
	# Built on first open: the engine notices are ~80 KB of text to shape.
	if state == State.CREDITS and credits_text.text.is_empty():
		credits_text.text = _credits_text()


func _show_muted(muted: bool) -> void:
	mute_button.text = "SOUND OFF" if muted else "SOUND ON"


# Godot's license asks for its notice and its third-party notices in the app.
func _credits_text() -> String:
	var sections: PackedStringArray = [
		ASSET_CREDITS,
		"ENGINE\nThis game uses Godot Engine, available under the following license:",
		_unwrap(Engine.get_license_text()),
		"Portions of this software are copyright (c) The FreeType Project (www.freetype.org). All rights reserved.",
		"THIRD-PARTY NOTICES",
	]
	for component: Dictionary in Engine.get_copyright_info():
		var lines := PackedStringArray([component.name])
		for part: Dictionary in component.parts:
			for holder: String in part.copyright:
				lines.append("(c) " + holder)
			lines.append("License: " + part.license)
		sections.append("\n".join(lines))
	var licenses := Engine.get_license_info()
	for license: String in licenses:
		sections.append(license.to_upper() + "\n" + _unwrap(licenses[license]))
	return "\n\n".join(sections)


# The license text is hard-wrapped for 80 columns; let the label wrap it instead.
func _unwrap(text: String) -> String:
	var paragraphs := text.strip_edges().split("\n\n")
	for i in paragraphs.size():
		paragraphs[i] = paragraphs[i].replace("\n", " ")
	return "\n\n".join(paragraphs)
