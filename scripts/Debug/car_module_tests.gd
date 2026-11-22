extends Node

@export var motor_tests: MotorTester
@export var rear_axle_tests: RearAxleTester
@export var transmission_tests: TransmissionTester
@export var continue_after_failing: bool

var test_log_path: StringName = "res://Logs/test_log.txt"

func _ready() -> void:
	var test_log_file := FileAccess.open(test_log_path, FileAccess.WRITE)
	var test_pass: bool = motor_tests.run(test_log_file)
	if (test_pass || continue_after_failing):
		test_pass = rear_axle_tests.run(test_log_file)
	if (test_pass || continue_after_failing):
		test_pass = transmission_tests.run(test_log_file)
	
	test_log_file.close()
