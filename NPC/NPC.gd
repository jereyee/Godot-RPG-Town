extends KinematicBody2D

export(String) var NPCName
export var hasQuest = false
export(String) var ID;
export var stationary = false

onready var playerInteract = get_tree().get_nodes_in_group("player")[0]

onready var sprite = $AnimatedSprite
onready var wanderController = $WanderController
enum {
	IDLE,
	WANDER,
	WALK,
	TALKING
}

enum {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

enum vendorShop {
	NONE,
	ITEMSHOP,
	WEAPONSHOP
}
export(vendorShop) var vendor_shop = vendorShop.NONE
export(String) var vendorGreetings setget greetings_setter
export(Array, String) var vendorItems


export var WANDER_TARGET_RANGE = 4
export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200
export var items_held = []
export var CUTSCENE = false

var direction = DOWN
var state = IDLE
var velocity = Vector2.ZERO


func greetings_setter(greetings):
	if vendor_shop == vendorShop.NONE:
		return
	vendorGreetings = greetings
	

func check_items_held(item):
	var check = items_held.has(item['itemName'])
	return check
	

# Called when the node enters the scene tree for the first time.
func _ready():
	#if playerInteract:
		#playerInteract.connect("NPCInteract", self, "face_direction")
	if !stationary:
		state = pick_random_state([IDLE, WANDER])
	var node = playerGlobal.interactedNPCs.get(get_path(), null)
	if node != null:
		ID = node.ID
	playAnimation("Idle")

func _physics_process(delta):
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			checkDirection(velocity)
			#playAnimation("Idle")
			
			if wanderController.get_time_left() == 0 && !stationary:
				update_wander()
		WANDER:
			if wanderController.get_time_left() == 0:
				state = pick_random_state([IDLE, WANDER])
				wanderController.start_wander_timer(rand_range(1, 3))
			
			accelerate_towards_point(wanderController.target_position, delta)
			
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				update_wander()
			checkDirection(velocity)
			playAnimation("Walk")
		TALKING:
			pass
			

	#if softCollision.is_colliding():
		#velocity += softCollision.get_push_vector() * delta * 400
	
	velocity = move_and_slide(velocity)

func playAnimation(animation):
	match direction:
		UP:
			sprite.play(animation + "Up")
		DOWN:
			sprite.play(animation + "Down")
		LEFT:
			sprite.play(animation + "Left")
			sprite.flip_h = false
		RIGHT:
			sprite.play(animation + "Left")
			sprite.flip_h = true

func checkDirection(vector):
	if vector.x < 0:
		direction = LEFT
	elif vector.x > 0:
		direction = RIGHT
	elif vector.y < 0:
		direction = UP
	elif vector.y > 0:
		direction = DOWN
			
func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()	

func set_wander():
	# saves the dialogue state of the NPC
	var NPCData = {"ID": ID}
	playerGlobal.interactedNPCs[get_path()] = NPCData
	
	if stationary == true:
		state = IDLE
		return
	update_wander()

func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))
	
func accelerate_towards_point(point, delta):
	var direction_towards = global_position.direction_to(point)
	velocity = velocity.move_toward(direction_towards * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0

func face_direction(NPC, player_position, _delta):
	if NPC == self && state != TALKING:
		var vectorTurn = -(global_position - player_position).normalized()
		var vectorAbs = abs(vectorTurn.x) - abs(vectorTurn.y)
		if vectorAbs < 0:
			vectorTurn = Vector2(0, vectorTurn.y)
		elif vectorAbs > 0:
			vectorTurn = Vector2(vectorTurn.x, 0)
		checkDirection(vectorTurn)
		playAnimation("Idle")
		velocity = Vector2.ZERO
		state = TALKING

func _on_AnimatedSprite_animation_finished():
	if CUTSCENE == true: return
	playAnimation("Idle")
