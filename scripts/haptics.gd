extends Node
## Phone vibrations, with every strength tuned here. On iOS, Godot plays
## Input.vibrate_handheld through the haptic engine. On desktop and web it does nothing.

# Coins come often, so theirs is the faintest tick that still registers.
const COIN_MS := 10
const COIN_AMPLITUDE := 0.3
const DAMAGE_MS := 120
const DAMAGE_AMPLITUDE := 0.7
const EXPLOSION_MS := 200
const EXPLOSION_AMPLITUDE := 1.0

# Pulses asked for in the same step, before the deferred call runs, play as one,
# the strongest, so a bomb that blows up on the player thumps once instead of buzzing twice.
var _pending_ms := 0
var _pending_amplitude := 0.0


func coin() -> void:
	_request(COIN_MS, COIN_AMPLITUDE)


func damage() -> void:
	_request(DAMAGE_MS, DAMAGE_AMPLITUDE)


func explosion() -> void:
	_request(EXPLOSION_MS, EXPLOSION_AMPLITUDE)


func _request(duration_ms: int, amplitude: float) -> void:
	if get_tree().paused or amplitude <= _pending_amplitude:
		return
	if _pending_amplitude == 0.0:
		_play_pending.call_deferred()
	_pending_ms = duration_ms
	_pending_amplitude = amplitude


func _play_pending() -> void:
	Input.vibrate_handheld(_pending_ms, _pending_amplitude)
	_pending_ms = 0
	_pending_amplitude = 0.0
