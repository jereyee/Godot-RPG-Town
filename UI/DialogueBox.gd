extends Popup

onready var playerInteract = get_tree().get_nodes_in_group("player")[0]
onready var timer = $TextSpeed
onready var dialogueBox = $DialogueBoxNode
onready var NPCName = $NPCName
onready var dialogue = $Dialogue
onready var dialogueparse = $DialogueParser
onready var notification = $Notification

var dialogues_dict = "dialogues"
var counter
var dialogueState
var nextID
var NPCItemsGiven

enum {
	FIRST,
	TALKING,
	OPTIONS,
	NOTIFICATION,
	DONE
}

signal talking_done
signal talking_now
signal NPC_give_item
signal close_notification
signal player_give_item

# Called when the node enters the scene tree for the first time.
func _ready():
	counter = 0
	dialogueState = FIRST
	hide()
	if playerInteract:
		playerInteract.connect("NPCInteract", self, "show_dialogue")
		if connect("talking_done", playerInteract, "set_move") != OK:
			print("error connecting talking done to set move")
		if connect("talking_now", playerInteract, "set_talking") != OK:
			print("error connecting talking now to set talking")
	
	NPCItemsGiven = []
	
func item_notification(item):
	dialogueState = NOTIFICATION
	self.rect_position = Vector2(170, 20)
	dialogueBox.rect_size.x = 300
	dialogueBox.rect_size.y = 30
	notification.text = "You have received '" + item.itemName + "'!"
	dialogue.text = ""
	NPCName.text = ""
	show()
	yield(dialogue, "continuePressed")
	dialogueState = FIRST
	hide()
	emit_signal('close_notification')

func show_dialogue(NPC, _global_position, _delta):
	notification.text = ""
	dialogue.delete_options()
	
	var completionID = dialogueparse.check_giveQuest(NPC.ID)
	if completionID != null:
		var completionID2 = dialogueparse.check_giveQuest(completionID)
		if completionID2 != null:
			NPC.ID = completionID2
		else:
			NPC.ID = completionID
	dialogueparse.check_completeQuest(NPC.ID)
	
	match dialogueState:
		FIRST:
			nextID = dialogueparse.get_dialogue_ID(NPC.ID)
			if nextID != NPC.ID:
				NPC.ID = nextID
			
			# check for items to give to the NPC by the player
			var playerItem = dialogueparse.check_needsItem(nextID)
			var playerHasItem = false
			if playerItem != null:
				playerHasItem = playerInteract.check_inventory(playerItem)
				print(playerHasItem)
				if playerHasItem:
					nextID = playerItem['next']
					print(nextID)
					dialogueparse.check_completeQuest(nextID)
					emit_signal("player_give_item", playerItem)
					NPC.ID = nextID
			dialogue.set_variables(NPC, _global_position)
			
			emit_signal("talking_now")
		TALKING:
			nextID = NPC.ID
		OPTIONS:
			nextID = NPC.ID
		DONE:
			hide()
			for i in NPCItemsGiven:
				emit_signal("NPC_give_item", i)
				yield (self, 'close_notification')
			if connect("talking_done", NPC, "set_wander") != OK:
				print("error connecting talking done to set wander")
			emit_signal("talking_done")
			disconnect("talking_done", NPC, "set_wander")
			NPCItemsGiven.clear()
			dialogueState = FIRST
			return
	
	if NPC.position.x < 320 && NPC.position.y < 180:
		self.rect_position = Vector2(10, 200)
	elif NPC.position.x > 320 && NPC.position.y < 180:
		self.rect_position = Vector2(300, 200)
	elif NPC.position.x < 320 && NPC.position.y > 180:
		self.rect_position  = Vector2(300, 10)
	elif NPC.position.x > 320 && NPC.position.y > 180:
		self.rect_position = Vector2(10, 10)
	
	
	show()
	NPCName.display_name(NPC.NPCName)
	
	# check for items to give to the player by the NPC
	var item = dialogueparse.check_giveItem(nextID)
	if item != null:
		print(item)
		NPCItemsGiven.append(item)
		
	var dialog = dialogueparse.get_current_dialogue(nextID, NPC.NPCName)
	dialogue.display_dialogue(dialog)
	match dialogueparse.get_dialogue_type(nextID):
		"text":
			dialogueBox.rect_size.y = 100
			dialogue.rect_size.y = 130
			pass
		"question":
			dialogueState = OPTIONS
			dialogueBox.rect_size.y = 200
			dialogue.rect_size.y = 230
			var options = dialogueparse.get_current_dialogue_options(nextID)
			if options != null:
				dialogue.display_options(options)
	timer.start()
	
		
func _on_Dialogue_receivedInput(NPC, _global_position, delta):
	show_dialogue(NPC, _global_position, delta)

