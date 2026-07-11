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
	var inner_radius = min(inner_diameter / 2.0, outer_radius - 0.0001)
	
	var volume = PI * length * (pow(outer_radius, 2) - pow(inner_radius, 2))
	var density = MaterialDB.get_density(material_name)
	
	return volume * density

func _calculate_local_cg() -> float:
	# A uniform cylinder's CG is exactly in the middle
	return length / 2.0

func get_local_Ixx(mass: float) -> float:
	var R_out = outer_diameter / 2.0
	var R_in = min(inner_diameter / 2.0, R_out - 0.0001)
	return mass * (pow(length, 2) / 12.0 + (pow(R_out, 2) + pow(R_in, 2)) / 4.0)

func get_local_Izz(mass: float) -> float:
	var R_out = outer_diameter / 2.0
	var R_in = min(inner_diameter / 2.0, R_out - 0.0001)
	return mass * (pow(R_out, 2) + pow(R_in, 2)) / 2.0
