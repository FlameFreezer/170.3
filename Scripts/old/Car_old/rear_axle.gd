class_name RearAxle

# constants set by _init()
var max_static_friction_force: float ## max force that the rear wheels can exert without slipping.
var max_kinetic_friction_force: float ## max force that the rear wheels can exert while slipping.
var kinetic_friction_accel_factor: float ## Proportion of kinetic friction that can be used by the rear wheels to accelerate.
##                                          The rest of the available kinetic friction force is used to provide cornering force.
##                                          In range [0, 1].
##                                          A value of zero means that the rear wheels cannot accelerate the car while in a slide.
##                                          A value of one means that the rear wheels cannot apply any cornering force while the car is in a slide.
var chassis_mass: float ## mass of the whole car.
var wheel_mass: float ## mass of the rear wheels.
var wheel_diameter: float ## diameter of the rear wheels.
var drag_factor: float ## In range [0, 1]. proportion of car's speed lost per second under no acceleration. A value of 0 means no drag.
var handbrake_strength: float ## how much the transmission favors the rear wheels over the engine when the handbrake is fully active.

# updated every frame
var true_rpm: float ## rear wheels' final RPM value at the end of each frame.
var handbrake_state: float ## in range [0, 1]. How much the handbrake is engaged. A value of 0 means the handbrake is not applied.
var adjusted_wheel_mass: float ## How much the transmission will be told the rear wheels weigh, based on actual rear wheel weight and handbrake state.
var slipping: bool ## Whether or not the rear wheels are sliding.

## Initializes variables and constants at the start of a scene.
func _init(in_chassis_mass: float, static_friction_coeff: float, kinetic_friction_coeff: float, in_kf_accel_factor: float, in_wheel_mass: float, in_wheel_diameter: float, in_drag_factor: float, in_handbrake_strength: float, starting_rpm: float) -> void:
	chassis_mass = in_chassis_mass
	max_static_friction_force = in_chassis_mass * static_friction_coeff * 9.81
	max_kinetic_friction_force = in_chassis_mass * kinetic_friction_coeff * 9.81
	wheel_mass = in_wheel_mass
	wheel_diameter = in_wheel_diameter
	kinetic_friction_accel_factor = in_kf_accel_factor
	drag_factor = in_drag_factor
	handbrake_strength = in_handbrake_strength
	
	true_rpm = starting_rpm
	handbrake_state = 0
	adjusted_wheel_mass = in_wheel_mass
	slipping = false

# ^---------- INITIALIZATION AND STORAGE SECTION ----------^

# v---------- DRIVETRAIN SIMULATOR SECTION ----------v

## input_value is in range [0, 1]; comes from the input system.
func update_handbrake(input_value: float) -> void:
	handbrake_state = input_value
	adjusted_wheel_mass = wheel_mass + handbrake_strength * handbrake_state

## called to give transmission the information it needs to determine current_rpm.
## returns the rear wheels' proposed rpm.
func propose_rpm(delta: float) -> float:
	var proposed_rpm: float
	if (handbrake_state == 0): # if handbrake is not applied, then apply drag
		proposed_rpm = true_rpm * (1 - drag_factor * delta)
		return proposed_rpm
	else:
		proposed_rpm = true_rpm * (1 - handbrake_state)
		if (true_rpm > 0):
			proposed_rpm = max(proposed_rpm, 0)
		else:
			proposed_rpm = min(proposed_rpm, 0)
		return proposed_rpm

## sets the final rpm of the rear wheels this frame.
func set_true_rpm(in_rpm: float) -> void:
	true_rpm = in_rpm


# ^---------- DRIVETRAIN SIMULATOR SECTION ----------^

# v---------- PHYSICS SECTION ----------v

## called only AFTER true_rpm is updated.
## axle_movement_vec is a vector representing the axle's movement last frame.
## car_direction is car's direction vector from last frame.
## delta is the physics timestep.
func get_force_output(axle_movement_vec: Vector2, car_direction: Vector2, delta: float) -> Vector2:
	# determine ground speed of wheels from rpm
	var proposed_wheel_translation: Vector2 = car_direction.normalized() * utils.snap(wheel_diameter * PI * true_rpm / 60 * delta)
	# use previous car speed to determine acceleration force demand
	var car_forward_velocity: Vector2 = car_direction.normalized() * car_direction.normalized().dot(axle_movement_vec)
	var acceleration_demand_vec: Vector2 = proposed_wheel_translation - car_forward_velocity
	var acceleration_demand: float = acceleration_demand_vec.length() * chassis_mass
	
	# find slip angle and use it to determine cornering force demand
	var car_normal: Vector2 = Vector2(utils.snap(cos(car_direction.angle() + PI / 2)), utils.snap(sin(car_direction.angle() + PI / 2)))
	var slip_motion: Vector2 = car_normal * (axle_movement_vec).dot(car_normal)
	var slip_distance: float = slip_motion.length()
	var cornering_demand: float = slip_distance * chassis_mass
	
	var delta_squared: float = pow(delta, 2) # conversion factor for friction force caps
	
	# handle slip state changes
	if (!slipping && sqrt(pow(acceleration_demand, 2) + pow(cornering_demand, 2)) > max_static_friction_force * delta_squared):
		slipping = true;
	elif(slipping && sqrt(pow(acceleration_demand, 2) + pow(cornering_demand, 2)) < max_kinetic_friction_force * delta_squared):
		slipping = false;
	
	# generate and return force vector
	var acceleration_output_vec: Vector2 # acceleration force component
	var cornering_output_vec: Vector2 # cornering force component
	if (slipping):
		cornering_output_vec = slip_motion.normalized() * -1 * utils.snap(min(abs(cornering_demand), max_kinetic_friction_force * delta_squared * (1 - kinetic_friction_accel_factor)))
		acceleration_output_vec = acceleration_demand_vec.normalized() * utils.snap(min(abs(acceleration_demand), max_kinetic_friction_force * delta_squared - cornering_output_vec.length()))
	else:
		cornering_output_vec = slip_motion.normalized() * -1 * utils.snap(abs(cornering_demand))
		acceleration_output_vec = acceleration_demand_vec.normalized() * utils.snap(abs(acceleration_demand))
	
	# variables for debugging
	var _acceleration_output_force: float = acceleration_output_vec.length()
	var _cornering_output_force: float = cornering_output_vec.length()
	
	var return_vec: Vector2 = acceleration_output_vec + cornering_output_vec
	return return_vec
