extends KinematicBody2D

#const ACCELERATION = 500
#const MAX_SPEED = 150
const CLIMB_SPEED = 50
const CLIMB_ACCELERATION = 100
#const FRICTION = 500

const ACCELERATION = 800
const MAX_SPEED = 150
const FRICTION = 700

enum {
	MOVE,
	CLIMB,
	TALKING,
	BUYING
}

enum {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

enum Layer {
	WORLD = 1,
	PLAYER = 2,
	NPC = 3,
	OBJECTS = 4,
	LADDER = 5
}

var state = MOVE
var velocity = Vector2.ZERO
var direction = DOWN
var interact_distance = 20

var can_climb = false

var inventoryList : Dictionary

onready var inventory = $Inventory
onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var NPCLook = $NPCLook
onready var animationState = animationTree.get("parameters/playback")

var playerCamera

signal NPCInteract
signal VendorInteract

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize();
	print(self.get_path())
	
	if playerGlobal.inventoryList != null:
		inventoryList = playerGlobal.inventoryList
	if playerGlobal.direction != null:
		direction = playerGlobal.direction
	if playerGlobal.spawn_location != null:
		global_position = playerGlobal.spawn_location
		
	animationTree.active = true
	set_starting_animation()
	
	if has_node("RemoteTransform2D"):
		playerCamera = $RemoteTransform2D
	if get_tree().get_nodes_in_group('camera').size() >= 1:
		playerCamera.remote_path = get_tree().get_nodes_in_group('camera')[0].get_path()
	
	#print(get_collision_mask())
	
func set_starting_animation():
	var startingVector
	match direction:
		UP:
			startingVector = Vector2(0, -1)
		DOWN:
			startingVector = Vector2(0, 1)
		LEFT:
			startingVector = Vector2(-1, 0)
		RIGHT:
			startingVector = Vector2(0, 1)
	animationTree.set("parameters/Idle/blend_position", startingVector)
		
	
func add_item_to_inventory(item, qty = 1):
	print("adding item to inventory")
	print(qty)
	if inventoryList.has(item.itemID):
		inventoryList[item.itemID]["quantity"] += qty
	else:
		inventoryList[item.itemID] = {"itemType": item.itemType}
		inventoryList[item.itemID]['quantity'] = qty
	playerGlobal.inventoryList = inventoryList
	item.queue_free()
	#inventory.add_child(item)
	pass

func remove_item_from_inventory(item, qty = 1):
	print("removing item from inventory")
	print(qty)
	if inventoryList.has(item['itemID']):
		inventoryList[item.itemID]["quantity"] -= qty
		if inventoryList[item['itemID']]['quantity'] <= 0:
			inventoryList.erase(item['itemID'])
	playerGlobal.inventoryList = inventoryList
	#inventory.add_child(item)
	pass

func check_inventory(item):
	print("checking items")
	var check = inventoryList.has(item['itemID'])
	return check

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
			check_npc_interact(delta)
		CLIMB:
			climb_state(delta)
		TALKING:
			
			pass
		BUYING:
			pass
	check_ladder(delta)
	
func climb_state(delta):
	match direction:
		UP:
			NPCLook.rotation_degrees = -180
		DOWN:
			NPCLook.rotation_degrees = 0
	var input_vector = Vector2.ZERO
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
		
	velocity = velocity.move_toward(input_vector * CLIMB_SPEED, CLIMB_ACCELERATION * delta)
	animationTree.set("parameters/Idle/blend_position", Vector2(0, -1))
	move()
	checkVelocity(input_vector)

func check_ladder(delta):
	if NPCLook.is_colliding():
		var collision = NPCLook.get_collider()
		if collision is Area2D:
			if collision.objectType == 1:
				can_climb = true
	else:
		can_climb = false
	
	if can_climb && state == MOVE:
		if (Input.is_action_just_pressed("ui_up") && direction == UP) || (Input.is_action_just_pressed("ui_down") && direction == DOWN):
			print("climbing ladder")
			animationState.start("Idle")
			$CollisionShape2D.disabled = true
			state = CLIMB
	elif !can_climb && state == CLIMB:
		var set_vector
		if Input.is_action_pressed("ui_down") && direction == DOWN:
			set_vector = Vector2(0, 1)
		elif Input.is_action_pressed("ui_up") && direction == UP:
			set_vector = Vector2(0, -1)
		print("exited ladder")
		animationTree.set("parameters/Idle/blend_position", set_vector)
		$CollisionShape2D.disabled = false
		state = MOVE
			

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	
	if input_vector != Vector2.ZERO:
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		if !animationState.is_playing():
			animationState.start("Run")
		else:
			animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		#print(animationState.is_playing())
		if animationState.get_current_node() != "Idle":
			animationState.start("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	if velocity != Vector2.ZERO:
		move()
	checkVelocity(input_vector)
	
	
func check_npc_interact(delta):
	match direction:
		UP:
			NPCLook.rotation_degrees = -180
		DOWN:
			NPCLook.rotation_degrees = 0
		LEFT:
			NPCLook.rotation_degrees = 90
		RIGHT:
			NPCLook.rotation_degrees = -90
	
	if Input.is_action_just_pressed("talk") && NPCLook.is_colliding() && state != TALKING:
		Input.action_release("talk")
		var collision = NPCLook.get_collider()
		if collision is KinematicBody2D:
			var NPC = collision
			animationState.start("Idle")
			emit_signal("NPCInteract", NPC, global_position, delta)
		elif collision is Area2D:
			# OBJECT TYPES:
			# 0: GIVEITEM
			# 1: LADDER
			# 2: VENDOR
			if collision.objectType == 0:
				collision._on_player_interaction()
			elif collision.objectType == 2:
				# VENDOR_SHOP:
				# 0: NONE
				# 1: ITEMSHOP
				# 2: WEAPONSHOP
				state = BUYING
				animationState.start("Idle")
				emit_signal("VendorInteract", collision.get_parent(), global_position, delta)
				pass

func set_talking():
	state = TALKING
	
func set_move():
	state = MOVE
	
func move():
	velocity = move_and_slide(velocity)
	
func checkVelocity(vector):
	if vector.x < 0:
		direction = LEFT
	elif vector.x > 0:
		direction = RIGHT
	elif vector.y < 0:
		direction = UP
	elif vector.y > 0:
		direction = DOWN
	
