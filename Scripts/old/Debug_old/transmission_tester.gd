class_name TransmissionTester extends Resource

var transmission: Transmission
var motor: Motor
var rear_axle: RearAxle

@export var gear_ratios: Array[float]
@export var clutch_response_time: float

@export var test_delta: float

var _log_file: FileAccess

const EPSILON: float = 0.0000001

func run(log_file: FileAccess) -> bool:
	_log_file = log_file
	transmission = Transmission.new(gear_ratios, clutch_response_time, 0)
	
	var msg: String = "STARTING: Transmission tests\n\n"
	_log_file.store_string(msg)
	print(msg)
	
	var test_pass: bool
	# Make sure gear_ratios was initialized correctly
	if gear_ratios.size() < 2:
		var errmsg: String = "ERRONEOUS INPUT: gear_ratios initialized to size %d. Should be at least 2!\n\n" % gear_ratios.size()
		printerr(errmsg)
		_log_file.store_string(errmsg)
		test_pass = false
	test_pass = test_update_gear()
	if test_pass:
		msg = utils.get_test_passed_str(test_update_gear)
		print(msg)
		_log_file.store_string(msg)
	if test_pass:
		test_pass = test_update_clutch_state()
	if test_pass:
		msg = utils.get_test_passed_str(test_update_clutch_state)
		print(msg)
		_log_file.store_string(msg)
	if test_pass:
		test_pass = test_get_ideal_rpm()
	if test_pass:
		msg = utils.get_test_passed_str(test_get_ideal_rpm)
		print(msg)
		_log_file.store_string(msg)
	if test_pass:
		test_pass = test_transmit_energy()
	if test_pass:
		msg = utils.get_test_passed_str(test_transmit_energy)
		print(msg)
		_log_file.store_string(msg)
	return test_pass

func test_update_gear() -> bool:
	var old_ratio_index: int
	# repeatedly upshift gear until it is one less than the number of gears
	for _i in range(0, gear_ratios.size()-1):
		old_ratio_index = transmission.current_gear_ratio_index
		_log_file.store_string("Shifting gear up one time: was on index %d. Expected index %d, " % [old_ratio_index, old_ratio_index + 1])
		transmission.update_gear(1)
		_log_file.store_string("got %d\n" % transmission.current_gear_ratio_index)
		if old_ratio_index + 1 != transmission.current_gear_ratio_index:
			var errmsg: String = "FAILED: expected gear ratio index %d, got %d!\n\n" % [old_ratio_index, transmission.current_gear_ratio_index]
			printerr(errmsg)
			_log_file.store_string(errmsg)
			return false
	# upshifting once now should not increase the value
	old_ratio_index = transmission.current_gear_ratio_index
	_log_file.store_string("Shifting gear up one time when at maximum: was on index %d. Expected index %d, " % [old_ratio_index, old_ratio_index])
	transmission.update_gear(1)
	_log_file.store_string("got %d\n" % transmission.current_gear_ratio_index)
	if old_ratio_index != transmission.current_gear_ratio_index:
			var errmsg: String = "FAILED: expected gear ratio index %d, got %d!\n\n" % [old_ratio_index, transmission.current_gear_ratio_index]
			printerr(errmsg)
			_log_file.store_string(errmsg)
			return false
	# downshifting to zero
	for _i in range(0, gear_ratios.size()-1):
		old_ratio_index = transmission.current_gear_ratio_index
		_log_file.store_string("Shifting gear down one time: was on index %d. Expected index %d, " % [old_ratio_index, old_ratio_index - 1])
		transmission.update_gear(-1)
		_log_file.store_string("got %d\n" % transmission.current_gear_ratio_index)
		if old_ratio_index - 1 != transmission.current_gear_ratio_index:
			var errmsg: String = "FAILED: expected gear ratio index %d, got %d!\n\n" % [old_ratio_index, transmission.current_gear_ratio_index]
			printerr(errmsg)
			_log_file.store_string(errmsg)
			return false
	# downshifting at this point should keep index at zero
	old_ratio_index = transmission.current_gear_ratio_index
	_log_file.store_string("Shifting gear down one time when at zero: was on index %d. Expected index %d, " % [old_ratio_index, old_ratio_index])
	transmission.update_gear(-1)
	_log_file.store_string("got %d\n" % transmission.current_gear_ratio_index)
	if old_ratio_index != transmission.current_gear_ratio_index:
			var errmsg: String = "FAILED: expected gear ratio index %d, got %d!\n\n" % [old_ratio_index, transmission.current_gear_ratio_index]
			printerr(errmsg)
			_log_file.store_string(errmsg)
			return false
	return true

