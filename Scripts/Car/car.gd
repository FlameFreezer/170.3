extends RigidBody3D

@onready var _transmission: Transmission = $Transmission
@onready var _motor: Motor = $Transmission/Motor
@onready var _rear_wheels: RearWheel = $"Transmission/Rear Wheels"

## TODO: get this from the wheels
@export var wheel_radius: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	linear_velocity = Vector3.FORWARD * _rear_wheels.rpm * wheel_radius


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Called during _physics_process, allows safe reading and modification of physics state before its application
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	pass
