extends Control

export (String, FILE, "*.json") var text_file_path : String
export (String, FILE, "*.json") var repeat_file_path : String

var text_dialogue : Dictionary
var repeat_dialogue : Dictionary

var dialogues_dict = "dialogues"
	
func load_dialogue(file_path) -> Dictionary:
	var file = File.new()
	assert(file.file_exists(file_path))
	
	file.open(file_path, file.READ)
	var dialogue = parse_json(file.get_as_text())
	assert(dialogue.size() > 0)
	return dialogue
	
# Called when the node enters the scene tree for the first time.
func _ready():
	text_dialogue = load_dialogue(text_file_path)
	repeat_dialogue = load_dialogue(repeat_file_path)
	
func get_dialogue_ID(ID):
	var extraRepeat = check_dialogues(ID, "extraRepeat");
	
	if extraRepeat != null:
		if !progress.get(dialogues_dict).has(ID):
			return ID
		else:
			var extraRepeats = extraRepeat.split(", ")
			for n in extraRepeats:
				if progress.get(dialogues_dict).has(n):
					continue
				return n
			# return extraRepeats[extraRepeats.size() - 1]
				
	return ID

func get_dialogue_type(ID):
	return check_dialogues(ID, 'type')
		
func get_current_dialogue_options(ID):
	return check_dialogues(ID, 'options')

func get_current_dialogue(ID, _name):
	var current_dialogue = check_dialogues(ID, 'text')
		
	if current_dialogue != null:
		progress.get(dialogues_dict)[ID] = true
		return current_dialogue
	else:
		print("there's no dialogue for " + ID + "!")
		
#	var dialoguename
#	if name != dialogue_name && dialogue_name != null:
#		return "I've been given the wrong dialogue!"

# this function checks if the dialogue ID has a next ID
func has_next(ID, _optionSelector):
	var next_dialogue = check_dialogues(ID, 'next')

	if next_dialogue != null && typeof(next_dialogue) == TYPE_ARRAY:
		if _optionSelector >= next_dialogue.size():
			return null
		return next_dialogue[_optionSelector]
	elif next_dialogue != null:	
		return next_dialogue
		
	return null

# this function checks if the dialogue ID goes to another ID once completed
func check_goto(ID):
	return check_dialogues(ID, 'goto')
		
# this function checks if the NPC gives an item
func check_giveItem(ID):
	if !progress.get(dialogues_dict).has(ID):
		return check_dialogues(ID, 'giveItem')
	return null
	
# this function checks if the NPC needs an item
func check_needsItem(ID):
	return check_dialogues(ID, 'needsItem')

# this function checks if the NPC gives a quest at that ID
func check_giveQuest(ID):
	# checks if the json has a quest to give
	var checkquests = check_dialogues(ID, 'giveQuest')
	
	# json has a quest to give
	if checkquests != null:
		# get its quest name
		var questname = checkquests['questName']
		# check the progress of the quest in the singleton
		var quest = progress.get('quests').get(questname, null)
		if quest == null:
			# no quest exists, so save the quest as a progress 
			progress.get('quests')[questname] = "IN_PROGRESS"
			return null
		elif quest == "IN_PROGRESS":
			# quest exists in progress, so do nothing
			return null
		elif quest == "COMPLETED":
			# quest has been completed, return the completion ID
			return checkquests['completedID']
	return null

# this function checks if the NPC completes a quest at that ID
func check_completeQuest(ID) -> void:
	# the function doesn't have to return everything because it just sets
	# the quest progress as completed
	var checkquests = check_dialogues(ID, 'completeQuest')
	if checkquests != null:
		progress.get('quests')[checkquests] = "COMPLETED"
			
func check_dialogues(ID, key):
	if text_dialogue.has(ID):
		return text_dialogue[ID].get(key, null)
	elif repeat_dialogue.has(ID):
		return repeat_dialogue[ID].get(key, null)
	else:
		print("no such ID!")
		return null 
