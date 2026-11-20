class_name Chassis extends RigidBody3D

signal update_values(String)

var front_axle: FrontAxle
var rear_axle: RearAxle
var motor: Motor
var transmission: Transmission

# General tuning variables

# Engine tuning variables
@export_category("Motor variables")
@export var redline_rpm: float = 10000 # Based on my own car's redline, even if I never reached it while recording its noises
@export var starting_rpm: float = 0
@export var flywheel_weight: float = 50
@export var cylinder_volume: float = 1
@export var drag_factor: float = 0.05

@export_category("Transmission variables")
@export var gear_ratios: Array[float] = [1.0/50, 1.0/25, 1.0/12.5, 1.0/6.25, 1.0/75, 1.0/3.125]
@export var starting_gear_ratio_index: int = 0
@export var clutch_response_time: float = 0.5 # In seconds

# Wheel tuning variables
@export_category("Steering Wheel variables")
@export var front_wheel_offset: float = -1.5 # Z position of front wheels relative to center of chassis
@export var front_wheels_static_friction: float = 5
@export var front_wheels_kinetic_friction: float = 2
@export var max_steering_angle: float = 30

@export_category("Drive Wheel variables")
@export var rear_wheel_offset: float = 1.5 # Z position of rear wheels relative to center of chassis
@export var rear_wheels_static_friction: float = 5
@export var rear_wheels_kinetic_friction: float = 2
@export var kinetic_friction_acceleration_factor: float = 0.5
@export var wheel_mass: float = 50 # In kilograms; roughly 3400lb
@export var wheel_diameter: float = 0.5 # In meters
@export var handbrake_strength: float = 100

# input storage variables
var throttle_input: int
var handbrake_input: int
var steering_input: int
var clutch_input: int
var shifter_input: int

# position storage variables
@onready var front_axle_pos: Node3D = $"1703FrontAxlePos"
var front_axle_last_position: Vector3
@onready var rear_axle_pos: Node3D = $"1703RearAxlePos"
var rear_axle_last_position: Vector3

# debug
var elapsed_time: float

# Initialize everything using the tuning variables
func _ready() -> void:
	rear_axle = RearAxle.new(mass, front_wheel_offset, rear_wheel_offset, rear_wheels_static_friction, rear_wheels_kinetic_friction, kinetic_friction_acceleration_factor, wheel_mass, wheel_diameter, drag_factor, handbrake_strength, starting_rpm)
	front_axle = FrontAxle.new(mass, front_wheel_offset, rear_wheel_offset, front_wheels_static_friction, front_wheels_kinetic_friction, max_steering_angle, 0)
	motor = Motor.new(redline_rpm, flywheel_weight, cylinder_volume, starting_rpm)
	transmission = Transmission.new(gear_ratios, clutch_response_time, starting_gear_ratio_index)
	elapsed_time = 0
	$"1703FrontAxlePos".position = Vector3(0, 0, front_wheel_offset)
	front_axle_last_position = $"1703FrontAxlePos".global_position
	$"1703RearAxlePos".position = Vector3(0, 0, rear_wheel_offset)
	rear_axle_last_position = $"1703RearAxlePos".global_position

func _process(delta: float) -> void:
	throttle_input = Input.is_action_pressed("throttle") as int
	handbrake_input = Input.is_action_pressed("handbrake") as int
	steering_input = (Input.is_action_pressed("steer right") as int) - (Input.is_action_pressed("steer left") as int)
	if (shifter_input == 0):
		shifter_input = (Input.is_action_just_pressed("upshift") as int) - (Input.is_action_just_pressed("downshift") as int)
	clutch_input = Input.is_action_pressed("clutch") as int
	elapsed_time += delta

## Uses Godot's physics engine to apply forces calculated by our physics engine
func _physics_process(delta: float) -> void:
	var motor_proposed_rpm := motor.propose_rpm(throttle_input, delta)
	rear_axle.update_handbrake(handbrake_input)
	var rear_axle_proposed_rpm := rear_axle.propose_rpm(delta)
	front_axle.set_wheel_angle(steering_input)
	transmission.update_clutch_state(clutch_input, delta)
	transmission.update_gear(shifter_input)
	shifter_input = 0
	
	transmission.transmit_energy(motor_proposed_rpm, rear_axle_proposed_rpm, motor, rear_axle)
	var front_axle_velocity = utils.get_vector2((front_axle_pos.global_position - front_axle_last_position) / delta)
	var rear_axle_velocity = utils.get_vector2((rear_axle_pos.global_position - rear_axle_last_position) / delta)
	if (front_axle_velocity.length() < 0.002):
		front_axle_velocity = Vector2(snappedf(front_axle_velocity.x, 0.001), snappedf(front_axle_velocity.y, 0.001))
	if (rear_axle_velocity.length() < 0.002):
		rear_axle_velocity = Vector2(snappedf(rear_axle_velocity.x, 0.001), snappedf(rear_axle_velocity.y, 0.001))
	var current_direction = utils.get_vector2(global_transform.basis * Vector3.FORWARD)
	var rear_force: Vector2 = rear_axle.get_force_output(rear_axle_velocity, current_direction, delta)
	var front_force: Vector2 = front_axle.get_force_output(front_axle_velocity, current_direction, delta)
	if (rear_force.length() < 0.002):
		rear_force = Vector2(snappedf(rear_force.x, 0.001), snappedf(rear_force.y, 0.001))
	if (front_force.length() < 0.002):
		front_force = Vector2(snappedf(front_force.x, 0.001), snappedf(front_force.y, 0.001))
	var hud_string := "motor_proposed_rpm: %f\nrear_axle_proposed_rpm: %f\nmotor_true_rpm: %f\nrear_wheels_true_rpm: %f\nrear slipping: %f\nfront slipping: %f\nrear_force: %v\nfront_force: %v\nsteering_angle: %f\ncar_direction: %v\nfront_axle_velocity: %v\nrear_axle_velocity: %v" % [motor_proposed_rpm, rear_axle_proposed_rpm, motor.true_rpm, rear_axle.true_rpm, rear_axle.slipping as int, front_axle.slipping as int, rear_force, front_force, front_axle.wheel_angle, current_direction, front_axle_velocity, rear_axle_velocity]
	update_values.emit(hud_string)
	apply_force(Vector3(front_force.x, 0, front_force.y), Vector3(0, 0, front_wheel_offset))
	apply_force(Vector3(rear_force.x, 0, rear_force.y), Vector3(0, 0, rear_wheel_offset))
	
	front_axle_last_position = front_axle_pos.global_position
	rear_axle_last_position = rear_axle_pos.global_position
	
	# apply_force(Vector3(elapsed_time * 100, 0, 0), Vector3(0, 0, 0))

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var car_normal_vec: Vector3 = (state.transform.basis * Vector3.RIGHT).normalized()
	if (state.linear_velocity.dot(car_normal_vec) < 0.001):
		state.linear_velocity -= car_normal_vec * state.linear_velocity.dot(car_normal_vec)
	if (state.angular_velocity.y < 0.001):
		state.angular_velocity.y = 0
