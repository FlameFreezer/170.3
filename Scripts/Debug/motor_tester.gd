class_name MotorTester extends Node

var motor: Motor
@export var motor_redline_rpm: float
@export var motor_flywheel_weight: float
@export var motor_cylinder_volume: float
@export var motor_starting_rpm: float

@export var test_delta: float
@export var rpm_print_gap: float

@export var continue_after_failing: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	motor = Motor.new(motor_redline_rpm, motor_flywheel_weight, motor_cylinder_volume, motor_starting_rpm)
	var test_pass: bool
	test_pass = test_set_true_rpm()
	if (test_pass):
		print("PASSED: test_set_true_rpm")
	if (test_pass || continue_after_failing):
		test_pass = test_propose_rpm()
	if (test_pass):
		print("\n\nPASSED: test_propose_rpm passed all tests.")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
	printerr("motor_tester.test_set_true_rpm: failed to set motor's true_rpm to %f (motor was actually set to rpm %f)" % motor_to_rpm, motor.true_rpm)

func test_propose_rpm() -> bool:
	var to_ret: bool = true
	# test spinup from 0
	var motor_rpm: float = 0
	var last_printed_rpm: float = motor_rpm
	var motor_throttle_state: float = 1
	motor.set_true_rpm(motor_rpm)
	var output: float = motor.propose_rpm(motor_throttle_state, test_delta)
	print("\n\nstarting motor spinup test from 0 to redline rpm of %f\n" % motor_redline_rpm)
	print("spinup from 0 test: motor proposed rpm of %f given true rpm %f and delta %f (acceleration of %f)" % [output, motor.true_rpm, test_delta, output - motor.true_rpm])
	motor_rpm += 1
	motor.set_true_rpm(motor_rpm)
	while (motor_rpm <= motor_redline_rpm):
		output = motor.propose_rpm(motor_throttle_state, test_delta)
		motor.set_true_rpm(motor_rpm)
		if (motor_rpm >= last_printed_rpm + rpm_print_gap):
			print("spinup from 0 test: motor proposed rpm of %f given true rpm %f and delta %f (acceleration of %f)" % [output, motor.true_rpm, test_delta, output - motor_rpm])
			last_printed_rpm = motor_rpm
		if (output > motor_redline_rpm):
			printerr("FAILED: spinup from 0 test: given true rpm of %f, motor proposed rpm of %f, which was higher than its redline of %f" % [motor.true_rpm, output, motor.redline_rpm])
			to_ret = false
			if (!continue_after_failing):
				return to_ret
		motor_rpm += 1
	print("\n\nPASSED: spinup from 0 test")
	
	# test spindown from redline
	print("\n\nstarting motor spindown test from redline rpm of %f to 0\n" % motor_redline_rpm)
	motor_rpm = motor_redline_rpm
	motor_throttle_state = 0
	motor.set_true_rpm(motor_redline_rpm)
	last_printed_rpm = motor_rpm
	output = motor.propose_rpm(motor_throttle_state, test_delta)
	motor_rpm -= 1
	print ("spindown from redline test: motor proposed rpm of %f given true rpm %f and delta %f (deceleration of %f)" % [output, motor.true_rpm, test_delta, motor.true_rpm - output])
	motor.set_true_rpm(motor_rpm)
	while (motor_rpm >= 0):
		output = motor.propose_rpm(motor_throttle_state, test_delta)
		if (motor_rpm <= last_printed_rpm - rpm_print_gap):
			print("spindown from redline test: motor proposed rpm of %f given true rpm %f and delta %f (deceleration of %f)" % [output, motor.true_rpm, test_delta, motor.true_rpm - output])
			last_printed_rpm = motor_rpm
		if (output < 0):
			printerr("FAILED: spindown from 0 test: motor proposed rpm of %f, which was lower than the lower bound of 0" % output)
			to_ret = false
			if (!continue_after_failing):
				return to_ret
		motor_rpm -= 1
		motor.set_true_rpm(motor_rpm)
		
	print("\n\nPASSED: spindown from redline test")
	
	
	# test spindown from above redline with throttle active
	motor_rpm = motor_redline_rpm * 1.5
	print("\n\n starting motor spindown test from above redline rpm (starting at %f) to redline rpm %f\n" % [motor_rpm, motor_redline_rpm])
	motor_throttle_state = 1
	motor.set_true_rpm(motor_rpm)
	last_printed_rpm = motor_rpm
	output = motor.propose_rpm(motor_throttle_state, test_delta)
	print("spindown from above redline test: motor proposed rpm of %f given true rpm %f and delta %f" % [output, motor.true_rpm, test_delta])
	if (output > motor_redline_rpm):
		printerr("FAILED: spindown from above redline test: given true rpm %f, motor proposed rpm of %f, which is greater than its redline of %f" % [motor.true_rpm, output, motor.redline_rpm])
		to_ret = false
		if (!continue_after_failing):
			return to_ret
	last_printed_rpm = motor_rpm
	motor_rpm -= 1
	motor.set_true_rpm(motor_rpm)
	while (motor_rpm >= motor_redline_rpm):
		output = motor.propose_rpm(motor_throttle_state, test_delta)
		if (motor_rpm <= last_printed_rpm - rpm_print_gap):
			print("spindown from above redline test: motor proposed rpm of %f given true rpm %f and delta %f" % [output, motor.true_rpm, test_delta])
			last_printed_rpm = motor_rpm
		if (output > motor_redline_rpm):
			printerr("FAILED: spindown from above redline test: given true rpm %f, motor proposed rpm of %f, which is greater than its redline" % [motor_rpm, output])
			to_ret = false
			if (!continue_after_failing):
				return to_ret
		motor_rpm -= 1
		motor.set_true_rpm(motor_rpm)
	
	print("\n\nPASSED: spindown from above redline test")
	
	return to_ret
