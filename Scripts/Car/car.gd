extends RigidBody3D

@onready var _transmission: Transmission = $Transmission
@onready var _motor: Motor = $Transmission/Motor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Called during _physics_process, allows safe reading and modification of physics state before its application
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	pass
