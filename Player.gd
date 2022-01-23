extends RigidBody
class_name Player

onready var body = $Body
onready var head = $Body/Head
onready var camera = $Body/Head/Camera
onready var raycast = $Body/Head/RayCast
onready var portal_gun = $Body/Head/Camera/PortalGun

onready var collision_shape = $CollisionShape
onready var mesh_instance = $Body/MeshInstance

var camera_x_rotation = 0

const mouse_sensitivity = 0.3
const movement_speed = 5
const acceleration = 100
const gravity_magnitude = 9.8
const jump_impulse = 5
const air_modifier = 0.1
const air_friction_modifier = 0.05

var direction = Vector3()

var paused = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if Input.is_action_just_pressed("Pause"):
		paused = not paused
		if paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if paused:
		return
	
	if event is InputEventMouseMotion:
		head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		
		var delta_x = event.relative.y * mouse_sensitivity
		if camera_x_rotation + delta_x > -90 and camera_x_rotation + delta_x < 90:
			camera.rotate_x(deg2rad(-delta_x))
			camera_x_rotation += delta_x
	
	var basis = head.get_global_transform().basis
	direction = Vector3()
	
	if Input.is_action_pressed("Forward"):
		direction -= basis.z
	if Input.is_action_pressed("Backward"):
		direction += basis.z
	if Input.is_action_pressed("Left"):
		direction -= basis.x
	if Input.is_action_pressed("Right"):
		direction += basis.x
	
	direction = direction.normalized()

func _integrate_forces(_state):
	# Movement
	var speed = linear_velocity.length()
	
	# Get speed in direction of movement (direction always normalized)
	var speed_in_direction = linear_velocity.dot(direction)
	var modifier = 0
	if speed_in_direction < movement_speed:
		modifier = acceleration
	if not is_on_floor():
		modifier *= air_modifier
	
	# Friction
	var friction = Vector3()
	if speed != 0:
		friction = linear_velocity.normalized() * -speed / movement_speed * 50
	if not is_on_floor():
		friction *= air_friction_modifier
	
	# Gravity
	var gravity = -gravity_magnitude
	
	var force = Vector3()
	force.z = direction.z * modifier + friction.z
	force.x = direction.x * modifier + friction.x
	force.y = gravity
	
	add_central_force(force)
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		apply_central_impulse(Vector3.UP * jump_impulse)

func _process(delta):
	if global_transform.origin.y < -10:
		global_transform.origin = Vector3(0, 5, 0)
	
	var fps = Engine.get_frames_per_second()
	var physics_fps = ProjectSettings.get_setting("physics/common/physics_fps")
	var lerp_interval = direction / fps
	var lerp_position = global_transform.origin + lerp_interval
	
	if fps > physics_fps:
		body.set_as_toplevel(true)
		body.global_transform.origin = body.global_transform.origin.linear_interpolate(lerp_position, 40 * delta)
	else:
		body.global_transform = global_transform
		body.set_as_toplevel(false)
	
	# If it isn't upright try to make it upright
	var basis_up = Quat(global_transform.basis)
	var up = Quat(Basis(global_transform.basis.x, Vector3.UP, global_transform.basis.z))
	var change = basis_up.inverse() * up
	var angle = 2 * acos(change.w)
	
	if angle >= 0.01:
		# Unlock axes
		axis_lock_angular_x = false
		axis_lock_angular_z = false
		
		var torque = Vector3.ZERO
		torque = (1 / sin(angle / 2)) * Vector3(change.x, change.y, change.z)
		add_torque(torque * 10 * angle)
	elif not axis_lock_angular_x:
		global_transform.basis = Basis(global_transform.basis.x, Vector3.UP, global_transform.basis.z)
		axis_lock_angular_x = true
		axis_lock_angular_z = true

func is_on_floor():
	return raycast.is_colliding()










