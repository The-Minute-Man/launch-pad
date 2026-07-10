class_name FinSet
extends RocketComponent

@export var fin_count: int = 3
@export var root_chord: float = 0.05
@export var tip_chord: float = 0.02
@export var span: float = 0.04
@export var sweep_length: float = 0.03
@export var thickness: float = 0.003

func _init() -> void:
	component_name = "Fin Set"
	material_name = "Plywood"

func _calculate_mass() -> float:
	# Area of a trapezoid
	var area = ((root_chord + tip_chord) / 2.0) * span
	var volume = area * thickness * float(fin_count)
	
	var density = MaterialDB.get_density(material_name)
	return volume * density

func _calculate_local_cg() -> float:
	# Simplified CG for a trapezoidal fin
	# Center of area of a trapezoid along the chord axis
	# Formula: (root_chord^2 + root_chord*tip_chord + tip_chord^2 + sweep*(root_chord + 2*tip_chord)) / (3 * (root_chord + tip_chord))
	var rc = root_chord
	var tc = tip_chord
	var s = sweep_length
	
	if (rc + tc) == 0.0: return 0.0
	
	var cg_x = (pow(rc, 2) + rc*tc + pow(tc, 2) + s*(rc + 2.0*tc)) / (3.0 * (rc + tc))
	return cg_x

# Barrowman Normal Force Coefficient (C_N_alpha) for this fin set
func get_cn_alpha(body_radius: float) -> float:
	if root_chord == 0 or span == 0: return 0.0
	
	var k_fb = 1.0 + (body_radius / (span + body_radius))
	var s = span
	var cr = root_chord
	var ct = tip_chord
	var l_r = sweep_length # length from root leading edge to tip leading edge
	var l_m = l_r + (ct / 2.0) - (cr / 2.0) # Mid-chord sweep
	
	# Barrowman C_N_a formula
	var term1 = (4.0 * float(fin_count) * pow(s / body_radius, 2))
	var term2 = 1.0 + sqrt(1.0 + pow(2.0 * l_m / (cr + ct), 2))
	
	return k_fb * (term1 / term2)

# Barrowman Center of Pressure for this fin set
func get_aerodynamic_cp() -> float:
	var cr = root_chord
	var ct = tip_chord
	var s = sweep_length
	
	if (cr + ct) == 0.0: return 0.0
	
	# X_f = distance from fin root leading edge
	var x_f = s / 3.0 * ((cr + 2.0 * ct) / (cr + ct)) + (1.0 / 6.0) * ((cr + ct) - (cr * ct) / (cr + ct))
	return x_f