func test_update_clutch_state() -> bool:
	var num_iterations: int = ceilf(transmission.clutch_response_time / test_delta) as int
	# Holding in the clutch
	var clutch_input: bool = true
	for i in range(1, num_iterations+1):
		transmission.update_clutch_state(clutch_input, test_delta)
		_log_file.store_string("Updating clutch state: input: %s, state: %f\n" % [utils.bool_to_string(clutch_input), transmission._clutch_state])
		if transmission._clutch_state == 1 && i != num_iterations:
			var errmsg: String = "FAILED: clutch locked in too early. Should have fully activated in %f seconds, actually took %f\n\n" % [transmission.clutch_response_time, i * test_delta]
			printerr(errmsg)
			_log_file.store_string(errmsg)
			return false
	# Ensuring clutch state did not exceed 1
	if transmission._clutch_state != 1:
		var errmsg: String = "FAILED: clutch did not reach correct value. Expected 1, got %f\n\n" % transmission._clutch_state
		printerr(errmsg)
		_log_file.store_string(errmsg)
		return false
	# Releasing the clutch
	clutch_input = false
	for i in range(1, num_iterations+1):
		transmission.update_clutch_state(clutch_input, test_delta)
		_log_file.store_string("Updating clutch state: input: %s, state: %f\n" % [utils.bool_to_string(clutch_input), transmission._clutch_state])
		if transmission._clutch_state <= 0 && i != num_iterations:
			var errmsg: String = "FAILED: clutch released too early. Should have fully released in %f seconds, actually took %f\n\n" % [transmission.clutch_response_time, i * test_delta]
			printerr(errmsg)
			_log_file.store_string(errmsg)
			return false
	# Ensuring clutch state did not go below zero
	if transmission._clutch_state != 0:
		var errmsg: String = "FAILED: clutch did not reach correct value. Expected 0, got %f\n\n" % transmission._clutch_state
		printerr(errmsg)
		_log_file.store_string(errmsg)
		return false
	return true

