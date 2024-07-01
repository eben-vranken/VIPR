extends RigidBody3D

@export var sphere_offset: Vector3 = Vector3.DOWN
@export var acceleration: float = 50.0
@export var braking_deceleration: float = 150.0 # Deceleration rate when braking
@export var normal_steering: float = 15.0
@export var steering_handbrake: float = 20.0
@export var turn_speed: float = 4.0
@export var turn_stop_limit: float = 2.0
@export var body_tilt: float = 1000.0
@export var straight_angular_damp: float = 2.0
@export var steering_angular_damp: float = 5.0
@export var min_turn_speed: float = 0.1
@export var max_turn_speed: float = 10.0

var wheel_turn_factor: float = 3.0

var speed_input = 0
var turn_input = 0
var handbrake: bool = false
var is_braking: bool = false

@onready var car_mesh: Node3D = $CarMesh
@onready var body_mesh: Node3D = $CarMesh/BodyMesh
@onready var ground_ray = $CarMesh/RayCast3D
@onready var right_wheel: MeshInstance3D = $CarMesh/BodyMesh/wheels/front_wheel_right
@onready var left_wheel: MeshInstance3D = $CarMesh/BodyMesh/wheels/front_wheel_left

func _physics_process(delta):
	get_input()
	apply_car_movement(delta)
	player_haptics()

func get_input():
	speed_input = Input.get_action_raw_strength("thrust") * acceleration
	turn_input = Input.get_axis("move_right", "move_left") * (-1 if speed_input < 0 else 1)
	handbrake = Input.is_action_pressed("handbrake")
	is_braking = Input.is_action_pressed("brake") and !Input.is_action_pressed("thrust")

func apply_car_movement(delta):
	# Update car mesh
	car_mesh.position = position

	# Apply steering
	var required_steering = steering_handbrake if handbrake else normal_steering
	turn_input *= deg_to_rad(required_steering)

	# Update dampening
	if turn_input:
		angular_damp = steering_angular_damp
	else:
		angular_damp = straight_angular_damp

	if ground_ray.is_colliding():
		if speed_input:
			apply_central_force(-car_mesh.global_transform.basis.z * speed_input)
		elif is_braking:
			var deceleration = braking_deceleration * delta
			if linear_velocity.length() > deceleration:
				apply_central_force(car_mesh.global_transform.basis.z * deceleration)
			else:
				linear_velocity = Vector3.ZERO

	print(linear_velocity.length())

func _process(delta):
	if not ground_ray.is_colliding():
		return

	if not is_braking:
		right_wheel.rotation.y = turn_input * wheel_turn_factor
		left_wheel.rotation.y = turn_input * wheel_turn_factor

	var current_speed = linear_velocity.length()

	if current_speed > min_turn_speed:
		var speed_factor = clamp((current_speed - min_turn_speed) / (max_turn_speed - min_turn_speed), 0, 1)
		var adjusted_turn_input = turn_input * speed_factor if not is_braking else 0.0

		if current_speed > turn_stop_limit:
			var new_basis = car_mesh.global_transform.basis.rotated(car_mesh.global_transform.basis.y, adjusted_turn_input)
			car_mesh.global_transform.basis = lerp(car_mesh.global_transform.basis, new_basis, turn_speed * delta)
			car_mesh.global_transform = car_mesh.global_transform.orthonormalized()

			var t = -adjusted_turn_input * current_speed / body_tilt
			body_mesh.rotation.z = lerp(body_mesh.rotation.z, t, 5.0 * delta)

			if ground_ray.is_colliding():
				var n = ground_ray.get_collision_normal()
				var xform = align_with_y(car_mesh.global_transform, n)
				car_mesh.global_transform = car_mesh.global_transform.interpolate_with(xform, 10.0 * delta)

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	return xform.orthonormalized()

func player_haptics():
	var vibration_strength = clamp(linear_velocity.length() / 50.0, 0, 1.0)
	Input.start_joy_vibration(0, vibration_strength, vibration_strength, 0.1)
