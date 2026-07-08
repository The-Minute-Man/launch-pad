extends Control
## Main ProjectScreen — lists all .lpad projects with a menu bar and project grid.

@onready var project_grid: GridContainer = $VBoxLayout/ContentMargin/ContentVBox/ScrollContainer/ProjectGrid
@onready var empty_state: CenterContainer = $VBoxLayout/ContentMargin/ContentVBox/EmptyState
@onready var new_project_btn: Button = $VBoxLayout/ContentMargin/ContentVBox/HeaderRow/NewProjectButton

func _ready() -> void:
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
	dialog.visibility_changed.connect(func():
		if not dialog.visible:
			dialog.queue_free()
	)
	dialog.popup_centered()

func _on_delete_requested(file_path: String) -> void:
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "Are you sure you want to delete this project?\nThis action cannot be undone."
	confirm.title = "Delete Project"
	confirm.min_size = Vector2i(400, 150)
	confirm.get_ok_button().text = "Delete"
	add_child(confirm)
	confirm.popup_centered()

	confirm.confirmed.connect(func():
		ProjectManager.delete_project(file_path)
		_refresh_projects()
		confirm.queue_free()
	)
	confirm.canceled.connect(func():
		confirm.queue_free()
	)

func _on_card_clicked(file_path: String) -> void:
	# TODO: Open the project editor screen
	print("Opening project: ", file_path)

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
