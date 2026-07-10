class_name RigidBodyPhysics
extends RefCounted

# Computes the state derivatives [v_dot, p_dot, w_dot, q_dot]
static func compute_derivatives(state: FlightState, env_system: FlightEnvironment, ref_area: float, ref_length: float, rocket_length: float, thrust: float) -> Dictionary:
	# 1. Environment & Wind
	var env_data = env_system.get_atmosphere(state.position.y) # Z is up in OpenRocket, but Godot uses Y up. Let's assume Y is up.
	var wind_global = env_system.get_wind(state.time, state.position.y)
	
	# Relative Wind in Global Frame
	var v_rel_global = wind_global - state.velocity
	
	# Rotate to Body Frame
	var v_rel_body = state.orientation.inverse() * v_rel_global
	
	# 2. Aerodynamics
	var aero = Aerodynamics.compute_aero_forces(state, env_data, v_rel_body, ref_area, ref_length, rocket_length)
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
	var gravity_force = Vector3(0, -9.81 * state.mass, 0)
	total_force_global += gravity_force
	
	# 4. Translational Derivatives
	var v_dot = total_force_global / state.mass
	var p_dot = state.velocity
	
	# 5. Rotational Derivatives (Euler's equations)
	var i_L = state.inertia_longitudinal
	var i_R = state.inertia_rotational
	
	var w_x = state.angular_velocity.x
	var w_y = state.angular_velocity.y
	var w_z = state.angular_velocity.z
	
	var w_dot_x = 0.0
	var w_dot_y = 0.0
	var w_dot_z = 0.0
	
	if i_L > 0 and i_R > 0:
		w_dot_x = (torque_total_body.x - (i_R - i_L) * w_y * w_z) / i_L
		w_dot_y = (torque_total_body.y - (i_L - i_R) * w_z * w_x) / i_L
		w_dot_z = torque_total_body.z / i_R
		
	var w_dot = Vector3(w_dot_x, w_dot_y, w_dot_z)
	
	# 6. Quaternion Derivative
	# q_dot = 0.5 * q * w (treating w as a quaternion with real part 0)
	var w_quat = Quaternion(w_x, w_y, w_z, 0.0)
	# Godot Quaternion doesn't directly support multiplying two quaternions like this out of the box in GDScript easily without writing the components.
	# Actually, q1 * q2 is supported. Let's do it manually just in case.
	var q = state.orientation
	var q_dot_x = 0.5 * (q.w * w_x + q.y * w_z - q.z * w_y)
	var q_dot_y = 0.5 * (q.w * w_y + q.z * w_x - q.x * w_z)
	var q_dot_z = 0.5 * (q.w * w_z + q.x * w_y - q.y * w_x)
	var q_dot_w = 0.5 * (-q.x * w_x - q.y * w_y - q.z * w_z)
	
	var q_dot = Quaternion(q_dot_x, q_dot_y, q_dot_z, q_dot_w)
	
	return {
		"v_dot": v_dot,
		"p_dot": p_dot,
		"w_dot": w_dot,
		"q_dot": q_dot
	}
