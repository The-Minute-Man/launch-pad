extends PanelContainer
## Reusable TopBar with Logo and MenuBar.

signal new_project_requested

func _ready() -> void:
	# Ensure signals are connected to this script
	if has_node("VBox/HBox/MenuBar/File"):
		$"VBox/HBox/MenuBar/File".id_pressed.connect(_on_file_id_pressed)
	if has_node("VBox/HBox/MenuBar/Edit"):
		$"VBox/HBox/MenuBar/Edit".id_pressed.connect(_on_edit_id_pressed)
	if has_node("VBox/HBox/MenuBar/Help"):
		$"VBox/HBox/MenuBar/Help".id_pressed.connect(_on_help_id_pressed)

func _on_home_button_pressed() -> void:
	if get_tree().current_scene.scene_file_path != "res://scenes/ProjectScreen.tscn":
		get_tree().change_scene_to_file("res://scenes/ProjectScreen.tscn")

func _on_file_id_pressed(id: int) -> void:
	match id:
		0:  # New Project
			new_project_requested.emit()
		1:  # Open Project Folder
			if ProjectManager.has_method("get_projects_dir"):
				OS.shell_open(ProjectSettings.globalize_path(ProjectManager.PROJECTS_DIR))
			else:
				OS.shell_open(ProjectSettings.globalize_path("user://projects/"))
		3:  # Exit
			get_tree().quit()

func _on_edit_id_pressed(id: int) -> void:
	match id:
		0:  # Preferences
			pass  # TODO: Preferences dialog

func _on_help_id_pressed(id: int) -> void:
	match id:
		0:  # Documentation
			pass
		1:  # About LaunchPad
			pass
