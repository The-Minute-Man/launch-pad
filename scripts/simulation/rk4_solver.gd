class_name RK4Solver
extends RefCounted

# Steps the simulation forward by dt
static func step(state: FlightState, env_system: FlightEnvironment, dt: float, ref_area: float, ref_length: float, rocket_length: float, thrust: float, sim_data: Dictionary) -> FlightState:
	
	# Helper function to add scaled derivatives to a state
	var add_derivatives = func(base_state: FlightState, derivs: Dictionary, scale: float) -> FlightState:
		var new_state = base_state.duplicate()
		new_state.time = base_state.time + scale
		new_state.position = base_state.position + derivs["p_dot"] * scale
		new_state.velocity = base_state.velocity + derivs["v_dot"] * scale
		new_state.angular_velocity = base_state.angular_velocity + derivs["w_dot"] * scale
		
		# Update orientation implicitly using the exact derivative
		new_state.orientation = Quaternion(
			base_state.orientation.x + derivs["q_dot"].x * scale,
			base_state.orientation.y + derivs["q_dot"].y * scale,
			base_state.orientation.z + derivs["q_dot"].z * scale,
			base_state.orientation.w + derivs["q_dot"].w * scale
		).normalized()
			
		return new_state

	# k1
	var k1 = RigidBodyPhysics.compute_derivatives(state, env_system, ref_area, ref_length, rocket_length, thrust, sim_data)
	
	# k2
	var state_k2 = add_derivatives.call(state, k1, dt * 0.5)
	var k2 = RigidBodyPhysics.compute_derivatives(state_k2, env_system, ref_area, ref_length, rocket_length, thrust, sim_data)
	
	# k3
	var state_k3 = add_derivatives.call(state, k2, dt * 0.5)
	var k3 = RigidBodyPhysics.compute_derivatives(state_k3, env_system, ref_area, ref_length, rocket_length, thrust, sim_data)
	
	# k4
	var state_k4 = add_derivatives.call(state, k3, dt)
	var k4 = RigidBodyPhysics.compute_derivatives(state_k4, env_system, ref_area, ref_length, rocket_length, thrust, sim_data)
	
	# Final State Assembly (including proper quaternion assembly)
	var next_state = state.duplicate()
	next_state.time = state.time + dt
	next_state.position += (dt / 6.0) * (k1["p_dot"] + 2.0 * k2["p_dot"] + 2.0 * k3["p_dot"] + k4["p_dot"])
	next_state.velocity += (dt / 6.0) * (k1["v_dot"] + 2.0 * k2["v_dot"] + 2.0 * k3["v_dot"] + k4["v_dot"])
	next_state.angular_velocity += (dt / 6.0) * (k1["w_dot"] + 2.0 * k2["w_dot"] + 2.0 * k3["w_dot"] + k4["w_dot"])
	
	next_state.orientation = Quaternion(
		state.orientation.x + (dt / 6.0) * (k1["q_dot"].x + 2.0 * k2["q_dot"].x + 2.0 * k3["q_dot"].x + k4["q_dot"].x),
		state.orientation.y + (dt / 6.0) * (k1["q_dot"].y + 2.0 * k2["q_dot"].y + 2.0 * k3["q_dot"].y + k4["q_dot"].y),
		state.orientation.z + (dt / 6.0) * (k1["q_dot"].z + 2.0 * k2["q_dot"].z + 2.0 * k3["q_dot"].z + k4["q_dot"].z),
		state.orientation.w + (dt / 6.0) * (k1["q_dot"].w + 2.0 * k2["q_dot"].w + 2.0 * k3["q_dot"].w + k4["q_dot"].w)
	).normalized()
	
	return next_state
