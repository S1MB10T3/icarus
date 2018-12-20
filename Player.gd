extends KinematicBody

# Walking variables.
# This manages how fast we are moving, fast we can walk,
# how quickly we can get to top speed, how strong gravity is, and how high we jump.
const GRAVITY = -30
var vel = Vector3()
const MAX_SPEED = 35
const JUMP_SPEED = 18
const ACCEL= 4.5

# A vector for storing the direction the player intends to move towards.
var dir = Vector3()

# Sprinting variables. Similar to the varibles above for walking,
# but these are used when sprinting (so they should be faster/higher)
const MAX_SPRINT_SPEED = 15
const SPRINT_ACCEL = 8
# A boolean to track if we are spriting

var will_dash = false 

# How fast we slow down, and the steepest angle that counts as a floor (to the KinematicBody).
const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

var resOn = false
# The camera and the rotation helper.
# We need the camera to get its directional vectors.
#We rotate ourselves on the Y-axis using the rotation_helper to avoid rotating on more than one axis at a time.
var camera
var rotation_helper

# The sensitivity of the mouse
# (Higher values equals faster movements with the mouse. Lower values equals slower movements with the mouse)
# (You may need to adjust depending on the sensitivity of your mouse)
var MOUSE_SENSITIVITY = 0.05

var animation_manager

# Weapon variables.
# The name of the weapon we are currently using
var current_weapon_name = "KNIFE"
# A dictionary of all the weapons we have
var weapons = {"UNARMED":null, "KNIFE":null, "PISTOL":null, "RIFLE":null}
# A dictionary containing the weapons names and which number they use
const WEAPON_NUMBER_TO_NAME = {0:"UNARMED", 1:"KNIFE", 2:"PISTOL", 3:"RIFLE"}
const WEAPON_NAME_TO_NUMBER = {"UNARMED":0, "KNIFE":1, "PISTOL":2, "RIFLE":3}
# A boolean to track if we are changing weapons
var changing_weapon = true
# The name of the weapon we want to change to, if we are changing weapons
var changing_weapon_name = "KNIFE"
# A boolean to track if we are reloading
var reloading_weapon = false


# The amount of health we currently have
var health = 100
# The amount of health we have when fully healed
const MAX_HEALTH = 100
# The amount of time (in seconds) required to respawn
const RESPAWN_TIME = 4
# A variable to track how long we've been dead
var dead_time = 0
# A variable to track whether or not we are currently dead
var is_dead = false

var regen_timer = 0

# The label for how much health we have, how many grenades we have,
# and how much ammo is in our current weapon (along with how much ammo we have in reserve for that weapon)
var UI_status_label
var UI_health_label
var UI_ability_1
var UI_ability_2
var UI_ability_3
var UI_gear_ability
var UI_ult_ability

# The flashlight spotlight
var flashlight

var grabbed_object = null
# The amount of force we throw grabbed objects at
const OBJECT_THROW_FORCE = 120
# The distance we hold grabbed objects at
const OBJECT_GRAB_DISTANCE = 7
# The distance of our grabbing raycast
const OBJECT_GRAB_RAY_DISTANCE = 10

var ability_one_timer = 0
var ability_two_timer = 0
var ability_three_timer = 0
var gear_ability_timer = 0
var ultimate_ability_timer = 0
var ability_three_effect_timer = 0

var globals


func _ready():
	# Get the camera and the rotation helper
	camera = $Rotation_Helper/Camera
	rotation_helper = $Rotation_Helper
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	MOUSE_SENSITIVITY = globals.mouse_sensitivity

func _physics_process(delta):	
	pass

func process_input(delta):
	# Reset dir, so our previous movement does not effect us
	dir = Vector3()
	# Get the camera's global transform so we can use its directional vectors
	var cam_xform = camera.get_global_transform()
	
	# Create a vector for storing our keyboard/joypad input
	var input_movement_vector = Vector2()
	
	# Add keyboard input
	if Input.is_action_pressed("movement_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x = 1
	
	input_movement_vector = input_movement_vector.normalized()
	
	dir += -cam_xform.basis.z.normalized() * input_movement_vector.y
	dir += cam_xform.basis.x.normalized() * input_movement_vector.x
	
	if is_on_floor():
		if Input.is_action_just_pressed("movement_jump"):
			vel.y = JUMP_SPEED
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("ability_one"):
		if ability_one_timer <= 0:
			var missingHealth = (MAX_HEALTH - health)
			var healthToHeal = (35 * missingHealth) / 100
			health += healthToHeal
			ability_one_timer = 20

	if Input.is_action_just_pressed("ability_two"):
		if ability_two_timer <= 0:
			# Based on which grenade we are using, instance it and assign it to grenade_clone
			var grenade_clone
			if (current_grenade == "Grenade"):
				grenade_clone = grenade_scene.instance()
			elif (current_grenade == "Sticky Grenade"):
				grenade_clone = sticky_grenade_scene.instance()
				# Sticky grenades will stick to the player if we do not pass ourselves
				grenade_clone.player_body = self
			
			# Add the grenade as a child, position it correctly, and apply an impulse so we are throwing it
			get_tree().root.add_child(grenade_clone)
			grenade_clone.global_transform = $Rotation_Helper/Grenade_Toss_Pos.global_transform
			grenade_clone.apply_impulse(Vector3(0,0,0), grenade_clone.global_transform.basis.z * GRENADE_THROW_FORCE)
			ability_two_timer = 8
		
		if Input.is_action_just_pressed("ability_three"):
			if ability_three_timer <= 0:
				resOn = true
				ability_three_effect_timer = 10
				ability_three_timer = 15
		
		if Input.is_action_just_pressed("gear_ability"):
			if gear_ability_timer <= 0:
				will_dash = true
				gear_ability_timer = 2

				
func process_view_input(delta):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()
	
	# Apply gravity
	vel.y += delta*GRAVITY
	
	# Set our velocity to a new variable (hvel) and remove the Y velocity.
	var hvel = vel
	hvel.y = 0
	
	# Based on whether we are sprinting or not, set our max speed accordingly.
	var target = dir
	if will_dash:
		target *= 75
	else:
		target *= MAX_SPEED
	
	
	# If we have movement input, then accelerate.
	# Otherwise we are not moving and need to start slowing down.
	var accel
	if dir.dot(hvel) > 0:
		# We should accelerate faster if we are sprinting
		if will_dash:
			accel = 75
			will_dash = false
		else:
			accel = ACCEL
	else:
		accel = DEACCEL
	
	# Interpolate our velocity (without gravity), and then move using move_and_slide
	hvel = hvel.linear_interpolate(target, accel*delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel,Vector3(0,1,0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))


func process_health_regen(delta):
	if regen_timer > 0:
		regen_timer -= delta
	else:
		health += 5
		health = clamp(health, 0, MAX_HEALTH)
		regen_timer = 1

func process_cooldowns(delta):
	if ability_one_timer > 0:
		ability_one_timer -= delta
	if ability_two_timer > 0:
		ability_two_timer -= delta
	if ability_three_timer > 0:
		ability_three_timer -= delta
	if ability_three_effect_timer > 0:
		ability_three_effect_timer -= delta
	if ability_three_effect_timer == 0:
		resOn = false
	if gear_ability_timer > 0:
		gear_ability_timer -= delta
	if ultimate_ability_timer > 0:
		gear_ability_timer -= delta


func bullet_hit(damage, bullet_hit_pos):
	# Removes damage from our 
	if resOn == true:
		health -= damage - 5
		regen_timer = 5
	else:
		health -= damage
		regen_timer = 5