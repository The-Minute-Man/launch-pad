extends Control

var current_project_path: String = ""
var rocket_design: RocketDesign = null
var selected_component: RocketComponent = null

@onready var top_bar: PanelContainer = $VBoxLayout/TopBar
@onready var tree: Tree = $VBoxLayout/HBoxLayout/ContentMargin/ContentVBox/MainEditorArea/LeftPanel/ComponentTree
@onready var inspector_vbox: VBoxContainer = $VBoxLayout/HBoxLayout/ContentMargin/ContentVBox/MainEditorArea/RightPanel/ScrollContainer/InspectorVBox
@onready var stats_label: Label = $VBoxLayout/HBoxLayout/ContentMargin/ContentVBox/StatsLabel
@onready var rocket_3d: Node3D = $VBoxLayout/HBoxLayout/ContentMargin/ContentVBox/MainEditorArea/CenterPanel/SubViewportContainer/SubViewport/Rocket

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
	
	# Create a dummy rocket for testing the UI
	rocket_design = RocketDesign.new()
	var nose = NoseCone.new()
	nose.length = 0.15
	nose.base_diameter = 0.04
	nose.component_name = "Nose Cone"
	rocket_design.add_component(nose)
	
	var body = BodyTube.new()
	body.length = 0.5
	body.outer_diameter = 0.04
	body.inner_diameter = 0.038
	body.component_name = "Body Tube"
	rocket_design.add_component(body)
	
	var fins = FinSet.new()
	fins.root_chord = 0.05
	fins.span = 0.04
	fins.component_name = "Fin Set"
	rocket_design.add_component(fins)
	
	var motor_path = "res://scripts/app/data/databases/parts/motors/C6_5f4294d20002e900000004e7.eng"
	var motor = MotorParser.parse_eng_file(motor_path)
	if motor != null:
		motor.component_name = "C6 Motor"
		rocket_design.add_component(motor)
	
	tree.item_selected.connect(_on_tree_item_selected)
	_refresh_tree()
	_update_visuals()

func _refresh_tree() -> void:
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "My Rocket")
	
	for comp in rocket_design.components:
		var item = tree.create_item(root)
		item.set_text(0, comp.component_name)
		item.set_metadata(0, comp)
		
func _on_tree_item_selected() -> void:
	var selected = tree.get_selected()
	if selected and selected.get_metadata(0) != null:
		selected_component = selected.get_metadata(0)
		_build_inspector(selected_component)

func _build_inspector(comp: RocketComponent) -> void:
	for child in inspector_vbox.get_children():
		child.queue_free()
		
	_add_inspector_title(comp.component_name + " Properties")
	
	if "length" in comp:
		_add_slider_property("Length (m)", comp.length, 0.01, 2.0, func(val): comp.length = val; _on_property_changed())
	if "base_diameter" in comp:
		_add_slider_property("Base Diameter (m)", comp.base_diameter, 0.01, 0.5, func(val): comp.base_diameter = val; _on_property_changed())
	if "outer_diameter" in comp:
		_add_slider_property("Outer Diameter (m)", comp.outer_diameter, 0.01, 0.5, func(val): comp.outer_diameter = val; _on_property_changed())
	if "inner_diameter" in comp:
		_add_slider_property("Inner Diameter (m)", comp.inner_diameter, 0.005, 0.49, func(val): comp.inner_diameter = val; _on_property_changed())
	if "root_chord" in comp:
		_add_slider_property("Root Chord (m)", comp.root_chord, 0.01, 0.3, func(val): comp.root_chord = val; _on_property_changed())
	if "span" in comp:
		_add_slider_property("Fin Span (m)", comp.span, 0.01, 0.3, func(val): comp.span = val; _on_property_changed())
		
	# Add relative offset for all components
	_add_slider_property("Relative Offset (m)", comp.relative_offset, -0.5, 0.5, func(val): comp.relative_offset = val; _on_property_changed())

func _add_inspector_title(title: String) -> void:
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 20)
	inspector_vbox.add_child(label)
	var hs = HSeparator.new()
	inspector_vbox.add_child(hs)

func _add_slider_property(label_text: String, value: float, min_val: float, max_val: float, setter_func: Callable) -> void:
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = 0.001
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v): setter_func.call(v))
	hbox.add_child(slider)
	
	var val_label = Label.new()
	val_label.text = str(snapped(value, 0.001))
	val_label.custom_minimum_size = Vector2(50, 0)
	slider.value_changed.connect(func(v): val_label.text = str(snapped(v, 0.001)))
	hbox.add_child(val_label)
	
	inspector_vbox.add_child(hbox)

func _on_property_changed() -> void:
	rocket_design.update_auto_stacking()
	_update_visuals()

func _update_visuals() -> void:
	rocket_3d.set_design(rocket_design)
	
	var sim_data = rocket_design.export_to_simulator()
	var mass_g = snapped(sim_data["mass"] * 1000.0, 0.1)
	var cg = snapped(sim_data["cg"], 0.001)
	var apogee = snapped(Simulator.run_simulation(sim_data), 0.1)
	
	stats_label.text = "Mass: " + str(mass_g) + " g | CG: " + str(cg) + " m | Est. Apogee: " + str(apogee) + " m"
