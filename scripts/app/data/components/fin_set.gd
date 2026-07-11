class_name FinSet
extends RocketComponent

enum Shape { TRAPEZOIDAL, ELLIPTICAL }

@export var fin_count: int = 3
@export var shape_type: Shape = Shape.TRAPEZOIDAL
@export var root_chord: float = 0.05
@export var tip_chord: float = 0.02
@export var span: float = 0.04
@export var sweep_length: float = 0.03
@export var thickness: float = 0.003
@export var fin_cant_angle: float = 0.0 # Angle in degrees to spin the rocket

func _init() -> void:
	component_name = "Fin Set"
	material_name = "Plywood"

func _calculate_mass() -> float:
	var area = 0.0
	if shape_type == Shape.TRAPEZOIDAL:
		area = ((root_chord + tip_chord) / 2.0) * span
	else:
		area = (PI / 4.0) * root_chord * span
		
	var volume = area * thickness * float(fin_count)
	var density = MaterialDB.get_density(material_name)
	return volume * density

func _calculate_local_cg() -> float:
	if shape_type == Shape.TRAPEZOIDAL:
		var rc = root_chord
		var tc = tip_chord
		var s = sweep_length
		if (rc + tc) == 0.0: return 0.0
		return (pow(rc, 2) + rc*tc + pow(tc, 2) + s*(rc + 2.0*tc)) / (3.0 * (rc + tc))
	else:
		return root_chord / 2.0

# Barrowman Normal Force Coefficient (C_N_alpha) for this fin set
func get_cn_alpha(body_radius: float) -> float:
	if root_chord == 0 or span == 0: return 0.0
	
	var k_fb = 1.0 + (body_radius / (span + body_radius))
	var s = span
	var d_ref = body_radius * 2.0
	
	# OpenRocket Interference Penalty for N >= 5
	var interference = [1.0, 1.0, 1.0, 1.0, 1.0, 0.948, 0.892, 0.846, 0.810]
	var idx = int(min(fin_count, 8))
	var int_factor = interference[idx]
	
	if shape_type == Shape.TRAPEZOIDAL:
		var cr = root_chord
		var ct = tip_chord
		var l_r = sweep_length
		var l_m = l_r + (ct / 2.0) - (cr / 2.0)
		
		# FIX: Use d_ref (diameter), not body_radius, resolving 4x overscaling error
		var term1 = (4.0 * float(fin_count) * pow(s / d_ref, 2)) * int_factor
		var term2 = 1.0 + sqrt(1.0 + pow(2.0 * l_m / (cr + ct), 2))
		return k_fb * (term1 / term2)
	else:
		var term1 = (4.0 * float(fin_count) * pow(s / d_ref, 2)) * int_factor
		var term2 = 2.0 # l_m = 0 for pure ellipse
		return k_fb * (term1 / term2)

# Barrowman Center of Pressure for this fin set
func get_aerodynamic_cp() -> float:
	if shape_type == Shape.TRAPEZOIDAL:
		var cr = root_chord
		var ct = tip_chord
		var s = sweep_length
		if (cr + ct) == 0.0: return 0.0
		# X_f = distance from fin root leading edge
		return s / 3.0 * ((cr + 2.0 * ct) / (cr + ct)) + (1.0 / 6.0) * ((cr + ct) - (cr * ct) / (cr + ct))
	else:
		# Barrowman approximation for Elliptical Fin CP
		return 0.288 * root_chord

func get_local_Ixx(mass: float) -> float:
	return (1.0/12.0) * mass * pow(root_chord, 2) + 0.5 * mass * pow(span / 2.0, 2)

func get_local_Izz(mass: float) -> float:
	return mass * pow(span / 2.0, 2)
