class_name Chassis extends RigidBody3D

@onready var front_wheels: FrontWheels
@onready var rear_wheels: RearAxle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var current_velocity = utils.get_vector2(linear_velocity)
	var current_direction = utils.get_vector2(global_basis.z)
	var rear_force = rear_wheels.get_force_output(current_velocity, current_direction, delta)
	var front_force = front_wheels.get_force_output(current_velocity, current_direction)
	var front_wheel_local_position = front_wheels.position - global_position
	apply_force(Vector3(front_force.x, 0, front_force.y), front_wheel_local_position)
	apply_force(Vector3(rear_force.x, 0, rear_force.y), front_wheel_local_position * Vector3(1, 1, -1))
