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
	var T = T0
	var p = P0
	var rho = 1.225
	
	if altitude < 11000.0:
		T = T0 - L * altitude
		p = P0 * pow(1.0 - (L * altitude) / T0, (G0 * M_AIR) / (R * L))
		rho = (p * M_AIR) / (R * T)
	else:
		T = 216.65 # Temp at 11km Tropopause
		var p11 = 22632.1 # Pressure at 11km
		p = p11 * exp((-G0 * M_AIR * (altitude - 11000.0)) / (R * T))
		rho = (p * M_AIR) / (R * T)
	
	var a = sqrt(GAMMA * (R / M_AIR) * T) # Speed of sound
	
	return {
		"temperature": T,
		"pressure": p,
		"density": rho,
		"speed_of_sound": a
	}

# Get current wind vector including pink noise turbulence
func get_wind(_time: float, _altitude: float) -> Vector3:
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
