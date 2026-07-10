class_name Aerodynamics
extends RefCounted

# Helper to compute the total aerodynamic force vector in body frame
static func compute_aero_forces(state: FlightState, env: Dictionary, relative_wind_body: Vector3, reference_area: float, reference_length: float, rocket_length: float) -> Dictionary:
	var v_rel_mag = relative_wind_body.length()
	if v_rel_mag < 0.001:
		return {"force": Vector3.ZERO, "torque": Vector3.ZERO}
	
	# Mach number and Reynolds number
	var mach = v_rel_mag / env["speed_of_sound"]
	var dynamic_viscosity = 1.8e-5
	var reynolds = (env["density"] * v_rel_mag * rocket_length) / dynamic_viscosity
	
	# Angle of attack (alpha)
	var v_lateral = sqrt(relative_wind_body.x * relative_wind_body.x + relative_wind_body.y * relative_wind_body.y)
	var alpha = atan2(v_lateral, abs(relative_wind_body.z))
	
	# --- 1. Compute Normal Force (Lift) ---
	# In a real setup, we'd sum C_N_alpha for all components. Using a dummy value for the whole rocket for now.
	var cn_alpha_total = 2.0 + 4.0 # Nose + Fins
	var normal_force_mag = 0.5 * env["density"] * v_rel_mag * v_rel_mag * reference_area * (cn_alpha_total * alpha)
	
	# Direction of normal force in body frame (perpendicular to Z, opposite to lateral wind)
	var normal_dir = Vector3(relative_wind_body.x, relative_wind_body.y, 0.0)
	if v_lateral > 0.0001:
		normal_dir = normal_dir.normalized()
	var normal_force = normal_dir * normal_force_mag
	
	# --- 2. Compute Drag Force ---
	var c_d = compute_drag_coefficient(mach, reynolds)
	var drag_force_mag = 0.5 * env["density"] * v_rel_mag * v_rel_mag * reference_area * c_d
	var drag_force = relative_wind_body.normalized() * drag_force_mag
	
	var total_force = drag_force + normal_force
	
	# --- 3. Compute Torques ---
	var cp_location = 1.5 # Dummy CP location from nose tip
	var lever_arm = Vector3(0, 0, state.cg - cp_location)
	var aero_torque = lever_arm.cross(total_force)
	
	# Damping torques
	var pitch_damp_coeff = 0.5 # Dummy C_R_alpha
	var pitch_damp_mag = 0.5 * env["density"] * v_rel_mag * reference_area * (reference_length * reference_length) * pitch_damp_coeff
	var damping_torque = -state.angular_velocity * pitch_damp_mag
	
	return {
		"force": total_force,
		"torque": aero_torque + damping_torque
	}

# Compute total axial drag coefficient (Skin Friction + Base Drag + Pressure Drag)
static func compute_drag_coefficient(mach: float, reynolds: float) -> float:
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
		
	return c_f * 10.0 + c_d_base + c_d_pressure # Multiplied c_f by 10 to account for wetted area vs ref area roughly
