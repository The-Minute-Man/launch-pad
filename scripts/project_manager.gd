extends Node
## Autoload singleton for managing .lpad project files.
## Handles creating, loading, saving, listing, and deleting projects.

const PROJECTS_DIR := "user://projects/"
const FILE_EXTENSION := ".lpad"

func _ready() -> void:
	_ensure_projects_dir()

## Make sure the projects directory exists.
func _ensure_projects_dir() -> void:
	if not DirAccess.dir_exists_absolute(PROJECTS_DIR):
		DirAccess.make_dir_recursive_absolute(PROJECTS_DIR)

## Get the current timestamp as an ISO 8601 string.
func _timestamp() -> String:
	var dt := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [
		dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"], dt["second"]
	]

## Generate a safe filename from a project name.
func _safe_filename(project_name: String) -> String:
	var safe := project_name.to_lower().strip_edges()
	safe = safe.replace(" ", "_")
	# Remove any characters that aren't alphanumeric or underscores
	var result := ""
	for c in safe:
		if c.is_valid_identifier() or c == "_":
			result += c
	if result.is_empty():
		result = "untitled"
	return result

## Create a brand-new project and save it to disk. Returns the ProjectData.
func create_project(project_name: String, description: String = "") -> ProjectData:
	var data := ProjectData.new()
	data.project_name = project_name
	data.description = description
	data.created_at = _timestamp()
	data.modified_at = data.created_at

	var filename := _safe_filename(project_name)
	var path := PROJECTS_DIR + filename + FILE_EXTENSION

	# If file already exists, append a number
	var counter := 1
	while FileAccess.file_exists(path):
		path = PROJECTS_DIR + filename + "_" + str(counter) + FILE_EXTENSION
		counter += 1

	data.file_path = path
	save_project(data)
	return data

## Save a ProjectData to its .lpad file.
func save_project(data: ProjectData) -> Error:
	data.modified_at = _timestamp()
	var json_string := JSON.stringify(data.to_dict(), "\t")
	var file := FileAccess.open(data.file_path, FileAccess.WRITE)
	if file == null:
		push_error("ProjectManager: Could not save project to " + data.file_path)
		return FileAccess.get_open_error()
	file.store_string(json_string)
	file.close()
	return OK

## Load a ProjectData from a .lpad file path.
func load_project(path: String) -> ProjectData:
	if not FileAccess.file_exists(path):
		push_error("ProjectManager: File not found: " + path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ProjectManager: Could not open " + path)
		return null
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		push_error("ProjectManager: JSON parse error in " + path)
		return null

	var data := ProjectData.new()
	data.from_dict(json.data)
	data.file_path = path
	return data

## List all projects in the projects directory.
func list_projects() -> Array[ProjectData]:
	_ensure_projects_dir()
	var projects: Array[ProjectData] = []
	var dir := DirAccess.open(PROJECTS_DIR)
	if dir == null:
		return projects

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(FILE_EXTENSION):
			var full_path := PROJECTS_DIR + file_name
			var project := load_project(full_path)
			if project != null:
				projects.append(project)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort by modified date (newest first)
	projects.sort_custom(func(a, b): return a.modified_at > b.modified_at)
	return projects

## Delete a project's .lpad file.
func delete_project(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var dir := DirAccess.open(PROJECTS_DIR)
	if dir == null:
		return ERR_CANT_OPEN
	return dir.remove(path.get_file())
