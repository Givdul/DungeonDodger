## What the bot needs to know about any enemy, whichever kind it is.


## The area that hurts the player on contact.
static func hit_area(enemy: Node) -> Area2D:
	return enemy if enemy is Area2D else enemy.get_node("HitArea")


static func hit_shape(enemy: Node) -> CollisionShape2D:
	return hit_area(enemy).find_children("*", "CollisionShape2D", false)[0]


## Whether it turns to follow the player as it moves, rather than going straight.
static func chases(enemy: Node) -> bool:
	return enemy.is_in_group("Phantoms")


## Whether it's a bat holding still before it winds up to charge in a straight line.
static func waits_to_rush(enemy: Node) -> bool:
	return enemy.is_in_group("Bats") and enemy.state == "locking"


## Whether it's a bat flashing before a rush along its marked line.
static func winds_up(enemy: Node) -> bool:
	return enemy.is_in_group("Bats") and enemy.state == "winding_up"


## Which way a chaser at from heads for a player at target, as phantom.gd's aim_point() works it out.
static func chase_direction(enemy: Node, from: Vector2, target: Vector2) -> Vector2:
	var to_target := target - from
	var flank_offset := clampf(to_target.length() - enemy.FLANK_END_DISTANCE, 0.0, enemy.FLANK_WIDTH)
	return from.direction_to(target + to_target.orthogonal().normalized() * enemy.flank * flank_offset)


static func is_alive(enemy: Node) -> bool:
	return enemy.get("is_dead") != true and enemy.get("state") != "dead"


## The enemy's scene name, such as "phantom" or "bat".
static func kind(enemy: Node) -> String:
	return enemy.scene_file_path.get_file().get_basename()
