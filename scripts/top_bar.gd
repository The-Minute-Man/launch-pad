extends PanelContainer
## Reusable TopBar with Logo and MenuBar.

signal new_project_requested

@onready var file_menu: PopupMenu = $VBox/HBox/MenuBar/File
@onready var project_title: Label = %ProjectTitle

func set_project_title(title: String) -> void:
	if is_node_ready():
		project_title.text = title
	else:
		await ready
		project_title.text = title

func _ready() -> void:
	# Ensure signals are connected to this script
	if has_node("VBox/HBox/MenuBar/File"):
		$"VBox/HBox/MenuBar/File".id_pressed.connect(_on_file_id_pressed)
	if has_node("VBox/HBox/MenuBar/Edit"):
		$"VBox/HBox/MenuBar/Edit".id_pressed.connect(_on_edit_id_pressed)
	if has_node("VBox/HBox/MenuBar/View"):
		$"VBox/HBox/MenuBar/View".id_pressed.connect(_on_view_id_pressed)
	if has_node("VBox/HBox/MenuBar/Help"):
		$"VBox/HBox/MenuBar/Help".id_pressed.connect(_on_help_id_pressed)

func _on_home_button_pressed() -> void:
	if get_tree().current_scene.scene_file_path != "res://scenes/project_screen.tscn":
		get_tree().change_scene_to_file("res://scenes/project_screen.tscn")

func _on_file_id_pressed(id: int) -> void:
	match id:
		0:  # New Project
			new_project_requested.emit()
		10: # Open Project...
			pass
		11: # Save Project
			pass
		12: # Save Project As...
			pass
		1:  # Open Project Folder
			if ProjectManager.has_method("get_projects_dir"):
				OS.shell_open(ProjectSettings.globalize_path(ProjectManager.PROJECTS_DIR))
			else:
				OS.shell_open(ProjectSettings.globalize_path("user://projects/"))
		13: # Export Design...
			pass
		3:  # Exit
			get_tree().quit()

func _on_edit_id_pressed(id: int) -> void:
	match id:
		10: # Undo
			pass
		11: # Redo
			pass
		13: # Cut
			pass
		14: # Copy
			pass
		15: # Paste
			pass
		16: # Delete
			pass
		18: # Project Settings...
			pass
		0:  # Preferences
			pass  # TODO: Preferences dialog

func _on_view_id_pressed(id: int) -> void:
	match id:
		10: # Toggle Sidebar
			pass
		11: # Toggle 3D Preview Grid
			pass
		12: # Zoom In
			pass
		13: # Zoom Out
			pass
		0:  # Reset Layout
			pass

func _on_help_id_pressed(id: int) -> void:
	match id:
		0:  # Documentation
			pass
		10: # Getting Started Tutorial
			pass
		11: # Physics Reference
			pass
		12: # Report a Bug
			pass
		14: # Check for Updates...
			pass
		1:  # About LaunchPad
			pass
