class_name RigidBodyPhysics
extends RefCounted

# Computes the state derivatives [v_dot, p_dot, w_dot, q_dot]
static func compute_derivatives(state: FlightState, env_system: FlightEnvironment, ref_area: float, ref_length: float, rocket_length: float, thrust: float, sim_data: Dictionary) -> Dictionary:
	# 1. Environment & Wind
	var env_data = FlightEnvironment.get_atmosphere(state.position.y) # Z is up in OpenRocket, but Godot uses Y up. Let's assume Y is up.
	var wind_global = env_system.get_wind(state.time, state.position.y)
	
	# Relative Wind in Global Frame
	var v_rel_global = wind_global - state.velocity
	
	# Rotate to Body Frame
	var v_rel_body = state.orientation.inverse() * v_rel_global
	
	# 2. Aerodynamics
	var aero = Aerodynamics.compute_aero_forces(state, env_data, v_rel_body, ref_area, ref_length, rocket_length, sim_data)
	var force_aero_body: Vector3 = aero["force"]
	var torque_total_body: Vector3 = aero["torque"]
	
	# 3. Thrust
	var force_thrust_body = Vector3(0, 0, -thrust) # Assuming nose points in -Z in Godot body frame? Let's assume nose points +Z for consistency with OpenRocket math.
	# Actually, OpenRocket +Z is nose tip. Let's use Vector3(0, 0, thrust)
	force_thrust_body = Vector3(0, 0, thrust)
	
	var total_force_body = force_aero_body + force_thrust_body
	
	# Rotate forces back to Global Frame
	var total_force_global = state.orientation * total_force_body
	
	# Add Gravity (Global -Y direction in Godot)
	# Inverse-square law: g = 9.80665 * (R_e / (R_e + h))^2
	var R_e = 6371000.0
	var h = state.position.y
	var g = 9.80665 * pow(R_e / (R_e + max(0.0, h)), 2)
	var gravity_force = Vector3(0, -g * state.mass, 0)
	total_force_global += gravity_force
	
	# 4. Translational Derivatives
	var v_dot = total_force_global / state.mass
	var p_dot = state.velocity
	
	# 5. Rotational Derivatives (Euler's equations)
	var Ixx = state.inertia_tensor.get("Ixx", 0.05)
	var Iyy = state.inertia_tensor.get("Iyy", 0.05)
	var Izz = state.inertia_tensor.get("Izz", 0.005)
	
	var w_x = state.angular_velocity.x
	var w_y = state.angular_velocity.y
	var w_z = state.angular_velocity.z
	
	var w_dot_x = 0.0
	var w_dot_y = 0.0
	var w_dot_z = 0.0
	
	if Ixx > 0 and Iyy > 0 and Izz > 0:
		w_dot_x = (torque_total_body.x - (Izz - Iyy) * w_y * w_z) / Ixx
		w_dot_y = (torque_total_body.y - (Ixx - Izz) * w_z * w_x) / Iyy
		w_dot_z = (torque_total_body.z - (Iyy - Ixx) * w_x * w_y) / Izz
		
	var w_dot = Vector3(w_dot_x, w_dot_y, w_dot_z)
	
	# 6. Quaternion Derivative (Exact derivative for intrinsic integration)
	# q_dot = 0.5 * q * w (where w is in body frame, represented as a pure quaternion)
	var q = state.orientation
	var w = state.angular_velocity
	var q_dot_w = 0.5 * (-q.x * w.x - q.y * w.y - q.z * w.z)
	var q_dot_x = 0.5 * ( q.w * w.x + q.y * w.z - q.z * w.y)
	var q_dot_y = 0.5 * ( q.w * w.y - q.x * w.z + q.z * w.x)
	var q_dot_z = 0.5 * ( q.w * w.z + q.x * w.y - q.y * w.x)
	var q_dot = Quaternion(q_dot_x, q_dot_y, q_dot_z, q_dot_w)
	
	return {
		"v_dot": v_dot,
		"p_dot": p_dot,
		"w_dot": w_dot,
		"q_dot": q_dot
	}
