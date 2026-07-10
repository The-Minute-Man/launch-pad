extends SceneTree

func _init():
	print("Running Physics Test...")
	var apogee = Simulator.run_simulation()
	print("Test Finished. Final Apogee: ", apogee)
	quit()
