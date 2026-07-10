class_name RocketComponent
extends Resource

@export var component_name: String = "Component"
@export var material_name: String = "Cardboard"

# The calculated absolute distance from the tip of the rocket to the tip of this component
@export var global_position: float = 0.0 

# User-defined offset relative to its auto-stacked position (e.g. sliding fins up a body tube)
@export var relative_offset: float = 0.0

# Optional user overrides
@export var mass_override: float = -1.0
@export var cg_override: float = -1.0

# --- Virtual Methods to be overridden by subclasses ---

func _calculate_mass() -> float:
	return 0.0

func _calculate_local_cg() -> float:
	return 0.0

# --- Public Getters ---

func get_mass() -> float:
	if mass_override >= 0.0:
		return mass_override
	return _calculate_mass()

func get_local_cg() -> float:
	if cg_override >= 0.0:
		return cg_override
	return _calculate_local_cg()

# Returns the global CG relative to the tip of the rocket
func get_global_cg() -> float:
	return global_position + get_local_cg()

func get_surface_roughness() -> float:
	return MaterialDB.get_roughness(material_name)
