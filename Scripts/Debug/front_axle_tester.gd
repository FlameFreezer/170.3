class_name FrontAxleTester extends Resource

var front_axle: FrontAxle
@export var chassis_mass: float
@export var static_friction_coeff: float
@export var kinetic_friction_coeff: float
@export var test_delta: float

var _log_file: FileAccess

func run(log_file: FileAccess) -> bool:
	_log_file = log_file
	var test_pass: bool = true
	front_axle = FrontAxle.new(chassis_mass, 0.0, 0.0, static_friction_coeff, kinetic_friction_coeff, 45, 0)
	var msg: String = "STARTING: front axle get force output tests\n\n"
	print(msg)
	_log_file.store_string(msg)
	test_pass = test_get_force_output()
	if test_pass:
		msg = utils.get_test_passed_str(test_get_force_output)
		print(msg)
		_log_file.store_string(msg)
	return test_pass
func test_get_force_output() -> bool:
	var test_pass: bool = true
	
	# Stationary car
	var car_velocity: Vector2 = Vector2.ZERO
	var car_direction: Vector2 = Vector2.UP
	var force: Vector2 = front_axle.get_force_output(car_velocity, car_direction, test_delta)
	_log_file.store_string("Getting force output for a car which should not move.\n\tInitial velocity: %v\n\tInitial direction: %v\n" % [car_velocity, car_direction])
	if force != Vector2.ZERO:
		var errmsg: String = "FAILED: front axle should have produced a force of zero, but actually gave %v\n\n" % force
		printerr(errmsg)
		_log_file.store_string(errmsg)
		test_pass = false
	if front_axle.slipping:
		var errmsg: String = "FAILED: front axle incorrectly set to slipping\n\n"
		printerr(errmsg)
		_log_file.store_string(errmsg)
		test_pass = false
	if not test_pass:
		return false
	# Car should not be slipping
	car_velocity = Vector2(0.0, -200.0)
	force = front_axle.get_force_output(car_velocity, car_direction, test_delta)
	_log_file.store_string("Getting force output for a car which should not slip.\n\nInitial velocity: %v\n\tInitial direction: %v\n" % [car_velocity, car_direction])
	if front_axle.slipping:
		var errmsg: String = "FAILED: front axle incorrectly set to slipping\n\n"
		printerr(errmsg)
		_log_file.store_string(errmsg)
		return false
	return test_pass
