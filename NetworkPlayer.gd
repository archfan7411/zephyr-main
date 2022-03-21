extends Spatial


var target_pos = Vector3(0,0,0)

var network_id = null

var total = 0

func set_target_pos(vector):
	target_pos = vector
	total = 0

func _process(delta):
	total += delta
	if total >= 0.1:
		return
	global_transform.origin = global_transform.origin.linear_interpolate(target_pos, total/Zephyr.pos_update_interval)

func to_string():
	return "NetworkPlayer"
