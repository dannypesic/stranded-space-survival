extends Control

signal finished(water_collected: float)

const CONTAINER_SIZE: float = 25.0
const SOURCE_WATER: float = 35.0
const POUR_RATE: float = 1.0
const SPILL_MULTIPLIER: float = 2.0
const RISE_SPEED: float = 0.7
const FALL_SPEED: float = 0.55
const ZONE_SIZE: float = 0.18
@export var target_cycle_seconds: float = 7.0

var _started: bool = false
var _elapsed: float = 0.0
var _marker_position: float = 0.5
var _target_position: float = 0.5
var _collected: float = 0.0
var _source: float = SOURCE_WATER

@onready var track: ColorRect = %Track
@onready var target: ColorRect = %Target
@onready var marker: ColorRect = %Marker
@onready var source_fill: ColorRect = %SourceFill
@onready var container_fill: ColorRect = %ContainerFill
@onready var water_sound: AudioStreamPlayer = $WaterSound
@onready var buzz_sound: AudioStreamPlayer = $BuzzSound


func _ready() -> void:
	track.resized.connect(_update_meters)
	visibility_changed.connect(_on_visibility_changed)
	# One full recording corresponds to one full container.
	water_sound.pitch_scale = water_sound.stream.get_length() * POUR_RATE / CONTAINER_SIZE
	buzz_sound.stream.loop = true


func start() -> void:
	_stop_sounds()
	_started = false
	_elapsed = 0.0
	_marker_position = 0.5
	_target_position = 0.5
	_collected = 0.0
	_source = SOURCE_WATER
	show()
	_update_meters()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if not _started:
		if not Input.is_action_just_pressed("pour"):
			return
		_started = true

	_elapsed += delta
	_target_position = 0.5 + 0.34 * sin(_elapsed * TAU / maxf(target_cycle_seconds, 1.0))
	var speed: float = RISE_SPEED if Input.is_action_pressed("pour") else -FALL_SPEED
	_marker_position = clampf(_marker_position + speed * delta, 0.0, 1.0)

	var in_zone: bool = absf(_marker_position - _target_position) <= ZONE_SIZE / 2.0
	var rate: float = POUR_RATE if in_zone else POUR_RATE * SPILL_MULTIPLIER
	var poured: float = minf(rate * delta, _source)
	_source -= poured
	if in_zone:
		_collected = minf(_collected + poured, CONTAINER_SIZE)
	_update_sounds(in_zone)
	_update_meters()

	if _collected >= CONTAINER_SIZE or _source <= 0.0:
		_started = false
		finished.emit(_collected)


func _update_sounds(in_zone: bool) -> void:
	if in_zone:
		buzz_sound.stop()
		if not water_sound.playing:
			water_sound.play(_collected / CONTAINER_SIZE * water_sound.stream.get_length())
	else:
		water_sound.stop()
		if not buzz_sound.playing:
			buzz_sound.play()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_stop_sounds()


func _stop_sounds() -> void:
	water_sound.stop()
	buzz_sound.stop()


func _update_meters() -> void:
	var travel: float = track.size.y - marker.size.y
	marker.position.y = (1.0 - _marker_position) * travel
	target.size.y = ZONE_SIZE * travel + marker.size.y
	target.position.y = (1.0 - _target_position) * travel - ZONE_SIZE * travel / 2.0

	var meter_height: float = track.size.y
	source_fill.size.y = meter_height * _source / SOURCE_WATER
	source_fill.position.y = meter_height - source_fill.size.y
	container_fill.size.y = meter_height * _collected / CONTAINER_SIZE
	container_fill.position.y = meter_height - container_fill.size.y
