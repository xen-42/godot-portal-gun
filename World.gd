extends Spatial

onready var player = $Player
onready var portal_a = $Portal
onready var portal_b = $Portal2


# Called when the node enters the scene tree for the first time.
func _ready():
	player.portal_gun.connect("create_portal_a_at", self, "_on_World_create_portal_a_at")
	player.portal_gun.connect("create_portal_b_at", self, "_on_World_create_portal_b_at")

func _on_World_create_portal_a_at(pos, norm):
	move_portal(portal_a, pos, norm)

func _on_World_create_portal_b_at(pos, norm):
	move_portal(portal_b, pos, norm)

func move_portal(portal, pos, norm):
	print(pos, norm)
	portal.reset()
	
	portal.global_transform.origin = pos + 0.01 * norm
	portal.look_at(pos - norm, -Vector3.UP)
	if norm == Vector3(0, 1, 0):
		portal.rotation_degrees.x = -90
	elif norm == Vector3(0, -1, 0):
		portal.rotation_degrees.x = 90
	
	portal.setup()
