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
	# Simplified CG for a frustum (biased towards the wider end)
	var R1 = fore_diameter / 2.0
	var R2 = aft_diameter / 2.0
	# Standard formula for frustum CG distance from fore end
	if length == 0: return 0.0
	var cg = length * (pow(R1, 2) + 2*R1*R2 + 3*pow(R2, 2)) / (4 * (pow(R1, 2) + R1*R2 + pow(R2, 2)))
	return cg

# Barrowman Aerodynamics
func get_cn_alpha() -> float:
	# Barrowman formula for conical transition based on reference area (we assume reference area is based on fore_diameter for standardizing)
	# C_Na = 2 * ((d_aft/d_ref)^2 - (d_fore/d_ref)^2)
	# The global aggregator will normalize this properly. We will just return the non-normalized ratio here.
	return 2.0 * (pow(aft_diameter, 2) - pow(fore_diameter, 2))

func get_aerodynamic_cp() -> float:
	if fore_diameter == aft_diameter: return length / 2.0
	# Barrowman CP for conical transition
	var cp = (length / 3.0) * (1.0 + (1.0 - fore_diameter/aft_diameter) / (1.0 - pow(fore_diameter/aft_diameter, 2)))
	return cp
