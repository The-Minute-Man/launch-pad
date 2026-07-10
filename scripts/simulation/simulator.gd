class_name Simulator
extends RefCounted

# Runs a full flight simulation and returns the max altitude (apogee)
static func run_simulation() -> float:
	var env = FlightEnvironment.new()
	
	# Initial State Setup
	var state = FlightState.new()
	state.mass = 0.5 # 500g rocket
	state.cg = 0.5   # CG is 50cm from nose
	state.inertia_longitudinal = 0.05
	state.inertia_rotational = 0.005
	
	# Rocket geometry assumptions
	var ref_area = PI * pow(0.02, 2) # 4cm diameter
	var ref_length = 0.04
	var rocket_length = 1.0
	
	# Point the rocket Straight UP!
	# In OpenRocket body frame, nose is +Z. In Godot global frame, Up is +Y.
	# We rotate -90 degrees around the X axis to point the nose to the sky.
	state.orientation = Quaternion(Vector3(1, 0, 0), -PI / 2.0)
	
	var dt = 0.01 # 100hz simulation rate
	var max_time = 120.0
	var apogee = 0.0
	var launch_rod_length = 2.0
	
	# Thrust profile (Dummy motor: 20N for 2 seconds)
	var motor_burn_time = 2.0
	var motor_thrust = 20.0
	
	print("--- Simulation Started ---")
	
	while state.position.y >= 0.0 and state.time < max_time:
		var current_thrust = 0.0
		if state.time < motor_burn_time:
			current_thrust = motor_thrust
			
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
