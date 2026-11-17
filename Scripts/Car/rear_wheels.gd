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

var _radius: float = 20 # ignore this for rpm determination
var proposed_rpm : float
var current_rpm: float
var handbrake_state: float

func update_wheel_angular_velocity(angular_velocity: Vector3) -> void:
	_rigid_body_left.angular_velocity = angular_velocity
	_rigid_body_right.angular_velocity = angular_velocity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

## input_value is in range [0, 1]; comes from the input system.
func set_handbrake_state(input_value: float) -> void:
	pass

## called to give transmission the information it needs to determine current_rpm.
func propose_rpm() -> float:
	return 0

## called after current_rpm is finalized for the frame. outputs physics forces to car body.
func get_force_output() -> Vector2:
	return Vector2(0, 0)
