class_name RK4Solver
extends RefCounted

# Steps the simulation forward by dt
static func step(state: FlightState, env_system: FlightEnvironment, dt: float, ref_area: float, ref_length: float, rocket_length: float, thrust: float) -> FlightState:
	
	# Helper function to add scaled derivatives to a state
	var add_derivatives = func(base_state: FlightState, derivs: Dictionary, scale: float) -> FlightState:
		var new_state = base_state.duplicate()
		new_state.time = base_state.time + dt * scale
		new_state.position += derivs["p_dot"] * scale
		new_state.velocity += derivs["v_dot"] * scale
		new_state.angular_velocity += derivs["w_dot"] * scale
		
		# Quaternion update
		var q_dot = derivs["q_dot"]
		new_state.orientation.x += q_dot.x * scale
		new_state.orientation.y += q_dot.y * scale
		new_state.orientation.z += q_dot.z * scale
		new_state.orientation.w += q_dot.w * scale
		new_state.orientation = new_state.orientation.normalized()
		return new_state

	# k1
	var k1 = RigidBodyPhysics.compute_derivatives(state, env_system, ref_area, ref_length, rocket_length, thrust)
	
	# k2
	var state_k2 = add_derivatives.call(state, k1, dt * 0.5)
	var k2 = RigidBodyPhysics.compute_derivatives(state_k2, env_system, ref_area, ref_length, rocket_length, thrust)
	
	# k3
	var state_k3 = add_derivatives.call(state, k2, dt * 0.5)
	var k3 = RigidBodyPhysics.compute_derivatives(state_k3, env_system, ref_area, ref_length, rocket_length, thrust)
	
	# k4
	var state_k4 = add_derivatives.call(state, k3, dt)
	var k4 = RigidBodyPhysics.compute_derivatives(state_k4, env_system, ref_area, ref_length, rocket_length, thrust)
	
	# Final State Assembly
	var next_state = state.duplicate()
	next_state.time = state.time + dt
	next_state.position += (dt / 6.0) * (k1["p_dot"] + 2.0 * k2["p_dot"] + 2.0 * k3["p_dot"] + k4["p_dot"])
	next_state.velocity += (dt / 6.0) * (k1["v_dot"] + 2.0 * k2["v_dot"] + 2.0 * k3["v_dot"] + k4["v_dot"])
	next_state.angular_velocity += (dt / 6.0) * (k1["w_dot"] + 2.0 * k2["w_dot"] + 2.0 * k3["w_dot"] + k4["w_dot"])
	
	# Specialized Quaternion Spherical Integration (as per docs: o_new = (cos(|w|*dt) + (w_hat)*sin(|w|*dt)) * o_old)
	# Alternatively, just average the q_dot derivatives for simplicity as a first pass, then normalize.
	var q_dot_avg_x = (k1["q_dot"].x + 2.0 * k2["q_dot"].x + 2.0 * k3["q_dot"].x + k4["q_dot"].x) / 6.0
	var q_dot_avg_y = (k1["q_dot"].y + 2.0 * k2["q_dot"].y + 2.0 * k3["q_dot"].y + k4["q_dot"].y) / 6.0
	var q_dot_avg_z = (k1["q_dot"].z + 2.0 * k2["q_dot"].z + 2.0 * k3["q_dot"].z + k4["q_dot"].z) / 6.0
	var q_dot_avg_w = (k1["q_dot"].w + 2.0 * k2["q_dot"].w + 2.0 * k3["q_dot"].w + k4["q_dot"].w) / 6.0
	
	next_state.orientation.x += q_dot_avg_x * dt
	next_state.orientation.y += q_dot_avg_y * dt
	next_state.orientation.z += q_dot_avg_z * dt
	next_state.orientation.w += q_dot_avg_w * dt
	next_state.orientation = next_state.orientation.normalized()
	
	return next_state
