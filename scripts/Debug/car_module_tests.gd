extends Node

@export var motor_tests: MotorTester

var test_log_path: StringName = "res://Logs/test_log.txt"

func _ready() -> void:
	var test_log_file := FileAccess.open(test_log_path, FileAccess.WRITE)
	var test_pass: bool = motor_tests.run(test_log_file)
	test_log_file.close()
