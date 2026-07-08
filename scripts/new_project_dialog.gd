extends ConfirmationDialog

signal project_created

@onready var name_input: LineEdit = %NameInput
@onready var desc_input: LineEdit = %DescInput

func _on_about_to_popup() -> void:
	name_input.text = ""
	desc_input.text = ""
	name_input.grab_focus()

func _on_confirmed() -> void:
	var pname := name_input.text.strip_edges()
	if pname == "":
		pname = "Untitled Project"
	ProjectManager.create_project(pname, desc_input.text.strip_edges())
	project_created.emit()
