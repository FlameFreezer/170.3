extends RigidBody3D

@onready var _transmission: Transmission = $Transmission
@onready var _motor: Motor = $Transmission/Motor
@onready var _rear_wheels: RearWheel = $"Transmission/Rear Wheels"

## TODO: get these from the wheels
@export var wheel_radius: float
var rear_wheels_rpm: float = 0.0
@export var rpm_accel: float = 50.0
@export var handbrake_decel: float = 75.0
var steer_state: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("throttle"):
		rear_wheels_rpm += delta * rpm_accel
	else:
		rear_wheels_rpm = move_toward(rear_wheels_rpm, 0.0, delta * rpm_accel * 0.25)
	if Input.is_action_pressed("handbrake"):
		rear_wheels_rpm = move_toward(rear_wheels_rpm, 0.0, delta * handbrake_decel)
	steer_state = int(Input.is_action_pressed("steer right")) - int(Input.is_action_pressed("steer left"))

# Called during _physics_process, allows safe reading and modification of physics state before its application
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var xz_velocity = Vector3.FORWARD * rear_wheels_rpm * wheel_radius
	state.linear_velocity.x = xz_velocity.x
	state.linear_velocity.z = xz_velocity.z
	var steer_force := Vector3(100.0, 0.0, 0.0)
	state.apply_force(steer_force * steer_state, Vector3(1.5, 0.0, 0.0) * steer_state)
