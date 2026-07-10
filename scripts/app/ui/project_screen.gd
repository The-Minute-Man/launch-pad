extends Control
## Main ProjectScreen — lists all .lpad projects with a menu bar and project grid.

@onready var project_grid: GridContainer = $VBoxLayout/HBoxLayout/ContentMargin/ContentVBox/ScrollContainer/ProjectGrid
@onready var empty_state: CenterContainer = $VBoxLayout/HBoxLayout/ContentMargin/ContentVBox/EmptyState
@onready var new_project_btn: Button = $VBoxLayout/HBoxLayout/ContentMargin/ContentVBox/HeaderRow/NewProjectButton
@onready var side_bar: PanelContainer = $VBoxLayout/HBoxLayout/SideBar

func _ready() -> void:
	side_bar.set_mode("home")
	new_project_btn.pressed.connect(_on_new_project)
	_refresh_projects()



## ── Project CRUD ──

func _on_new_project() -> void:
	var dialog_scene := preload("res://scenes/new_project_dialog.tscn")
	var dialog := dialog_scene.instantiate()
	add_child(dialog)
	dialog.project_created.connect(func():
		_refresh_projects()
	)

func _on_delete_requested(file_path: String) -> void:
	var dialog_scene := preload("res://scenes/delete_project_dialog.tscn")
	var dialog := dialog_scene.instantiate()
	dialog.setup(file_path)
	add_child(dialog)
	dialog.project_deleted.connect(func():
		_refresh_projects()
	)

func _on_card_clicked(file_path: String) -> void:
	var editor_scene := preload("res://scenes/project_editor_screen.tscn").instantiate()
	editor_scene.setup(file_path)
	
	get_tree().root.add_child(editor_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = editor_scene

## ── Refresh Grid ──

func _refresh_projects() -> void:
	# Clear old cards
	for child in project_grid.get_children():
		child.queue_free()

	var projects := ProjectManager.list_projects()

	if projects.size() == 0:
		empty_state.visible = true
		project_grid.visible = false
		return

	empty_state.visible = false
	project_grid.visible = true

	var card_scene := preload("res://scenes/project_card.tscn")
	for project in projects:
		var card := card_scene.instantiate()
		card.setup(project)
		card.delete_requested.connect(_on_delete_requested)
		card.card_clicked.connect(_on_card_clicked)
		project_grid.add_child(card)
