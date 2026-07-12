extends Node3D

@export var min_zoom := 0.5
@export var max_zoom := 10.0
@export var zoom_speed := 0.2
@export var rotation_speed := 0.005
@export var pan_speed := 0.01

var zoom := 2.5
var dragging := false
var panning := false
var auto_rotate := true
var auto_rotate_speed := 0.5

@onready var camera = $Camera3D

func _ready() -> void:
	camera.position.z = zoom
	# Initial rotation to view rocket horizontally
	rotation.y = PI / 2.0
	rotation.x = -PI / 8.0

func _process(delta: float) -> void:
	if auto_rotate and not dragging and not panning:
		rotation.y += auto_rotate_speed * delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = max(min_zoom, zoom - zoom_speed)
			camera.position.z = zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = min(max_zoom, zoom + zoom_speed)
			camera.position.z = zoom
			
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				if Input.is_key_pressed(KEY_SHIFT):
					panning = true
				else:
					dragging = true
			else:
				dragging = false
				panning = false

	elif event is InputEventMouseMotion:
		if dragging:
			rotation.y -= event.relative.x * rotation_speed
			rotation.x -= event.relative.y * rotation_speed
			rotation.x = clamp(rotation.x, -PI/2.0, PI/2.0)
		elif panning:
			var right = global_transform.basis.x
			var up = global_transform.basis.y
			position -= right * event.relative.x * pan_speed
			position += up * event.relative.y * pan_speed
