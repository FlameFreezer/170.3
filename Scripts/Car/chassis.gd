class_name Chassis extends RigidBody3D

@onready var front_wheels: FrontWheels
@onready var rear_wheels: RearAxle

@export var wheel_offset: float = 5 # How far away the wheels are from the chassis' center

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var current_velocity = utils.get_vector2(linear_velocity)
	var current_direction = utils.get_vector2(global_basis.z)
	var rear_force = rear_wheels.get_force_output(current_velocity, current_direction, delta)
	var front_force = front_wheels.get_force_output(current_velocity, current_direction)
	apply_force(Vector3(front_force.x, 0, front_force.y), Vector3(0, 0, wheel_offset))
	apply_force(Vector3(rear_force.x, 0, rear_force.y), Vector3(0, 0, -wheel_offset))
