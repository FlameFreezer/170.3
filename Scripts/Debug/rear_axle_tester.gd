class_name RearAxleTester extends Resource

var rear_axle_drivetrain: RearAxle
var rear_axle_physics: RearAxle

@export var static_friction_coeff: float ## static friction coefficient for the rear axle.
@export var kinetic_friction_coeff: float ## kinetic friction coefficient for the rear axle.
@export var kinetic_friction_accel_factor: float ## Proportion of kinetic friction that can be used by the rear wheels to accelerate.
##                                          The rest of the available kinetic friction force is used to provide cornering force.
##                                          In range [0, 1].
##                                          A value of zero means that the rear wheels cannot accelerate the car while in a slide.
##                                          A value of one means that the rear wheels cannot apply any cornering force while the car is in a slide.
@export var chassis_mass: float ## mass of the whole car.
@export var front_axle_distance_from_com: float ## distance from car's center of mass to the front axle.
@export var rear_axle_distance_from_com: float ## distance from the car's center of mass to the rear axle.
@export var wheel_mass: float ## mass of the rear wheels.
@export var wheel_diameter: float ## diameter of the rear wheels.
@export var drag_factor: float ## In range [0, 1]. proportion of car's speed lost per second under no acceleration. A value of 0 means no drag.
@export var handbrake_strength: float ## how much the transmission favors the rear wheels over the engine when the handbrake is fully active.
var init_starting_rpm: float = 0.0

@export var test_delta: float
@export var rpm_print_gap: float

@export var continue_after_failing: bool

var _log_file: FileAccess

# Called when the node enters the scene tree for the first time.
func run(log_file: FileAccess) -> bool:
	_log_file = log_file
	
	# test drivetrain sim functionality
	rear_axle_drivetrain = RearAxle.new(chassis_mass, static_friction_coeff, kinetic_friction_coeff, kinetic_friction_accel_factor, wheel_mass, wheel_diameter, drag_factor, handbrake_strength, init_starting_rpm)
	var msg: String = "STARTING: RearAxle (drivetrain side) tests\n\n"
	_log_file.store_string(msg)
	print(msg)
	var test_pass: bool
	test_pass = test_set_true_rpm()
	if (test_pass):
		msg = "PASSED: test_set_true_rpm passed all tests.\n\n"
		_log_file.store_string(msg)
		print(msg)
		
	if (test_pass || continue_after_failing):
		test_pass = test_update_handbrake()
	if (test_pass):
		msg = "PASSED: test_update_handbrake passed all tests.\n\n"
		_log_file.store_string(msg)
		print(msg)
	
	if (test_pass || continue_after_failing):
		test_pass = test_propose_rpm()
	if (test_pass):
		msg = "PASSED: test_propose_rpm passed all tests.\n\n"
		_log_file.store_string(msg)
		print(msg)
		## keep this store_string in the last test_pass check
		msg = "PASSED: RearAxle (drivetrain side) passed all tests.\n"
		_log_file.store_string(msg)
		print(msg)
	
	# TODO: test physics sim functionality
	return test_pass

func run_physics(log_file: FileAccess) -> bool:
	_log_file = log_file
	rear_axle_physics = RearAxle.new(chassis_mass, static_friction_coeff, kinetic_friction_coeff, kinetic_friction_accel_factor, wheel_mass, wheel_diameter, drag_factor, handbrake_strength, init_starting_rpm)
	var to_ret: bool = true
	var msg: String
	to_ret = test_get_force_output()
	if (to_ret):
		msg = "PASSED: get_force_output passed all tests.\n\n"
		_log_file.store_string(msg)
		print(msg)
		
		msg = "PASSED: RearAxle (physics side) passed all tests.\n"
		_log_file.store_string(msg)
		print(msg)
	return to_ret

func test_set_true_rpm() -> bool:
	var to_ret: bool = true
	var axle_to_rpm: float = -5000
	while (axle_to_rpm <= 5000):
		rear_axle_drivetrain.set_true_rpm(axle_to_rpm)
		if (rear_axle_drivetrain.true_rpm != axle_to_rpm):
			to_ret = false
			true_rpm_print_test_fail(axle_to_rpm)
			if (!continue_after_failing):
				return to_ret
		axle_to_rpm += 1
	return to_ret

func true_rpm_print_test_fail(axle_to_rpm: float) -> void:
	var msg: String = "rear_axle_tester.test_set_true_rpm: failed to set rear axle's true_rpm to %f (axle was actually set to rpm %f\n\n)" % [axle_to_rpm, rear_axle_drivetrain.true_rpm]
	printerr(msg)
	_log_file.store_string(msg)

