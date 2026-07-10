class_name MotorParser
extends RefCounted

# Parses an .eng file and returns a RocketMotor object
static func parse_eng_file(file_path: String) -> RocketMotor:
	if not FileAccess.file_exists(file_path):
		printerr("Motor file not found: ", file_path)
		return null
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var motor = RocketMotor.new()
	var is_header_parsed = false
	var raw_data_points: Array[Vector2] = []
	var max_thrust = 0.0
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		
		if line.is_empty() or line.begins_with(";"):
			continue # Skip comments and empty lines
			
		var tokens = line.split(" ", false) # false drops empty tokens caused by multiple spaces
		
		# The first valid line is always the header
		if not is_header_parsed:
			if tokens.size() >= 6:
				motor.component_name = tokens[0]
				motor.diameter = float(tokens[1]) / 1000.0 # Convert mm to meters
				motor.length = float(tokens[2]) / 1000.0 # Convert mm to meters
				# tokens[3] is delays (e.g. 0,3,5,7)
				motor.propellant_mass = float(tokens[4])
				motor.total_mass = float(tokens[5])
				if tokens.size() >= 7:
					motor.manufacturer = tokens[6]
			is_header_parsed = true
		else:
			# Parse thrust data points
			if tokens.size() >= 2:
				var time = float(tokens[0])
				var thrust = float(tokens[1])
				raw_data_points.append(Vector2(time, thrust))
				if thrust > max_thrust:
					max_thrust = thrust
				if time > motor.burn_time:
					motor.burn_time = time
					
	file.close()
	
	# Build the Godot Curve
	motor.thrust_curve = Curve.new()
	# Optional: Set max Y so the curve editor inside Godot knows the bounds, though evaluate returns true Y
	motor.thrust_curve.min_value = 0.0
	motor.thrust_curve.max_value = max(max_thrust, 1.0)
	
	for point in raw_data_points:
		# Curve X must be 0.0 to 1.0
		var normalized_time = 0.0
		if motor.burn_time > 0:
			normalized_time = point.x / motor.burn_time
			
		motor.thrust_curve.add_point(Vector2(normalized_time, point.y))
		
	return motor
