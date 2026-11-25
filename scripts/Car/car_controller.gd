extends CharacterBody3D
signal update_values(String)

## Amount of acceleleration to apply from the throttle
@export var throttle_force: float

## Max static friction force that can be applied
@export var static_friction_force: float
@export var kinetic_friction_force: float
## Diameter of the wheels in meters
@export var wheel_diameter: float
@export var wheel_spindown_rate: float
@export var handbrake_power: float
@export var gear_ratios: Array[float]

var _throttle_state: float = 0.0
var _wheel_rpm: float = 0.0
var _handbrake_state: float = 0.0
var _current_gear_ratio_index: int = 2

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_pressed("throttle"):
		_throttle_state = 1.0
	else:
		_throttle_state = 0.0
	
	if Input.is_action_pressed("handbrake"):
		_handbrake_state = 1.0
	else:
		_handbrake_state = 0.0
		
	if Input.is_action_just_pressed("upshift"):
		change_gear_ratio(1)
	if Input.is_action_just_pressed("downshift"):
		change_gear_ratio(-1)
	
	_wheel_rpm += _throttle_state * throttle_force * delta / gear_ratios[_current_gear_ratio_index]
	_wheel_rpm = move_toward(_wheel_rpm, 0.0, (wheel_spindown_rate + _handbrake_state * handbrake_power) * delta)
	velocity = transform.basis * Vector3.FORWARD * wheel_diameter * PI * _wheel_rpm * delta
	
	update_values.emit("Velocity: %v\nWheel RPM: %f\nGear Ratio Index: %d" % [velocity, _wheel_rpm, _current_gear_ratio_index])
	
	move_and_slide()

func change_gear_ratio(shift: int) -> void:
	_current_gear_ratio_index += shift
	_current_gear_ratio_index = max(0, min(_current_gear_ratio_index, gear_ratios.size() - 1))
	#if _current_gear_ratio_index >= gear_ratios.size():
		#_current_gear_ratio_index = gear_ratios.size() - 1
	#elif _current_gear_ratio_index < 0:
		#_current_gear_ratio_index = 0
