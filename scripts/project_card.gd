extends PanelContainer
## A single project card in the grid. Displays name, date, description.

signal delete_requested(file_path: String)
signal card_clicked(file_path: String)

var _file_path: String = ""

@onready var name_label: Label = %NameLabel
@onready var date_label: Label = %DateLabel
@onready var desc_label: Label = %DescLabel
@onready var delete_btn: Button = %DeleteButton
@onready var motor_label: Label = %MotorLabel
@onready var altitude_label: Label = %AltitudeLabel

func setup(data: ProjectData) -> void:
	_file_path = data.file_path

	# Wait for nodes if not ready
	if not is_node_ready():
		await ready

	name_label.text = data.project_name
	desc_label.text = data.description if data.description != "" else "No description"
	motor_label.text = "Motor: " + data.motor_class
	altitude_label.text = "Alt: " + str(int(data.target_altitude)) + "m"

	# Format date nicely
	if data.modified_at != "":
		var parts := data.modified_at.split("T")
		date_label.text = parts[0] if parts.size() > 0 else data.modified_at
	else:
		date_label.text = "Just now"

func _ready() -> void:
	delete_btn.pressed.connect(_on_delete_pressed)
	gui_input.connect(_on_gui_input)

func _on_delete_pressed() -> void:
	delete_requested.emit(_file_path)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(_file_path)
