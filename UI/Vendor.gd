extends Popup

onready var dialogueOptions = preload("res://UI/DialogueOptions.tscn")
onready var UIOptions = preload("res://UI/VendorOptions.tscn")
onready var playerInteract = get_tree().get_nodes_in_group("player")[0]
onready var timer = $TextSpeed
onready var textholder = $Boxes
onready var labels = $Labels
onready var varioustexts = $Text
onready var options = $MenuOptions
onready var itemOptions = $ItemOptions
onready var vendorparser = $VendorParser

var optionSelector = 0
var qtySelector = 1
var vendor;
var playerInventory;

# from the perspective of the player
enum {
	NOTHING,
	MENU,
	BUYING,
	CHOOSING_QUANTITY,
	SELLING
}

enum vendorShop {
	NONE,
	ITEMSHOP,
	WEAPONSHOP
}

var prev_state = NOTHING
var state = NOTHING

var max_qty_selection
var min_qty_selection

signal vendorExit
signal itemBought
signal itemSold

var timerVar = 0

func exit_vendor():
	hide()
	emit_signal("vendorExit")
	options.get_children()[optionSelector].selector.visible = false
	state = NOTHING
	optionSelector = 0

func _process(delta):
	varioustexts.get_node("CurrencyText").text = str(playerGlobal.coins)
	match state:
		NOTHING:
			return
		MENU:
			labels.visible = false
			varioustexts.get_node("DescriptionText").text = ""
			receive_input(options)
			if Input.is_action_just_pressed("talk"):
				Input.action_release("talk")
				match optionSelector:
					0: #BUY
						display_buy_items()
						state = BUYING
					1: #SELL
						display_sell_items()
						state = SELLING
					2: #EXIT
						exit_vendor()
				optionSelector = 0
			elif Input.is_action_just_pressed("ui_back"):
				exit_vendor()
		BUYING:
			labels.visible = true
			labels.get_node("CostLabel").text = "Cost"
			var item = itemOptions.get_children()[optionSelector].item
			varioustexts.get_node("DescriptionText").text = item.get("itemDescription", null)
			varioustexts.get_node("GreetingsText").text = "Pick what you need!"
			receive_input(itemOptions)
			if Input.is_action_just_pressed("ui_back"):
				for option in itemOptions.get_children():
					option.queue_free()
				optionSelector = 0
				state = MENU
			elif Input.is_action_just_pressed("talk"):
				itemOptions.get_children()[optionSelector].selector.color = Color(0.3, 0, 1, 0.5)
				match vendor.vendor_shop:
					vendorShop.WEAPONSHOP:
						varioustexts.get_node("GreetingsText").text = "Thanks for purchasing!" 
						# start the 'refresh' timer
						set_refresh_timer(0.25)
						yield($InputTimer, "timeout")
						# wait for the timer to finish, then update the UI
						itemOptions.get_children()[optionSelector].selector.color = Color(1, 1, 1, 0.354)
						varioustexts.get_node("GreetingsText").text = vendor.vendorGreetings
						emit_signal("itemBought", itemOptions.get_children()[optionSelector].item, qtySelector)
						itemOptions.get_children()[optionSelector].increase_quantity(1)
					vendorShop.ITEMSHOP:
						varioustexts.get_node("GreetingsText").text = "How many?"
						labels.get_node("OwnedLabel").text = "Quantity"
						$CaratDown.visible = true
						$CaratUp.visible = true
						$CaratUp.position.y = 113 + (optionSelector * 22)
						$CaratDown.position.y = 128 + (optionSelector * 22)
						
						prev_state = BUYING
						max_qty_selection = 99
						min_qty_selection = 1
						state = CHOOSING_QUANTITY
						itemOptions.get_children()[optionSelector].reset_owned()
					
		CHOOSING_QUANTITY:
			$CaratUp.modulate = Color(1, 1, 1) # reset to default
			$CaratDown.modulate = Color(1, 1, 1) # reset to default
			timerVar += delta
			
			if Input.is_action_just_pressed("ui_back"):
				set_buying_state(0)
			elif Input.is_action_pressed("ui_up") && qtySelector <= max_qty_selection:
				$CaratUp.modulate = Color(1, 0, 0) # red shade		
				if timerVar >= 0.2:
					change_quantity(1)
					timerVar = 0
			elif Input.is_action_pressed("ui_down") && qtySelector > min_qty_selection:
				$CaratDown.modulate = Color(1, 0, 0) # red shade
				if timerVar >= 0.2:
					change_quantity(-1)
					timerVar = 0
			elif Input.is_action_just_pressed("ui_right") && qtySelector <= max_qty_selection-10:
				change_quantity(10)
			elif Input.is_action_just_pressed("ui_left") && qtySelector >= min_qty_selection+10:
				change_quantity(-10)
			elif Input.is_action_just_pressed("talk"):
				match prev_state:
					BUYING:
						var total_cost = itemOptions.get_children()[optionSelector].get_total_price()
				
						if total_cost > playerGlobal.coins:
							itemOptions.get_children()[optionSelector].selector.color = Color(1, 0, 0, 0.354)
							varioustexts.get_node("GreetingsText").text = "You don't have enough money!" 
							# start the 'refresh' timer
							set_refresh_timer(1)
							yield($InputTimer, "timeout")
							# wait for the timer to finish, then update the UI
							set_buying_state(0)
							return
						
						itemOptions.get_children()[optionSelector].selector.color = Color(0, 1, 0, 0.354)
						varioustexts.get_node("GreetingsText").text = "Thanks for purchasing!" 
						# start the 'refresh' timer
						set_refresh_timer(0.5)
						yield($InputTimer, "timeout")
						# wait for the timer to finish, then update the UI
						varioustexts.get_node("GreetingsText").text = vendor.vendorGreetings	
						playerGlobal.coins -= total_cost
						emit_signal("itemBought", itemOptions.get_children()[optionSelector].item, qtySelector)
						itemOptions.get_children()[optionSelector].reset_owned()
						set_buying_state(qtySelector)
					SELLING:
						var total_price = itemOptions.get_children()[optionSelector].get_total_price()
				
						itemOptions.get_children()[optionSelector].selector.color = Color(0, 1, 0, 0.354)
						varioustexts.get_node("GreetingsText").text = "I'll take that." 
						# start the 'refresh' timer
						set_refresh_timer(0.5)
						yield($InputTimer, "timeout")
						# wait for the timer to finish, then update the UI
						varioustexts.get_node("GreetingsText").text = vendor.vendorGreetings	
						playerGlobal.coins += total_price
						emit_signal("itemSold", itemOptions.get_children()[optionSelector].item, qtySelector)
						itemOptions.get_children()[optionSelector].reset_owned()
						set_selling_state(qtySelector)
						pass

		SELLING:
			if itemOptions.get_children().size() == 0:
				varioustexts.get_node("GreetingsText").text = "You've got nothing to sell!"
				optionSelector = 1
				state = MENU
				return
			labels.visible = true
			labels.get_node("CostLabel").text = "Offer"
			var item = itemOptions.get_children()[optionSelector].item
			varioustexts.get_node("DescriptionText").text = item.get("itemDescription", null)
			varioustexts.get_node("GreetingsText").text = "Show me what you have."
			receive_input(itemOptions)
			if Input.is_action_just_pressed("ui_back"):
				for option in itemOptions.get_children():
					option.queue_free()
				optionSelector = 1
				state = MENU
			elif Input.is_action_just_pressed("talk"):
				itemOptions.get_children()[optionSelector].selector.color = Color(0.3, 0, 1, 0.5)
				match item['itemType']:
					"weapon":
						varioustexts.get_node("GreetingsText").text = "Thanks for purchasing!" 
						# start the 'refresh' timer
						set_refresh_timer(0.25)
						yield($InputTimer, "timeout")
						# wait for the timer to finish, then update the UI
						itemOptions.get_children()[optionSelector].selector.color = Color(1, 1, 1, 0.354)
						varioustexts.get_node("GreetingsText").text = vendor.vendorGreetings
						emit_signal("itemBought", itemOptions.get_children()[optionSelector].item, qtySelector)
						itemOptions.get_children()[optionSelector].increase_quantity(1)
					_:
						varioustexts.get_node("GreetingsText").text = "How many?"
						labels.get_node("OwnedLabel").text = "Quantity"
						$CaratDown.visible = true
						$CaratUp.visible = true
						$CaratUp.position.y = 113 + (optionSelector * 22)
						$CaratDown.position.y = 128 + (optionSelector * 22)
						
						prev_state = SELLING
						max_qty_selection = itemOptions.get_children()[optionSelector].prev_owned - 1
						min_qty_selection = 1
						state = CHOOSING_QUANTITY
						itemOptions.get_children()[optionSelector].reset_owned()

