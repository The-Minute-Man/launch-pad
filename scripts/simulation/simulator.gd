class_name Simulator
extends RefCounted

# Runs a full flight simulation and returns the max altitude (apogee)
static func run_simulation(sim_data: Dictionary) -> float:
	var env = FlightEnvironment.new()
	
	# Initial State Setup
	var state = FlightState.new()
	state.mass = sim_data["mass"]
	state.cg = sim_data["cg"]
	state.inertia_tensor = sim_data["inertia"].duplicate()
	
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
	var has_parachute = sim_data.get("has_parachute", false)
	var parachute_deployed = false
	
	print("--- Simulation Started ---")
	
	while state.position.y >= 0.0 and state.time < max_time:
		# Check for apogee (must be off the launch rod/ground to trigger)
		if state.velocity.y < 0.0 and state.position.y > launch_rod_length and not parachute_deployed and has_parachute:
			parachute_deployed = true
			sim_data["parachute_deployed"] = true
			print("Apogee reached! Deploying Parachute at ", snapped(state.time, 0.1), "s")
			
		var current_thrust = 0.0
		var motor_burn_time = 0.0
		if motor != null:
			motor_burn_time = motor.length
			current_thrust = motor.get_thrust_at_time(state.time)
			state.mass = sim_data["mass"] - (motor.total_mass - motor.get_mass_at_time(state.time))
			
			var burn_ratio = 0.0
			var b_time = motor.burn_time
			if b_time > 0.0:
				burn_ratio = clamp(state.time / b_time, 0.0, 1.0)
			
			state.cg = sim_data["cg"] - (motor.propellant_mass * burn_ratio * 0.1)
			state.inertia_tensor["Ixx"] = sim_data["inertia"]["Ixx"] * (1.0 - 0.1 * burn_ratio)
			state.inertia_tensor["Iyy"] = sim_data["inertia"]["Iyy"] * (1.0 - 0.1 * burn_ratio)
			
		# Step RK4
		state = RK4Solver.step(state, env, dt, ref_area, ref_length, rocket_length, current_thrust, sim_data)
		
		# Enforce Constraints: Launch Rod
		if state.position.length() < launch_rod_length:
			state.angular_velocity = Vector3.ZERO
			# Force orientation to be straight up (Identity handles this mostly if we start straight)
			state.velocity.x = 0
			state.velocity.z = 0
			
		# Enforce Constraints: Launch Pad (Cannot fall through the earth before liftoff)
		if state.position.y < 0.0 and state.time <= motor_burn_time + 1.0:
			state.position.y = 0.0
			if state.velocity.y < 0.0:
				state.velocity.y = 0.0
		
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
