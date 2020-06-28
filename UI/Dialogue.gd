extends Label

onready var dialogueOptions = preload("res://UI/DialogueOptions.tscn")
onready var dialogueParser = $"../DialogueParser"
var chooseTalkingOptions
var optionSelector = 0

var originID
var NPC
var _global_position

enum {
	FIRST,
	TALKING,
	OPTIONS,
	NOTIFICATION,
	DONE
}

signal receivedInput
signal continuePressed

func _ready():
	chooseTalkingOptions = false
	visible_characters = 0;

func set_variables(_NPC, _globalposition):
	self.originID = _NPC.ID
	self.NPC = _NPC
	self._global_position = _globalposition

func _process(delta):
	if chooseTalkingOptions:
		get_children()[optionSelector].selector.visible = true
		if Input.is_action_just_pressed("ui_down") && optionSelector < get_children().size():
			get_children()[optionSelector].selector.visible = false
			optionSelector += 1
		elif Input.is_action_just_pressed("ui_up") && optionSelector > 0:
			get_children()[optionSelector].selector.visible = false
			optionSelector -= 1
	
	if Input.is_action_just_pressed("talk") && get_parent().dialogueState != NOTIFICATION && get_parent().dialogueState != DONE && originID != null:
		Input.action_release("talk")
		# there's a bunch of stuff going on here
		
		# check if there is a gotoID for when the talking is done
		var gotoID = dialogueParser.check_goto(NPC.ID)
		if gotoID != null:
			originID = gotoID # there is. so the origins becomes the gotoID
				
		if chooseTalkingOptions:
			get_parent().dialogueState = TALKING
			if gotoID == null:
				# there isn't. if your're picking options then the original ID
				# goes back to your NPC ID that allows you to pick up the options
				originID = NPC.ID 
			# this checks for the next dialogue ID corresponding to your option
			NPC.ID = dialogueParser.has_next(NPC.ID, optionSelector)
			chooseTalkingOptions = false
		else:
			# if you're not picking options, then go to the next dialogue ID
			NPC.ID = dialogueParser.has_next(NPC.ID, null) 
			
		if NPC.ID == null: # if there's no next ID to go to, with or without options
			get_parent().dialogueState = DONE # complete the dialogue
			# your NPC ID goes back to being the original ID
			# if there was a goto ID, then your NPC ID will change to that
			NPC.ID = originID
			# reset the origin ID to account for input presses
			originID = null
			optionSelector = 0
		else:
			# if there was an ID, then your talking state continues
			get_parent().dialogueState = TALKING
		
		emit_signal("receivedInput", NPC, _global_position, delta)
	elif Input.is_action_just_pressed("talk") && get_parent().dialogueState == NOTIFICATION:
		Input.action_release("talk")
		emit_signal("continuePressed")
	
func display_dialogue(dialog):
	if dialog == null:
		return
	text = "\"" + dialog + "\""
	visible_characters = 0;	

func display_options(options):
	chooseTalkingOptions = true
	for n in options.size():
		var child = dialogueOptions.instance()
		add_child(child)
		child.rect_position.y += 25 * n
		child.selector.visible = false
		child.text = options[n]

func delete_options():
	for child in self.get_children():
		child.queue_free()

func _on_Timer_timeout():
	visible_characters = visible_characters + 1;
