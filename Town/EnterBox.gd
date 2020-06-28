extends Area2D

export (String, FILE, "*") var next_location : String
export (Vector2) var spawn_location

# Called when the node enters the scene tree for the first time.
func _ready():
	print(get_owner())
	connect("body_entered", self, "_on_body_entered")
	pass # Replace with function body.

func _on_body_entered(body):
	var playerNode = get_tree().get_nodes_in_group('player')[0]
	if body != playerNode:
		return
	print("hi")
	var root = get_tree().get_root()
	
	# save player data
	playerGlobal.direction = body.direction
	playerGlobal.inventoryList = body.inventoryList
	
	playerGlobal.spawn_location = spawn_location
	
	# Remove the current location
	var level = get_owner()
	#get_parent().remove_child(body)
	root.call_deferred("remove_child", level)
	level.call_deferred("queue_free")
	
	# Add the next location
	var next_level_resource = load(next_location)
	var next_level = next_level_resource.instance()
	root.call_deferred("add_child", next_level)
	#next_level.call_deferred("add_child", body)
