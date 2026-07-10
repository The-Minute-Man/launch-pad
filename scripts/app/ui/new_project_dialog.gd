extends ColorRect

signal project_created

@onready var name_input: LineEdit = %NameInput
@onready var desc_input: LineEdit = %DescInput
@onready var cancel_button: Button = %CancelButton
@onready var create_button: Button = %CreateButton
func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel)
	create_button.pressed.connect(_on_create)
	name_input.text = ""
	desc_input.text = ""
	name_input.grab_focus()

func _on_cancel() -> void:
	queue_free()

func _on_create() -> void:
	var pname := name_input.text.strip_edges()
	if pname == "":
		pname = "Untitled Project"
	ProjectManager.create_project(pname, desc_input.text.strip_edges())
	project_created.emit()
	queue_free()
