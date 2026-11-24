class_name utils

const EPSILON: float = 0.00001

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

static func handle_epsilon(val: float) -> float:
	if (abs(val) < EPSILON):
		return 0.0
	return val

static func snap(val: float) -> float:
	return snappedf(handle_epsilon(val), EPSILON)

static func snapVec2(vec: Vector2) -> Vector2:
	return Vector2(utils.snap(vec.x), utils.snap(vec.y))

static func snapVec3(vec: Vector3) -> Vector3:
	return Vector3(utils.snap(vec.x), utils.snap(vec.y), utils.snap(vec.z))

static func make_snappedVec2(x: float, y: float) -> Vector2:
	return Vector2(utils.snap(x), utils.snap(y))

static func make_snappedVec3(x: float, y: float, z: float) -> Vector3:
	return Vector3(utils.snap(x), utils.snap(y), utils.snap(z))
