extends KinematicBody

onready var camera = $Camera
onready var pause_menu = $PauseMenu
onready var fire = $Camera/Pistol/Fire

var sensitivity = 0.002
var speed = 12
var jump_velocity = 8

var enabled = true

var strafe_multiplier = 0.5

var velocity = Vector3()

var gravity = 16

var time_since_on_floor = 0

var forgiving_jump_time = 0.1

var time_since_fire = 0
var fire_delay = 0.2
var damage_per_shot = 20

var is_fire_visible = false
var duration_fire_visible = 0.1

var health = Zephyr.base_health

var mouse_captured = false

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	if event is InputEventMouseMotion and mouse_captured:
		self.rotate(Vector3(0, 1, 0), -event.relative.x*sensitivity)
		if abs(camera.rotation_degrees.x-event.relative.y*sensitivity) < 90:
			camera.rotate(Vector3(1, 0, 0), -event.relative.y*sensitivity)
	if Input.is_action_just_pressed("fire") and mouse_captured and enabled:
		if time_since_fire >= fire_delay:
			time_since_fire = 0
			var collider = Zephyr.raycast.get_collider()
			if collider:
				if collider.to_string() == "NetworkPlayer":
					var network_id = collider.network_id
					Zephyr.main.damage_player(network_id, damage_per_shot)
			fire.show()
			is_fire_visible = true

func capture_mouse():
	pause_menu.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	pause_menu.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _ready():
	Zephyr.player = self
	capture_mouse()

func _physics_process(delta):
	if time_since_fire < 100:
		time_since_fire += delta
	if is_fire_visible and (time_since_fire > duration_fire_visible):
		fire.hide()
		is_fire_visible = false
	if self.is_on_floor():
		time_since_on_floor = 0
		velocity = Vector3()
		if enabled:
			if Input.is_action_pressed("forward"):
				velocity += -self.get_global_transform().basis.z.normalized()*speed
			if Input.is_action_pressed("backward"):
				velocity += self.get_global_transform().basis.z.normalized()*speed
			if Input.is_action_pressed("left"):
				velocity += -self.get_global_transform().basis.x.normalized()*speed*strafe_multiplier
			if Input.is_action_pressed("right"):
				velocity += self.get_global_transform().basis.x.normalized()*speed*strafe_multiplier
	else:
		time_since_on_floor += delta
		velocity.y -= gravity*delta
		
	if Input.is_action_pressed("jump") and (self.is_on_floor() or time_since_on_floor < forgiving_jump_time):
		if enabled:
			velocity += Vector3(0, jump_velocity, 0)
			time_since_on_floor = forgiving_jump_time + 1
	
	self.move_and_slide(velocity, Vector3(0,1,0))

func set_health(value):
	health = value
	Zephyr.healthbar.value = (float(health) / Zephyr.base_health) * 100

func damage(amount):
	set_health(health - amount)
	if health <= 0:
		death()
		
func death():
	self.translation = Zephyr.respawn_point.translation
	set_health(Zephyr.base_health)
