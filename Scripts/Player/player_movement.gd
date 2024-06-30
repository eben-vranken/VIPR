extends CharacterBody3D

# Player Variables
@export var acceleration: float = 100.0
@export var friction: float = 0.5
@export var gravity: float = -9.86
@export var brake_speed: float = 12.5
@export var mass: float = 20.0
@export var tilt_amount: float = 0.3
@export var tilt_speed: float = 5.0

# Turning
@export var turn_amount: float = 50.0
@export var turn_speed: float = 1.0
@export var turn_stop_limit: float = 25.0 # Speed needed to turn

# Inputs
var turn_input: float = 0.0
var thrust: float = 0.0
var brake: float = 0.0

# Nodes
@onready var car_collision: CollisionShape3D = $CarCollision
@onready var car_mesh: MeshInstance3D = $CarMesh
@onready var ground_check_raycast: RayCast3D = $GroundCheck
@onready var player_camera: Camera3D = $CarMesh/Camera3D

func _physics_process(delta):
	player_inputs()
	player_movement(delta)
	update_camera()
	player_haptic()

func player_inputs():
	turn_input = Input.get_axis("move_left", "move_right")
	thrust = Input.get_action_raw_strength("thrust")
	brake = Input.get_action_raw_strength("brake")

func player_movement(delta):
	# Apply gravity
	if not ground_check_raycast.is_colliding():
		velocity.y += gravity * delta

	# Get the forward direction of the car
	var forward = -global_transform.basis.z

	# Forward or backward movement
	if thrust:
		var desired_speed = thrust * acceleration * delta
		velocity += forward * desired_speed

	# Apply friction
	var friction_force = velocity * friction * delta
	if friction_force.length() > velocity.length():
		velocity = Vector3.ZERO
	else:
		velocity -= friction_force

	# Apply brake
	if brake:
		var brake_force = brake * brake_speed * delta
		if brake_force > velocity.length():
			velocity = Vector3.ZERO
		else:
			velocity -= velocity.normalized() * brake_force

	# Steering
	var turn_amount_rad = turn_input * deg_to_rad(turn_amount)
	var speed = velocity.length()
	var turn_delta = turn_amount_rad * min(1.0, speed / turn_stop_limit) * delta

	# Rotate the car
	rotate_y(-turn_delta * turn_speed)

	# Align velocity with the new forward direction
	var forward_velocity = forward * velocity.dot(forward)
	var side_velocity = velocity - forward_velocity
	side_velocity = side_velocity.lerp(Vector3.ZERO, friction * delta)
	velocity = forward_velocity + side_velocity

	# Tilt when steering
	var tilt = -turn_input * tilt_amount
	car_mesh.rotation.z = lerp(car_mesh.rotation.z, tilt, tilt_speed * delta)

	print("Car speed: ", speed)
	move_and_slide()

func update_camera():
	player_camera.rotation = Vector3.ZERO

func player_haptic():
	# Vibrate
	Input.start_joy_vibration(0, thrust, thrust, 0.1)
