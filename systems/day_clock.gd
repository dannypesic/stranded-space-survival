class_name DayClock
extends Node

signal time_changed(day: int, hour: int, minute: int)
## sent during midnight
signal day_changed(day: int)

const MINUTES_PER_HOUR: int = 60
const MINUTES_PER_DAY: int = 24 * MINUTES_PER_HOUR

@export_range(0, 23) var starting_hour: int = 8
@export_range(0, 59) var starting_minute: int = 0
@export_range(0.0, 60.0, 0.25, "or_greater") var game_minutes_per_second: float = 1.0
@export_range(0.0, 60.0, 0.25, "or_greater") var speed_multiplier: float = 1.0

var paused: bool = false

var elapsed_minutes: float:
	get:
		return _elapsed_minutes

var day: int:
	get:
		return floori(_total_minutes() / MINUTES_PER_DAY) + 1

var hour: int:
	get:
		return floori(_total_minutes() / MINUTES_PER_HOUR) % 24

var minute: int:
	get:
		return floori(_total_minutes()) % MINUTES_PER_HOUR

var _elapsed_minutes: float = 0.0
var _elapsed_correction: float = 0.0


func _ready() -> void:
	time_changed.emit(day, hour, minute)


func _process(delta: float) -> void:
	if not paused:
		advance_minutes(delta * maxf(game_minutes_per_second, 0.0) * maxf(speed_multiplier, 0.0))


func advance_minutes(amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		return

	var previous_minute: int = floori(_total_minutes())
	var corrected_amount: float = amount - _elapsed_correction
	var target_elapsed: float = _elapsed_minutes + corrected_amount
	_elapsed_correction = (target_elapsed - _elapsed_minutes) - corrected_amount
	var next_midnight: float = day * MINUTES_PER_DAY - _starting_minutes()

	while next_midnight <= target_elapsed:
		_elapsed_minutes = next_midnight
		time_changed.emit(day, hour, minute)
		day_changed.emit(day)
		previous_minute = floori(_total_minutes())
		next_midnight += MINUTES_PER_DAY

	_elapsed_minutes = target_elapsed
	if floori(_total_minutes()) != previous_minute:
		time_changed.emit(day, hour, minute)


func reset() -> void:
	_elapsed_minutes = 0.0
	_elapsed_correction = 0.0
	speed_multiplier = 1.0
	paused = false
	time_changed.emit(day, hour, minute)


func _starting_minutes() -> int:
	return starting_hour * MINUTES_PER_HOUR + starting_minute


func _total_minutes() -> float:
	return _starting_minutes() + _elapsed_minutes