func set_refresh_timer(wait_time):
	$InputTimer.wait_time = wait_time
	$InputTimer.start()

func change_quantity(number):
	# for the carat and the UI display
	qtySelector += number
	itemOptions.get_children()[optionSelector].increase_quantity(number)				

func set_buying_state(number):
	itemOptions.get_children()[optionSelector].refresh_owned(number)
	labels.get_node("OwnedLabel").text = "Owned"
	qtySelector = 1
	$CaratDown.visible = false
	$CaratUp.visible = false
	itemOptions.get_children()[optionSelector].selector.color = Color(1, 1, 1, 0.354)
	state = BUYING
	
func set_selling_state(number):
	itemOptions.get_children()[optionSelector].refresh_owned(-number)
	labels.get_node("OwnedLabel").text = "Owned"
	qtySelector = 1
	$CaratDown.visible = false
	$CaratUp.visible = false
	itemOptions.get_children()[optionSelector].selector.color = Color(1, 1, 1, 0.354)
	state = SELLING

func receive_input(node):
	node.get_children()[optionSelector].selector.visible = true
	if Input.is_action_just_pressed("ui_down") && optionSelector < node.get_children().size() - 1:
		node.get_children()[optionSelector].selector.visible = false
		optionSelector += 1
	elif Input.is_action_just_pressed("ui_up") && optionSelector > 0:
		node.get_children()[optionSelector].selector.visible = false
		optionSelector -= 1

