extends Label

@export var cube: PhysicsTestCube


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cube.set_hud_values.connect(_update_text)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
	
func _update_text(in_text: String) -> void:
	text = in_text
