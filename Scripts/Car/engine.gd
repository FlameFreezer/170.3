extends Node3D

## RPM. maximum speed the engine can reach under throttling.
@export var redline_rpm: float

## In range (0, 1). 0 is no mass, 1 is infinite mass. Weight of flywheel for use by internal scripts. Used to calculate the engine's spin-down speed.
@export var _flywheel_weight_internal: float

## Kilograms. Weight of flywheel for use by external scripts. Used to calculate how much kE the engine is storing.
@export var flywheel_weight_external: float 

## In range (0, 1). 0 is no volume, 1 is infinite volume. Total volume of engine's cylinders. Used to calculate engine's power output per combustion cycle.
@export var _cylinder_volume: float

# max number of rpms the engine is allowed to change by per second.
var _max_acceleration: float
var _max_deceleration: float

var _current_rpm: float
var proposed_rpm: float

# debug
var debug_throttlestate: bool
var old_rpm: float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	"""debug_throttlestate = true
	old_rpm = 0.0"""


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	"""if (debug_throttlestate):
		_propose_new_rpm(1)
		set_rpm(proposed_rpm)
		if (_current_rpm >= redline_rpm - 10):
			debug_throttlestate = false;
	else:
		_propose_new_rpm(0)
		set_rpm(proposed_rpm)
		if (_current_rpm <= 10):
			debug_throttlestate = true;"""


func _propose_new_rpm(throttle_state: float) -> void:
	_max_acceleration = redline_rpm * _cylinder_volume * 5 # ask quincy what the non dumb way of doing this is. i know it has to exist
	_max_deceleration = redline_rpm * pow(1 - _flywheel_weight_internal, 2) * 5
	
	var target_rpm: float = redline_rpm * throttle_state
	var rpm_to_propose: float
	if (target_rpm > _current_rpm):
		rpm_to_propose = min(_current_rpm + _get_acceleration_value(true), target_rpm)
	else:
		rpm_to_propose = max(_current_rpm + _get_acceleration_value(false), target_rpm)
	
		
	"""if (_current_rpm - old_rpm > 1000):
		print_debug("_current_rpm: %f" % _current_rpm)
		print_debug("acceleration value: %f" % _get_acceleration_value(true))
		old_rpm = _current_rpm
	
	if (old_rpm - _current_rpm > 1000):
		print_debug("_current_rpm: %f" % _current_rpm)
		print_debug("acceleration value: %f" % _get_acceleration_value(false))
		old_rpm = _current_rpm"""
		
	proposed_rpm = rpm_to_propose


func _get_acceleration_value(accelerating: bool) -> float:
	if (accelerating):
		var max_torque: float = redline_rpm * 0.75
		var distance_from_max_torque: float = abs(max_torque - _current_rpm) / max_torque
		
		var torque_factor = max(exp(distance_from_max_torque * -2), 1 - _flywheel_weight_internal)
		
		return _max_acceleration * torque_factor * get_process_delta_time()
	else:
		return _max_deceleration * get_process_delta_time() * -1


## Only to be called by transmission.gd.
func set_rpm(in_rpm: float) -> void:
	_current_rpm = in_rpm
