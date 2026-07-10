extends Node

func _ready() -> void:
	print("====================================")
	print("🛠️ BUILDING THEORETICAL ROCKET 🛠️")
	print("====================================")
	
	var rocket = RocketDesign.new()
	
	# 1. Nose Cone
	var nose = NoseCone.new()
	nose.length = 0.15
	nose.base_diameter = 0.04
	nose.wall_thickness = 0.002
	nose.position_offset = 0.0
	nose.material_name = "Plastic (Polystyrene)"
	rocket.add_component(nose)
	
	# 2. Body Tube
	var body = BodyTube.new()
	body.length = 0.5
	body.outer_diameter = 0.04
	body.inner_diameter = 0.038
	body.position_offset = 0.15 # Starts right after the nose cone
	body.material_name = "Cardboard"
	rocket.add_component(body)
	
	# 3. Fin Set
	var fins = FinSet.new()
	fins.fin_count = 3
	fins.root_chord = 0.05
	fins.tip_chord = 0.02
	fins.span = 0.04
	fins.thickness = 0.003
	fins.position_offset = 0.6 # Attached near the bottom
	fins.material_name = "Plywood"
	rocket.add_component(fins)
	
	# 4. The Real Motor! (Estes C6)
	var motor_path = "res://scripts/app/data/databases/parts/motors/C6_5f4294d20002e900000004e7.eng"
	var motor = MotorParser.parse_eng_file(motor_path)
	if motor != null:
		motor.position_offset = 0.65 - motor.length # Put motor at the very bottom
		rocket.add_component(motor)
		print("Loaded Motor: ", motor.component_name, " by ", motor.manufacturer)
	
	# Output the calculated stats
	var sim_data = rocket.export_to_simulator()
	print("Total Mass: ", snapped(sim_data["mass"] * 1000.0, 0.1), " grams")
	print("Center of Gravity: ", snapped(sim_data["cg"], 0.001), " meters from tip")
	print("Max Diameter: ", sim_data["ref_length"], " meters")
	print("Total Length: ", sim_data["rocket_length"], " meters")
	
	print("\n====================================")
	print("🚀 RUNNING PHYSICS ENGINE TEST 🚀")
	print("====================================")
	
	# This calls the run_simulation function we built
	# Note: We now pass the dynamically calculated sim_data directly into the engine!
	var apogee = Simulator.run_simulation(sim_data)
	
	print("====================================")
	print("✅ TEST FINISHED ✅")
	print("Highest point reached (Apogee): ", snapped(apogee, 0.1), " meters")
	print("====================================")

