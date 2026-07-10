class_name MaterialDB
extends RefCounted

# Pre-defined materials with their densities (kg/m^3) and surface roughness (m)
static var materials: Dictionary = {
	"Cardboard": {
		"density": 680.0,
		"roughness": 50e-6
	},
	"Plywood": {
		"density": 600.0,
		"roughness": 100e-6
	},
	"Balsa": {
		"density": 160.0,
		"roughness": 100e-6
	},
	"PLA (3D Printed)": {
		"density": 1250.0,
		"roughness": 60e-6
	},
	"PETG (3D Printed)": {
		"density": 1270.0,
		"roughness": 60e-6
	},
	"Fiberglass": {
		"density": 1850.0,
		"roughness": 20e-6
	},
	"Carbon Fiber": {
		"density": 1550.0,
		"roughness": 15e-6
	},
	"Plastic (Polystyrene)": {
		"density": 1040.0,
		"roughness": 10e-6
	},
	"Aluminum": {
		"density": 2700.0,
		"roughness": 5e-6
	}
}

static func get_density(material_name: String) -> float:
	if materials.has(material_name):
		return materials[material_name]["density"]
	return 1000.0 # Default fallback

static func get_roughness(material_name: String) -> float:
	if materials.has(material_name):
		return materials[material_name]["roughness"]
	return 50e-6 # Default fallback
