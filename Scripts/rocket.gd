extends Node3D
@export var rocket_text: String = "PROJECTS"
@export var is_rotating: bool = true

func _ready() -> void:
	if has_node("Visuals"):
		for child in $Visuals.get_children():
			if child is Label3D:
				if rocket_text == "":
					child.visible = false
				else:
					child.visible = true
					child.text = rocket_text

func _process(delta):
	if not is_inside_tree():
		return
	
	# Spin slowly. The root node stays perfectly still (so the editor base tilt is never lost).
	# We only spin the inner Visuals container!
	if is_rotating and has_node("Visuals"):
		$Visuals.rotate_y(0.5 * delta)
