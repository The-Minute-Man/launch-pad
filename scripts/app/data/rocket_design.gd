class_name RocketDesign
extends Resource

@export var components: Array[RocketComponent] = []

func add_component(comp: RocketComponent) -> void:
	components.append(comp)

func get_total_mass() -> float:
	var total_mass = 0.0
	for comp in components:
		total_mass += comp.get_mass()
	return total_mass

# Calculates the Center of Gravity using a weighted average of all component masses
# CG = Sum(Mass * Position) / TotalMass
func get_cg() -> float:
	var total_mass = 0.0
	var weighted_sum = 0.0
	
	for comp in components:
		var m = comp.get_mass()
		var cg = comp.get_global_cg()
		
		total_mass += m
		weighted_sum += (m * cg)
		
	if total_mass == 0.0:
		return 0.0
		
	return weighted_sum / total_mass

# Finds the largest outer diameter among body tubes or nose cones
# Used as the Reference Area for aerodynamic calculations
func get_max_diameter() -> float:
	var max_d = 0.0
	for comp in components:
		if comp is BodyTube:
			if comp.outer_diameter > max_d:
				max_d = comp.outer_diameter
		elif comp is NoseCone:
			if comp.base_diameter > max_d:
				max_d = comp.base_diameter
	return max_d

func get_total_length() -> float:
	var max_len = 0.0
	for comp in components:
		var end_pos = comp.position_offset
		if comp is BodyTube:
			end_pos += comp.length
		elif comp is NoseCone:
			end_pos += comp.length
		# FinSets don't typically add to rocket total length unless they hang off back
		
		if end_pos > max_len:
			max_len = end_pos
	return max_len

# Rough approximation for Moments of Inertia
func get_inertia_longitudinal() -> float:
	# Using standard approximation for now
	# I_L = Sum(I_local + mass * distance_to_cg^2)
	var cg = get_cg()
	var inertia = 0.0
	for comp in components:
		var m = comp.get_mass()
		var d = comp.get_global_cg() - cg
		
		# Simple local inertia approximation (treating components as point masses for now)
		# A real implementation would use solid geometry inertia formulas
		var local_i = 0.0
		
		inertia += local_i + (m * pow(d, 2))
	
	if inertia < 0.001: inertia = 0.05 # Minimum sanity check
	return inertia

func get_inertia_rotational() -> float:
	var max_d = get_max_diameter()
	var mass = get_total_mass()
	var inertia = 0.5 * mass * pow(max_d / 2.0, 2)
	if inertia < 0.001: inertia = 0.005
	return inertia

func get_motor() -> RocketMotor:
	for comp in components:
		if comp is RocketMotor:
			return comp
	return null

# Packages all data into the exact format simulator.gd expects
func export_to_simulator() -> Dictionary:
	var d = get_max_diameter()
	var ref_area = PI * pow(d / 2.0, 2)
	
	if ref_area == 0.0:
		ref_area = PI * pow(0.02, 2) # Fallback to 4cm diameter
		
	return {
		"mass": get_total_mass(),
		"cg": get_cg(),
		"inertia_longitudinal": get_inertia_longitudinal(),
		"inertia_rotational": get_inertia_rotational(),
		"ref_area": ref_area,
		"ref_length": d,
		"rocket_length": get_total_length(),
		"motor": get_motor()
	}
