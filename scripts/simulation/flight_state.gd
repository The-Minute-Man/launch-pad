class_name FlightState
extends RefCounted

var time: float = 0.0
var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var orientation: Quaternion = Quaternion.IDENTITY
var angular_velocity: Vector3 = Vector3.ZERO

# Mass Properties (these can change during flight due to motor burn)
var mass: float = 0.0
var cg: float = 0.0
var inertia_tensor: Dictionary = { "Ixx": 0.05, "Iyy": 0.05, "Izz": 0.005 }

func _init(t: float = 0.0, pos: Vector3 = Vector3.ZERO, vel: Vector3 = Vector3.ZERO, ori: Quaternion = Quaternion.IDENTITY, ang_vel: Vector3 = Vector3.ZERO) -> void:
	time = t
	position = pos
	velocity = vel
	orientation = ori
	angular_velocity = ang_vel

func duplicate() -> FlightState:
	var copy = FlightState.new(time, position, velocity, orientation, angular_velocity)
	copy.mass = mass
	copy.cg = cg
	copy.inertia_tensor = inertia_tensor.duplicate()
	return copy