func test_update_handbrake() -> bool:
	var to_ret: bool = true
	var to_handbrake_state: float = 0.0
	while (to_handbrake_state < 1.0):
		rear_axle_drivetrain.update_handbrake(to_handbrake_state)
		if (rear_axle_drivetrain.adjusted_wheel_mass != rear_axle_drivetrain.wheel_mass + rear_axle_drivetrain.handbrake_strength * to_handbrake_state):
			to_ret = false
			var msg: String = "rear_axle_tester.test_update_handbrake: failed to set rear axle's adjusted_wheel_mass using input value %f. Resulting value was %f (should have been %f)\n\n" % [to_handbrake_state, rear_axle_drivetrain.adjusted_wheel_mass, rear_axle_drivetrain.wheel_mass + rear_axle_drivetrain.handbrake_strength * to_handbrake_state]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		if (rear_axle_drivetrain.handbrake_state != to_handbrake_state):
			to_ret = false
			var msg: String = "rear_axle_tester.test_update_handbrake: failed to set rear axle's handbrake state to %f (handbrake state was actually set to %f)" % [to_handbrake_state, rear_axle_drivetrain.handbrake_state]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		to_handbrake_state += 0.0001
	
	# test with value 1.0
	to_handbrake_state = 1.0
	rear_axle_drivetrain.update_handbrake(to_handbrake_state)
	if (rear_axle_drivetrain.adjusted_wheel_mass != rear_axle_drivetrain.wheel_mass + rear_axle_drivetrain.handbrake_strength * to_handbrake_state):
		to_ret = false
		var msg: String = "rear_axle_tester.test_update_handbrake: failed to set rear axle's adjusted_wheel_mass using input value %f. Resulting value was %f (should have been %f)\n\n" % [to_handbrake_state, rear_axle_drivetrain.adjusted_wheel_mass, rear_axle_drivetrain.wheel_mass + rear_axle_drivetrain.handbrake_strength * to_handbrake_state]
		printerr(msg)
		_log_file.store_string(msg)
		if (!continue_after_failing):
			return to_ret
	if (rear_axle_drivetrain.handbrake_state != to_handbrake_state):
		to_ret = false
		var msg: String = "rear_axle_tester.test_update_handbrake: failed to set rear axle's handbrake state to %f (handbrake state was actually set to %f)" % [to_handbrake_state, rear_axle_drivetrain.handbrake_state]
		printerr(msg)
		_log_file.store_string(msg)
		if (!continue_after_failing):
			return to_ret
	
	# return test results
	return to_ret

func test_propose_rpm() -> bool:
	var to_ret: bool = true
	
	# spindown from positive rpm tests
	var spindown_tests_starting_rpm: float = 10000.0
	var handbrake_state: float = 0.0
	while (handbrake_state <= 1):
		to_ret = run_spindown_test(spindown_tests_starting_rpm, handbrake_state)
		if (!to_ret && !continue_after_failing):
			return to_ret
		handbrake_state += 0.1
	
	var successmsg: String = "\nPASSED: spindown from %f tests\n\n" % spindown_tests_starting_rpm
	print(successmsg)
	_log_file.store_string(successmsg)
	
	# spindown from negative rpm tests
	spindown_tests_starting_rpm = -10000.0
	handbrake_state = 0.0
	while (handbrake_state <= 1):
		to_ret = run_spindown_test(spindown_tests_starting_rpm, handbrake_state)
		if (!to_ret && !continue_after_failing):
			return to_ret
		handbrake_state += 0.1
		
	if (to_ret):
		successmsg = "\nPASSED: spindown from %f tests\n\n" % spindown_tests_starting_rpm
		print(successmsg)
		_log_file.store_string(successmsg)
	return to_ret

