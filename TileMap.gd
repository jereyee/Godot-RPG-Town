extends TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_EnterBox_body_entered(body):
	var playerNode = get_node("../Player")
	if body != playerNode:
		return
	print("hi")
	var root = get_tree().get_root()
	
	# save player data
	playerGlobal.direction = body.direction
	playerGlobal.inventoryList = body.inventoryList
	
	playerGlobal.spawn_location = $EnterBox.spawn_location
	
	# Remove the current location
	var level = root.get_node("Town")
	#get_parent().remove_child(body)
	root.call_deferred("remove_child", level)
	level.call_deferred("queue_free")
	
	# Add the next location
	var next_level_resource = load($EnterBox.next_location)
	var next_level = next_level_resource.instance()
	root.call_deferred("add_child", next_level)
	#next_level.call_deferred("add_child", body)
	
