extends Area2D

signal picked_up

@onready var anim = $AnimatedSprite2D
@onready var audio_stream_player = $AudioStreamPlayer


var picked_up_already := false  # Add this at the top of the script

func _on_body_entered(body):
	if body.is_in_group("Player") and not picked_up_already:
		picked_up_already = true  # Prevent retriggering

		emit_signal("picked_up")
		$CollisionShape2D.disabled = true  # Disable collision to be extra safe
		anim.play("picked_up")
		audio_stream_player.play()
		await anim.animation_finished
		queue_free()
