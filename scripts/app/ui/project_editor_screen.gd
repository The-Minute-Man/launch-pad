extends Control

var current_project_path: String = ""

@onready var top_bar: PanelContainer = $VBoxLayout/TopBar

func setup(file_path: String) -> void:
	current_project_path = file_path
	
	if not is_node_ready():
		await ready
		
	var data := ProjectManager.load_project(file_path)
	if data:
		top_bar.set_project_title(data.project_name)
	else:
		top_bar.set_project_title("Error Loading Project")

func _ready() -> void:
	$VBoxLayout/HBoxLayout/SideBar.set_mode("editor")
