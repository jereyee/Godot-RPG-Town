extends AnimationPlayer

onready var soldier = $"../YSort/SOLDIER"
onready var player = $"../YSort/TileMap/Player"
onready var dialogue = $"../CanvasLayer/UI/DialogueBox"

enum POINTS {
	SOLDIER_WALK_DOWN,
	SOLDIER_WALK_RIGHT,
	SOLDIER_WALK_UP,
	FINISHED
}

var tween
var cutscenePoints

# Called when the node enters the scene tree for the first time.
func _ready():
	if playerGlobal.cutscenes.has(get_path()):
			soldier.stationary = false
			soldier.update_wander()
			self.queue_free()
			return

	play("Cutscene")
	if connect("animation_finished", self, "changeValues") != OK:
		print("error connecting animation finished to changeValues")

func changeValues(_anim_name):	
	soldier.direction = 0
	dialogue.show_dialogue(soldier, soldier.position, 0)
	playerGlobal.cutscenes.append(get_path())
	
	self.queue_free()
#	return
#	player.state = 2
#
#	tween = Tween.new()
#	soldier.add_child(tween)
#	cutscenePoints = POINTS.SOLDIER_WALK_DOWN
#
#
#var tweening = false
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	match cutscenePoints:
#		POINTS.SOLDIER_WALK_DOWN:
#			soldier.sprite.play("WalkDown")
#			tween.interpolate_property(soldier, "global_position",
#			soldier.global_position, soldier.global_position + Vector2(0, 130), 1,
#			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
#			tween.start()
#			yield(tween, "tween_completed")
#			cutscenePoints = POINTS.SOLDIER_WALK_RIGHT
#			tween.stop_all()
#
#		POINTS.SOLDIER_WALK_RIGHT:
#			soldier.sprite.play("WalkLeft")
#			soldier.sprite.flip_h = true
#			tween.interpolate_property(soldier, "global_position",
#			soldier.global_position, soldier.global_position + Vector2(150, 0), 1,
#			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
#			tween.start()
#			yield(tween, "tween_completed")
#			cutscenePoints = POINTS.SOLDIER_WALK_UP
#			tween.stop_all()
#
#		POINTS.SOLDIER_WALK_UP:
#			soldier.sprite.play("WalkUp")
#			tween.interpolate_property(soldier, "global_position",
#			soldier.global_position, soldier.global_position + Vector2(3, -35), 0.5,
#			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
#			tween.start()
#			yield(tween, "tween_completed")
#			cutscenePoints = POINTS.FINISHED
#			tween.stop_all()
#
#		POINTS.FINISHED:
#			soldier.sprite.play("IdleUp")
#			soldier.velocity = Vector2.ZERO
#			soldier.direction = 0
#			playerGlobal.cutscenes.append(get_path())
#			dialogue.show_dialogue(soldier, soldier.position, delta)
#			self.queue_free()
			
