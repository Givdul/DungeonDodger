extends CanvasLayer

signal restart_requested

enum State { START, PLAYING, PAUSED, GAME_OVER }

var state := State.START

@onready var pause_button: Button = %PauseButton
@onready var mute_button: Button = %MuteButton
@onready var dim: ColorRect = %Dim
@onready var start_screen: Control = %StartScreen
@onready var pause_screen: Control = %PauseScreen
@onready var game_over_screen: Control = %GameOverScreen


func _ready() -> void:
	%PlayButton.pressed.connect(start_playing)
	%ResumeButton.pressed.connect(start_playing)
	%RestartButton.pressed.connect(restart_requested.emit)
	pause_button.pressed.connect(_set_state.bind(State.PAUSED))
	mute_button.pressed.connect(Settings.toggle_mute)
	Settings.muted_changed.connect(_show_muted)
	_show_muted(Settings.muted)


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
	mute_button.visible = not playing
	dim.visible = not playing
	start_screen.visible = state == State.START
	pause_screen.visible = state == State.PAUSED
	game_over_screen.visible = state == State.GAME_OVER


func _show_muted(muted: bool) -> void:
	mute_button.text = "SOUND OFF" if muted else "SOUND ON"
