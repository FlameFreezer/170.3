class_name Motor

# constants set by _init()
var redline_rpm: float  # maximum RPM the motor can reach under throttle power.
var flywheel_weight: float  # weight of the flywheel used by the transmission to send energy to the rear wheels.
var cylinder_volume: float # constant multiple applied to the power output of the engine.

# updated every frame
var true_rpm: float # engine's final speed at the end of each frame.

# debug
var last_print_time: float # for managing the gap between print statements
var elapsed_time: float # for managing the gap between print statements
var print_gap: float = 0.25 # time in seconds between debug print statements. change this if desired.
var last_rpm: float # for monitoring spinup/spindown rates

## initializes variables and constants at the start of a scene.
func _init(in_redline_rpm: float, in_flywheel_weight: float, in_cylinder_volume: float, starting_rpm: float) -> void:
	# set constants
	redline_rpm = in_redline_rpm
	flywheel_weight = in_flywheel_weight
	cylinder_volume = in_cylinder_volume
	# initialize variables
	true_rpm = starting_rpm
	# initialize debug variables
	last_print_time = 0
	last_rpm = starting_rpm
	elapsed_time = 0
	pass

# ^---------- INITIALIZATION AND STORAGE SECTION ----------^

# v---------- DRIVETRAIN SIMULATOR SECTION ----------v

## convert throttle input into an acceleration value for the engine this frame.
func propose_rpm(throttle_state: float, delta: float) -> float:
	# convert throttle state to rpm
	var target_rpm: float = redline_rpm * throttle_state
	
	# apply acceleration or deceleration to move toward rpm target
	var rpm_to_propose: float
	if (target_rpm > true_rpm):
		rpm_to_propose = min(true_rpm + _calculate_acceleration_value() * delta, target_rpm)
	else:
		rpm_to_propose = max(true_rpm + _calculate_deceleration_value() * delta, target_rpm)
	
	# return resulting rpm value
	return rpm_to_propose

## mathematical function that defines the engine's spinup acceleration curve.
func _calculate_acceleration_value() -> float:
	# this acceleration formula is based off desmos experimentation to get a nice curve over the right domain and range.
	# i know it is incomprehensible. place your faith in the mysterious engineer from days past who once worked on this.
	# don't touch it.
	var to_ret: float
	to_ret = -0.035 * redline_rpm * pow(((true_rpm * -1) / (0.7 * redline_rpm) + 2.83), 3)
	to_ret += 0.15 * redline_rpm * tan(PI * ((true_rpm * -1) / (1.8 * redline_rpm) + 0.13)) + (1.3 * redline_rpm)
	
	return to_ret

## mathematical function that defines the engine's spindown deceleration curve.
func _calculate_deceleration_value() -> float:
	# I'm just using a linear function for this for now. decel feel is a lot less precise than accel feel, so it should
	#     be okay for now. Can be changed later if needed.
	var to_ret: float
	to_ret = redline_rpm / -2.5
	
	return to_ret

## sets the final rpm of the motor this frame.
func set_true_rpm(in_rpm: float) -> void:
	true_rpm = in_rpm

# ^---------- DRIVETRAIN SIMULATOR SECTION ----------^

# v---------- DEBUG SECTION ----------v

## should be called every frame if debug mode is active. prints engine rpm changes over time.
func print_debug_values(delta: float) -> void:
	if (elapsed_time - last_print_time > print_gap):
		print_debug("motor.gd debug stats:\nmotor's current rpm: %f\nrpm change since last printout: %f" % [true_rpm, (true_rpm - last_rpm)])
		last_print_time = elapsed_time
		last_rpm = true_rpm
	
	elapsed_time += delta
