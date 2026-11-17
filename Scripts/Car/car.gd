class_name Car extends RigidBody3D

@onready var _transmission: Transmission = $Transmission
@onready var _motor: Motor = $Transmission/Motor
@onready var _rear_wheels: RearWheel = $"Transmission/Rear Wheels"

## TODO: get these from the wheels
@export var throttle_power: float = 20.0
@export var handbrake_decel: float = 25.0
var steer_state: int = 0

var throttle_state: bool = false
var handbrake_state: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	throttle_state = Input.is_action_pressed("throttle")
	handbrake_state = Input.is_action_pressed("handbrake")
	steer_state = int(Input.is_action_pressed("steer right")) - int(Input.is_action_pressed("steer left"))
	#if Input.is_action_pressed("throttle"):
		#rear_wheels_rpm += delta * rpm_accel
	#else:
		#rear_wheels_rpm = move_toward(rear_wheels_rpm, 0.0, delta * rpm_accel * 0.25)
	#if Input.is_action_pressed("handbrake"):
		#rear_wheels_rpm = move_toward(rear_wheels_rpm, 0.0, delta * handbrake_decel)
	#steer_state = int(Input.is_action_pressed("steer right")) - int(Input.is_action_pressed("steer left"))

# Called during _physics_process, allows safe reading and modification of physics state before its application
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var s_linear_velocity := state.linear_velocity
	s_linear_velocity.y = 0.0
	if s_linear_velocity.length() == 0.0:
		state.apply_force(state.transform.basis * Vector3.FORWARD * 0.25)
	if throttle_state:
		state.apply_force(state.transform.basis * Vector3.FORWARD * throttle_power)
	else:
		pass
		## TODO: actual manual friction
		#state.apply_force(state.transform.basis * -s_linear_velocity * throttle_power)
	if handbrake_state:
		state.apply_force(state.transform.basis * -s_linear_velocity * handbrake_decel)
	
	if (s_linear_velocity.length() != 0.0):
		steer_state = int(Input.is_action_pressed("steer right")) - int(Input.is_action_pressed("steer left"))
		var steer_force := Vector3(5.0, 0.0, 0.0)
		state.apply_force(steer_force * steer_state, Vector3(0.5 * steer_state, 0.0, -2))
