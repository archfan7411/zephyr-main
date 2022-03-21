extends Label

var time_since_message = 0
var time_before_fade = 7
var fade_time = 2
var chat_open = false

func display_message(message):
	time_since_message = 0
	self.text = message + "\n" + self.text
	Zephyr.history.text = message + "\n" + Zephyr.history.text
	self.self_modulate.a = 1

func _process(delta):
	var input = Zephyr.input
	var history = Zephyr.history
	if Input.is_action_pressed("open_chat"):
		self.hide()
		input.show()
		input.grab_focus()
		history.show()
		Zephyr.player.enabled = false
	elif Input.is_action_pressed("open_chat_with_slash"):
		self.hide()
		input.show()
		input.text = "/"
		input.grab_focus()
		history.show()
		input.caret_position = 1
		Zephyr.player.enabled = false
	elif Input.is_action_pressed("close_chat"):
		self.show()
		input.hide()
		history.hide()
		input.text = ""
		Zephyr.player.enabled = true
	elif Input.is_action_pressed("send_chat"):
		Zephyr.main.send_chat_message(input.text)
		self.show()
		input.hide()
		history.hide()
		input.text = ""
		Zephyr.player.enabled = true
	
	if time_since_message < time_before_fade + fade_time:
		time_since_message += delta
	else:
		return
	
	if time_since_message > time_before_fade:
		var proper_alpha = (1-((time_since_message-time_before_fade)/fade_time))
		if proper_alpha < 0:
			proper_alpha = 0
			self.text = ""
		self.self_modulate.a = proper_alpha
		
