class_name ProjectData
extends Resource
## Data model for a LaunchPad project (.lpad file).
## Stores constraints, GA results, and metadata.

# ── Metadata ──
@export var project_name: String = "Untitled Project"
@export var description: String = ""
@export var created_at: String = ""
@export var modified_at: String = ""
@export var file_path: String = ""

# ── Constraints (user inputs) ──
@export var target_altitude: float = 0.0       # meters
@export var max_diameter: float = 0.1              # meters
@export var motor_class: String = ""
@export var stability_margin: float = 1.5          # calibers

# ── GA Results (populated after optimization) ──
@export var generation_count: int = 0
@export var population_size: int = 100
@export var top_candidates: Array = []             # Array of Dictionaries

## Convert this resource to a dictionary for JSON serialization.
func to_dict() -> Dictionary:
	return {
		"project_name": project_name,
		"description": description,
		"created_at": created_at,
		"modified_at": modified_at,
		"target_altitude": target_altitude,
		"max_diameter": max_diameter,
		"motor_class": motor_class,
		"stability_margin": stability_margin,
		"generation_count": generation_count,
		"population_size": population_size,
		"top_candidates": top_candidates,
	}

## Populate this resource from a dictionary (loaded from JSON).
func from_dict(data: Dictionary) -> void:
	project_name = data.get("project_name", "Untitled Project")
	description = data.get("description", "")
	created_at = data.get("created_at", "")
	modified_at = data.get("modified_at", "")
	target_altitude = data.get("target_altitude", 0.0)
	max_diameter = data.get("max_diameter", 0.1)
	motor_class = data.get("motor_class", "")
	stability_margin = data.get("stability_margin", 1.5)
	generation_count = data.get("generation_count", 0)
	population_size = data.get("population_size", 100)
	top_candidates = data.get("top_candidates", [])
