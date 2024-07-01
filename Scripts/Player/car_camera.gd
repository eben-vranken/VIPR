extends Camera3D

@export var lerp_speed: float = 5.0
@export var offset: Vector3 = Vector3.ZERO

@onready var car_mesh: Node3D = get_tree().get_first_node_in_group("CarMesh")

func _physics_process(delta):
	if !car_mesh:
		return
	var target_pos = car_mesh.global_transform.translated_local(offset)
	global_transform = global_transform.interpolate_with(target_pos, lerp_speed * delta)
	look_at(car_mesh.global_position, Vector3.UP)
