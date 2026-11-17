class_name FrontWheels extends Node3D

## float in range [0, 90). max angle the wheels can reach relative to the car in degrees.
@export var max_steering_angle: float

## float. static friction (non-sliding) coefficient of front wheels.
@export var static_friction: float

## float. kinetic friction (sliding) coefficient of front wheels.
@export var kinetic_friction: float




@onready var _slip_threshold = 1 * static_friction

@onready var _kinetic_friction_force = 1 * kinetic_friction

## current angle of wheels relative to car, in radians
var curr_wheel_angle: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

## steer_input: in range [-1, 1]. taken from player's steering wheel input.
func set_wheel_angle(steer_input: float):
	curr_wheel_angle = max_steering_angle * steer_input
	pass

## car_motion: proposed motion vector of the car this frame.
## car_direction: direction the car is facing this frame.
func get_force_output(car_motion: Vector2, car_direction: Vector2):
	
	# determine direction of cornering force
	var wheel_angle = car_direction.angle() + curr_wheel_angle
	var wheel_normal_vec = Vector2(cos(wheel_angle + PI / 2), sin(wheel_angle + PI / 2))
	
	# get cornering force
	var slip_motion = wheel_normal_vec * (wheel_normal_vec.dot(car_motion))
	var slip_force = slip_motion.length()
	
	# determine whether force demands cause wheels to slide or not, and create friction force vector
	var out_force: Vector2
	if (slip_force > _slip_threshold):
		out_force = slip_motion.normalized() * -1 * _kinetic_friction_force
	else:
		out_force = slip_motion * -1
	
	# return friction force vector
	return out_force
