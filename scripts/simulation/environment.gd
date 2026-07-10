class_name FlightEnvironment
extends RefCounted

const T0: float = 288.15        # Sea level temp (Kelvin)
const P0: float = 101325.0      # Sea level pressure (Pascals)
const L: float = 0.0065         # Lapse rate (K/m)
const M_AIR: float = 0.0289644  # Molar mass of air (kg/mol)
const R: float = 8.3144598      # Universal gas constant
const GAMMA: float = 1.4        # Ratio of specific heats
const G0: float = 9.80665       # Standard gravity (m/s^2)

# Wind simulation variables
var _wind_x_n1: float = 0.0
var _wind_x_n2: float = 0.0
var _wind_y_n1: float = 0.0
var _wind_y_n2: float = 0.0
var base_wind: Vector3 = Vector3(5.0, 0.0, 0.0) # Base wind in global frame (m/s)
var wind_std_dev: float = 1.0

# Pink noise filter coefficients (example values for 20Hz sampling)
var a1: float = -1.9
var a2: float = 0.9025

# Get atmospheric conditions at a given altitude
static func get_atmosphere(altitude: float) -> Dictionary:
	var h = max(0.0, altitude)
	# 1. Temperature drops linearly
	var temp = T0 - (L * h)
	
	# 2. Pressure drops exponentially (Hydrostatic equation)
	var pressure = P0 * pow(1.0 - (L * h) / T0, (G0 * M_AIR) / (R * L))
	
	# 3. Density (Ideal Gas Law)
	var density = (pressure * M_AIR) / (R * temp)
	
	# 4. Speed of Sound
	var speed_of_sound = sqrt(GAMMA * (R / M_AIR) * temp)
	
	return {
		"temperature": temp,
		"pressure": pressure,
		"density": density,
		"speed_of_sound": speed_of_sound
	}

# Get current wind vector including pink noise turbulence
func get_wind(time: float, altitude: float) -> Vector3:
	# Generate white noise
	var w_x = randfn(0.0, 1.0)
	var w_y = randfn(0.0, 1.0)
	
	# 2-pole IIR filter
	var x_n_x = w_x - a1 * _wind_x_n1 - a2 * _wind_x_n2
	_wind_x_n2 = _wind_x_n1
	_wind_x_n1 = x_n_x
	
	var x_n_y = w_y - a1 * _wind_y_n1 - a2 * _wind_y_n2
	_wind_y_n2 = _wind_y_n1
	_wind_y_n1 = x_n_y
	
	# Scale by 2.252 as per docs to normalize variance, then multiply by std dev
	var turb_x = (x_n_x / 2.252) * wind_std_dev
	var turb_y = (x_n_y / 2.252) * wind_std_dev
	
	return base_wind + Vector3(turb_x, turb_y, 0.0)
