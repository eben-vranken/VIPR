extends CharacterBody3D

# Player Variables
@export var move_speed: float = 100.0
@export var acceleration: float = 15.0
@export var friction: float = 0.5
@export var gravity: float = -9.86
@export var brake_speed: float = 5.0
@export var mass: float = 20.0

# Turning
@export var turn_amount: float = 30.0
@export var turn_speed: float = 2.5
@export var turn_stop_limit: float = 25.0 # Speed needed to turn

# Inputs
var turn_input: float = 0.0
var thrust: float = 0.0
var brake: float = 0.0

# Nodes
@onready var car_collision: CollisionShape3D = $CarCollision
@onready var car_mesh: MeshInstance3D = $CarMesh
@onready var ground_check_raycast: RayCast3D = $GroundCheck
@onready var player_camera: Camera3D = $Camera3D

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
		velocity.y += gravity

	# Forward or backward movement
	if thrust:
		var desired_speed = thrust * acceleration / mass
		velocity += desired_speed * -global_transform.basis.z


	# Apply friction
	if not thrust:
		var friction_force = velocity * friction * delta
		if friction_force.length() > velocity.length():
			velocity = Vector3.ZERO
		else:
			velocity -= friction_force

	# Apply brake
	if brake:
		var brake_force = brake * brake_speed / mass
		if brake_force > velocity.length():
			velocity = Vector3.ZERO
		else:
			velocity -= brake_force * velocity.normalized()

	# Steering
	var turn_amount_rad = turn_input * deg_to_rad(turn_amount)
	var turn_delta = turn_amount_rad * min(1.0, abs(velocity.z) / turn_stop_limit) * delta
	global_transform.basis = global_transform.basis.rotated(Vector3.UP, -turn_delta * turn_speed)

	# Leaning
	rotation.z = lerp(rotation.z, turn_input / 3, 0.5)

	print("Car speed: ", abs(velocity.z))
	move_and_slide()

func update_camera():
	player_camera.global_transform.origin = car_mesh.global_transform.origin + Vector3(0, 5, 10)
	player_camera.look_at(car_mesh.global_transform.origin, Vector3.UP)

func player_haptic():
	# Vibrate
	Input.start_joy_vibration(0, thrust, thrust, 0.1)
