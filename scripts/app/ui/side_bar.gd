extends PanelContainer

@onready var home_tools: VBoxContainer = %HomeTools
@onready var editor_tools: VBoxContainer = %EditorTools

func set_mode(mode: String) -> void:
	if not is_node_ready():
		await ready
		
	if mode == "home":
		home_tools.visible = true
		editor_tools.visible = false
	elif mode == "editor":
		home_tools.visible = false
		editor_tools.visible = true
