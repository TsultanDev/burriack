extends Node3D
## Title screen with an animated 3D backdrop and campaign entry point.

const CRYSTAL_SCENE := preload("res://scenes/crystal.tscn")
const Ui := preload("res://scripts/ui_theme.gd")
const SettingsPanelScript := preload("res://scripts/settings_panel.gd")
const LevelSelectScript := preload("res://scripts/level_select.gd")
const GAME_SCENE := "res://scenes/main.tscn"

@onready var camera: Camera3D = $Camera3D
@onready var backdrop: Node3D = $Backdrop
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var rim_cyan: OmniLight3D = $RimCyan
@onready var rim_magenta: OmniLight3D = $RimMagenta

var _time := 0.0
var _starting := false
var _fade: ColorRect
var _settings_panel: Control
var _level_select: Control
var _torus: MeshInstance3D
var _buttons: Array[Button] = []


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	_build_backdrop()
	_build_ui()
	Settings.changed.connect(_apply_graphics_quality)
	_apply_graphics_quality()


func _process(delta: float) -> void:
	_time += delta
	camera.position = Vector3(3.0 + sin(_time * 0.16) * 1.8, 3.5 + sin(_time * 0.42) * 0.18, 12.4)
	camera.look_at(Vector3(4.2, 1.7, -2.0), Vector3.UP)
	backdrop.rotation.y = sin(_time * 0.12) * 0.06
	if _torus != null:
		_torus.rotation.y += delta * 0.35
		_torus.rotation.x = 0.4 + sin(_time * 0.5) * 0.12


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _settings_panel != null and _settings_panel.visible:
		_settings_panel.close()
		get_viewport().set_input_as_handled()
	elif _level_select != null and _level_select.visible:
		_level_select.close()
		get_viewport().set_input_as_handled()


func _apply_graphics_quality() -> void:
	var low := Settings.low_graphics
	sun.shadow_enabled = not low
	rim_cyan.visible = not low
	rim_magenta.visible = not low
	var environment := world_environment.environment
	if environment != null:
		environment.glow_enabled = not low
		environment.fog_enabled = not low
		environment.ssao_enabled = false


