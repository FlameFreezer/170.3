class_name Chassis extends RigidBody3D

<<<<<<< HEAD
var front_wheels: FrontWheels
var rear_wheels: RearAxle

@export var front_wheel_offset: float = 5 # Z position of front wheels relative to center of chassis
@export var rear_wheel_offset: float = -5 # Z position of rear wheels relative to center of chassis
@export var wheel_static_friction: float = 100 
@export var wheel_kinetic_friction: float = 100
@export var kf_accel_factor: float = 100 # TODO: Figure out wtf this is
@export var wheel_mass: float = 1550 # In kilograms; roughly 3400lb
@export var wheel_diameter: float = 0.5 # Probably in meters, right?
@export var drag_factor: float = 1
@export var handbrake_strength: float = 1
@export var max_steering_angle: float = 3.14159 / 2 # In radians

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rear_wheels = RearAxle.new(mass, front_wheel_offset, rear_wheel_offset, wheel_static_friction, wheel_kinetic_friction, kf_accel_factor, wheel_mass, wheel_diameter, drag_factor, handbrake_strength, 0)
	front_wheels = FrontWheels.new(mass, front_wheel_offset, rear_wheel_offset, wheel_static_friction, wheel_kinetic_friction, max_steering_angle, 0)
=======
@onready var front_wheels: FrontWheels
@onready var rear_wheels: RearAxle

@export var wheel_offset: float = 5 # How far away the wheels are from the chassis' center

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
>>>>>>> 4efb0b99c775da939fd044f461db175d4079be8a

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var current_velocity = utils.get_vector2(linear_velocity)
	var current_direction = utils.get_vector2(global_basis.z)
	var rear_force = rear_wheels.get_force_output(current_velocity, current_direction, delta)
	var front_force = front_wheels.get_force_output(current_velocity, current_direction)
<<<<<<< HEAD
	apply_force(Vector3(front_force.x, 0, front_force.y), Vector3(0, 0, front_wheel_offset))
	apply_force(Vector3(rear_force.x, 0, rear_force.y), Vector3(0, 0, rear_wheel_offset))
=======
	apply_force(Vector3(front_force.x, 0, front_force.y), Vector3(0, 0, wheel_offset))
	apply_force(Vector3(rear_force.x, 0, rear_force.y), Vector3(0, 0, -wheel_offset))
>>>>>>> 4efb0b99c775da939fd044f461db175d4079be8a
