class_name NoseCone
extends RocketComponent

enum Shape { CONICAL, OGIVE, PARABOLIC }

@export var length: float = 0.15
@export var base_diameter: float = 0.05
@export var wall_thickness: float = 0.002
@export var shape_type: Shape = Shape.OGIVE

func _init() -> void:
	component_name = "Nose Cone"
	material_name = "Plastic (Polystyrene)"

func _calculate_mass() -> float:
	var outer_radius = base_diameter / 2.0
	var inner_radius = outer_radius - wall_thickness
	if inner_radius < 0: inner_radius = 0.0
	
	var outer_volume = 0.0
	var inner_volume = 0.0
	
	# Simplification: Treat volume approximation based on shape
	match shape_type:
		Shape.CONICAL:
			outer_volume = (PI * pow(outer_radius, 2) * length) / 3.0
			inner_volume = (PI * pow(inner_radius, 2) * (length - wall_thickness)) / 3.0
		Shape.OGIVE, Shape.PARABOLIC:
			# Approx volume of ogive/parabola is ~0.5 of cylinder
			outer_volume = 0.5 * PI * pow(outer_radius, 2) * length
			inner_volume = 0.5 * PI * pow(inner_radius, 2) * (length - wall_thickness)
			
	var volume = outer_volume - inner_volume
	if volume < 0: volume = 0.0
	
	var density = MaterialDB.get_density(material_name)
	return volume * density

func _calculate_local_cg() -> float:
	# Simplified CG based on hollow shape approximations
	match shape_type:
		Shape.CONICAL:
			return length * 0.66
		Shape.OGIVE:
			return length * 0.466
		Shape.PARABOLIC:
			return length * 0.5
	return length * 0.5

# Specific to aerodynamic calculation for Simulator
func get_aerodynamic_cp() -> float:
	match shape_type:
		Shape.CONICAL:
			return length * 0.666
		Shape.OGIVE, Shape.PARABOLIC:
			return length * 0.466
	return length * 0.5
