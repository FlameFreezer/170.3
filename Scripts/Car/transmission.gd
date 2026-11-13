extends Node3D

@export var gear_ratios: Array[float]
@export var clutch_response_time: float
var clutch_state: float = 0.0
var current_gear_ratio_index: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var clutch_input: bool = Input.is_action_pressed("clutch")
	if (clutch_input):
		clutch_state = move_toward(clutch_state, clutch_response_time, delta)
	else:
		clutch_state = move_toward(clutch_state, 0.0, delta)
	
	## TODO: get these from the rear wheels and transmission
	var engine_rev_state: float = 0.0
	var rear_wheels_rev_state: float = 0.0
	
	if (clutch_state == 0.0):
		## TODO: pass engine and rear wheels rev states back to them
		pass
	else:
		_calculate_rev_states(engine_rev_state, rear_wheels_rev_state)
		
func _calculate_rev_states(engine_rev_state: float, rear_wheels_rev_state: float):
	const engine_flywheel_weight: float = 1.0 ##TODO: grab from engine node
	const rear_wheel_weight: float = 1.0 ##TODO: grab from rear wheels
	var ke_engine: float = pow(engine_rev_state, 2) * 0.5 * engine_flywheel_weight
	var ke_rear_wheels: float = pow(rear_wheels_rev_state, 2) * 0.5 * rear_wheel_weight
	var ke_diff := ke_engine - ke_rear_wheels
	var rev_difference: float = engine_rev_state - rear_wheels_rev_state
	
	pass
