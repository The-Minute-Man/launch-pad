class_name Aerodynamics
extends RefCounted

# Helper to compute the total aerodynamic force vector in body frame
static func compute_aero_forces(state: FlightState, env: Dictionary, relative_wind_body: Vector3, reference_area: float, reference_length: float, rocket_length: float, sim_data: Dictionary) -> Dictionary:
	var v_rel_mag = relative_wind_body.length()
	if v_rel_mag < 0.001:
		return {"force": Vector3.ZERO, "torque": Vector3.ZERO}
	
	# Mach number and Reynolds number
	var mach = v_rel_mag / env["speed_of_sound"]
	var dynamic_viscosity = 1.8e-5
	var reynolds = (env["density"] * v_rel_mag * rocket_length) / dynamic_viscosity
	
	# Angle of Attack (alpha)
	var v_lateral = sqrt(relative_wind_body.x * relative_wind_body.x + relative_wind_body.y * relative_wind_body.y)
	var alpha = atan2(v_lateral, -relative_wind_body.z) # Wind from front means negative Z velocity
	
	# --- 1. Compute Normal Force (Lift) ---
	var cn_alpha_total = sim_data.get("cn_alpha", 2.0)
	var cp_location = sim_data.get("cp", 1.5)
	
	# Supersonic Prandtl-Glauert CP shift correction
	if mach > 0.8:
		# Shift CP backward during transonic/supersonic flight (clamp to avoid divide-by-zero singularity at Mach 1)
		var pg_factor = 1.0 / sqrt(max(abs(1.0 - mach*mach), 0.01))
		cp_location += 0.05 * pg_factor
		
	var normal_force_mag = 0.5 * env["density"] * v_rel_mag * v_rel_mag * reference_area * (cn_alpha_total * alpha)
	
	# Direction of normal force in body frame (perpendicular to Z, opposite to lateral wind)
	var normal_dir = Vector3(relative_wind_body.x, relative_wind_body.y, 0.0)
	if v_lateral > 0.0001:
		normal_dir = normal_dir.normalized()
	var normal_force = normal_dir * normal_force_mag
	
	# --- 2. Compute Drag Force ---
	var wetted_area = sim_data.get("wetted_area", reference_area * 10.0)
	var c_d = compute_drag_coefficient(mach, reynolds, reference_area, wetted_area)
	var drag_force_mag = 0.5 * env["density"] * v_rel_mag * v_rel_mag * reference_area * c_d
	
	if sim_data.get("parachute_deployed", false) and sim_data.get("has_parachute", false):
		var para_d = sim_data.get("parachute_diameter", 0.3)
		var para_cd = sim_data.get("parachute_cd", 1.5)
		var para_area = PI * pow(para_d / 2.0, 2)
		var para_drag_mag = 0.5 * env["density"] * v_rel_mag * v_rel_mag * para_area * para_cd
		drag_force_mag += para_drag_mag # Sum the forces properly
		
	var drag_force = relative_wind_body.normalized() * drag_force_mag
	
	var total_force = drag_force + normal_force
	
	# --- 3. Compute Torques ---
	var lever_arm = Vector3(0, 0, state.cg - cp_location)
	var aero_torque = lever_arm.cross(total_force)
	
	# Fin Cant Roll Torque
	var roll_torque = 0.0
	var fin_cant = sim_data.get("fin_cant_angle", 0.0)
	if abs(fin_cant) > 0.001:
		var cant_rad = deg_to_rad(fin_cant)
		var fin_span = sim_data.get("fin_span", reference_length)
		# Improved Roll Forcing coefficient approximation using actual fin span
		roll_torque = 0.5 * env["density"] * v_rel_mag * v_rel_mag * reference_area * sin(cant_rad) * (fin_span + reference_length / 2.0)
		
	aero_torque.z += roll_torque
	
	# Damping torques
	var pitch_damp_coeff = 0.5 # C_R_alpha
	var pitch_damp_mag = 0.5 * env["density"] * v_rel_mag * reference_area * (reference_length * reference_length) * pitch_damp_coeff
	
	var roll_damp_coeff = 0.05 # C_l_p (much smaller than pitch damping)
	var roll_damp_mag = 0.5 * env["density"] * v_rel_mag * reference_area * (reference_length * reference_length) * roll_damp_coeff
	
	var damping_torque = Vector3(
		-state.angular_velocity.x * pitch_damp_mag,
		-state.angular_velocity.y * pitch_damp_mag,
		-state.angular_velocity.z * roll_damp_mag
	)
	
	return {
		"force": total_force,
		"torque": aero_torque + damping_torque
	}

# Compute total axial drag coefficient (Skin Friction + Base Drag + Pressure Drag)
static func compute_drag_coefficient(mach: float, reynolds: float, reference_area: float, wetted_area: float) -> float:
	# A. Skin Friction (Turbulent assumption)
	var r = max(reynolds, 1000.0)
	var c_f = 1.0 / pow(1.50 * log(r) - 5.6, 2)
	
	# Compressibility correction
	if mach < 1.0:
		c_f = c_f * (1.0 - 0.1 * mach * mach)
	else:
		c_f = c_f / pow(1.0 + 0.15 * mach * mach, 0.58)
	
	# B. Base Drag
	var c_d_base = 0.0
	if mach < 1.0:
		c_d_base = 0.12 + 0.13 * mach * mach
	else:
		c_d_base = 0.25 / mach
		
	# C. Pressure Drag (Wave drag simplified)
	var c_d_pressure = 0.0
	if mach > 0.8 and mach < 1.0:
		c_d_pressure = 0.1 # Transonic rise dummy
	elif mach >= 1.0:
		var half_angle = deg_to_rad(15.0)
		c_d_pressure = (2.1 * pow(sin(half_angle), 2)) / (mach * mach)
		
	var c_d_skin = c_f * (wetted_area / reference_area)
	return c_d_skin + c_d_base + c_d_pressure
