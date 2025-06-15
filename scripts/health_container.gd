extends Node2D

@export var full_icon: Texture2D
@export var empty_icon: Texture2D

@onready var hearts := [$Heart1, $Heart2, $Heart3]

func _ready():
	get_tree().get_first_node_in_group("Player").connect("lives_changed", Callable(self, "update_lives"))

func update_lives(lives: int):
	for i in range(hearts.size()):
		if i < lives:
			hearts[i].texture = full_icon
		else:
			hearts[i].texture = empty_icon