func test_get_ideal_rpm() -> bool:
	# Dummy case
	var old_ratio: float = transmission.gear_ratios[transmission.current_gear_ratio_index]
	transmission.gear_ratios[transmission.current_gear_ratio_index] = 1.0
	var ideal_rpm: float = transmission._get_ideal_rpm(1.0, 1.0, 1.0, 0.5, 1.0)
	_log_file.store_string("Get ideal RPM dummy case: motor_current_rpm == motor_proposed_rpm == rear_axle_rpm. Expected 1.0, got %f\n" % ideal_rpm)
	if ideal_rpm != 1.0:
		var errmsg: String = "FAILED: ideal RPM failed dummy case. Expected 1.0, got %f\n\n" % ideal_rpm
		printerr(errmsg)
		_log_file.store_string(errmsg)
		return false
	# Dummy case with gear ratio not 1
	transmission.gear_ratios[transmission.current_gear_ratio_index] = old_ratio
	ideal_rpm = transmission._get_ideal_rpm(1.0, 1.0, 1.0, 0.5, 1.0)
	var expected_ideal_rpm: float = sqrt(2.0 / (1.0 + pow(transmission.gear_ratios[transmission.current_gear_ratio_index], 2)))
	_log_file.store_string("Get ideal RPM dummy case with gear ratio %f. Expected %f, got %f.\n" % [transmission.gear_ratios[transmission.current_gear_ratio_index], expected_ideal_rpm, ideal_rpm])
	if abs(expected_ideal_rpm - ideal_rpm) > EPSILON:
		var errmsg: String = "FAILED: ideal RPM failed dummy case with adjusted gear ratio. Expected %f, got %f.\n\n" % [expected_ideal_rpm, ideal_rpm]
		printerr(errmsg)
		_log_file.store_string(errmsg)
		return false
	# A more realistic case
	ideal_rpm = transmission._get_ideal_rpm(2000.0, 150.0, 4.0, 1.0, 0.3)
	expected_ideal_rpm = 2000.2351069
	_log_file.store_string("Get ideal RPM:\n\tProposed Motor RPM: %f\n\tProposed Rear Axle RPM: %f\n\tMotor Flywheel Weight: %f\n\tRear Wheel Radius: %f\n\tRear Wheel Weight: %f\n\tExpected: %f, got: %f\n" % [2000.0, 150.0, 4.0, 0.3, 1.0, expected_ideal_rpm, ideal_rpm])
	if abs(expected_ideal_rpm - ideal_rpm) > EPSILON:
		var errmsg: String = "FAILED: ideal RPM failed realistic case. Expected %f, got %f.\n\n" % [expected_ideal_rpm, ideal_rpm]
		printerr(errmsg)
		_log_file.store_string(errmsg)
		return false
	# Higher gear-ratio
	transmission.update_gear(3)
	ideal_rpm = transmission._get_ideal_rpm(2000.0, 150.0, 4.0, 1.0, 0.3)
	expected_ideal_rpm = 1999.1019576
	_log_file.store_string("Get ideal RPM:\n\tProposed Motor RPM: %f\n\tProposed Rear Axle RPM: %f\n\tMotor Flywheel Weight: %f\n\tRear Wheel Radius: %f\n\tRear Wheel Weight: %f\n\tExpected: %f, got: %f\n" % [2000.0, 150.0, 4.0, 0.3, 1.0, expected_ideal_rpm, ideal_rpm])
	if abs(expected_ideal_rpm - ideal_rpm) > EPSILON:
		var errmsg: String = "FAILED: ideal RPM failed realistic case with higher gear ratio. Expected %f, got %f.\n\n" % [expected_ideal_rpm, ideal_rpm]
		printerr(errmsg)
		_log_file.store_string(errmsg)
		return false
	# Money shift - expect engine RPM to shoot up
	transmission.update_gear(2)
	ideal_rpm = transmission._get_ideal_rpm(4000.0, 5000.0, 4.0, 1.0, 3.0)
	expected_ideal_rpm = 7776.2837033
	_log_file.store_string("Get ideal RPM:\n\tProposed Motor RPM: %f\n\tProposed Rear Axle RPM: %f\n\tMotor Flywheel Weight: %f\n\tRear Wheel Radius: %f\n\tRear Wheel Weight: %f\n\tExpected: %f, got: %f\n" % [2000.0, 150.0, 4.0, 0.3, 1.0, expected_ideal_rpm, ideal_rpm])
	if abs(expected_ideal_rpm - ideal_rpm) > EPSILON:
		var errmsg: String = "FAILED: ideal RPM failed realistic case with higher gear ratio. Expected %f, got %f.\n\n" % [expected_ideal_rpm, ideal_rpm]
		printerr(errmsg)
		_log_file.store_string(errmsg)
		return false
	transmission.current_gear_ratio_index = 0
	return true