func display_buy_items():
	var vendorItems : Array
	vendorItems = vendor.vendorItems
	for n in vendorItems.size():
		var item = vendorparser.get_item(vendorItems[n])
		item['itemID'] = vendorItems[n]
		var playeritem = playerGlobal.inventoryList.get(vendorItems[n], null)
		var quantity = 0
		if playeritem != null:
			quantity = playeritem['quantity']
		create_item_option("itemCost", quantity, item, n)
		
func display_sell_items():
	var playerItems : Dictionary
	playerItems = playerGlobal.inventoryList
	var counter = 0
	for n in playerItems:
		if playerItems[n].get("itemType", null) == "key":
			continue
		var item = vendorparser.get_item(n)
		item['itemID'] = n
		var quantity = playerItems[n].get("quantity", 0)
		create_item_option("itemOffer", quantity, item, counter)
		counter += 1

func create_item_option(costOffer, quantity, item, n):
	var child = UIOptions.instance()
	itemOptions.add_child(child)
	child.position.x = 220
	child.position.y = 110 + (22 * n)
	child.selector.visible = false
	child.item = item
	child.set_item_options(costOffer, quantity)
		
func vendor_interaction(_vendor, _playerInventory):
	vendor = _vendor
	playerInventory = _playerInventory
	print("interaction")
	$Text.get_node("GreetingsText").text = vendor.vendorGreetings
	match vendor.vendor_shop:
		1:
			$Text.get_node("VendorName").text = "Item Shop Owner:"
		2:
			$Text.get_node("VendorName").text = "Weapon Shop Owner:"
		
	state = MENU
	show()
	pass

func _on_InputTimer_timeout():
	pass # Replace with function body.
