extends Node2D

var item : Dictionary setget set_item
onready var selector = $Selector
var prev_owned = 0
var owned = 0
var cost_offer = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_item(_item):
	item = _item

func set_item_options(costOffer, quantity):
	if item == null:
		return
	get_node("Item").text = item.get("itemName", null)
	cost_offer = item.get(costOffer, null)
	owned = quantity
	prev_owned = owned
	if owned != null:
		set_text()

func set_text():
	get_node("Owned").text = str(owned)
	get_node("Cost").text = str(cost_offer)
	
func reset_owned():
	# resets owned quantity to 1
	owned = 1
	set_text()

func refresh_owned(number):
	# add the number of items bought/sold to the original quantity
	owned = prev_owned + number
	# this equation accounts for multiple transactions
	prev_owned = owned
	if owned == 0:
		self.queue_free()
	set_text()
		
func increase_quantity(number):
	owned += number
	set_text()

func get_total_price():
	return owned * cost_offer
