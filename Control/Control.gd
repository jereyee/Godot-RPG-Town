extends Node2D

onready var playerClass = get_tree().get_nodes_in_group("player")[0]
onready var dialogueClass = get_node("../CanvasLayer/UI/DialogueBox")
onready var vendorClass = get_node("../CanvasLayer/UI/Vendor")
const itemResource = preload("res://Item/Item.tscn")

signal item_notif
signal NPCInteraction
signal vendor_interacted
signal vendor_finished
signal itemBought
signal itemSold

# Called when the node enters the scene tree for the first time.
func _ready():
	dialogueClass.connect("NPC_give_item", self, "add_item")
	if connect("item_notif", playerClass, "add_item_to_inventory") != OK:
		print("error connecting item notif to player class")
		
	if connect("itemBought", playerClass, "add_item_to_inventory") != OK:
		print("error connecting item bought signal to player class")
		
	if connect("itemSold", playerClass, "remove_item_from_inventory") != OK:
		print("error connecting item sold signal to player class")
		
	if connect("vendor_finished", playerClass, "set_move") != OK:
		print("error connecting finished vendor to playerClass")
		
	if connect("item_notif", dialogueClass, "item_notification") != OK:
		print("error connecting item notif to dialogue class")
		
	if connect("vendor_interacted", vendorClass, "vendor_interaction") != OK:
		print("error connecting vendor interaction to vendor class")
	
	playerClass.connect("NPCInteract", self, "NPC_interaction")
	playerClass.connect("VendorInteract", self, "vendor_interaction")
	
	vendorClass.connect("vendorExit", self, "vendor_exit")
	vendorClass.connect("itemBought", self, "item_bought")
	vendorClass.connect("itemSold", self, "item_sold")
	dialogueClass.connect("player_give_item", self, "item_sold")

func item_sold(item, qty = 1):
	emit_signal("itemSold", item, qty)

func item_bought(item, qty):
	var newItem = itemResource.instance()
	newItem.itemName = item['itemName']
	newItem.itemType = item['itemType']
	newItem.itemID = item['itemID']
	emit_signal("itemBought", newItem, qty)
	
func vendor_exit():
	emit_signal("vendor_finished")

func vendor_interaction(vendor, _global_position, delta):
	NPC_interaction(vendor, _global_position, delta)
	emit_signal("vendor_interacted", vendor, playerClass.inventoryList)

func NPC_interaction(NPC, _global_position, delta):
	var NPCClass = get_node(NPC.get_path())
	# connects to the NPC that the player has interacted with
	if connect("NPCInteraction", NPCClass, "face_direction") != OK:
		print("error connecting NPC interaction to NPC class")
	# sends out the signal to the NPC 
	emit_signal("NPCInteraction", NPC, _global_position, delta)
	disconnect("NPCInteraction", NPCClass, "face_direction")
	

func add_item(item):
	var newItem = itemResource.instance()
	newItem.itemName = item['itemName']
	newItem.itemType = item['itemType']
	newItem.itemID = item['itemID']
	emit_signal("item_notif", newItem)