func run_spindown_test(starting_rpm: float, handbrake_state: float) -> bool:
	var to_ret: bool = true
	rear_axle_drivetrain.update_handbrake(handbrake_state)
	var msg: String = "\nstarting rear axle spindown from %frpm with handbrake state %f\n\n" % [starting_rpm, handbrake_state]
	_log_file.store_string(msg)
	var axle_rpm: float = starting_rpm
	var last_printed_rpm: float = axle_rpm
	rear_axle_drivetrain.set_true_rpm(axle_rpm)
	var output: float = rear_axle_drivetrain.propose_rpm(test_delta)
	msg = "spindown from %f test: rear axle proposed rpm of %f given true rpm %f, handbrake state %f, and delta %f\n" % [starting_rpm, output, rear_axle_drivetrain.true_rpm, rear_axle_drivetrain.handbrake_state, test_delta]
	_log_file.store_string(msg)
	while (abs(axle_rpm) > 0):
		axle_rpm = (abs(axle_rpm) - 1) * sign(axle_rpm)
		rear_axle_drivetrain.set_true_rpm(axle_rpm)
		output = rear_axle_drivetrain.propose_rpm(test_delta)
		if (abs(last_printed_rpm) - abs(axle_rpm) >= rpm_print_gap):
			msg = "spindown from %f test: rear axle proposed rpm of %f given true rpm %f, handbrake state %f, and delta %f\n" % [starting_rpm, output, rear_axle_drivetrain.true_rpm, rear_axle_drivetrain.handbrake_state, test_delta]
			_log_file.store_string(msg)
			last_printed_rpm = axle_rpm
		if (abs(output) > abs(axle_rpm)):
			to_ret = false
			msg = "FAILED: spindown from %f test: propsed rpm was larger than axle's current rpm!\nFailed test: rear axle proposed rpm of %f given true rpm %f, handbrake state %f, and delta %f\n" % [starting_rpm, output, rear_axle_drivetrain.true_rpm, rear_axle_drivetrain.handbrake_state, test_delta]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		if (sign(output) != sign(axle_rpm) && output != 0.0):
			to_ret = false
			msg = "FAILED: spindown from %f test: proposed rpm returned an rpm of the opposite sign!\nFailed test: rear axle proposed rpm of %f given true rpm %f, handbrake state %f, and delta %f\n" % [starting_rpm, output, rear_axle_drivetrain.true_rpm, rear_axle_drivetrain.handbrake_state, test_delta]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
	return to_ret

