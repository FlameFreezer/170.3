class_name RearWheel extends Node3D

var STATIC_FRICTION : float = 100
var DYNAMIC_FRICTION : float = 100
var WEIGHT : int = 100

var transmission : Node3D
var wheel_rigid_body : RigidBody3D

var proposed_rpm : float = 0.0
var rpm: float = 0.0

func update_wheel_angular_velocity(angular_velocity: Vector3) -> void:
	wheel_rigid_body.angular_velocity = angular_velocity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Poll inputs for brakes
	if Input.is_action_pressed("handbrake"):
		proposed_rpm = 0.0
	else:
		pass
		#proposed_rpm = wheel_rigid_body.angular_velocity
