extends KinematicBody

var speed = 10

var enabled = true

func _ready():
	Zephyr.player = self

func _process(delta):
	if enabled:
		if Input.is_key_pressed(KEY_W):
			move_and_slide(Vector3(0,0,-speed))
		if Input.is_key_pressed(KEY_S):
			move_and_slide(Vector3(0,0,speed))
		if Input.is_key_pressed(KEY_A):
			move_and_slide(Vector3(-speed,0,0))
		if Input.is_key_pressed(KEY_D):
			move_and_slide(Vector3(speed,0,0))