func _build_backdrop() -> void:
	var floor_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(90.0, 90.0)
	floor_instance.mesh = plane
	floor_instance.position = Vector3(4.0, -0.5, -8.0)

	var floor_material := ShaderMaterial.new()
	floor_material.shader = preload("res://shaders/floor_grid.gdshader")
	floor_material.set_shader_parameter("base_color", Color(0.03, 0.035, 0.065, 1.0))
	floor_material.set_shader_parameter("line_color", Color(0.18, 0.62, 0.82, 1.0))
	floor_instance.material_override = floor_material
	backdrop.add_child(floor_instance)

	var shards := [
		[Vector3(5.5, 2.1, 0.0), 1.6],
		[Vector3(8.5, 3.0, -2.5), 1.1],
		[Vector3(2.0, 1.5, -3.0), 0.9],
		[Vector3(10.5, 1.7, -5.5), 1.3],
		[Vector3(6.0, 3.4, -6.5), 1.0],
		[Vector3(0.5, 2.6, -7.0), 1.2],
		[Vector3(8.0, 1.3, -9.0), 1.5],
	]
	for entry in shards:
		var crystal := CRYSTAL_SCENE.instantiate()
		crystal.position = entry[0]
		crystal.scale = Vector3.ONE * float(entry[1])
		crystal.rotation.y = randf() * TAU
		backdrop.add_child(crystal)

	var torus_material := StandardMaterial3D.new()
	torus_material.albedo_color = Color(1.0, 0.22, 0.78, 1.0)
	torus_material.metallic = 0.45
	torus_material.roughness = 0.25
	torus_material.emission_enabled = true
	torus_material.emission = Color(1.0, 0.15, 0.7, 1.0)
	torus_material.emission_energy_multiplier = 2.6

	var torus_mesh := TorusMesh.new()
	torus_mesh.inner_radius = 1.75
	torus_mesh.outer_radius = 1.9
	torus_mesh.rings = 40
	torus_mesh.ring_segments = 8
	torus_mesh.material = torus_material

	_torus = MeshInstance3D.new()
	_torus.mesh = torus_mesh
	_torus.position = Vector3(6.4, 2.5, -6.0)
	_torus.rotation = Vector3(0.4, 0.2, 0.15)
	backdrop.add_child(_torus)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.008, 0.01, 0.024, 0.9))
	gradient.set_color(1, Color(0.008, 0.01, 0.024, 0.0))
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 256
	gradient_texture.height = 4
	gradient_texture.fill_from = Vector2(0.0, 0.0)
	gradient_texture.fill_to = Vector2(1.0, 0.0)

	var shade := TextureRect.new()
	shade.texture = gradient_texture
	shade.anchor_right = 0.68
	shade.anchor_bottom = 1.0
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var box := VBoxContainer.new()
	box.anchor_bottom = 1.0
	box.offset_left = 86.0
	box.offset_right = 606.0
	box.offset_top = 0.0
	box.offset_bottom = 0.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	root.add_child(box)

	var eyebrow := Ui.label("LOW-POLY NEON ARENA", 13, Ui.CYAN)
	box.add_child(eyebrow)

	var title_stack := VBoxContainer.new()
	title_stack.add_theme_constant_override("separation", -18)
	box.add_child(title_stack)

	var title_top := Ui.label("CRYSTAL", 76, Ui.CYAN)
	title_stack.add_child(title_top)

	var title_bottom := Ui.label("RUSH", 76, Ui.MAGENTA)
	title_stack.add_child(title_bottom)

	var rule := ColorRect.new()
	rule.color = Color(Ui.CYAN.r, Ui.CYAN.g, Ui.CYAN.b, 0.4)
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	box.add_child(rule)

	var description := Ui.label("TWO PAGES. TWENTY LEVELS. TWO BOSSES.\nCollect every shard. Shoot the stalkers. Stay alive.", 17, Ui.DIM)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(0.0, 58.0)
	box.add_child(description)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 18.0)
	box.add_child(spacer)

	var buttons := VBoxContainer.new()
	buttons.custom_minimum_size = Vector2(330.0, 0.0)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	buttons.add_theme_constant_override("separation", 9)
	box.add_child(buttons)

	var play := Ui.button("PLAY CAMPAIGN", Ui.CYAN)
	play.pressed.connect(_on_play_pressed)
	buttons.add_child(play)

	var settings := Ui.button("SETTINGS", Ui.MAGENTA)
	settings.pressed.connect(_on_settings_pressed)
	buttons.add_child(settings)

	var exit := Ui.button("EXIT", Ui.RED)
	exit.pressed.connect(_on_exit_pressed)
	buttons.add_child(exit)

	_buttons = [play, settings, exit]

	var footer := Ui.label("WASD MOVE      LMB SHOOT      ESC PAUSE", 12, Ui.DIM)
	box.add_child(footer)

	_fade = ColorRect.new()
	_fade.color = Color(0.01, 0.014, 0.028, 1.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.65)

	_level_select = LevelSelectScript.new()
	_level_select.level_chosen.connect(_on_level_chosen)
	root.add_child(_level_select)

	_settings_panel = SettingsPanelScript.new()
	root.add_child(_settings_panel)


func _on_play_pressed() -> void:
	Sfx.play("ui")
	_settings_panel.close()
	_level_select.open()


func _on_level_chosen(index: int) -> void:
	if _starting:
		return
	_starting = true
	Sfx.play("ui")
	_level_select.close()
	GameState.select_level(index)
	for button in _buttons:
		button.disabled = true
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.3)
	tween.tween_callback(_begin_game)


func _begin_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_pressed() -> void:
	Sfx.play("ui")
	if _level_select != null:
		_level_select.close()
	_settings_panel.open()


func _on_exit_pressed() -> void:
	Sfx.play("ui_back")
	get_tree().quit()
