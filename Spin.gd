extends Spatial

var speed = 0.1

func _process(delta):
	rotate(Vector3(0,1,0), speed*delta)
