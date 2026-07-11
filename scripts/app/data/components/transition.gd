class_name Transition
extends RocketComponent

@export var fore_diameter: float = 0.04
@export var aft_diameter: float = 0.03
@export var wall_thickness: float = 0.002
@export var length: float = 0.1

func _init() -> void:
	component_name = "Transition"
	material_name = "Cardboard"

func _calculate_mass() -> float:
	# Area of a frustum cone
	var R1 = fore_diameter / 2.0
	var R2 = aft_diameter / 2.0
	var slant_length = sqrt(pow(R1 - R2, 2) + pow(length, 2))
	var surface_area = PI * (R1 + R2) * slant_length
	
	# Very rough mass calculation
	var density = MaterialDB.get_density(material_name)
	var volume = surface_area * wall_thickness
	return volume * density

func _calculate_local_cg() -> float:
	if fore_diameter + aft_diameter == 0: return 0.0
	# CG for a hollow conical frustum (shell)
	return length * (fore_diameter + 2.0 * aft_diameter) / (3.0 * (fore_diameter + aft_diameter))

# Barrowman Aerodynamics
func get_cn_alpha() -> float:
	return 2.0 * (pow(aft_diameter, 2) - pow(fore_diameter, 2))

func get_aerodynamic_cp() -> float:
	if fore_diameter == aft_diameter: return length / 2.0
	var cp = (length / 3.0) * (1.0 + (1.0 - fore_diameter/aft_diameter) / (1.0 - pow(fore_diameter/aft_diameter, 2)))
	return cp

func get_local_Ixx(mass: float) -> float:
	var R1 = fore_diameter / 2.0
	var R2 = aft_diameter / 2.0
	# Approximation for thin-walled conical frustum local Ixx
	return mass * (pow(length, 2) / 12.0 + (pow(R1, 2) + R1*R2 + pow(R2, 2)) / 6.0)

func get_local_Izz(mass: float) -> float:
	var R1 = fore_diameter / 2.0
	var R2 = aft_diameter / 2.0
	# Exact Izz for thin-walled conical frustum
	return mass * (pow(R1, 2) + R1*R2 + pow(R2, 2)) / 3.0
