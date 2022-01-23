extends Sprite3D
tool

export(NodePath) var linked_portal_path
var linked_portal

onready var viewport = $Viewport
onready var camera_base = $Viewport/CameraBase
onready var camera = $Viewport/CameraBase/Camera
export var size = Vector2(100, 100) setget set_size
export var portal_colour = Color.cyan

onready var particles = $CPUParticles

onready var player = get_parent().get_node("Player")

onready var area = $Area

var up = Vector3.UP

var _portal_scale = 0

# Dictionary body -> its copy
var copies = {}

var _viewport_size = Vector2(
		ProjectSettings.get("display/window/size/width"),
		ProjectSettings.get("display/window/size/height")
	)


# Called when the node enters the scene tree for the first time.
func _ready():
	viewport.size = _viewport_size
	texture = viewport.get_texture()
	camera.transform = self.transform
	camera.translation -= transform.basis.z
	camera.rotate_y(PI)
	
	linked_portal = get_node(linked_portal_path)
	
	# Duplicate the material immediately
	material_override = material_override.duplicate(0)
	material_override.set_shader_param("portal_colour", portal_colour)
	
	var mesh = particles.mesh
	particles.mesh = mesh.duplicate(0)
	var mat = particles.mesh.surface_get_material(0).duplicate()
	particles.mesh.surface_set_material(0, mat)
	particles.mesh.surface_get_material(0).albedo_color = portal_colour

var _is_set_up = false
func setup():
	# check for static bodies and remove their collision (if they are behind the portal)
	_is_set_up = true
	for body in area.get_overlapping_bodies():
		if body is StaticBody and global_transform.xform_inv(body.global_transform.origin).z <= 0:
			body.set_collision_layer_bit(0, false)
			body.set_collision_mask_bit(0, false)
			
			body.set_collision_layer_bit(1, true)
			body.set_collision_mask_bit(1, true)
	particles.restart()
	particles.emitting = true
	_portal_scale = 0
	up = global_transform.basis.y

func reset():
	# Gives collisions back
	for body in area.get_overlapping_bodies():
		if body is StaticBody:
			body.set_collision_layer_bit(0, true)
			body.set_collision_mask_bit(0, true)
			
			body.set_collision_layer_bit(1, false)
			body.set_collision_mask_bit(1, false)

func set_size(s):
	if Engine.is_editor_hint():
		size = s
		region_rect.position = Vector2(
			(_viewport_size.x - size.x) / 2,
			(_viewport_size.y - size.y) / 2
		)
		region_rect.size = s


func _process(delta):
	if _portal_scale < 1.0:
		_portal_scale += delta
	
	if not _is_set_up:
		setup()
	
	if linked_portal != null:
		var d = (linked_portal.global_transform.origin - camera.global_transform.origin).length()
		camera.near = clamp(d, 0.05, camera.far)
		
		material_override.set_shader_param("viewport_texture", viewport.get_texture())
		material_override.set_shader_param("scale", _portal_scale)
		texture = viewport.get_texture()
		
		# Get player camera position relative to the portal
#		if camera in player: # else it keeps throwing stupid errors
		var relative_transform = global_transform.inverse() * player.camera.global_transform
		# Rotate it 180 degrees
		relative_transform = relative_transform.rotated(up, PI)
		# Move the camera to be at this position relative to the other portal
		camera.global_transform = linked_portal.global_transform * relative_transform
	
	if area != null:
		# Check if any bodies have left
		for body in copies.keys():
			if not area.get_overlapping_bodies().has(body):
				_body_exited(body)
		
		# Check if any entered and process those that are in
		for body in area.get_overlapping_bodies():
			# We only want to copy RigidBody that are not already copied/copies
			if not copies.keys().has(body) and body is RigidBody and not copies.values().has(body):
				_body_entered(body)
			
			# Sync the copies movement with the original
			if copies.keys().has(body):
				_process_copy(body)



func _process_copy(body):
	var copy = copies[body]
	
	# Get body position relative to the portal
	var relative_transform = global_transform.inverse() * body.global_transform
	# Rotate it 180 degrees
	relative_transform = relative_transform.rotated(up, PI)
	# Move the copy to be at this position relative to the other portal
	copy.global_transform = linked_portal.global_transform * relative_transform
	
	# If the original object is halfway through the portal swap it with the copy
	if global_transform.xform_inv(body.global_transform.origin).z < 0.0:
		_swap_bodies(body, copy)


func _swap_bodies(body, copy):
	var swap = body.global_transform
	body.global_transform = copy.global_transform
	copy.global_transform = swap
	
	# It is leaving this one and entering the other
	_body_exited(body)
	linked_portal._body_entered(body)
	
	# For the player we want to move its head to be oriented properly
	if body is Player:
		# Need the axis and angle between the transforms of the two portals
		var a = Quat(global_transform.basis)
		var b = Quat(linked_portal.global_transform.basis.rotated(linked_portal.up, PI))
		
		var diff = b.inverse() * a
		
		var angle = 2 * acos(diff.w)
		if angle != 0:
			var axis = (1 / sin(angle / 2)) * Vector3(diff.x, diff.y, diff.z)
		
#				var t = body.head.get_global_transform()
#				t.basis = t.basis.rotated(axis, angle)
#				t.basis.y = Vector3.UP
#				body.head.set_global_transform(t)
			body.direction = body.direction.rotated(axis, angle)
			#body.linear_velocity = body.linear_velocity.rotated(axis, angle)


func _body_entered(body: PhysicsBody):
	# Make a copy here
	# Doing kinematic body or else it sucks the player in idk
#	var copy = body.duplicate(0)
#	copy.mode = RigidBody.MODE_KINEMATIC
	
	if copies.values().has(body) or copies.keys().has(body):
		return
	
	var copy : RigidBody = body.duplicate()
	copy.mode = RigidBody.MODE_KINEMATIC
	copy.set_script(null)
	add_child(copy)
	
#	var copy = KinematicBody.new()
#	add_child(copy)

	var m = MeshInstance.new()
	var s = CapsuleMesh.new()
	m.mesh = s
	copy.add_child(m)
	
	copies[body] = copy
	remove_camera(copy)
	
	# Make it so the body no longer collides with layer 2
	body.set_collision_mask_bit(1, false)


func remove_camera(obj):
	for c in obj.get_children():
		remove_camera(c)
		if c is Camera:
			c.free()


func _body_exited(body):
	if copies.has(body):
		copies[body].queue_free()
		copies.erase(body)
		if is_instance_valid(body):
			body.set_collision_mask_bit(1, true)
