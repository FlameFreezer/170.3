class_name FrontWheels

# constants set by _init()
var max_static_friction: float ## max force that can be applied by the front wheels without slipping.
var max_kinetic_friction: float ## max force that can be applied by the front wheels while slipping.
var chassis_mass: float ## mass of the whole car.
var front_axle_distance_from_com: float ## distance from car's center of mass to the front axle.
var rear_axle_distance_from_com: float ## distance from the car's center of mass to the rear axle.
var max_steering_angle: float ## in range [0, 90). max angle the wheels can reach relative to the chassis when steering.

# updated every frame
var wheel_angle: float ## current angle of the front wheels relative to the chassis, in radians.
var slipping: bool ## whether or not the front wheels are currently slipping.

func _init(in_chassis_mass: float, in_front_axle_offset: float, in_rear_axle_offset: float, static_friction_coeff: float, kinetic_friction_coeff: float, in_max_steering_angle: float, starting_steer_angle: float) -> void:
	chassis_mass = in_chassis_mass
	front_axle_distance_from_com = abs(in_front_axle_offset)
	rear_axle_distance_from_com = abs(in_rear_axle_offset)
	max_static_friction = in_chassis_mass * static_friction_coeff * 9.81
	max_kinetic_friction = in_chassis_mass * kinetic_friction_coeff * 9.81
	max_steering_angle = in_max_steering_angle
	
	wheel_angle = starting_steer_angle
	slipping = false

# ^---------- INITIALIZATION AND STORAGE SECTION ----------^

# v---------- INPUT HANDLING SECTION ----------v

## steer_input: in range [-1, 1]. taken from player's steering wheel input.
func set_wheel_angle(steer_input: float):
	wheel_angle = max_steering_angle * steer_input
	pass

# ^---------- INPUT HANDLING SECTION ----------^

# v---------- PHYSICS SECTION ----------v

## car_motion: proposed motion vector of the car this frame.
## car_direction: direction the car is facing this frame.
func get_force_output(car_motion: Vector2, car_direction: Vector2, delta: float) -> Vector2:
	
	# determine wheel angle in global space
	var global_wheel_angle: float = car_direction.angle() + deg_to_rad(wheel_angle)
	var car_normal_vec: Vector2 = Vector2(cos(car_direction.angle() - PI / 2), sin(car_direction.angle() - PI / 2))
	var wheel_normal_vec: Vector2 = Vector2(cos(global_wheel_angle - PI / 2), sin(global_wheel_angle - PI / 2)) # this will point to the right at steering angle 0
	
	# find cornering force demand
	var cornering_motion: Vector2 = car_normal_vec * car_normal_vec.dot(car_motion * delta)
	var cornering_distance: float = cornering_motion.length()
	var adjusted_cornering_demand: float = 2 * cornering_distance / pow(delta, 2)
	adjusted_cornering_demand /= 1 + front_axle_distance_from_com / rear_axle_distance_from_com
	
	# find steering force demand
	var slip_motion: Vector2 = wheel_normal_vec * ((car_motion - cornering_motion) * delta).dot(wheel_normal_vec)
	var slip_distance: float = slip_motion.length()
	var slip_demand: float = 2 * slip_distance / pow(delta, 2)
	
	# set slip state
	if (!slipping && (slip_demand) * chassis_mass > max_static_friction):
		slipping = true;
	elif(slipping && (slip_demand) * chassis_mass < max_kinetic_friction):
		slipping = false;
	
	# cap force outputs and build return vector
	
	var out_steering_vec: Vector2
	if (slipping):
		out_steering_vec = slip_motion.normalized() * -1 * min(slip_demand * chassis_mass, max_kinetic_friction)
	else:
		out_steering_vec = slip_motion.normalized() * -1 * min(slip_demand * chassis_mass, max_static_friction)
	var out_steering_force: float = out_steering_vec.length()
	
	var out_cornering_vec: Vector2
	if (slipping):
		out_cornering_vec = cornering_motion.normalized() * -1 * min(adjusted_cornering_demand * chassis_mass, max_kinetic_friction - out_steering_force)
	else:
		out_cornering_vec = cornering_motion.normalized() * -1 * min(adjusted_cornering_demand * chassis_mass, max_static_friction - out_steering_force)
	
	var return_vec: Vector2 = out_steering_vec + out_cornering_vec
	return return_vec
