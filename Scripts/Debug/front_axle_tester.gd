class_name FrontAxleTester extends Resource

var front_axle: FrontAxle
@export var chassis_mass: float
@export var static_friction_coeff: float
@export var kinetic_friction_coeff: float
@export var test_delta: float
@export var continue_after_failing: bool

var _log_file: FileAccess

func run(log_file: FileAccess) -> bool:
	_log_file = log_file
	var test_pass: bool = true
	front_axle = FrontAxle.new(chassis_mass, static_friction_coeff, kinetic_friction_coeff, 45, 0)
	var msg: String = "STARTING: front axle set wheel angle tests\n\n"
	_log_file.store_string(msg)
	
	test_pass = test_set_wheel_angle()
	if (test_pass):
		msg = "PASSED: front_axle.test_set_wheel_angle passed all tests.\n\n"
		print(msg)
		_log_file.store_string(msg)
	
	if (test_pass || continue_after_failing):
		msg = "STARTING: front axle get force output tests\n\n"
		print(msg)
		_log_file.store_string(msg)
		test_pass = test_get_force_output()
	if test_pass:
		msg = utils.get_test_passed_str(test_get_force_output)
		print(msg)
		_log_file.store_string(msg)
	
	if (test_pass):
		msg = "PASSED: FrontAxle passed all tests.\n"
		print(msg)
		_log_file.store_string(msg)
	return test_pass

func test_set_wheel_angle() -> bool:
	var to_ret: bool = true
	var msg: String
	
	# test valid steering angle vlaues
	var to_wheel_angle: float = -1.0
	while (to_wheel_angle <= 1.0):
		front_axle.set_wheel_angle(to_wheel_angle)
		if (front_axle.wheel_angle != to_wheel_angle * deg_to_rad(front_axle.max_steering_angle)):
			to_ret = false
			msg = "FAILED: front_axle_tester.test_set_wheel_angle: failed to set wheel angle correctly using steering input of %f." % to_wheel_angle
			printerr(msg)
			_log_file.store_string(msg)
			if (!continue_after_failing):
				return to_ret
		to_wheel_angle += 0.01
	
	# test invalid steering angle values
	to_wheel_angle = -50.0
	front_axle.set_wheel_angle(to_wheel_angle)
	if (abs(front_axle.wheel_angle) > abs(front_axle.max_steering_angle)):
		to_ret = false
		msg = "FAILED: front_axle_tester.set_wheel_angle: failed to keep wheel angle within the range defined by max_steering_angle given invalid steering input value of %f." % to_wheel_angle
		printerr(msg)
		_log_file.store_string(msg)
		if (!continue_after_failing):
			return to_ret
	
	to_wheel_angle = 50.0
	front_axle.set_wheel_angle(to_wheel_angle)
	if (abs(front_axle.wheel_angle) > abs(front_axle.max_steering_angle)):
		to_ret = false
		msg = "FAILED: front_axle_tester.set_wheel_angle: failed to keep wheel angle within the range defined by max_steering_angle given invalid steering input value of %f." % to_wheel_angle
		printerr(msg)
		_log_file.store_string(msg)
		if (!continue_after_failing):
			return to_ret
	return to_ret

