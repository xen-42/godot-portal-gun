extends Spatial

onready var portal_raycast = $PortalRayCast
onready var particles = $MeshInstance/CPUParticles

signal create_portal_a_at(pos, norm)
signal create_portal_b_at(pos, norm)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _input(_event):
	if portal_raycast.is_colliding():
		var obj = portal_raycast.get_collider()
		if not obj is StaticBody:
			return
		
		var pos = portal_raycast.get_collision_point()
		var norm = portal_raycast.get_collision_normal()
		
		if Input.is_action_just_pressed("portal_a"):
			emit_signal("create_portal_a_at", pos, norm)
			portal_flash(Color(0, 1, 1))
		if Input.is_action_just_pressed("portal_b"):
			emit_signal("create_portal_b_at", pos, norm)
			portal_flash(Color(1, 167/255.0, 0))


func portal_flash(c):
	particles.mesh.surface_get_material(0).albedo_color = c
	particles.restart()
	particles.emitting = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
