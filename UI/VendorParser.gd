extends Control

export (String, FILE, "*.json") var items_file_path : String

var items : Dictionary
var repeat_dialogue : Dictionary
	
func load_dialogue(file_path) -> Dictionary:
	var file = File.new()
	assert(file.file_exists(file_path))
	
	file.open(file_path, file.READ)
	var itemData = parse_json(file.get_as_text())
	assert(itemData.size() > 0)
	return itemData
	
# Called when the node enters the scene tree for the first time.
func _ready():
	items = load_dialogue(items_file_path)
	
func get_item(ID):
	return items.get(ID, null)
