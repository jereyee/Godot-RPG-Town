extends Camera2D

func set_camera_limits():
	var ground = $"../Ground"
	var groundRect
	if !ground: 
		return
	groundRect = ground.get_rect()
	limit_left = groundRect.position.x + 320
	limit_top = groundRect.position.y + 180
	limit_right = limit_left + groundRect.size.x
	limit_bottom = limit_top + groundRect.size.y
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	set_camera_limits()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
