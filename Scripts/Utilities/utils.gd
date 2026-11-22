class_name utils

static func get_vector2(inVector: Vector3) -> Vector2:
	return Vector2(inVector.x, inVector.z)

static func kinetic_energy(velocity: float, mass: float) -> float:
	return pow(velocity, 2) * mass / 2.0

static func get_test_passed_str(test: Callable) -> String:
	return "PASSED: %s passed all tests\n\n" % test.get_method()

static func bool_to_string(val: bool) -> StringName:
	if val: 
		return "true"
	else: 
		return "false"
