class_name utils

static func get_vector2(inVector: Vector3) -> Vector2:
	return Vector2(inVector.x, inVector.z)

static func kinetic_energy(velocity: float, mass: float) -> float:
	return pow(velocity, 2) * mass / 2.0
