@tool
extends Node3D

func _process(delta):
	# Spin slowly. The root node stays perfectly still (so the editor base tilt is never lost).
	# We only spin the inner Visuals container!
	if has_node("Visuals"):
		$Visuals.rotate_y(0.5 * delta)
