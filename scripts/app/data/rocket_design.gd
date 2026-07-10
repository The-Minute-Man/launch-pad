class_name RocketDesign
extends Resource

@export var components: Array[RocketComponent] = []

func add_component(comp: RocketComponent) -> void:
	components.append(comp)
	update_auto_stacking()

func update_auto_stacking() -> void:
	var current_y = 0.0
	var last_structural_length = 0.0
	
	for comp in components:
		if comp is NoseCone or comp is BodyTube or comp is Transition:
			comp.global_position = current_y + comp.relative_offset
			if "length" in comp:
				last_structural_length = comp.length
				current_y += comp.length
		elif comp is FinSet:
			# FinSets stick to the bottom of the previous structural component by default
			comp.global_position = current_y - comp.root_chord + comp.relative_offset
		elif comp is RocketMotor:
			# Stick motor to the bottom of the previous structural component
			comp.global_position = current_y - comp.length + comp.relative_offset
		elif comp is Parachute:
			# Stick parachute inside the previous structural component
			comp.global_position = current_y - (last_structural_length / 2.0) + comp.relative_offset

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
		var end_pos = comp.global_position
		if comp is BodyTube:
			end_pos += comp.length
		elif comp is NoseCone:
			end_pos += comp.length
		# FinSets don't typically add to rocket total length unless they hang off back
		
		if end_pos > max_len:
			max_len = end_pos
	return max_len

# High-Fidelity 3x3 Inertia Tensor Approximation
# Returns { "Ixx": float, "Iyy": float, "Izz": float }
# Z is the longitudinal axis (roll), X and Y are lateral pitch/yaw
func get_inertia_tensor() -> Dictionary:
	var cg = get_cg()
	var Ixx = 0.0
	var Iyy = 0.0
	var Izz = 0.0
	
	for comp in components:
		var m = comp.get_mass()
		var d = comp.get_global_cg() - cg
		
		# Simple local inertia approximation
		# In a real system, each component would return its own local tensor
		var r = get_max_diameter() / 2.0
		var local_Izz = 0.5 * m * pow(r, 2)
		
		var comp_len = 0.0
		if "length" in comp:
			comp_len = comp.length
		elif "packed_length" in comp:
			comp_len = comp.packed_length
		elif "root_chord" in comp:
			comp_len = comp.root_chord
			
		var local_Ixx = (1.0/12.0) * m * pow(comp_len, 2) + 0.25 * m * pow(r, 2)
		
		# Parallel axis theorem
		Ixx += local_Ixx + (m * pow(d, 2))
		Iyy += local_Ixx + (m * pow(d, 2)) # Symmetrical
		Izz += local_Izz
	
	return { "Ixx": Ixx, "Iyy": Iyy, "Izz": Izz }

# Barrowman Aerodynamic Aggregator
func get_aerodynamics() -> Dictionary:
	var total_cn_alpha = 0.0
	var weighted_cp_sum = 0.0
	var max_d = get_max_diameter()
	
	for comp in components:
		var cn_a = 0.0
		var cp_local = 0.0
		
		if comp is NoseCone:
			cn_a = 2.0
			cp_local = comp.get_aerodynamic_cp()
		elif comp is FinSet:
			cn_a = comp.get_cn_alpha(max_d / 2.0)
			cp_local = comp.get_aerodynamic_cp()
		elif comp is Transition:
			cn_a = comp.get_cn_alpha()
			# Normalizing based on reference area diameter
			cn_a *= pow(max_d / comp.fore_diameter, 2) # Rough normalization
			cp_local = comp.get_aerodynamic_cp()
			
		# Add global position offset to the local CP
		var global_cp = comp.global_position + cp_local
		
		total_cn_alpha += cn_a
		weighted_cp_sum += (cn_a * global_cp)
		
	var final_cp = 0.0
	if total_cn_alpha > 0:
		final_cp = weighted_cp_sum / total_cn_alpha
		
	return { "cn_alpha": total_cn_alpha, "cp": final_cp }

func get_motor() -> RocketMotor:
	for comp in components:
		if comp is RocketMotor:
			return comp
	return null

func get_parachute() -> Parachute:
	for comp in components:
		if comp is Parachute:
			return comp
	return null

func get_fin_cant() -> float:
	for comp in components:
		if comp is FinSet:
			return comp.fin_cant_angle
	return 0.0

func get_wetted_area() -> float:
	var area = 0.0
	for comp in components:
		if comp is BodyTube:
			area += 2.0 * PI * (comp.outer_diameter / 2.0) * comp.length
		elif comp is Transition:
			var R1 = comp.fore_diameter / 2.0
			var R2 = comp.aft_diameter / 2.0
			var slant = sqrt(pow(R1 - R2, 2) + pow(comp.length, 2))
			area += PI * (R1 + R2) * slant
		elif comp is FinSet:
			area += 2.0 * comp.span * comp.root_chord * comp.fin_count
	return area

func get_fin_span() -> float:
	for comp in components:
		if comp is FinSet:
			return comp.span
	return 0.0

# Packages all data into the exact format simulator.gd expects
func export_to_simulator() -> Dictionary:
	var d = get_max_diameter()
	var ref_area = PI * pow(d / 2.0, 2)
	
	if ref_area == 0.0:
		ref_area = PI * pow(0.02, 2) # Fallback to 4cm diameter
		
	var aero = get_aerodynamics()
	var inertia = get_inertia_tensor()
	var parachute = get_parachute()
	
	return {
		"mass": get_total_mass(),
		"cg": get_cg(),
		"inertia": inertia,
		"cn_alpha": aero["cn_alpha"],
		"cp": aero["cp"],
		"fin_cant_angle": get_fin_cant(),
		"fin_span": get_fin_span(),
		"wetted_area": get_wetted_area(),
		"ref_area": ref_area,
		"ref_length": d,
		"rocket_length": get_total_length(),
		"motor": get_motor(),
		"has_parachute": parachute != null,
		"parachute_diameter": parachute.diameter if parachute else 0.0,
		"parachute_cd": parachute.drag_coefficient if parachute else 0.0
	}
