extends PanelContainer

@onready var home_tools: VBoxContainer = %HomeTools
@onready var editor_tools: VBoxContainer = %EditorTools
@onready var rocket_components_tools: VBoxContainer = %RocketComponentsTools
@onready var sub_components_tools: VBoxContainer = %SubComponentsTools
@onready var sub_items: VBoxContainer = %Items

@onready var components_btn: Button = editor_tools.get_node("ComponentsBtn")

@onready var components_back_btn: Button = rocket_components_tools.get_node("ComponentsBackBtn")
@onready var assembly_btn: Button = rocket_components_tools.get_node("AssemblyBtn")
@onready var body_btn: Button = rocket_components_tools.get_node("BodyBtn")
@onready var inner_btn: Button = rocket_components_tools.get_node("InnerBtn")
@onready var mass_btn: Button = rocket_components_tools.get_node("MassBtn")
@onready var fin_btn: Button = rocket_components_tools.get_node("FinBtn")

@onready var sub_back_btn: Button = sub_components_tools.get_node("SubBackBtn")

var current_mode = "home"

func _ready() -> void:
	components_btn.pressed.connect(_on_components_btn_pressed)
	components_back_btn.pressed.connect(_on_components_back_btn_pressed)
	
	assembly_btn.pressed.connect(func(): _show_sub_components("assembly_components"))
	body_btn.pressed.connect(func(): _show_sub_components("body_components"))
	inner_btn.pressed.connect(func(): _show_sub_components("inner_components"))
	mass_btn.pressed.connect(func(): _show_sub_components("mass_components"))
	fin_btn.pressed.connect(func(): _show_sub_components("fin_components"))
	
	sub_back_btn.pressed.connect(_on_sub_back_btn_pressed)

func set_mode(mode: String) -> void:
	if not is_node_ready():
		await ready
		
	current_mode = mode
	
	home_tools.visible = mode == "home"
	editor_tools.visible = mode == "editor"
	rocket_components_tools.visible = mode == "rocket_components"
	sub_components_tools.visible = mode == "sub_components"

func _on_components_btn_pressed() -> void:
	set_mode("rocket_components")

func _on_components_back_btn_pressed() -> void:
	set_mode("editor")
	
func _on_sub_back_btn_pressed() -> void:
	set_mode("rocket_components")

func _show_sub_components(category: String) -> void:
	for child in sub_items.get_children():
		child.queue_free()
		
	var dir = DirAccess.open("res://ui/icons/rocket_components/" + category)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var processed_files = {}
		while file_name != "":
			if not dir.current_is_dir():
				var actual_file = file_name.replace(".import", "")
				if actual_file.ends_with(".svg") and not processed_files.has(actual_file):
					processed_files[actual_file] = true
					_create_sub_btn("res://ui/icons/rocket_components/" + category + "/" + actual_file, actual_file.replace(".svg", "").replace("_", " "))
			file_name = dir.get_next()
			
	set_mode("sub_components")

func _create_sub_btn(icon_path: String, tooltip: String) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(48, 48)
	btn.tooltip_text = tooltip.capitalize()
	btn.flat = true
	var tex = load(icon_path)
	if tex:
		btn.icon = tex
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.expand_icon = true
	sub_items.add_child(btn)
