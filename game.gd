extends Node2D

const RESOURCE_CAP: float = 100.0
var _clock_was_paused: bool = false

var resources: Dictionary[StringName, float] = {
	&"food": 80.0,
	&"water": 80.0,
	&"integrity": 100.0,
}

@onready var clock: DayClock = $DayClock
@onready var water_activity = $HUD.get_node("%WaterActivity")
@onready var resource_labels: Dictionary[StringName, Label] = {
	&"food": $HUD.get_node("%FoodLabel"),
	&"water": $HUD.get_node("%WaterLabel"),
	&"integrity": $HUD.get_node("%IntegrityLabel"),
}


func _ready() -> void:
	clock.time_changed.connect(_update_time)
	clock.day_changed.connect(_consume_daily_resources)
	$World/ShipRoom/WaterStation.interacted.connect(_open_water_station)
	water_activity.finished.connect(_complete_water)
	_update_time(clock.day, clock.hour, clock.minute)
	_update_resources()


func _unhandled_input(event: InputEvent) -> void:
	if $HUD.get_node("%WaterActivity").visible and event.is_action_pressed("ui_cancel"):
		_close_water_station()
		get_viewport().set_input_as_handled()


func _open_water_station() -> void:
	if $HUD.get_node("%WaterActivity").visible:
		return
	$World/Player.movement_enabled = false
	$World/Player.velocity = Vector2.ZERO
	_clock_was_paused = clock.paused
	clock.paused = true
	water_activity.start()


func _complete_water(water_collected: float) -> void:
	if not $HUD.get_node("%WaterActivity").visible:
		return
	change_resource(&"water", water_collected)
	clock.advance_minutes(120.0)
	_close_water_station()


func _close_water_station() -> void:
	$HUD.get_node("%WaterActivity").hide()
	$World/Player.movement_enabled = true
	clock.paused = _clock_was_paused


func change_resource(resource: StringName, amount: float) -> void:
	if not resources.has(resource):
		push_warning("Unknown resource: %s" % resource)
		return
	resources[resource] = clampf(resources[resource] + amount, 0.0, RESOURCE_CAP)
	_update_resources()


func _consume_daily_resources(_day: int) -> void:
	change_resource(&"food", -15.0)
	change_resource(&"water", -20.0)
	change_resource(&"integrity", -7.0)


func _update_resources() -> void:
	for resource in resources:
		resource_labels[resource].text = "%s: %d / %d" % [
			String(resource).capitalize(), roundi(resources[resource]), int(RESOURCE_CAP),
		]


func _update_time(current_day: int, current_hour: int, current_minute: int) -> void:
	$HUD.get_node("%DayLabel").text = "Day %d" % current_day
	$HUD.get_node("%TimeLabel").text = "%02d:%02d" % [current_hour, current_minute]
