extends Node

@export var motor_tests: MotorTester
@export var rear_axle_tests: RearAxleTester
@export var transmission_tests: TransmissionTester
@export var front_axle_tests: FrontAxleTester
@export var continue_after_failing: bool

var test_log_path: StringName = "res://Logs/test_log.txt"

func _ready() -> void:
	var test_log_file := FileAccess.open(test_log_path, FileAccess.WRITE)
	var test_pass: bool = motor_tests.run(test_log_file)
	if (test_pass || continue_after_failing):
		test_pass = rear_axle_tests.run(test_log_file)
	if (test_pass || continue_after_failing):
		# Transmission depends on these objects to run its tests
		transmission_tests.motor = motor_tests.motor
		transmission_tests.rear_axle = rear_axle_tests.rear_axle_drivetrain
		test_pass = transmission_tests.run(test_log_file)
	if (test_pass || continue_after_failing):
		test_pass = rear_axle_tests.run_physics(test_log_file)
	if (test_pass || continue_after_failing):
		test_pass = front_axle_tests.run(test_log_file)
	
	test_log_file.close()
