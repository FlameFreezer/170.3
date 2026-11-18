class_name Transmission

## List of gear ratios accessible to the driver
var gear_ratios: Array[float]
## Index into the gear ratios array
var current_gear_ratio_index: int = 0
## Time it takes the clutch to fully lock into place
var clutch_response_time: float
## Amount of time since the clutch was released
var _clutch_state: float = 0.0

func _init(in_gear_ratios: Array[float], in_clutch_response_time: float, in_gear_ratio_index: int) -> void:
	gear_ratios = in_gear_ratios
	clutch_response_time = in_clutch_response_time
	current_gear_ratio_index = in_gear_ratio_index

# ^---------- INITIALIZATION AND STORAGE SECTION ----------^

# v---------- DRIVETRAIN SIMULATOR SECTION ----------v

## Change the gear ratio to the index supplied. Prints a message if out of range, but clamps the index to a valid range.
func update_gear(in_gear_ratio_index: int) -> void:
	current_gear_ratio_index = in_gear_ratio_index
	if(current_gear_ratio_index > gear_ratios.size()):
		printerr("[TRANSMISSION]: Supplied gear ratio index \"%d\" out of range of gear ratios array with size \"%d\". Clamping gear ratio index to range" % [current_gear_ratio_index, gear_ratios.size()])
		current_gear_ratio_index = gear_ratios.size() - 1

## Updates the clutch state to reflect the current input
func update_clutch_state(clutch_input: bool, delta: float) -> void:
	_clutch_state = move_toward(_clutch_state, clutch_response_time * (clutch_input as float), delta)

## Checks the state of the motor and rear axle and ajusts their RPMs to what they should be
func transmit_energy(motor_proposed_rpm: float, rear_axle_proposed_rpm: float, motor: Motor, rear_axle: RearAxle) -> void:
	var motor_new_rpm : float = motor_proposed_rpm
	var rear_axle_new_rpm : float = rear_axle_proposed_rpm
	if _clutch_state != 0.0:
		var ideal_rpm := _get_ideal_rpm(motor_proposed_rpm, rear_axle_proposed_rpm, motor, rear_axle)
		## The percentage of force that the clutch is actually able to apply to the motor and rear axle
		var clutch_factor := _clutch_state / clutch_response_time
		motor_new_rpm = lerpf(motor.last_rpm, ideal_rpm, clutch_factor)
		rear_axle_new_rpm = lerpf(rear_axle.true_rpm, ideal_rpm * gear_ratios[current_gear_ratio_index], clutch_factor)
	motor.set_true_rpm(motor_new_rpm)
	rear_axle.set_true_rpm(rear_axle_new_rpm)

## Checks the kinetic energy of the system to find out how fast the motor flywheel should be spinning at the end of this frame
func _get_ideal_rpm(motor_proposed_rpm: float, rear_axle_proposed_rpm: float, motor: Motor, rear_axle: RearAxle) -> float:
	## Amount of energy the motor would have next frame
	var ke_motor_proposed := utils.kinetic_energy(motor_proposed_rpm, motor.flywheel_weight)
	## Amount of energy the rear axle would have next frame
	var ke_rear_axle_proposed := utils.kinetic_energy(rear_axle_proposed_rpm * rear_axle.wheel_diameter / 2.0, rear_axle.adjusted_wheel_mass) * 2
	## Actual amount of energy the motor has this frame
	var ke_motor := utils.kinetic_energy(motor.last_rpm, motor.flywheel_weight)
	## Amount of energy the motor can add or subtract the system
	var work_motor := ke_motor_proposed - ke_motor
	## Amount of energy currently in the system
	var ke_system := ke_motor + ke_rear_axle_proposed + work_motor
	var weight_sum := motor.flywheel_weight + rear_axle.adjusted_wheel_mass * gear_ratios[current_gear_ratio_index]
	
	var ideal_rpm := sqrt(2.0 * ke_system / weight_sum)
	return ideal_rpm
