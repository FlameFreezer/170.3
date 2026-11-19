class_name Chassis extends RigidBody3D

var front_wheels: FrontWheels
var rear_wheels: RearAxle
var engine: Motor
var transmission: Transmission

@export var starting_rpm: float = 0
@export var redline_rpm: float = 6000 # Based on my own car's redline, even if I never reached it while recording its noises
@export var flywheel_weight: float = 100
@export var cylinder_volume: float = 100
@export var gear_ratios: array[float] = [1, 2, 3, 4, 5, 6]
@export var starting_gear_ratio_index: int = 0
@export var clutch_response_time: float = 0.5 # In seconds
@export var front_wheel_offset: float = 5 # Z position of front wheels relative to center of chassis
@export var rear_wheel_offset: float = -5 # Z position of rear wheels relative to center of chassis
@export var wheel_static_friction: float = 100 
@export var wheel_kinetic_friction: float = 100
@export var kinetic_friction_acceleration_factor: float = 5
@export var wheel_mass: float = 1550 # In kilograms; roughly 3400lb
@export var wheel_diameter: float = 0.5 # In meters
@export var drag_factor: float = 1
@export var handbrake_strength: float = 1
@export var max_steering_angle: float = 3.14159 / 2 # In radians

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rear_wheels = RearAxle.new(mass, front_wheel_offset, rear_wheel_offset, wheel_static_friction, wheel_kinetic_friction, kinetic_friction_acceleration_factor, wheel_mass, wheel_diameter, drag_factor, handbrake_strength, starting_rpm)
	front_wheels = FrontWheels.new(mass, front_wheel_offset, rear_wheel_offset, wheel_static_friction, wheel_kinetic_friction, max_steering_angle, 0)
	engine = Motor.new(redline_rpm, flywheel_weight, cylinder_volume, starting_rpm)
	transmission = Transmission.new(gear_ratios, clutch_response_time, starting_gear_ratio_index)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var current_velocity = utils.get_vector2(linear_velocity)
	var current_direction = utils.get_vector2(global_basis.z)
	var rear_force = rear_wheels.get_force_output(current_velocity, current_direction, delta)
	var front_force = front_wheels.get_force_output(current_velocity, current_direction)
	apply_force(Vector3(front_force.x, 0, front_force.y), Vector3(0, 0, front_wheel_offset))
	apply_force(Vector3(rear_force.x, 0, rear_force.y), Vector3(0, 0, rear_wheel_offset))
