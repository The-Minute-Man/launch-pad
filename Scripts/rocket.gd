@tool
extends Node3D

func _ready():
	# Make it smaller
	scale = Vector3(0.5, 0.5, 0.5)
	
	# Move it slightly lower
	position = Vector3(0, -1.0, 0)
	
	# Rotate it diagonally (increased angles to make it more horizontal)
	rotation_degrees = Vector3(60, 45, -60)

func _process(delta):
	# Spin slowly along the rocket's local Y axis
	rotate_object_local(Vector3.UP, 0.5 * delta)
