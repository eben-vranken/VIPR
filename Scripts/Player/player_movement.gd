extends CharacterBody3D

###############
# Player Variables
###############

# Car properties
@export var acceleration: float = 17.5
@export var reverse_acceleration: float = 20.0
@export var max_speed: float = 150.0 # Kmph
@export var reverse_max_speed: float = 25.0 # Kmph
@export var friction: float = 0.25
@export var gravity: float = -9.86
@export var brake_speed: float = 15.5
@export var mass: float = 20.0
@export var turn_stop_limit: float = 50.0 # Speed needed to turn
@export var turn_amount: float = 750.0
@export var min_turn_amount: float = 150.0 # Minimum turn amount at maximum speed
@export var turn_speed: float = 0.3
@export var min_turn_speed: float = 0.15

# Tilt
@export var tilt_amount: float = 0.2
@export var tilt_speed: float = 5.0

# Inputs
var turn_input: float = 0.0
var thrust: float = 0.0
var brake_input_force: float = 0.0

###############
# Nodes
###############

@onready var car_collision: CollisionShape3D = $CarCollision
@onready var car_mesh: Node3D = $CarMesh
@onready var ground_check_raycast: RayCast3D = $GroundCheck
@onready var player_camera: Camera3D = $CarMesh/Camera3D

# Canvas
@onready var ui_car_speed: Label = $PlayerUI/MarginContainer/Dashboard/CarSpeed

###############
# Car Stats
###############
var speed = 0.0
var reverse = false

func _physics_process(delta):
	player_inputs()
	player_movement(delta)
	update_camera()
	player_haptic()
	update_ui()

func player_inputs():
	turn_input = Input.get_axis("move_left", "move_right")
	thrust = Input.get_action_raw_strength("thrust")
	brake_input_force = Input.get_action_raw_strength("brake")

func player_movement(delta):
	# Apply gravity
	if not ground_check_raycast.is_colliding():
		velocity.y += gravity

	# Get the forward direction of the car
	var forward = -global_transform.basis.z

	# Forward
	if thrust:
		var desired_speed = thrust * acceleration * delta
		velocity += forward * desired_speed

	# Apply friction
	if not thrust:
		var friction_force = velocity * friction * delta
		if friction_force.length() > velocity.length():
			velocity = Vector3.ZERO
		else:
			velocity -= friction_force

	var brake_force = brake_input_force * brake_speed * delta
	if brake_force > velocity.length():
		velocity = Vector3.ZERO
	else:
		velocity -= velocity.normalized() * brake_force


	# Steering
	speed = abs(Vector3(velocity.x, 0.0, velocity.z).length())
	var speed_ratio = clamp(speed / max_speed, 0, 1)
	var dynamic_turn_amount = lerp(turn_amount, min_turn_amount, speed_ratio)
	var dynamic_turn_speed = lerp(turn_speed, min_turn_speed, speed_ratio)
	var turn_amount_rad = turn_input * deg_to_rad(dynamic_turn_amount)

	var turn_delta

	# Apply the turn_stop_limit to restrict turning at low speeds
	if speed >= turn_stop_limit:
		turn_delta = turn_amount_rad * delta
	else:
		turn_delta = turn_amount_rad * (speed / turn_stop_limit) * delta

	# Rotate the car
	rotate_y(-turn_delta * dynamic_turn_speed)

	# Align velocity with the new forward direction
	var forward_velocity = forward * velocity.dot(forward)
	var side_velocity = velocity - forward_velocity
	side_velocity = side_velocity.lerp(Vector3.ZERO, turn_speed)
	velocity = forward_velocity + side_velocity

	# Tilt when steering
	var tilt = -turn_input * tilt_amount * clamp(speed, 0, 1.0)
	car_mesh.rotation.z = lerp(car_mesh.rotation.z, tilt, tilt_speed * delta)

	# Cap velocity to max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	move_and_slide()

func update_camera():
	player_camera.rotation = Vector3.ZERO

func player_haptic():
	# Vibrate
	if thrust:
		Input.start_joy_vibration(0, thrust, thrust, 0.1)
	elif brake_input_force:
		Input.start_joy_vibration(0, abs(velocity.z), abs(velocity.z), 0.1)

func update_ui():
	### Dashboard
	ui_car_speed.text = str(int(speed), " km/h")
	print("Current Speed:", speed)
