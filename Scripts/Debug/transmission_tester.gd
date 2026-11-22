class_name TransmissionTester extends Resource

var transmission: Transmission
var motor: Motor
var rear_axle: RearAxle

@export var gear_ratios: Array[float]
@export var clutch_response_time: float

@export var test_delta: float
@export var rpm_print_gap: float

var _log_file: FileAccess

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
