extends Spatial

var NetworkObjects = {}

var previously_sent_position = Vector3(0,0,0)
var time_since_pos_update = 0

var initialized = false

var peer = StreamPeerTCP.new()

onready var NetworkPlayer = preload("res://NetworkPlayer.tscn")

func send_chat_message(message):
	if peer.get_status() == 2:
		peer.put_u16(4)
		peer.put_utf8_string(message)

func _ready():
	Zephyr.main = self
	print("Connecting...")
	peer.connect_to_host(Zephyr.target_address, Zephyr.target_port)

func _process(_delta):
	if peer.get_status() == 2: # STATUS_CONNECTED
		if peer.get_available_bytes() > 0:
			var code = peer.get_u16()
			match code:
				1: # Server Initialization
					print("Server Init acquired")
					print(peer.get_available_bytes())
					var protocol_version = peer.get_u16()
					if protocol_version == Zephyr.protocol_version:
						initialized = true
						peer.put_u16(2) # send confirmation
				2: # New Player
					var id = peer.get_u32()
					var new_player = NetworkPlayer.instance()
					new_player.network_id = id
					get_parent().add_child(new_player)
					NetworkObjects[id] = new_player
				3: # Update Player
					var id = peer.get_u32()
					var x = float(peer.get_32())/100
					var y = float(peer.get_32())/100
					var z = float(peer.get_32())/100
					if id in NetworkObjects:
						NetworkObjects[id].set_target_pos(Vector3(x,y,z))
				4: # Delete Player
					var id = peer.get_u32()
					if id in NetworkObjects:
						NetworkObjects[id].queue_free()
						NetworkObjects.erase(id)
				5: # Chat Message
					var message = peer.get_utf8_string()
					if len(message) > 0:
						$Chat.display_message(message)
				6: # Damaged
					var amount = peer.get_32()
					Zephyr.player.damage(amount)
		
		if not initialized:
			peer.put_u16(1) # send client hello
	elif peer.get_status() == 3: # STATUS_ERROR
		pass

# TODO: Convert all events to be sent in this manner
func damage_player(network_id, amount):
	peer.put_u16(5) # Damage Player
	peer.put_u32(network_id)
	peer.put_32(amount)

func _physics_process(delta):
	if Zephyr.player != null:
		if time_since_pos_update < 10: # to prevent it from getting overly large
			time_since_pos_update += delta
		var position = Zephyr.player.global_transform.origin
		if position != previously_sent_position and time_since_pos_update > Zephyr.pos_update_interval:
			var x = int(position.x*100)
			var y = int(position.y*100)
			var z = int(position.z*100)
			peer.put_u16(3) # update position
			peer.put_32(x)
			peer.put_32(y)
			peer.put_32(z)
			previously_sent_position = position
			time_since_pos_update = 0
