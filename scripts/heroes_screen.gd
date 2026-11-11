extends Control
## The HEROES screen: the selected skin big on top with how to get it, and every skin in a grid below.

signal back_pressed

const COLUMNS := 5
const CELL_SIZE := Vector2(30, 30)
const LOCKED_TINT := Color(0.07, 0.07, 0.09)
const PRICE_COLOR := Color(0.75, 0.75, 0.75)

@export var crystal_icon: Texture2D
@export var trophy_icon: Texture2D
@export var select_icon: Texture2D
@export var regular_font: Font

var _selected := Progress.worn
var _cells := {}
var _group := ButtonGroup.new()

@onready var wallet_label: Label = %WalletLabel
@onready var preview: AnimatedSprite2D = %Preview
@onready var name_label: Label = %HeroNameLabel
@onready var status_label: Label = %HeroStatusLabel
@onready var action_button: Button = %HeroActionButton
@onready var goal_row: Control = %GoalRow
@onready var goal_bar: ProgressBar = %GoalBar
@onready var goal_label: Label = %GoalLabel
@onready var grid: GridContainer = %HeroGrid
@onready var select_marker := TextureRect.new()


func _ready() -> void:
	%HeroesBackButton.pressed.connect(back_pressed.emit)
	action_button.pressed.connect(_on_action_pressed)
	select_marker.texture = select_icon
	select_marker.mouse_filter = MOUSE_FILTER_IGNORE
	select_marker.position = Vector2(CELL_SIZE.x - 15, -2)
	grid.columns = COLUMNS
	for id in Heroes.ids():
		_cells[id] = _make_cell(id)
		grid.add_child(_cells[id])


## Brings the screen up to date with Progress and selects the worn skin.
func open() -> void:
	_selected = Progress.worn
	_refresh()


func _refresh() -> void:
	wallet_label.text = str(Progress.wallet)
	for id: String in _cells:
		_fill_cell(_cells[id], id)
	_show_selected()


func _show_selected() -> void:
	var id := _selected
	var rule := Heroes.unlock_rule(id)
	preview.sprite_frames = Heroes.sprite_frames(id)
	preview.play(&"idle")
	name_label.text = Heroes.display_name(id).to_upper()
	var owned := Progress.is_unlocked(id)
	action_button.visible = owned or rule.kind == "crystals"
	goal_row.visible = not action_button.visible
	action_button.disabled = false
	if Progress.worn == id:
		status_label.text = "Worn"
		action_button.text = "WORN"
		action_button.disabled = true
	elif owned:
		status_label.text = "Owned"
		action_button.text = "WEAR"
	elif rule.kind == "crystals":
		status_label.text = "Unlock with crystals"
		action_button.text = "BUY %d" % rule.price
		action_button.disabled = Progress.wallet < rule.price
	else:
		status_label.text = rule.text
		var reached := mini(Progress.stat(rule.stat), rule.goal)
		goal_bar.max_value = rule.goal
		goal_bar.value = reached
		goal_label.text = "%s / %s" % [_stat_text(rule.stat, reached), _stat_text(rule.stat, rule.goal)]
	var cell_button: Button = _cells[id].get_child(0)
	cell_button.button_pressed = true
	if select_marker.get_parent():
		select_marker.get_parent().remove_child(select_marker)
	cell_button.add_child(select_marker)


func _on_action_pressed() -> void:
	if Progress.is_unlocked(_selected):
		Progress.wear(_selected)
	else:
		Progress.buy(_selected)
	_refresh()


func _select(id: String) -> void:
	_selected = id
	_show_selected()


static func _stat_text(stat: String, value: int) -> String:
	if stat.ends_with("_seconds"):
		@warning_ignore("integer_division")
		return "%d:%02d" % [value / 60, value % 60]
	return str(value)


# An item box with the skin standing in it, and its price or a trophy under it while it's locked.
func _make_cell(id: String) -> Control:
	var cell := VBoxContainer.new()
	cell.mouse_filter = MOUSE_FILTER_PASS
	cell.add_theme_constant_override(&"separation", 1)
	var button := Button.new()
	button.custom_minimum_size = CELL_SIZE
	button.focus_mode = FOCUS_NONE
	button.toggle_mode = true
	# Passes drags on to the scroll container, so a swipe that starts on a cell still scrolls.
	button.mouse_filter = MOUSE_FILTER_PASS
	button.button_group = _group
	button.pressed.connect(_select.bind(id))
	cell.add_child(button)
	var portrait := TextureRect.new()
	portrait.texture = Heroes.portrait(id)
	portrait.mouse_filter = MOUSE_FILTER_IGNORE
	portrait.position = ((CELL_SIZE - Vector2(Heroes.FRAME_SIZE)) / 2).floor()
	button.add_child(portrait)
	# A plain Control around the price, so a four-digit one can spill into the gaps instead of widening its column.
	var price_slot := Control.new()
	price_slot.custom_minimum_size.y = 8
	price_slot.mouse_filter = MOUSE_FILTER_IGNORE
	var price := HBoxContainer.new()
	price.set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_MINSIZE)
	price.grow_horizontal = GROW_DIRECTION_BOTH
	price.grow_vertical = GROW_DIRECTION_BOTH
	price.add_theme_constant_override(&"separation", 1)
	price.mouse_filter = MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	price.add_child(icon)
	var label := Label.new()
	label.add_theme_font_override(&"font", regular_font)
	label.add_theme_color_override(&"font_color", PRICE_COLOR)
	price.add_child(label)
	price_slot.add_child(price)
	cell.add_child(price_slot)
	return cell


func _fill_cell(cell: Control, id: String) -> void:
	var owned := Progress.is_unlocked(id)
	var rule := Heroes.unlock_rule(id)
	var portrait: TextureRect = cell.get_child(0).get_child(0)
	portrait.self_modulate = Color.WHITE if owned else LOCKED_TINT
	var price := cell.get_child(1).get_child(0)
	var icon: TextureRect = price.get_child(0)
	var label: Label = price.get_child(1)
	icon.visible = not owned
	label.visible = not owned and rule.kind == "crystals"
	if rule.kind == "crystals":
		icon.texture = crystal_icon
		label.text = str(rule.price)
	else:
		icon.texture = trophy_icon
