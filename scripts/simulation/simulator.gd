class_name Simulator
extends RefCounted

# Runs a full flight simulation and returns the max altitude (apogee)
static func run_simulation(sim_data: Dictionary) -> float:
	var env = FlightEnvironment.new()
	
	# Initial State Setup
	var state = FlightState.new()
	state.mass = sim_data["mass"]
	state.cg = sim_data["cg"]
	state.inertia_longitudinal = sim_data["inertia_longitudinal"]
	state.inertia_rotational = sim_data["inertia_rotational"]
	
	# Rocket geometry assumptions
	var ref_area = sim_data["ref_area"]
	var ref_length = sim_data["ref_length"]
	var rocket_length = sim_data["rocket_length"]
	
	# Point the rocket Straight UP!
	# In OpenRocket body frame, nose is +Z. In Godot global frame, Up is +Y.
	# We rotate -90 degrees around the X axis to point the nose to the sky.
	state.orientation = Quaternion(Vector3(1, 0, 0), -PI / 2.0)
	
	var dt = 0.01 # 100hz simulation rate
	var max_time = 120.0
	var apogee = 0.0
	var launch_rod_length = 2.0
	
	var motor: RocketMotor = sim_data.get("motor", null)
	
	print("--- Simulation Started ---")
	
	while state.position.y >= 0.0 and state.time < max_time:
		var current_thrust = 0.0
		var motor_burn_time = 0.0
		if motor != null:
			current_thrust = motor.get_thrust_at_time(state.time)
			motor_burn_time = motor.burn_time
			# Dynamically update the rocket mass as propellant burns!
			state.mass = (sim_data["mass"] - motor.total_mass) + motor.get_mass_at_time(state.time)
			
		# Step RK4
		state = RK4Solver.step(state, env, dt, ref_area, ref_length, rocket_length, current_thrust)
		
		# Enforce Constraints: Launch Rod
		if state.position.length() < launch_rod_length:
			state.angular_velocity = Vector3.ZERO
			# Force orientation to be straight up (Identity handles this mostly if we start straight)
			state.velocity.x = 0
			state.velocity.z = 0
		
		# Track Apogee
		if state.position.y > apogee:
			apogee = state.position.y
			
		# Break if we hit ground (already handled by while loop condition, but just in case we fall fast)
		if state.time > motor_burn_time and state.position.y < 0.0:
			break
			
	print("--- Simulation Complete ---")
	print("Apogee Reached: ", apogee, " meters")
	print("Flight Time: ", state.time, " seconds")
	
	return apogee
