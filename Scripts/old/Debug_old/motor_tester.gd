class_name MotorTester extends Resource

var motor: Motor
@export var motor_redline_rpm: float
@export var motor_flywheel_weight: float
@export var motor_cylinder_volume: float
@export var motor_starting_rpm: float

@export var test_delta: float
@export var rpm_print_gap: float

@export var continue_after_failing: bool

var _log_file: FileAccess

func run(log_file: FileAccess) -> bool:
	_log_file = log_file
	motor = Motor.new(motor_redline_rpm, motor_flywheel_weight, motor_cylinder_volume, motor_starting_rpm)
	_log_file.store_string("STARTING: motor tests\n\n")
	var test_pass: bool
	test_pass = test_set_true_rpm()
	if (test_pass):
		_log_file.store_string("PASSED: test_set_true_rpm passed all tests.\n\n")
	if (test_pass || continue_after_failing):
		test_pass = test_propose_rpm()
	if (test_pass):
		_log_file.store_string("PASSED: test_propose_rpm passed all tests.\n\n")
		
		## keep this store_string in the last test_pass check
		_log_file.store_string("PASSED: motor passed all tests.\n")
	
	return test_pass

func test_set_true_rpm() -> bool:
	var to_ret: bool = true
	var motor_to_rpm: float = motor_redline_rpm * -1.5
	while (motor_to_rpm < motor_redline_rpm * 1.5):
		motor.set_true_rpm(motor_to_rpm)
		if (motor.true_rpm != motor_to_rpm):
			to_ret = false
			true_rpm_print_test_fail(motor_to_rpm)
			if (!continue_after_failing):
				return to_ret
		motor_to_rpm += 1
	return to_ret

func true_rpm_print_test_fail(motor_to_rpm: float) -> void:
	var msg: String = "motor_tester.test_set_true_rpm: failed to set motor's true_rpm to %f (motor was actually set to rpm %f\n\n)" % [motor_to_rpm, motor.true_rpm]
	printerr(msg)
	_log_file.store_string(msg)

func test_propose_rpm() -> bool:
	var to_ret: bool = true
	# test spinup from 0
	var motor_rpm: float = 0
	var last_printed_rpm: float = motor_rpm
	var motor_throttle_state: float = 1
	motor.set_true_rpm(motor_rpm)
	var output: float = motor.propose_rpm(motor_throttle_state, test_delta)
	_log_file.store_string("starting motor spinup test from 0 to redline rpm of %f\n" % motor_redline_rpm)
	_log_file.store_string("spinup from 0 test: motor proposed rpm of %f given true rpm %f and delta %f (acceleration of %f)\n" % [output, motor.true_rpm, test_delta, output - motor.true_rpm])
	motor_rpm += 1
	motor.set_true_rpm(motor_rpm)
	while (motor_rpm <= motor_redline_rpm):
		output = motor.propose_rpm(motor_throttle_state, test_delta)
		motor.set_true_rpm(motor_rpm)
		if (motor_rpm >= last_printed_rpm + rpm_print_gap):
			_log_file.store_string("spinup from 0 test: motor proposed rpm of %f given true rpm %f and delta %f (acceleration of %f)\n" % [output, motor.true_rpm, test_delta, output - motor_rpm])
			last_printed_rpm = motor_rpm
		if (output > motor_redline_rpm):
			var errmsg: String = "FAILED: spinup from 0 test: given true rpm of %f, motor proposed rpm of %f, which was higher than its redline of %f\n\n" % [motor.true_rpm, output, motor.redline_rpm]
			printerr(errmsg)
			_log_file.store_string(errmsg)
			to_ret = false
			if (!continue_after_failing):
				return to_ret
		motor_rpm += 1
	var successmsg: String = "\nPASSED: spinup from 0 test\n\n"
	print(successmsg)
	_log_file.store_string(successmsg)
	
	# test spindown from redline
	_log_file.store_string("starting motor spindown test from redline rpm of %f to 0\n\n" % motor_redline_rpm)
	motor_rpm = motor_redline_rpm
	motor_throttle_state = 0
	motor.set_true_rpm(motor_redline_rpm)
	last_printed_rpm = motor_rpm
	output = motor.propose_rpm(motor_throttle_state, test_delta)
	motor_rpm -= 1
	_log_file.store_string("spindown from redline test: motor proposed rpm of %f given true rpm %f and delta %f (deceleration of %f)\n" % [output, motor.true_rpm, test_delta, motor.true_rpm - output])
	motor.set_true_rpm(motor_rpm)
	while (motor_rpm >= 0):
		output = motor.propose_rpm(motor_throttle_state, test_delta)
		if (motor_rpm <= last_printed_rpm - rpm_print_gap):
			_log_file.store_string("spindown from redline test: motor proposed rpm of %f given true rpm %f and delta %f (deceleration of %f)\n" % [output, motor.true_rpm, test_delta, motor.true_rpm - output])
			last_printed_rpm = motor_rpm
		if (output < 0):
			var errmsg: String = "FAILED: spindown from 0 test: motor proposed rpm of %f, which was lower than the lower bound of 0\n\n" % output
			printerr(errmsg)
			_log_file.store_string(errmsg)
			to_ret = false
			if (!continue_after_failing):
				return to_ret
		motor_rpm -= 1
		motor.set_true_rpm(motor_rpm)
	successmsg = "\nPASSED: spindown from redline test\n\n"
	print(successmsg)
	_log_file.store_string(successmsg)
	
	
	# test spindown from above redline with throttle active
	motor_rpm = motor_redline_rpm * 1.5
	_log_file.store_string("starting motor spindown test from above redline rpm (starting at %f) to redline rpm %f\n\n" % [motor_rpm, motor_redline_rpm])
	motor_throttle_state = 1
	motor.set_true_rpm(motor_rpm)
	last_printed_rpm = motor_rpm
	output = motor.propose_rpm(motor_throttle_state, test_delta)
	_log_file.store_string("spindown from above redline test: motor proposed rpm of %f given true rpm %f and delta %f\n" % [output, motor.true_rpm, test_delta])
	if (output > motor_redline_rpm):
		var errmsg: String = "FAILED: spindown from above redline test: given true rpm %f, motor proposed rpm of %f, which is greater than its redline of %f\n\n" % [motor.true_rpm, output, motor.redline_rpm]
		printerr(errmsg)
		_log_file.store_string(errmsg)
		to_ret = false
		if (!continue_after_failing):
			return to_ret
	last_printed_rpm = motor_rpm
	motor_rpm -= 1
	motor.set_true_rpm(motor_rpm)
	while (motor_rpm >= motor_redline_rpm):
		output = motor.propose_rpm(motor_throttle_state, test_delta)
		if (motor_rpm <= last_printed_rpm - rpm_print_gap):
			_log_file.store_string("spindown from above redline test: motor proposed rpm of %f given true rpm %f and delta %f\n" % [output, motor.true_rpm, test_delta])
			last_printed_rpm = motor_rpm
		if (output > motor_redline_rpm):
			var errmsg: String = "FAILED: spindown from above redline test: given true rpm %f, motor proposed rpm of %f, which is greater than its redline\n\n" % [motor_rpm, output]
			printerr(errmsg)
			_log_file.store_string(errmsg)
			to_ret = false
			if (!continue_after_failing):
				return to_ret
		motor_rpm -= 1
		motor.set_true_rpm(motor_rpm)
	successmsg = "\nPASSED: spindown from above redline test\n\n"
	print(successmsg)
	_log_file.store_string(successmsg)
	
	return to_ret
