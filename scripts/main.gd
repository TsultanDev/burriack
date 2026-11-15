extends Node3D
## One campaign sector: collect every shard, shoot the stalkers, stay alive.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const CRYSTAL_SCENE := preload("res://scenes/crystal.tscn")
const STALKER_SCENE := preload("res://scenes/enemy.tscn")
const LEVELS := preload("res://scripts/level_data.gd")

const MAIN_SCENE := "res://scenes/main.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"

@onready var arena: Node3D = $Arena
@onready var actors: Node3D = $Actors
@onready var pickups: Node3D = $Pickups
@onready var hud: CanvasLayer = $HUD
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var rim_cyan: OmniLight3D = $RimCyan
@onready var rim_magenta: OmniLight3D = $RimMagenta

var level: Dictionary = {}
var level_index := 1
var player: Player
var state := "playing"
var paused := false
var score := 0
var kills := 0
var shards_left := 0
var shard_total := 0
var elapsed := 0.0

var _arena_half := 26.0
var _enemy_respawn := 4.5
var _last_health := 100
var _rng := RandomNumberGenerator.new()
var _floor_material: ShaderMaterial
var _wall_material: StandardMaterial3D
var _crate_material: StandardMaterial3D
var _pillar_material: StandardMaterial3D
var _trim_primary: StandardMaterial3D
var _trim_secondary: StandardMaterial3D
var _spawn_points: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()

	level_index = clampi(GameState.current_level, 1, LEVELS.count())
	GameState.current_level = level_index
	level = LEVELS.get_level(level_index - 1)
	_arena_half = float(level["arena_half"])
	_enemy_respawn = float(level["respawn"])
	_shard_setup()

	hud.set_level(level_index, LEVELS.count(), str(level["name"]))
	hud.set_score(0)
	hud.set_crystals(0, shard_total)
	hud.set_health(100, 100)
	hud.set_time(0.0)
	hud.resume_requested.connect(_on_resume_requested)
	hud.restart_requested.connect(_restart_level)
	hud.next_level_requested.connect(_on_next_level_requested)
	hud.menu_requested.connect(_go_to_menu)

	_build_materials()
	_apply_theme()
	_build_arena()
	_spawn_player()

	for point in level["shards"]:
		_spawn_crystal(point)
	for i in int(level["enemy_count"]):
		_spawn_stalker()

	hud.show_toast(str(level["name"]), str(level["brief"]), 4.0)


func _shard_setup() -> void:
	shard_total = level["shards"].size()
	shards_left = shard_total
	_spawn_points = level["spawns"]


