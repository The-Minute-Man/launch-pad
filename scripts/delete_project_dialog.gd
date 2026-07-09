extends ColorRect

signal project_deleted

@onready var cancel_button: Button = %CancelButton
@onready var delete_button: Button = %DeleteButton

var target_file_path: String = ""

func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel)
	delete_button.pressed.connect(_on_delete)
	cancel_button.grab_focus()

func setup(file_path: String) -> void:
	target_file_path = file_path

func _on_cancel() -> void:
	queue_free()

func _on_delete() -> void:
	if target_file_path != "":
		ProjectManager.delete_project(target_file_path)
		project_deleted.emit()
	queue_free()
