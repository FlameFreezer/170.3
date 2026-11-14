extends Node3D

@export var gear_ratios: Array[float]
@export var clutch_response_time: float
var clutch_state: float = 0.0
## Index into the gear ratios array
var current_gear_ratio_index: int = 0

@onready var _motor: Motor = $Motor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var clutch_input: bool = Input.is_action_pressed("clutch")
	if (clutch_input):
		clutch_state = move_toward(clutch_state, clutch_response_time, delta)
	else:
		clutch_state = move_toward(clutch_state, 0.0, delta)
	
	var motor_proposed_rpm: float = _motor.proposed_rpm
	## TODO: get this from rear wheels
	var rear_wheels_rpm: float = 0.0
	
	if (clutch_state == 0.0):
		_motor.set_rpm(motor_proposed_rpm)
		## TODO: maintain rear wheels rpm
	else:
		var ideal_rpm := _calculate_revs(motor_proposed_rpm, rear_wheels_rpm)
		var motor_rpm: float = _motor.current_rpm
		var clutch_factor := clutch_state / clutch_response_time
		var motor_new_rpm := lerpf(motor_rpm, ideal_rpm, clutch_factor)
		var rear_wheels_new_rpm := lerpf(rear_wheels_rpm, ideal_rpm * gear_ratios[current_gear_ratio_index], clutch_factor)
		## TODO: pass energy response to rear wheels to change their rotation speed
		_motor.set_rpm(motor_new_rpm)


func _calculate_revs(motor_proposed_rpm: float, rear_wheels_rpm: float) -> float:
	const rear_wheel_weight: float = 1.0 ##TODO: grab from rear wheels
	var motor_rpm: float = _motor.current_rpm
	var motor_flywheel_weight: float = _motor.flywheel_weight_external
	
	var ke_motor_proposed := utils.kinetic_energy(motor_proposed_rpm, motor_flywheel_weight)
	var ke_rear_wheels := utils.kinetic_energy(rear_wheels_rpm, rear_wheel_weight) * 2
	var ke_motor := utils.kinetic_energy(motor_rpm, motor_flywheel_weight)
	var work_motor := ke_motor_proposed - ke_motor
	var ke_system := ke_motor + ke_rear_wheels + work_motor
	var weight_sum := motor_flywheel_weight + rear_wheel_weight * gear_ratios[current_gear_ratio_index]
	
	var ideal_revs := sqrt(2.0 * ke_system / weight_sum)
	return ideal_revs
