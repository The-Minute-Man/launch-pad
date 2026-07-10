extends Node

func _ready() -> void:
	print("====================================")
	print("🚀 RUNNING PHYSICS ENGINE TEST 🚀")
	print("====================================")
	
	# This calls the run_simulation function we built
	var apogee = Simulator.run_simulation()
	
	print("====================================")
	print("✅ TEST FINISHED ✅")
	print("Highest point reached (Apogee): ", snapped(apogee, 0.1), " meters")
	print("====================================")
