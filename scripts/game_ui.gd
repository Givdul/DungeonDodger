extends CanvasLayer

signal restart_requested

enum State { START, PLAYING, PAUSED, GAME_OVER }

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


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_to_screen)
	_fit_to_screen()
	%PlayButton.pressed.connect(start_playing)
	%ResumeButton.pressed.connect(start_playing)
	%RestartButton.pressed.connect(restart_requested.emit)
	pause_button.pressed.connect(_set_state.bind(State.PAUSED))
	mute_button.pressed.connect(Settings.toggle_mute)
	Settings.muted_changed.connect(_show_muted)
	_show_muted(Settings.muted)


func _fit_to_screen() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	root.size = viewport_size / UI_SCALE
	# Keep the HUD level with the hearts and score, which are drawn in the room,
	# and out of the notch and home indicator.
	var hud := _room_on_screen(viewport_size).intersection(_safe_area_in_viewport())
	hud_area.offset_left = hud.position.x / UI_SCALE
	hud_area.offset_top = hud.position.y / UI_SCALE
	hud_area.offset_right = (hud.end.x - viewport_size.x) / UI_SCALE
	hud_area.offset_bottom = (hud.end.y - viewport_size.y) / UI_SCALE


# The camera frames the room to exactly the design viewport; taller screens add wall above and below.
func _room_on_screen(viewport_size: Vector2) -> Rect2:
	var design_size := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	return Rect2((viewport_size - design_size) / 2, design_size)


# DisplayServer reports the safe area in screen pixels; map it into viewport units.
func _safe_area_in_viewport() -> Rect2:
	var window := Rect2(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area()).intersection(window)
	safe.position -= window.position
	return get_viewport().get_screen_transform().affine_inverse() * safe


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
