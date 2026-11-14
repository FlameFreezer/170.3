extends Node3D

@export var gear_ratios: Array[float]
@export var clutch_response_time: float
var clutch_state: float = 0.0
## Index into the gear ratios array
var current_gear_ratio_index: int = 0

@onready var _motor: Motor = $Motor

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
	var engine_proposed_revs: float = 0.0
	var rear_wheels_rev_state: float = 0.0
	
	if (clutch_state == 0.0):
		## TODO: pass engine and rear wheels rev states back to them
		pass
	else:
		var ideal_revs := _calculate_revs(engine_proposed_revs, rear_wheels_rev_state)
		const engine_revs: float = 1.0 ##TODO: grab from engine node
		var clutch_factor := clutch_state / clutch_response_time
		var engine_new_revs := lerpf(engine_revs, ideal_revs, clutch_factor)
		var rear_wheels_new_revs := lerpf(rear_wheels_rev_state, ideal_revs * gear_ratios[current_gear_ratio_index], clutch_factor)
		## TODO: pass energy response to rear wheels to change their rotation speed


func _calculate_revs(engine_proposed_revs: float, rear_wheels_rev_state: float) -> float:
	const engine_flywheel_weight: float = 1.0 ##TODO: grab from engine node
	const rear_wheel_weight: float = 1.0 ##TODO: grab from rear wheels
	const engine_revs: float = 1.0 ##TODO: grab from engine node
	var ke_engine_proposed := utils.kinetic_energy(engine_proposed_revs, engine_flywheel_weight)
	var ke_rear_wheels := utils.kinetic_energy(rear_wheels_rev_state, rear_wheel_weight)
	var ke_engine := utils.kinetic_energy(engine_revs, engine_flywheel_weight)
	var work_engine := ke_engine_proposed - ke_engine
	var ke_system := ke_engine + ke_rear_wheels + work_engine
	var weight_sum := engine_flywheel_weight + rear_wheel_weight * gear_ratios[current_gear_ratio_index]
	
	var ideal_revs := sqrt(2.0 * ke_system / weight_sum)
	return ideal_revs
