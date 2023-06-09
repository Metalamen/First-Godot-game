extends CharacterBody3D

@onready var camera_3d = $Camera3D
@onready var origCamPos : Vector3 = camera_3d.position
@onready var floorcast = $FloorDetectRayCast3D
@onready var player_footstep_sound = $PlayerFootstepSound
@onready var interact_raycast = $Camera3D/InteractRaycast
@onready var interact_label = $InteractLabel
@onready var crosshair = $Control/Crosshair
@onready var health = $Health
@onready var weapon_manager = $Camera3D/WeaponManager

var hotkeys = {
	KEY_1 : 0,
	KEY_2 : 1,
	KEY_3 : 2,
	KEY_4 : 3,
	KEY_5 : 4,
	KEY_6 : 5,
	KEY_7 : 6,
	KEY_8 : 7,
	KEY_9 : 8,
	KEY_0 : 9,
}


var dead = false
var mouse_sens := 0.15
var direction = Vector3.ZERO
var speed := 3 
var jump_ := 3
const gravity = 5

var isRunning := false
var distanceFootstep := 0.0
var playFootstep := 1

var _delta := 0.0
var camSpeed := 10 #10
var camUpDown := 1 #0.5

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$MeshInstance3D.visible = false
	health._init()
	if dead: return

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		camera_3d.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	if Input.is_action_just_pressed("run"):
		isRunning = true
	if Input.is_action_just_released("run"):
		isRunning = false
	
	if Input.is_action_just_pressed("interact"):
		var interacted = interact_raycast.get_collider()
		if interacted != null and interacted.is_in_group("Interactable") and interacted.has_method("action_use"):
			interacted.action_use()
	
	if Input.is_action_just_pressed("slot1"):
		weapon_manager.switch_to_weapon_slot(0)
	if Input.is_action_just_pressed("slot2"):
		weapon_manager.switch_to_weapon_slot(1)
	if Input.is_action_just_pressed("slot3"):
		weapon_manager.switch_to_weapon_slot(2)
	if Input.is_action_just_pressed("slot4"):
		weapon_manager.switch_to_weapon_slot(3)

func _process(delta):

	_physics_miscare(delta)
	_procesare_miscare(delta)
	if floorcast.is_colliding():
		var walkingTerrain = floorcast.get_collider().get_parent()
		if walkingTerrain != null and walkingTerrain.get_groups().size() > 0:
			var terraingroup = walkingTerrain.get_groups()[0]
			#print(terraingroup)
			_processGroundSounds(terraingroup)
	_label_dispaly()
			
func _label_dispaly():
	if interact_raycast.is_colliding():
		if is_instance_valid(interact_raycast.get_collider()):
			if interact_raycast.get_collider().is_in_group("Interactable"):
				interact_label.text = interact_raycast.get_collider().type
				interact_label.visible = true
				crosshair.hide()
			else:
				interact_label.visible = false
				crosshair.show()
	else:
		interact_label.visible = false
		crosshair.show()


func _processGroundSounds(group: String):
	
	if isRunning:
		playFootstep = 1 #mai repede cu cat valoarea este mai mica
	else:
		playFootstep = 3
	
	if  (int(velocity.x)!= 0) || int(velocity.z) != 0:
		distanceFootstep += .1
	
	if distanceFootstep > playFootstep and is_on_floor():
		match group:
			"WoodTerrain":
				player_footstep_sound.stream = load("res://Sounds/concrete-footsteps-6752 render 001.wav")
			#in caz ca doresc sa mai adaug un sunet specific pentru alta grupa, gen iarba 
			#"GrassTerrain":
			#	player_footstep_sound.stream = load("res://Sounds/concrete-footsteps-6752 render 001.wav")
		player_footstep_sound.pitch_scale=randf_range(.8,1.2)
		player_footstep_sound.play()
		distanceFootstep = 0.0



func _physics_miscare(delta):
	_delta += delta
	var cam_bob
	var objCam
	
	if isRunning:
		cam_bob = floor(abs(direction.z) + abs(direction.x)) * _delta * camSpeed * 10
		objCam = origCamPos + Vector3.UP * sin(cam_bob) * camUpDown
	if direction != Vector3.ZERO:
		cam_bob = floor(abs(direction.z) + abs(direction.x)) * _delta * camSpeed
		objCam = origCamPos + Vector3.UP * sin(cam_bob) * camUpDown
	else:
		cam_bob = floor(abs(1)+ abs(1)) * _delta * .6
		objCam = origCamPos + Vector3.UP * sin(cam_bob) * camUpDown * .1
	camera_3d.position = camera_3d.position.lerp(objCam, delta)

func _procesare_miscare(delta):
	direction = Vector3.ZERO
	var h_rot = global_transform.basis.get_euler().y
	direction.x = -Input.get_action_strength("ui_left") + Input.get_action_strength("ui_right")
	direction.z = -Input.get_action_strength("ui_up") + Input.get_action_strength("ui_down")
	direction = Vector3(direction.x, 0, direction.z).rotated(Vector3.UP, h_rot).normalized()
	var actualSpeed

	if isRunning:
		actualSpeed = speed * 2.5
	else:
		actualSpeed = speed
	
	velocity.x = direction.x * actualSpeed
	velocity.z = direction.z * actualSpeed
	
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_ 
			hurt(50) # Apply jump force
		else:
			velocity.y = 0  # Reset vertical velocity when on the floor and not jumping
	else:
		velocity.y -= gravity * delta  # Apply gravity
	
	move_and_slide() 	 # Move the character and slide on slopes

func hurt(damage):
	health.hurt(damage)
	
func heal(amount):
	health.heal(amount)

func kill():
	dead = true
	