func _process(delta: float) -> void:
	if state != "playing" or paused:
		return
	elapsed += delta
	hud.set_time(elapsed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		if not paused:
			_restart_level()
			get_viewport().set_input_as_handled()
		return

	if not event.is_action_pressed("ui_cancel"):
		return

	if state == "playing":
		if hud.is_settings_open():
			hud.close_settings()
		else:
			_set_paused(not paused)
		get_viewport().set_input_as_handled()
	elif state == "won" or state == "lost":
		_go_to_menu()
		get_viewport().set_input_as_handled()


func _set_paused(value: bool) -> void:
	if state != "playing" or paused == value:
		return
	paused = value
	hud.show_pause(paused, "LEVEL %d / %d  -  %s" % [level_index, LEVELS.count(), str(level["name"])])
	if paused:
		if player != null:
			player.set_active(false)
		get_tree().paused = true
	else:
		get_tree().paused = false
		if player != null and player.alive:
			player.set_active(true)


func _on_resume_requested() -> void:
	_set_paused(false)


func _restart_level() -> void:
	get_tree().paused = false
	if state == "won" and GameState.is_final_level():
		GameState.start_campaign()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_next_level_requested() -> void:
	Sfx.play("ui")
	get_tree().paused = false
	GameState.next_level()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _go_to_menu() -> void:
	Sfx.play("ui_back")
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func _build_materials() -> void:
	_floor_material = ShaderMaterial.new()
	_floor_material.shader = preload("res://shaders/floor_grid.gdshader")
	_floor_material.set_shader_parameter("base_color", level["floor_base"])
	_floor_material.set_shader_parameter("line_color", level["floor_line"])

	_wall_material = _standard(level["wall"], 0.3, 0.6)
	_crate_material = _standard(level["crate"], 0.2, 0.75)
	_pillar_material = _standard(level["pillar"], 0.4, 0.45)

	_trim_primary = _standard(level["trim_a"], 0.2, 0.25)
	_trim_primary.emission_enabled = true
	_trim_primary.emission = level["trim_a"]
	_trim_primary.emission_energy_multiplier = 3.0

	_trim_secondary = _standard(level["trim_b"], 0.2, 0.25)
	_trim_secondary.emission_enabled = true
	_trim_secondary.emission = level["trim_b"]
	_trim_secondary.emission_energy_multiplier = 3.0


func _apply_theme() -> void:
	var environment := world_environment.environment
	if environment != null:
		environment.fog_light_color = level["fog"]
		var sky := environment.sky
		if sky != null and sky.sky_material is ProceduralSkyMaterial:
			var sky_material := sky.sky_material as ProceduralSkyMaterial
			sky_material.sky_top_color = level["sky_top"]
			sky_material.sky_horizon_color = level["sky_horizon"]
			sky_material.ground_horizon_color = level["ground_horizon"]

	sun.light_color = level["sun"]
	rim_cyan.light_color = level["rim_a"]
	rim_magenta.light_color = level["rim_b"]


func _standard(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _build_arena() -> void:
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(_arena_half * 2.0, 1.0, _arena_half * 2.0), _floor_material)

	var wall_height := 4.5
	var wall_center := wall_height * 0.5
	_add_box(Vector3(0.0, wall_center, -_arena_half), Vector3(_arena_half * 2.0, wall_height, 1.0), _wall_material)
	_add_box(Vector3(0.0, wall_center, _arena_half), Vector3(_arena_half * 2.0, wall_height, 1.0), _wall_material)
	_add_box(Vector3(-_arena_half, wall_center, 0.0), Vector3(1.0, wall_height, _arena_half * 2.0), _wall_material)
	_add_box(Vector3(_arena_half, wall_center, 0.0), Vector3(1.0, wall_height, _arena_half * 2.0), _wall_material)

	var inner := _arena_half - 0.56
	var trim_y := wall_height - 0.55
	var trim_length := _arena_half * 2.0 - 1.2
	_add_decor(Vector3(0.0, trim_y, -inner), Vector3(trim_length, 0.09, 0.09), _trim_primary)
	_add_decor(Vector3(0.0, trim_y, inner), Vector3(trim_length, 0.09, 0.09), _trim_primary)
	_add_decor(Vector3(-inner, trim_y, 0.0), Vector3(0.09, 0.09, trim_length), _trim_primary)
	_add_decor(Vector3(inner, trim_y, 0.0), Vector3(0.09, 0.09, trim_length), _trim_primary)

	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var corner := Vector3(sx * (_arena_half - 1.5), 3.0, sz * (_arena_half - 1.5))
			_add_box(corner, Vector3(2.0, 6.0, 2.0), _wall_material)
			_add_decor(corner + Vector3(0.0, 2.35, 0.0), Vector3(2.2, 0.12, 2.2), _trim_secondary)

	for crate in level["crates"]:
		_add_box(crate, Vector3(1.7, 1.3, 1.7), _crate_material)

	for wall in level["walls"]:
		_add_box(wall["center"], wall["size"], _crate_material)

	for pillar in level["pillars"]:
		var center: Vector3 = pillar["center"]
		var size: Vector3 = pillar["size"]
		_add_box(center, size, _pillar_material)
		_add_decor(center + Vector3(0.0, size.y * 0.5 + 0.03, 0.0), Vector3(size.x + 0.15, 0.1, size.z + 0.15), _trim_secondary)


func _add_box(center: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	arena.add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _add_decor(center: Vector3, size: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = center
	arena.add_child(mesh_instance)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = level["player_spawn"]
	actors.add_child(player)
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)


func _spawn_crystal(point: Vector3) -> void:
	var crystal := CRYSTAL_SCENE.instantiate()
	crystal.position = point
	pickups.add_child(crystal)
	crystal.collected.connect(_on_crystal_collected)


func _spawn_stalker() -> void:
	if state != "playing":
		return
	var point: Vector3 = _spawn_points[_rng.randi_range(0, _spawn_points.size() - 1)]
	var stalker := STALKER_SCENE.instantiate()
	stalker.max_health = int(level["enemy_health"])
	stalker.speed = float(level["enemy_speed"])
	stalker.touch_damage = int(level["enemy_damage"])
	stalker.position = point + Vector3(_rng.randf_range(-1.4, 1.4), 0.0, _rng.randf_range(-1.4, 1.4))
	actors.add_child(stalker)
	stalker.player = player
	stalker.destroyed.connect(_on_stalker_destroyed)
	_spawn_burst(stalker.global_position, Color(1.0, 0.2, 0.3), 0.25)


func _on_crystal_collected(crystal: Area3D, value: int) -> void:
	if state != "playing":
		return
	shards_left -= 1
	score += value
	hud.set_score(score)
	hud.set_crystals(shard_total - shards_left, shard_total)
	hud.ping_crystal()
	_spawn_burst(crystal.global_position, Color(0.35, 1.0, 0.9), 0.3)
	if shards_left <= 0:
		_win()


func _on_stalker_destroyed(at: Vector3) -> void:
	if state != "playing":
		return
	kills += 1
	score += 75
	hud.set_score(score)
	_spawn_burst(at, Color(1.0, 0.25, 0.2), 0.35)
	get_tree().create_timer(_enemy_respawn, false).timeout.connect(_respawn_stalker)


func _respawn_stalker() -> void:
	if is_inside_tree() and state == "playing" and not paused:
		_spawn_stalker()


func _on_health_changed(current: int, maximum: int) -> void:
	if current < _last_health:
		hud.flash_damage()
	_last_health = current
	hud.set_health(current, maximum)


func _on_player_died() -> void:
	if state != "playing":
		return
	state = "lost"
	Sfx.play("lose", 1.0, -5.0)
	await get_tree().create_timer(0.9).timeout
	if is_inside_tree() and state == "lost":
		hud.show_end(false, elapsed, score, kills, shard_total - shards_left, shard_total, level_index, false, GameState.total_score)


func _win() -> void:
	state = "won"
	GameState.add_score(score)
	Sfx.play("win", 1.0, -4.0)
	if player != null:
		player.set_active(false)
	await get_tree().create_timer(0.55).timeout
	if is_inside_tree() and state == "won":
		hud.show_end(true, elapsed, score, kills, shard_total, shard_total, level_index, GameState.is_final_level(), GameState.total_score)


func _spawn_burst(at: Vector3, color: Color, size: float) -> void:
	var instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	instance.mesh = sphere

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(color.r, color.g, color.b, 0.85)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 4.0
	material.no_depth_test = true
	instance.material_override = material

	actors.add_child(instance)
	instance.global_position = at

	var tween := instance.create_tween()
	tween.set_parallel(true)
	tween.tween_property(instance, "scale", Vector3.ONE * 3.0, 0.25)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.25)
	tween.chain().tween_callback(instance.queue_free)
