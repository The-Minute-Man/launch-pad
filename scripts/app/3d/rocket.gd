extends Node3D
@export var rocket_text: String = "PROJECTS"
@export var is_rotating: bool = true

var current_design: RocketDesign = null
var generated_meshes: Array[Node] = []

func _ready() -> void:
	if has_node("Visuals"):
		for child in $Visuals.get_children():
			if child is Label3D:
				if rocket_text == "":
					child.visible = false
				else:
					child.visible = true
					child.text = rocket_text

func set_design(design: RocketDesign) -> void:
	current_design = design
	_rebuild_visuals()

func _rebuild_visuals() -> void:
	if not has_node("Visuals"):
		return
		
	var visuals = $Visuals
	
	# Clean up old generated meshes
	for mesh in generated_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()
	generated_meshes.clear()
	
	# Hide static placeholder meshes
	if visuals.has_node("Cylinder"): visuals.get_node("Cylinder").visible = false
	if visuals.has_node("Fins"): visuals.get_node("Fins").visible = false
	if visuals.has_node("Nose"): visuals.get_node("Nose").visible = false
	
	if current_design == null:
		# Show placeholders if no design
		if visuals.has_node("Cylinder"): visuals.get_node("Cylinder").visible = true
		if visuals.has_node("Fins"): visuals.get_node("Fins").visible = true
		if visuals.has_node("Nose"): visuals.get_node("Nose").visible = true
		return
		
	# Materials
	var cyl_mat = StandardMaterial3D.new()
	cyl_mat.albedo_color = Color(0.76, 0.73, 0.61)
	var nose_mat = StandardMaterial3D.new()
	nose_mat.albedo_color = Color(0.55, 0.21, 0.01)
	var fin_mat = StandardMaterial3D.new()
	fin_mat.albedo_color = Color(0.15, 0.15, 0.16)
	
	# Build new meshes
	for comp in current_design.components:
		if comp is NoseCone:
			var mi = MeshInstance3D.new()
			var m = CylinderMesh.new()
			m.top_radius = 0.0
			m.bottom_radius = comp.base_diameter / 2.0
			m.height = comp.length
			mi.mesh = m
			mi.material_override = nose_mat
			mi.position = Vector3(0, -comp.global_position - (comp.length / 2.0), 0)
			visuals.add_child(mi)
			generated_meshes.append(mi)
			
		elif comp is BodyTube:
			var mi = MeshInstance3D.new()
			var m = CylinderMesh.new()
			m.top_radius = comp.outer_diameter / 2.0
			m.bottom_radius = comp.outer_diameter / 2.0
			m.height = comp.length
			mi.mesh = m
			mi.material_override = cyl_mat
			# Cylinder center is at height/2
			mi.position = Vector3(0, -comp.global_position - (comp.length / 2.0), 0)
			visuals.add_child(mi)
			generated_meshes.append(mi)
			
		elif comp is FinSet:
			# Generic boxes for fins
			for i in range(comp.fin_count):
				var mi = MeshInstance3D.new()
				var m = BoxMesh.new()
				m.size = Vector3(comp.span, comp.root_chord, comp.thickness)
				mi.mesh = m
				mi.material_override = fin_mat
				var angle = i * (2.0 * PI / comp.fin_count)
				mi.position = Vector3(cos(angle) * (comp.span/2.0), -comp.global_position - (comp.root_chord / 2.0), sin(angle) * (comp.span/2.0))
				mi.rotation = Vector3(0, -angle, 0)
				visuals.add_child(mi)
				generated_meshes.append(mi)

func _process(delta):
	if not is_inside_tree():
		return
	
	# Spin slowly
	if is_rotating and has_node("Visuals"):
		$Visuals.rotate_y(0.5 * delta)
