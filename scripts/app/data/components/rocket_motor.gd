class_name RocketMotor
extends RocketComponent

@export var manufacturer: String = ""
@export var diameter: float = 0.018 # 18mm standard
@export var length: float = 0.070 # 70mm standard
@export var propellant_mass: float = 0.0
@export var total_mass: float = 0.0

# The actual thrust curve. Time is X, Thrust (Newtons) is Y
var thrust_curve: Curve = Curve.new()
var burn_time: float = 0.0

func _init() -> void:
	component_name = "Rocket Motor"
	material_name = "Cardboard" # Casing

func _calculate_mass() -> float:
	# Total mass is the fully loaded mass (casing + propellant)
	return total_mass

func _calculate_local_cg() -> float:
	# Approximate CG of a motor is its exact center
	return length / 2.0

# Returns the exact thrust in Newtons at a given millisecond
func get_thrust_at_time(time: float) -> float:
	if time > burn_time or time < 0.0:
		return 0.0
	
	# Since Curve evaluates from 0.0 to 1.0 (X-axis), we normalize the time
	var normalized_time = time / burn_time
	return thrust_curve.sample(normalized_time)

# Calculates how much the motor weighs at this exact millisecond
func get_mass_at_time(time: float) -> float:
	if time >= burn_time:
		# Empty casing mass
		return total_mass - propellant_mass
	if time <= 0.0:
		return total_mass
		
	# Assume linear propellant burn for simplicity (or integrate the thrust curve)
	var burned_fraction = time / burn_time
	return total_mass - (propellant_mass * burned_fraction)

func get_local_Ixx(mass: float) -> float:
	var R = diameter / 2.0
	return mass * (pow(length, 2) / 12.0 + pow(R, 2) / 4.0)

func get_local_Izz(mass: float) -> float:
	var R = diameter / 2.0
	return mass * pow(R, 2) / 2.0