func test_transmit_energy() -> bool:
	motor.set_true_rpm(4000.0)
	rear_axle.set_true_rpm(400.0)
	var motor_proposed_rpm: float = 4500.0
	var rear_axle_proposed_rpm: float = 400.0
	var test_pass: bool = true
	# Set clutch to be fully engaged
	transmission._clutch_state = 1.0
	# Expect RPMs to not change
	transmission.transmit_energy(motor_proposed_rpm, rear_axle_proposed_rpm, motor, rear_axle)
	_log_file.store_string("Transmit energy with clutch fully engaged: \n\tProposed Motor RPM: %f, Resulting RPM: %f\n\tProposed Rear Axle RPM: %f, Resulting RPM: %f\n" % [motor_proposed_rpm, motor.true_rpm, rear_axle_proposed_rpm, rear_axle.true_rpm])
	if motor_proposed_rpm != motor.true_rpm:
		test_pass = false
		var errmsg: String = "FAILED: motor has incorrect RPM. Expected %f, got %f\n\n" % [motor_proposed_rpm, motor.true_rpm]
		printerr(errmsg)
		_log_file.store_string(errmsg)
	if rear_axle_proposed_rpm != rear_axle.true_rpm:
		test_pass = false
		var errmsg: String = "FAILED: rear axle has incorrect RPM. Expected %f, got %f\n\n" % [rear_axle_proposed_rpm, rear_axle.true_rpm]
		printerr(errmsg)
		_log_file.store_string(errmsg)
	if not test_pass:
		return false
	# Set clutch to be fully disengaged
	transmission._clutch_state = 0.0
	motor.set_true_rpm(4000.0)
	rear_axle.set_true_rpm(80.0)
	transmission.transmit_energy(motor_proposed_rpm, rear_axle_proposed_rpm, motor, rear_axle)
	_log_file.store_string("Transmit energy with clutch fully disengaged: \n\tProposed Motor RPM: %f, Resulting RPM: %f\n\tProposed Rear Axle RPM: %f, Resulting RPM: %f\n" % [motor_proposed_rpm, motor.true_rpm, rear_axle_proposed_rpm, rear_axle.true_rpm])
	if abs(motor.true_rpm * transmission.gear_ratios[transmission.current_gear_ratio_index] - rear_axle.true_rpm) > EPSILON:
		var errmsg: String = "FAILED: rear axle RPM is not accurate. Expected %f, got %f\n\n" % [motor.true_rpm * transmission.gear_ratios[transmission.current_gear_ratio_index], rear_axle.true_rpm]
		printerr(errmsg)
		_log_file.store_string(errmsg)
		return false
	# Test engaging clutch
	transmission._clutch_state = 1.0
	motor.set_true_rpm(4000.0)
	rear_axle.set_true_rpm(80.0)
	rear_axle_proposed_rpm = 80.0
	var num_iterations: int = ceilf(transmission.clutch_response_time / test_delta) as int
	for i in range(1, num_iterations+1):
		transmission.update_clutch_state(0, test_delta)
		transmission.transmit_energy(motor_proposed_rpm, rear_axle_proposed_rpm, motor, rear_axle)
		rear_axle_proposed_rpm = rear_axle.true_rpm
		_log_file.store_string("Transmit energy with clutch being disengaged.\n\tTime since disengagement: %f\n\tMotor RPM: %f\n\t Rear Axle RPM: %f\n" % [test_delta * i, motor.true_rpm, rear_axle.true_rpm])
	# Test negative gear ratio
	var old_ratio: float = transmission.gear_ratios[transmission.current_gear_ratio_index]
	transmission.gear_ratios[transmission.current_gear_ratio_index] = -0.02
	transmission._clutch_state = 0.0
	motor.set_true_rpm(0.0)
	rear_axle.set_true_rpm(0.0)
	rear_axle_proposed_rpm = 0.0
	motor_proposed_rpm = 100.0
	transmission.transmit_energy(motor_proposed_rpm, rear_axle_proposed_rpm, motor, rear_axle)
	_log_file.store_string("Transmit energy with negative gear ratio: Gear Ratio: %f, Motor RPM: %f, Rear Axle RPM: %f\n" % [transmission.gear_ratios[transmission.current_gear_ratio_index], motor.true_rpm, rear_axle.true_rpm])
	if rear_axle.true_rpm >= 0.0:
		var errmsg: String = "FAILED: rear axle RPM should be negative, is actually %f\n\n" % rear_axle.true_rpm
		printerr(errmsg)
		_log_file.store_string(errmsg)
		return false
	transmission.gear_ratios[transmission.current_gear_ratio_index] = old_ratio
	return true
