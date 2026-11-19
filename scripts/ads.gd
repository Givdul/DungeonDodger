extends Node

## Runs consent, tracking and ad loading at launch, and shows the game's two ads:
## an opt-in rewarded ad to continue a run and an interstitial on restart.
## Without the native AdMob plugin (desktop and editor runs) no ad is ever available.
## The iOS export plugin reads the app ID and ATT text from the Admob node in admob.tscn.

signal privacy_options_changed
signal _interstitial_finished
signal _rewarded_finished

const PLUGIN_SINGLETON := "AdmobPlugin"
const ADMOB_SCENE := preload("res://scenes/admob.tscn")
# Hyper-casual norm. Counted in play time only: this node pauses with the game.
const INTERSTITIAL_GAP_SECONDS := 90.0
const RELOAD_DELAY_SECONDS := 30.0

var _can_request_ads := false
var _play_seconds_since_ad := 0.0
var _reward_earned := false

var admob: Admob


func _ready() -> void:
	if not Engine.has_singleton(PLUGIN_SINGLETON):
		return
	admob = ADMOB_SCENE.instantiate()
	add_child(admob)
	admob.consent_info_updated.connect(_on_consent_info_updated)
	admob.consent_info_update_failed.connect(_on_consent_info_updated.unbind(1))
	admob.initialization_completed.connect(_on_initialized.unbind(1))
	admob.consent_form_loaded.connect(admob.show_consent_form)
	admob.consent_form_failed_to_load.connect(_on_consent_gathered.unbind(1))
	admob.consent_form_dismissed.connect(_on_consent_gathered.unbind(1))
	admob.tracking_authorization_granted.connect(_load_ads)
	admob.tracking_authorization_denied.connect(_load_ads)

	admob.interstitial_ad_failed_to_load.connect(_reload_later.bind(admob.load_interstitial_ad).unbind(2))
	admob.interstitial_ad_dismissed_full_screen_content.connect(_on_interstitial_closed.unbind(1))
	admob.interstitial_ad_failed_to_show_full_screen_content.connect(_on_interstitial_closed.unbind(2))

	admob.rewarded_ad_failed_to_load.connect(_reload_later.bind(admob.load_rewarded_ad).unbind(2))
	admob.rewarded_ad_user_earned_reward.connect(func(_ad, _reward): _reward_earned = true)
	admob.rewarded_ad_dismissed_full_screen_content.connect(_on_rewarded_closed.unbind(1))
	admob.rewarded_ad_failed_to_show_full_screen_content.connect(_on_rewarded_closed.unbind(2))

	admob.update_consent_info()


func _process(delta: float) -> void:
	_play_seconds_since_ad += delta


func can_continue() -> bool:
	return _can_request_ads and admob.is_rewarded_ad_loaded()


## Shows the rewarded ad. Returns whether the player earned the continue.
func show_continue_ad() -> bool:
	_reward_earned = false
	admob.show_rewarded_ad()
	await _rewarded_finished
	return _reward_earned


## Shows an interstitial if enough play time has passed since the last ad.
## Returns once the player is back in the game.
func show_interstitial_if_due() -> void:
	if _play_seconds_since_ad < INTERSTITIAL_GAP_SECONDS:
		return
	if not _can_request_ads or not admob.is_interstitial_ad_loaded():
		return
	admob.show_interstitial_ad()
	await _interstitial_finished


## Players in regions that need consent (EEA, UK) must be able to change it later.
func has_privacy_options() -> bool:
	if admob == null:
		return false
	var consent := admob.get_consent_status()
	return consent != null and consent.status in [UserConsent.Status.REQUIRED, UserConsent.Status.OBTAINED]


# The plugin has no UMP privacy-options form (godot-admob#125). Loading and presenting
# the consent form again is how UMP let users change their choices before that API existed.
func show_privacy_options() -> void:
	admob.load_consent_form()


# The SDK has to be started before the plugin can load a consent form.
func _on_consent_info_updated() -> void:
	admob.initialize()


func _on_initialized() -> void:
	privacy_options_changed.emit()
	var consent := admob.get_consent_status()
	if consent.status == UserConsent.Status.REQUIRED and admob.is_consent_form_available():
		admob.load_consent_form()
	else:
		_on_consent_gathered()


func _on_consent_gathered() -> void:
	privacy_options_changed.emit()
	if _can_request_ads:
		return
	var consent := admob.get_consent_status().status
	_can_request_ads = consent in [UserConsent.Status.OBTAINED, UserConsent.Status.NOT_REQUIRED]
	if _can_request_ads:
		admob.request_tracking_authorization()


func _load_ads() -> void:
	admob.load_interstitial_ad()
	admob.load_rewarded_ad()


func _reload_later(load_ad: Callable) -> void:
	get_tree().create_timer(RELOAD_DELAY_SECONDS).timeout.connect(load_ad)


func _on_interstitial_closed() -> void:
	_play_seconds_since_ad = 0.0
	admob.load_interstitial_ad()
	_interstitial_finished.emit()


func _on_rewarded_closed() -> void:
	_play_seconds_since_ad = 0.0
	admob.load_rewarded_ad()
	_rewarded_finished.emit()
