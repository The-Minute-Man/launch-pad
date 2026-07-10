class_name Parachute
extends RocketComponent

@export var diameter: float = 0.3 # 30cm parachute
@export var drag_coefficient: float = 1.5 # Standard for semi-elliptical/flat parachutes
# Deploy conditions (e.g. Apogee) will be handled by the simulator logic
@export var cloth_density: float = 0.067 # kg/m^2 (e.g. 1.9 oz ripstop nylon)
@export var lines_mass: float = 0.005 # Mass of shroud lines

func _init() -> void:
	component_name = "Parachute"
	material_name = "Ripstop Nylon"

func _calculate_mass() -> float:
	var area = PI * pow(diameter / 2.0, 2)
	return (area * cloth_density) + lines_mass

@export var packed_length: float = 0.05 # 5cm packed length

func _calculate_local_cg() -> float:
	# Packed parachute CG is usually the center of its packed length
	return packed_length / 2.0
