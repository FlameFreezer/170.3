class_name FrontAxle

# constants set by _init()
var max_static_friction_force: float ## max force that can be applied by the front wheels without slipping.
var max_kinetic_friction_force: float ## max force that can be applied by the front wheels while slipping.
var chassis_mass: float ## mass of the whole car.
var max_steering_angle: float ## in range [0, 90). max angle the wheels can reach relative to the chassis when steering.

# updated every frame
var wheel_angle: float ## current angle of the front wheels relative to the chassis, in radians.
var slipping: bool ## whether or not the front wheels are currently slipping.

func _init(in_chassis_mass: float, static_friction_coeff: float, kinetic_friction_coeff: float, in_max_steering_angle: float, starting_steer_angle: float) -> void:
	chassis_mass = in_chassis_mass
	max_static_friction_force = in_chassis_mass * static_friction_coeff * 9.81
	max_kinetic_friction_force = in_chassis_mass * kinetic_friction_coeff * 9.81
	max_steering_angle = in_max_steering_angle
	
	wheel_angle = starting_steer_angle
	slipping = false

# ^---------- INITIALIZATION AND STORAGE SECTION ----------^

# v---------- INPUT HANDLING SECTION ----------v

## steer_input: in range [-1, 1]. taken from player's steering wheel input.
func set_wheel_angle(steer_input: float):
	var clamped_input: float = clamp(steer_input,  -1.0, 1.0)
	wheel_angle = deg_to_rad(max_steering_angle) * clamped_input

# ^---------- INPUT HANDLING SECTION ----------^

# v---------- PHYSICS SECTION ----------v

## axle_movement_vec is a vector representing the axle's movement last frame.
## car_direction: direction the car is facing this frame.
func get_force_output(axle_movement_vec: Vector2, car_direction: Vector2, delta: float) -> Vector2:
	
	# determine wheel angle in global space
	var global_wheel_angle: float = car_direction.angle() + wheel_angle
	var _global_wheel_angle_degs: float = rad_to_deg(global_wheel_angle)
	var axle_movement_angle: float = axle_movement_vec.angle()
	
	# apply epsilon deadzone to wheel angle differences
	if (utils.snap(global_wheel_angle - axle_movement_angle) == 0):
		return Vector2(0.0, 0.0)
	
	var wheel_normal_vec: Vector2 = Vector2(utils.snap(cos(global_wheel_angle - PI / 2)), utils.snap(sin(global_wheel_angle - PI / 2)))
	var _wheel_normal_degs: float = rad_to_deg(wheel_normal_vec.angle())
	
	# find steering force demand
	var slip_motion: Vector2 = wheel_normal_vec * axle_movement_vec.dot(wheel_normal_vec)
	var slip_distance: float = slip_motion.length()
	var slip_demand: float = slip_distance * chassis_mass
	
	var delta_squared = pow(delta, 2)
	
	# set slip state
	if (!slipping && slip_demand > max_static_friction_force * delta_squared):
		slipping = true;
	elif(slipping && slip_demand < max_kinetic_friction_force * delta_squared):
		slipping = false;
	
	# cap force outputs and build return vector
	var return_vec: Vector2
	if (slipping):
		return_vec = slip_motion.normalized() * utils.snap(-1 * max_kinetic_friction_force * delta_squared)
	else:
		return_vec = slip_motion.normalized() * utils.snap(-1 * abs(slip_demand))
	
	return return_vec
