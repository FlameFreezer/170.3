class_name PhysicsTestCube extends RigidBody3D

var forward_input_down: bool
var back_input_down: bool
var left_input_down: bool
var right_input_down: bool

var cube_last_pos: Vector3

signal set_hud_values(String)

@export var force_to_apply: float
var use_impulse: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	can_sleep = false
	use_impulse = false
	cube_last_pos = global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (Input.is_action_just_pressed("throttle")):
		forward_input_down = true
	if (Input.is_action_just_pressed("backwards (FOR PHYSICS TESTING ONLY. NOT FOR CAR CONTROL)")):
		back_input_down = true
	if (Input.is_action_just_pressed("steer left")):
		left_input_down = true
	if (Input.is_action_just_pressed("steer right")):
		right_input_down = true
	if (Input.is_action_just_pressed("handbrake")):
		use_impulse = !use_impulse

func _physics_process(delta: float) -> void:
	var impulse_force: float = force_to_apply
	var force_force: float = force_to_apply / delta
	if (forward_input_down):
		if (use_impulse):
			apply_impulse(Vector3(0, 0, impulse_force * -1), Vector3(0, 0, 0))
		else:
			apply_force(Vector3(0, 0, force_force * -1), Vector3(0, 0, 0))
	if (back_input_down):
		if (use_impulse):
			apply_impulse(Vector3(0, 0, impulse_force), Vector3(0, 0, 0))
		else:
			apply_force(Vector3(0, 0, force_force), Vector3(0, 0, 0))
	if (right_input_down):
		if (use_impulse):
			apply_impulse(Vector3(impulse_force, 0, 0), Vector3(0, 0, 0))
		else:
			apply_force(Vector3(force_force, 0, 0), Vector3(0, 0, 0))
	if (left_input_down):
		if (use_impulse):
			apply_impulse(Vector3(impulse_force * -1, 0, 0), Vector3(0, 0, 0))
		else:
			apply_force(Vector3(force_force * -1, 0, 0), Vector3(0, 0, 0))
	
	var hud_string := "cube's position: %v\ncube's velocity: %v\nsleeping: %s\nusing impulse: %s" % [global_position, (global_position - cube_last_pos) / delta, utils.bool_to_string(sleeping), utils.bool_to_string(use_impulse)]
	set_hud_values.emit(hud_string)
	cube_last_pos = global_position
		
	forward_input_down = false
	back_input_down = false
	left_input_down = false
	right_input_down = false
