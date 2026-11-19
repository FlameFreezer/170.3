class_name Chassis extends RigidBody3D

var front_axle: FrontWheels
var rear_axle: RearAxle
var motor: Motor
var transmission: Transmission

# General tuning variables

# Engine tuning variables
@export_category("Motor variables")
@export var redline_rpm: float = 10000 # Based on my own car's redline, even if I never reached it while recording its noises
@export var starting_rpm: float = 0
@export var flywheel_weight: float = 6
@export var cylinder_volume: float = 1
@export var drag_factor: float = 0.2

@export_category("Transmission variables")
@export var gear_ratios: Array[float] = [1.0/500, 1.0/375, 1.0/200, 1.0/125, 1.0/75, 1.0/50]
@export var starting_gear_ratio_index: int = 0
@export var clutch_response_time: float = 0.5 # In seconds

# Wheel tuning variables
@export_category("Steering Wheel variables")
@export var front_wheel_offset: float = 1.5 # Z position of front wheels relative to center of chassis
@export var front_wheels_static_friction: float = 1.2
@export var front_wheels_kinetic_friction: float = 0.8
@export var max_steering_angle: float = 45

@export_category("Drive Wheel variables")
@export var rear_wheel_offset: float = -1.5 # Z position of rear wheels relative to center of chassis
@export var rear_wheels_static_friction: float = 1.2
@export var rear_wheels_kinetic_friction: float = 0.8
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

# Initialize everything using the tuning variables
func _ready() -> void:
	rear_axle = RearAxle.new(mass, front_wheel_offset, rear_wheel_offset, rear_wheels_static_friction, rear_wheels_kinetic_friction, kinetic_friction_acceleration_factor, wheel_mass, wheel_diameter, drag_factor, handbrake_strength, starting_rpm)
	front_axle = FrontWheels.new(mass, front_wheel_offset, rear_wheel_offset, front_wheels_static_friction, front_wheels_kinetic_friction, max_steering_angle, 0)
	motor = Motor.new(redline_rpm, flywheel_weight, cylinder_volume, starting_rpm)
	transmission = Transmission.new(gear_ratios, clutch_response_time, starting_gear_ratio_index)

func _process(delta: float) -> void:
	throttle_input = Input.is_action_pressed("throttle") as int
	handbrake_input = Input.is_action_pressed("handbrake") as int
	steering_input = (Input.is_action_pressed("steer right") as int) - (Input.is_action_pressed("steer left") as int)
	clutch_input = Input.is_action_pressed("clutch") as int

## Uses Godot's physics engine to apply forces calculated by our physics engine
func _physics_process(delta: float) -> void:
	shifter_input = (Input.is_action_just_pressed("upshift") as int) - (Input.is_action_just_pressed("downshift") as int)
	var motor_proposed_rpm := motor.propose_rpm(throttle_input, delta)
	var rear_axle_proposed_rpm := rear_axle.propose_rpm(delta)
	transmission.update_clutch_state(clutch_input, delta)
	transmission.update_gear(shifter_input)
	
	transmission.transmit_energy(motor_proposed_rpm, rear_axle_proposed_rpm, motor, rear_axle)
	
	
	var current_velocity = utils.get_vector2(linear_velocity)
	var current_direction = utils.get_vector2(global_basis.z)
	var rear_force = rear_axle.get_force_output(current_velocity, current_direction, delta) * 1000.0
	var front_force = front_axle.get_force_output(current_velocity, current_direction) * 1000.0
	printerr("_physics_process:\nmotor_proposed_rpm: %f\nrear_axle_proposed_rpm: %f\nmotor_true_rpm: %f\nrear_wheels_true_rpm: %f\nslipping: %f\nrear_force: %v\n" % [motor_proposed_rpm, rear_axle_proposed_rpm, motor.true_rpm, rear_axle.true_rpm, rear_axle.slipping as int, rear_force])
	# apply_force(Vector3(front_force.x, 0, front_force.y), Vector3(0, 0, front_wheel_offset))
	# apply_force(Vector3(rear_force.x, 0, rear_force.y), Vector3(0, 0, rear_wheel_offset))
	apply_force(Vector3(0, 0, -500), Vector3(0, 0, 0))
