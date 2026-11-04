extends Node2D

const RADIUS := Vector2(6, 2.5)
const COLOR := Color(0, 0, 0, 0.35)


func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, RADIUS / RADIUS.x)
	draw_circle(Vector2.ZERO, RADIUS.x, COLOR)
