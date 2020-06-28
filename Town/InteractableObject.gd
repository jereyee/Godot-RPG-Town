extends Area2D

onready var ControlClass = get_tree().get_nodes_in_group("controlListener")[0]

enum type {
	GIVEITEM
	LADDER
	VENDOR
}

enum object_sprite {
	NONE
	CHEST
}

export(object_sprite) var objectSprite = object_sprite.NONE
export(type) var objectType = type.GIVEITEM
export var item = { "itemID": "", "itemName": "", "itemType": ""}

var objectState = {"open": false}

signal object_give_item

func _on_player_interaction():
	if objectState["open"] == true:
		print("Hi")
		print(get_path())
		return

	if objectType == type.GIVEITEM:
		objectState["open"] = true
		emit_signal("object_give_item", item)
		print(get_path())
		playerGlobal.interactedObjects[get_path()] = objectState
		match objectSprite:
			object_sprite.NONE:
				pass
			object_sprite.CHEST:
				get_parent().get_node("Sprite").frame = 1
				pass
		self.queue_free()
		return ("ITEM")

# Called when the node enters the scene tree for the first time.
func _ready():
	objectState["open"] = false
	# check for record of this node
	var node = playerGlobal.interactedObjects.get(get_path(), null)
	if node != null:
		objectState["open"] = node["open"]
		if objectState["open"] == true && objectSprite == object_sprite.CHEST:
			get_parent().get_node("Sprite").frame = 1

	connect("object_give_item", ControlClass, "add_item")

	pass # Replace with function body.

