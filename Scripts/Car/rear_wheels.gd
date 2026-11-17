class_name RearWheel extends Node3D

@export var static_friction : float
@export var kinetic_friction : float
@export var mass : float
@export var handbrake_strength: float

## transmission: interface with rpm determination system
@onready var _transmission: Transmission = $Transmission
## back left wheel: for animation
@onready var _rigid_body_left: RigidBody3D = $RigidBody3D
## back right wheel: for animation
@onready var _rigid_body_right: RigidBody3D = $RigidBody3D
## car body; interface with physics system
@onready var _body: Car = $Car

@onready var static_friction_force: float = Car.mass * static_friction
@onready var kinetic_friction_force: float = Car.mass * kinetic_friction
@onready var slipping: bool = false
@onready var weight_on_wheels: float = Car.mass + mass

var _radius: float = 20 # ignore this for rpm determination
var proposed_rpm : float
var current_rpm: float
var handbrake_state: float

func update_wheel_angular_velocity(angular_velocity: Vector3) -> void:
	_rigid_body_left.angular_velocity = angular_velocity
	_rigid_body_right.angular_velocity = angular_velocity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_rpm = 0;
	proposed_rpm = 0;
	handbrake_state = 0;
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

## input_value is in range [0, 1]; comes from the input system.
func set_handbrake_state(input_value: float) -> void:
	handbrake_state = input_value

## called to give transmission the information it needs to determine current_rpm.
func propose_rpm() -> float:
	return current_rpm * handbrake_state

## car_velocity is car's movement vector from last frame. car_direction is car's direction vector from last frame.
## called after current_rpm is finalized for the frame. outputs physics forces to car body.
func get_force_output(car_velocity: Vector2, car_direction: Vector2) -> Vector2:
	# determine ground speed of wheels from rpm
	var proposed_wheel_translation: Vector2 = car_direction.normalized() * _radius * (current_rpm / 60) * (2 * PI) * get_process_delta_time()
	
	# use previous car speed to determine acceleration force demand
	var acceleration_vector: Vector2 = proposed_wheel_translation - car_velocity
	var acceleration_force: float = acceleration_vector.length() * Car.mass
	
	# find slip angle and use it to determine cornering force demand
	var car_normal: Vector2 = Vector2(cos(car_direction.angle() + PI / 2), sin(car_direction.angle() + PI / 2))
	var slip_motion: Vector2 = car_normal * car_velocity.dot(car_normal)
	var slip_force: float = slip_motion.length() * Car.mass
	
	# determine whether or not back wheels are sliding
	if (!slipping && acceleration_force + slip_force > static_friction_force):
		slipping = true;
	elif(slipping && acceleration_force + slip_force < kinetic_friction_force):
		slipping = false;
	
	# generate and return force vector
	var accel_vec: Vector2 # acceleration force component
	if (slipping):
		accel_vec = acceleration_vector.normalized() * min(acceleration_force, kinetic_friction_force)
	else:
		accel_vec = acceleration_vector.normalized() * min(acceleration_force, static_friction_force)
	var accel_force: float = accel_vec.length() * Car.mass
	
	var cornering_vec: Vector2 # cornering force component
	if (slipping):
		cornering_vec = slip_motion.normalized() * -1 * min(slip_force, kinetic_friction_force / 2)
	else:
		cornering_vec = slip_motion.normalized() * -1 * min(slip_force, static_friction_force - accel_force)
	
	return accel_vec + cornering_vec