func test_get_force_output() -> bool:
	var msg: String
	var to_ret: bool = true
	
	# Stationary car
	#var car_velocity: Vector2 = Vector2.ZERO
	#var car_direction: Vector2 = Vector2.UP
	#var force: Vector2 = front_axle.get_force_output(car_velocity, car_direction, test_delta)
	#_log_file.store_string("Getting force output for a car which should not move.\n\tInitial velocity: %v\n\tInitial direction: %v\n" % [car_velocity, car_direction])
	#if force != Vector2.ZERO:
		#var errmsg: String = "FAILED: front axle should have produced a force of zero, but actually gave %v\n\n" % force
		#printerr(errmsg)
		#_log_file.store_string(errmsg)
		#test_pass = false
	#if front_axle.slipping:
		#var errmsg: String = "FAILED: front axle incorrectly set to slipping\n\n"
		#printerr(errmsg)
		#_log_file.store_string(errmsg)
		#test_pass = false
	#if not test_pass:
		#return false
	## Car should not be slipping
	#car_velocity = Vector2(0.0, -200.0)
	#force = front_axle.get_force_output(car_velocity, car_direction, test_delta)
	#_log_file.store_string("Getting force output for a car which should not slip.\n\nInitial velocity: %v\n\tInitial direction: %v\n" % [car_velocity, car_direction])
	#if front_axle.slipping:
		#var errmsg: String = "FAILED: front axle incorrectly set to slipping\n\n"
		#printerr(errmsg)
		#_log_file.store_string(errmsg)
		#return false
	
	# run tests that should return 0 force (straight steering + straight forward velocity)
	var current_vehicle_velocity: Vector2 = Vector2.ZERO
	var current_vehicle_direction: Vector2 = Vector2.UP
	front_axle.set_wheel_angle(0)
	while (current_vehicle_velocity.length() < 500.0):
		var output: Vector2 = front_axle.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
		if (output.length() != 0.0):
			to_ret = false
			msg = "FAILED: front_axle no acceleration needed test (no steering angle): get_force_output returned a non-zero acceleration value given wheel angle %f and vehicle speed %f in direction %f.\n" % [rad_to_deg(front_axle.wheel_angle), current_vehicle_velocity.length(), rad_to_deg(current_vehicle_direction.angle())]
			printerr(msg)
			_log_file.store_string(msg)
			var _trace: Vector2 = front_axle.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
			if (!continue_after_failing):
				return to_ret
		current_vehicle_velocity += Vector2(0, -0.25)
	
	if (to_ret):
		msg = "PASSED: front_axle no acceleration needed test (no steering angle)\n\n"
		print(msg)
		_log_file.store_string(msg)
	
	# run tests that should return 0 force (angled steering + equally angled velocity)
	var current_steering_angle: float = -1.0
	current_vehicle_direction = Vector2.UP
	while (current_steering_angle <= 1.0):
		front_axle.set_wheel_angle(current_steering_angle)
		current_vehicle_velocity = Vector2.ZERO
		var current_velocity_direction: float = current_vehicle_direction.angle() + front_axle.wheel_angle # current_vehicle_direction.angle() IS A PILE OF JANK. FUCK YOU!
		var _direction_degs: float = rad_to_deg(current_velocity_direction)
		var velocity_increment_vector: Vector2 = Vector2(cos(current_velocity_direction), sin(current_velocity_direction)) / 5
		while (current_vehicle_velocity.length() < 194.0): # 194 meters per frame is the speed limit that our physics can handle.
			msg = "front_axle_tester: starting no acceleration needed test at wheel angle %f and velocity %f at velocity angle %f\n" % [rad_to_deg(current_velocity_direction), current_vehicle_velocity.length(), rad_to_deg(current_vehicle_velocity.angle())]
			# _log_file.store_string(msg)
			var output: Vector2 = front_axle.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
			if (utils.snap(output.length()) != 0.0):
				to_ret = false
				msg = "FAILED: front_axle no acceleration needed test (varied steering angle): get_force_output returned a non-zero acceleration value given wheel angle %f and vehicle speed %f in direction %f.\n" % [rad_to_deg(current_velocity_direction), current_vehicle_velocity.length(), rad_to_deg(current_vehicle_velocity.angle())]
				printerr(msg)
				_log_file.store_string(msg)
				var _trace: Vector2 = front_axle.get_force_output(current_vehicle_velocity, current_vehicle_direction, test_delta)
				if (!continue_after_failing):
					return to_ret
			current_vehicle_velocity += velocity_increment_vector
		current_steering_angle += 0.01
		_log_file.store_string("\n")
	
	# verify location and behavior of slip point (straight steering + pure normal load)
	
	# verify location and behavior of catch point (straight steering + pure normal load)
	
	# verify location and behavior of slip point (angled steering + straight forward velocity)
	
	# verify location and behavior of catch point (angled steering + straight forward velocity)
	
	# verify location and behavior of slip point (angled steering + non-equally angled velocity)
	
	# verify location and behavior of catch point (angled steering + non-equally angled velocity)
	
	return to_ret