func test_get_force_output() -> bool:
	# test a bunch of cases that should return zero acceleration
	var to_ret: bool = true
	var current_tire_rpm: float = -500
	var current_vehicle_velocity: Vector2 = Vector2(0, -1) * utils.snap(rear_axle_physics.wheel_diameter * PI * current_tire_rpm / 60 * test_delta)
	var current_vehicle_direction: Vector2 = Vector2(0, -1)
	var msg: String
	var output: Vector2
	rear_axle_physics.update_handbrake(0)
	while (current_tire_rpm <= 500):
		rear_axle_physics.set_true_rpm(current_tire_rpm)
		output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
		if (output != Vector2.ZERO):
			to_ret = false
			msg = "FAILED: no acceleration needed test: get_force_output returned a non-zero acceleration value given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		current_tire_rpm += 1
		current_vehicle_velocity = Vector2(0, -1) * utils.snap(rear_axle_physics.wheel_diameter * PI * current_tire_rpm / 60 * test_delta)
	if (to_ret):
		msg = "PASSED: no acceleration needed tests\n\n"
		print(msg)
		_log_file.store_string(msg)
	
	# verify location and behavior of slip point (tires accelerate car)
	current_tire_rpm = 1
	current_vehicle_velocity = Vector2.ZERO
	var max_static_friction_speed_change: float = utils.snap(rear_axle_physics.max_static_friction_force / rear_axle_physics.chassis_mass)
	while (current_tire_rpm < max_static_friction_speed_change / (rear_axle_physics.wheel_diameter * PI)):
		rear_axle_physics.set_true_rpm(current_tire_rpm)
		output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
		var expected_force: float = utils.snap(utils.snap(rear_axle_physics.wheel_diameter * PI * current_tire_rpm / 60 * test_delta) * rear_axle_physics.chassis_mass)
		var output_force: float = utils.snap(output.length())
		if (expected_force != output_force):
			to_ret = false
			msg = "FAILED: slip point location test (tires accelerate car): get_force_output failed to match vehicle speed to tire motion given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		current_tire_rpm += 1
	rear_axle_physics.set_true_rpm(current_tire_rpm)
	output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
	if (!rear_axle_physics.slipping):
		to_ret = false
		msg = "FAILED: slip point location test (tires accelerate car): get_force_output failed to enter the slip state given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
		printerr(msg)
		_log_file.store_string(msg)
		if (!continue_after_failing):
			return to_ret
	
	if (to_ret):
		msg = "PASSED: slip point location test (tires accelerate car)\n\n"
		print(msg)
		_log_file.store_string(msg)
		
	# verify location and behavior of catch point (tires accelerate car)
	var max_kinetic_friction_speed_change: float = utils.snap(rear_axle_physics.max_kinetic_friction_force / rear_axle_physics.chassis_mass)
	while (current_tire_rpm > max_kinetic_friction_speed_change / (rear_axle_physics.wheel_diameter * PI)):
		rear_axle_physics.set_true_rpm(current_tire_rpm)
		output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
		var expected_force: float = utils.snap(rear_axle_physics.max_kinetic_friction_force * pow(test_delta, 2))
		var output_force: float = utils.snap(output.length())
		if (expected_force != output_force):
			to_ret = false
			msg = "FAILED: catch point location test (tires accelerate car): get_force_output didn't output the maximum possible force while slipping given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		current_tire_rpm -= 1
	rear_axle_physics.set_true_rpm(current_tire_rpm)
	output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
	if (rear_axle_physics.slipping):
		to_ret = false
		msg = "FAILED: catch point location test (tires accelerate car): get_force_output failed to exit the slip state given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
		printerr(msg)
		_log_file.store_string(msg)
		if (!continue_after_failing):
			return to_ret
	
	if (to_ret):
		msg = "PASSED: catch point location test (tires accelerate car)\n\n"
		print(msg)
		_log_file.store_string(msg)
	
	# verify location and behavior of slip point (tires decelerate car)
	current_tire_rpm = 0
	rear_axle_physics.set_true_rpm(current_tire_rpm)
	current_vehicle_velocity = Vector2(0, utils.snap(-1 * rear_axle_physics.wheel_diameter * PI / 60 * test_delta))
	while (abs(current_vehicle_velocity.y) < abs(max_static_friction_speed_change * pow(test_delta, 2))):
		output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
		var expected_force: Vector2 = Vector2(0, utils.snap(current_vehicle_velocity.y * rear_axle_physics.chassis_mass * -1))
		if (expected_force != output):
			to_ret = false
			msg = "FAILED: slip point location test (tires decelerate car): get_force_output failed to match vehicle speed to tire motion given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		current_vehicle_velocity.y -= utils.snap(rear_axle_physics.wheel_diameter * PI / 60 * test_delta)
	rear_axle_physics.set_true_rpm(current_tire_rpm)
	output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
	if (!rear_axle_physics.slipping):
		to_ret = false
		msg = "FAILED: slip point location test (tires decelerate car): get_force_output failed to enter the slip state given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
		printerr(msg)
		_log_file.store_string(msg)
		if (!continue_after_failing):
			return to_ret
	
	if (to_ret):
		msg = "PASSED: slip point location test (tires decelerate car)\n\n"
		print(msg)
		_log_file.store_string(msg)
	
	# verify location and behavior of catch point (tires decelerate car)
	while (abs(current_vehicle_velocity.y) > abs(max_kinetic_friction_speed_change * pow(test_delta, 2))):
		output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
		var expected_force: Vector2 = Vector2(0, utils.snap(rear_axle_physics.max_kinetic_friction_force * pow(test_delta, 2)))
		if (expected_force != output):
			to_ret = false
			msg = "FAILED: catch point location test (tires decelerate car): get_force_output didn't output the maximum possible force while slipping given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		current_vehicle_velocity.y += utils.snap(rear_axle_physics.wheel_diameter * PI / 60 * test_delta)
	output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
	if (rear_axle_physics.slipping):
		to_ret = false
		msg = "FAILED: catch point location test (tires decelerate car): get_force_output failed to exit the slip state given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
		printerr(msg)
		_log_file.store_string(msg)
		if (!continue_after_failing):
			return to_ret
	
	if (to_ret):
		msg = "PASSED: catch point location test (tires decelerate car)\n\n"
		print(msg)
		_log_file.store_string(msg)
	
	# verify location and behavior of slip point (cornering force only)
	current_tire_rpm = 0
	rear_axle_physics.set_true_rpm(current_tire_rpm)
	current_vehicle_velocity = Vector2(utils.snap(-1 * rear_axle_physics.wheel_diameter * PI / 60 * test_delta), 0)
	while (abs(current_vehicle_velocity.x) < abs(max_static_friction_speed_change * pow(test_delta, 2))):
		output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
		var expected_force: Vector2 = Vector2(utils.snap(current_vehicle_velocity.x * rear_axle_physics.chassis_mass * -1), -0.0)
		if (expected_force != output):
			to_ret = false
			msg = "FAILED: slip point location test (cornering force only): get_force_output failed to match vehicle speed to tire motion given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		current_vehicle_velocity.x -= utils.snap(rear_axle_physics.wheel_diameter * PI / 60 * test_delta)
	rear_axle_physics.set_true_rpm(current_tire_rpm)
	output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
	if (!rear_axle_physics.slipping):
		to_ret = false
		msg = "FAILED: slip point location test (cornering force only): get_force_output failed to enter the slip state given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
		printerr(msg)
		_log_file.store_string(msg)
		if (!continue_after_failing):
			return to_ret
	
	if (to_ret):
		msg = "PASSED: slip point location test (cornering force only)\n\n"
		print(msg)
		_log_file.store_string(msg)
	
	# verify location and behavior of catch point (cornering force only)
	while (abs(current_vehicle_velocity.x) > abs(max_kinetic_friction_speed_change * pow(test_delta, 2))):
		output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
		var expected_force: Vector2 = Vector2(utils.snap(rear_axle_physics.max_kinetic_friction_force * pow(test_delta, 2) * (1.0 - rear_axle_physics.kinetic_friction_accel_factor)), 0)
		if (expected_force != output):
			to_ret = false
			msg = "FAILED: catch point location test (tires decelerate car, cornering force only): get_force_output didn't output the maximum possible force while slipping given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		current_vehicle_velocity.x += utils.snap(rear_axle_physics.wheel_diameter * PI / 60 * test_delta)
	output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
	if (rear_axle_physics.slipping):
		to_ret = false
		msg = "FAILED: catch point location test (tires decelerate car, cornering force only): get_force_output failed to exit the slip state given axle rpm %f and vehicle speed %f.\n" % [current_tire_rpm, current_vehicle_velocity.length()]
		printerr(msg)
		_log_file.store_string(msg)
		if (!continue_after_failing):
			return to_ret
	
	if (to_ret):
		msg = "PASSED: catch point location test (tires decelerate car, cornering force only)\n\n"
		print(msg)
		_log_file.store_string(msg)
	
	# test simultaneous cornering and acceleration loads
	var rpm_to_distance_per_frame: float = rear_axle_physics.wheel_diameter * PI / 60 * test_delta
	var curr_velocity_direction: float = -2 * PI / 3 # angle of car velocity in radians
	while (curr_velocity_direction <= 2 * PI / 3):
		msg = "rear_axle_tester.test_get_force_output: starting simultaneous cornering and acceleration load test at velocity angle %f\n" % rad_to_deg(curr_velocity_direction)
		_log_file.store_string(msg)
		current_vehicle_velocity = Vector2(-utils.snap(rpm_to_distance_per_frame * cos(curr_velocity_direction)), -utils.snap(rpm_to_distance_per_frame * sin(curr_velocity_direction)))
		rear_axle_physics.true_rpm = 0.0
		var _count: int = 0
		while (abs(utils.snap(current_vehicle_velocity.length())) < abs(utils.snap(max_static_friction_speed_change * pow(test_delta, 2)))):
			msg = "rear_axle_tester.test_get_force_output: running test %d at angle %f\n" % [_count, rad_to_deg(curr_velocity_direction)]
			_log_file.store_string(msg)
			output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
			var expected_output: Vector2 = Vector2(utils.snap(current_vehicle_velocity.x * chassis_mass * -1), utils.snap(current_vehicle_velocity.y * chassis_mass * -1))
			if output != expected_output:
				to_ret = false
				msg = "FAILED: simultaneous cornering and acceleration (tires decelerate car): get_force_output failed to stop car given axle rpm %f and vehicle speed %f in direction %f.\n" % [current_tire_rpm, current_vehicle_velocity.length(), rad_to_deg(curr_velocity_direction)]
				printerr(msg)
				_log_file.store_string(msg)
				if (!continue_after_failing):
					return to_ret
			#var x: float = rpm_to_distance_per_frame * cos(curr_velocity_direction) * 10000
			current_vehicle_velocity -= Vector2(utils.snap(rpm_to_distance_per_frame / 5 * cos(curr_velocity_direction)), utils.snap(rpm_to_distance_per_frame / 5 * sin(curr_velocity_direction)))
			_count += 1
		output = rear_axle_physics.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
		if (!rear_axle_physics.slipping):
			to_ret = false
			msg = "FAILED: simultaneous cornering and acceleration (tires decelerate car): tires failed to enter the slip state given axle rpm %f and vehicle speed %f in direction %f.\n" % [current_tire_rpm, current_vehicle_velocity.length(), rad_to_deg(curr_velocity_direction)]
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		rear_axle_physics.slipping = false
		curr_velocity_direction += PI / 120
	if (to_ret):
		msg = "PASSED: simultaneous cornering and acceleration at various angles (tires decelerate car)\n\n"
		print(msg)
		_log_file.store_string(msg)
	return true
