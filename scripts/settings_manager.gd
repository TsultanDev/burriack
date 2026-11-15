extends Node
## Player settings persisted to user://settings.cfg.

signal changed

const CONFIG_PATH := "user://settings.cfg"
const DEFAULT_SENSITIVITY := 1.0
const DEFAULT_VOLUME := 0.8
const DEFAULT_FULLSCREEN := false
const DEFAULT_LOW_GRAPHICS := false

var sensitivity := DEFAULT_SENSITIVITY
var master_volume := DEFAULT_VOLUME
var fullscreen := DEFAULT_FULLSCREEN
var low_graphics := DEFAULT_LOW_GRAPHICS


func _ready() -> void:
	load_settings()
	apply_all()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		sensitivity = float(config.get_value("input", "sensitivity", DEFAULT_SENSITIVITY))
		master_volume = float(config.get_value("audio", "master_volume", DEFAULT_VOLUME))
		fullscreen = bool(config.get_value("video", "fullscreen", DEFAULT_FULLSCREEN))
		low_graphics = bool(config.get_value("video", "low_graphics", DEFAULT_LOW_GRAPHICS))
	_clamp_values()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("input", "sensitivity", sensitivity)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "low_graphics", low_graphics)
	config.save(CONFIG_PATH)


func set_sensitivity(value: float, persist: bool = true) -> void:
	sensitivity = clampf(value, 0.2, 3.0)
	if persist:
		save_settings()
	changed.emit()


func set_master_volume(value: float, persist: bool = true) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	if persist:
		save_settings()
	changed.emit()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply_video()
	save_settings()
	changed.emit()


func set_low_graphics(value: bool, persist: bool = true) -> void:
	low_graphics = value
	apply_graphics()
	if persist:
		save_settings()
	changed.emit()


func reset_defaults() -> void:
	sensitivity = DEFAULT_SENSITIVITY
	master_volume = DEFAULT_VOLUME
	fullscreen = DEFAULT_FULLSCREEN
	low_graphics = DEFAULT_LOW_GRAPHICS
	apply_all()
	save_settings()
	changed.emit()


func apply_all() -> void:
	apply_audio()
	apply_video()
	apply_graphics()


func apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, master_volume <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.001)))


func apply_video() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var is_fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if fullscreen and not is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func apply_graphics() -> void:
	if not is_inside_tree():
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	if low_graphics:
		viewport.msaa_3d = Viewport.MSAA_DISABLED
		viewport.scaling_3d_scale = 0.7
	else:
		viewport.msaa_3d = Viewport.MSAA_4X
		viewport.scaling_3d_scale = 1.0


func _clamp_values() -> void:
	sensitivity = clampf(sensitivity, 0.2, 3.0)
	master_volume = clampf(master_volume, 0.0, 1.0)
