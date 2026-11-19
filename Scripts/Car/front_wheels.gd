class_name FrontWheels

# constants set by _init()
var max_static_friction: float # max force that can be applied by the front wheels without slipping.
var max_kinetic_friction: float # max force that can be applied by the front wheels while slipping.
var chassis_mass: float # mass of the whole car.
var front_axle_offset: float # distance from car's center of mass to the front axle.
var rear_axle_offset: float # distance from the car's center of mass to the rear axle.
var max_steering_angle: float # in range [0, 90). max angle the wheels can reach relative to the chassis when steering.

# updated every frame
var wheel_angle: float # current angle of the front wheels relative to the chassis, in radians.
var slipping: bool # whether or not the front wheels are currently slipping.

func _init(in_chassis_mass: float, in_front_axle_offset: float, in_rear_axle_offset: float, static_friction_coeff: float, kinetic_friction_coeff: float, in_max_steering_angle: float, starting_steer_angle: float) -> void:
	chassis_mass = in_chassis_mass
	front_axle_offset = in_front_axle_offset
	rear_axle_offset = in_rear_axle_offset
	max_static_friction = in_chassis_mass * static_friction_coeff
	max_kinetic_friction = in_chassis_mass * kinetic_friction_coeff
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
func get_force_output(car_motion: Vector2, car_direction: Vector2) -> Vector2:
	
	# determine wheel angle in global space
	var global_wheel_angle = car_direction.angle() + wheel_angle
	var wheel_normal_vec = Vector2(cos(global_wheel_angle - PI / 2), sin(global_wheel_angle - PI / 2)) # this will point to the right at steering angle 0
	
	# get total force demand on front wheels
	var slip_motion = wheel_normal_vec * (wheel_normal_vec.dot(car_motion))
	var slip_force = slip_motion.length() * chassis_mass
	
	# determine whether force demands cause wheels to slide or not, and create friction force vector
	if (!slipping && slip_force > max_static_friction):
		slipping = true;
	elif (slipping && slip_force < max_kinetic_friction):
		slipping = false;
	
	# decompose force demand into two vectors
	var car_normal_vec: Vector2 = Vector2(cos(car_direction.angle() + PI / 2), sin(car_direction.angle() + PI / 2))
	var cornering_motion: Vector2 = car_normal_vec * slip_motion.dot(car_normal_vec) * rear_axle_offset / front_axle_offset # component of wheel load coming from cornering inertia
	var cornering_force: float = cornering_motion.length() * chassis_mass
	var steering_motion: Vector2 = wheel_normal_vec * slip_motion.dot(car_direction) / car_direction.length() # component of wheel load coming from steering angle
	var steering_force: float = steering_motion.length() * chassis_mass
	
	# create and return traction force vector
	var out_force: Vector2
	if (slipping):
		out_force = steering_motion.normalized() * -1 * min(max_kinetic_friction, steering_force) # steering force going first means wheels prioritize spinning the car over preventing sideways motion
		out_force += cornering_motion.normalized() * -1 * rear_axle_offset / front_axle_offset * min(max_kinetic_friction - steering_force, cornering_force)
	else:
		out_force = steering_motion.normalized() * -1 * min(max_static_friction, steering_force)
		out_force += cornering_motion.normalized() * -1 * rear_axle_offset / front_axle_offset * min(max_static_friction - steering_force, cornering_force)
	
	# return friction force vector
	return out_force
