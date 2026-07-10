class_name BodyTube
extends RocketComponent

@export var length: float = 0.5
@export var outer_diameter: float = 0.05
@export var inner_diameter: float = 0.048

func _init() -> void:
	component_name = "Body Tube"
	material_name = "Cardboard"

func _calculate_mass() -> float:
	var outer_radius = outer_diameter / 2.0
	var inner_radius = inner_diameter / 2.0
	
	var volume = PI * length * (pow(outer_radius, 2) - pow(inner_radius, 2))
	var density = MaterialDB.get_density(material_name)
	
	return volume * density

func _calculate_local_cg() -> float:
	# A uniform cylinder's CG is exactly in the middle
	return length / 2.0
