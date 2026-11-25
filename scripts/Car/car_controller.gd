extends CharacterBody3D
signal update_values(String)

@export_category("Engine")
## Amount of acceleleration to apply from the throttle
@export var throttle_force: float
@export var max_engine_rpm: float
@export var engine_spindown_rate: float
@export_category("Wheels")
## Diameter of the wheels in meters
@export var wheel_diameter: float
@export var wheel_spindown_rate: float
@export var handbrake_power: float
## Max static friction force that can be applied
@export var static_friction_force: float
@export var kinetic_friction_force: float
@export_category("General motion")
@export var gear_ratios: Array[float]

var _throttle_state: float = 0.0
var _wheel_rpm: float = 0.0
var _engine_rpm: float = 0.0
var _handbrake_state: float = 0.0
var _current_gear_ratio_index: int = 2
var _is_slipping: bool = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	read_input()
	
	# Apply throttle to the engine
	_engine_rpm = move_toward(_engine_rpm, max_engine_rpm, _throttle_state * throttle_force * delta)
	# Spindown the engine if throttle is not in
	if _throttle_state == 0.0:
		_engine_rpm = move_toward(_engine_rpm, 0.0, (engine_spindown_rate + _handbrake_state * handbrake_power * get_gear_ratio()) * delta)
	# Set wheel rpm to ratio of engine rpm
	if _handbrake_state == 0.0:
		_wheel_rpm = _engine_rpm / get_gear_ratio()
	# Spindown wheel rpm
	_wheel_rpm = move_toward(_wheel_rpm, 0.0, (wheel_spindown_rate + _handbrake_state * handbrake_power) * delta)
	
	# Determine if wheels are slipping
	var wheel_translation: float = wheel_diameter * PI * _wheel_rpm
	if !_is_slipping and abs(wheel_translation) > static_friction_force:
		_is_slipping = true
	elif _is_slipping and abs(wheel_translation) < kinetic_friction_force:
		_is_slipping = false
	
	# Affect acceleration by slip state
	var accel_impact: Vector3
	if !_is_slipping:
		accel_impact = wheel_translation * get_forward() - get_forward_velocity()
	else:
		accel_impact = -kinetic_friction_force * velocity.normalized()
	velocity += accel_impact
	
	update_values.emit("Velocity: %v\nWheel RPM: %f\nGear Ratio Index: %d\nEngine RPM: %f\nSlipping: %s" % [velocity, _wheel_rpm, _current_gear_ratio_index, _engine_rpm, utils.bool_to_string(_is_slipping)])
	
	move_and_slide()

func read_input() -> void:
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

func change_gear_ratio(shift: int) -> void:
	_current_gear_ratio_index = clampi(_current_gear_ratio_index + shift, 0, gear_ratios.size() - 1)
		
func get_gear_ratio() -> float:
	return gear_ratios[_current_gear_ratio_index]
	
func get_forward() -> Vector3:
	return transform.basis * Vector3.FORWARD
	
func get_forward_velocity() -> Vector3:
	return get_forward() * velocity.dot(get_forward())
