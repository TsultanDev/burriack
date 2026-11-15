extends Node3D
## Crystal Rush: collect every shard, shoot the stalkers, stay alive.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const CRYSTAL_SCENE := preload("res://scenes/crystal.tscn")
const STALKER_SCENE := preload("res://scenes/enemy.tscn")

const ARENA_HALF := 26.0
const SHARD_TOTAL := 12
const STALKER_TOTAL := 5
const STALKER_RESPAWN := 4.5
const PLAYER_SPAWN := Vector3(0.0, 1.2, 15.0)

@onready var arena: Node3D = $Arena
@onready var actors: Node3D = $Actors
@onready var pickups: Node3D = $Pickups
@onready var hud: CanvasLayer = $HUD

var player: Player
var state := "playing"
var score := 0
var kills := 0
var shards_left := SHARD_TOTAL
var elapsed := 0.0

var _last_health := 100
var _rng := RandomNumberGenerator.new()
var _floor_material: ShaderMaterial
var _wall_material: StandardMaterial3D
var _crate_material: StandardMaterial3D
var _pillar_material: StandardMaterial3D
var _trim_cyan: StandardMaterial3D
var _trim_magenta: StandardMaterial3D

var _shard_points: Array[Vector3] = [
	Vector3(-8.0, 2.0, -6.0),
	Vector3(8.0, 2.0, -6.0),
	Vector3(0.0, 1.25, 12.0),
	Vector3(-19.0, 1.25, 1.0),
	Vector3(19.0, 1.25, 1.0),
	Vector3(-14.0, 1.25, -12.0),
	Vector3(14.0, 1.25, -12.0),
	Vector3(0.0, 1.25, -20.0),
	Vector3(-19.0, 1.25, 19.0),
	Vector3(19.0, 1.25, 19.0),
	Vector3(-3.0, 1.25, -2.0),
	Vector3(4.0, 1.25, -4.0),
]

var _spawn_points: Array[Vector3] = [
	Vector3(0.0, 0.9, -22.0),
	Vector3(22.0, 0.9, 0.0),
	Vector3(-22.0, 0.9, 0.0),
	Vector3(0.0, 0.9, 22.0),
	Vector3(21.0, 0.9, 21.0),
	Vector3(-21.0, 0.9, -21.0),
	Vector3(21.0, 0.9, -21.0),
	Vector3(-21.0, 0.9, 21.0),
]


func _ready() -> void:
	_rng.randomize()
	hud.set_score(0)
	hud.set_crystals(0, SHARD_TOTAL)
	hud.set_health(100, 100)
	hud.set_time(0.0)

	_build_materials()
	_build_arena()
	_spawn_player()

	for point in _shard_points:
		_spawn_crystal(point)
	for i in STALKER_TOTAL:
		_spawn_stalker()

	hud.show_toast("CRYSTAL RUSH", "Collect all %d shards. Shoot the stalkers. Stay alive." % SHARD_TOTAL, 3.8)


func _process(delta: float) -> void:
	if state != "playing":
		return
	elapsed += delta
	hud.set_time(elapsed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _build_materials() -> void:
	_floor_material = ShaderMaterial.new()
	_floor_material.shader = preload("res://shaders/floor_grid.gdshader")
	_floor_material.set_shader_parameter("base_color", Color(0.035, 0.045, 0.07, 1.0))
	_floor_material.set_shader_parameter("line_color", Color(0.14, 0.7, 0.82, 1.0))

	_wall_material = _standard(Color(0.075, 0.075, 0.13, 1.0), 0.3, 0.6)
	_crate_material = _standard(Color(0.12, 0.12, 0.2, 1.0), 0.2, 0.75)
	_pillar_material = _standard(Color(0.09, 0.08, 0.14, 1.0), 0.4, 0.45)

	_trim_cyan = _standard(Color(0.12, 0.75, 0.9, 1.0), 0.2, 0.25)
	_trim_cyan.emission_enabled = true
	_trim_cyan.emission = Color(0.1, 0.85, 1.0, 1.0)
	_trim_cyan.emission_energy_multiplier = 3.0

	_trim_magenta = _standard(Color(0.9, 0.2, 0.75, 1.0), 0.2, 0.25)
	_trim_magenta.emission_enabled = true
	_trim_magenta.emission = Color(1.0, 0.15, 0.7, 1.0)
	_trim_magenta.emission_energy_multiplier = 3.0


func _standard(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _build_arena() -> void:
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(ARENA_HALF * 2.0, 1.0, ARENA_HALF * 2.0), _floor_material)

	var wall_height := 4.5
	var wall_center := wall_height * 0.5
	_add_box(Vector3(0.0, wall_center, -ARENA_HALF), Vector3(ARENA_HALF * 2.0, wall_height, 1.0), _wall_material)
	_add_box(Vector3(0.0, wall_center, ARENA_HALF), Vector3(ARENA_HALF * 2.0, wall_height, 1.0), _wall_material)
	_add_box(Vector3(-ARENA_HALF, wall_center, 0.0), Vector3(1.0, wall_height, ARENA_HALF * 2.0), _wall_material)
	_add_box(Vector3(ARENA_HALF, wall_center, 0.0), Vector3(1.0, wall_height, ARENA_HALF * 2.0), _wall_material)

	var inner := ARENA_HALF - 0.56
	var trim_y := wall_height - 0.55
	var trim_length := ARENA_HALF * 2.0 - 1.2
	_add_decor(Vector3(0.0, trim_y, -inner), Vector3(trim_length, 0.09, 0.09), _trim_cyan)
	_add_decor(Vector3(0.0, trim_y, inner), Vector3(trim_length, 0.09, 0.09), _trim_cyan)
	_add_decor(Vector3(-inner, trim_y, 0.0), Vector3(0.09, 0.09, trim_length), _trim_cyan)
	_add_decor(Vector3(inner, trim_y, 0.0), Vector3(0.09, 0.09, trim_length), _trim_cyan)

	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var corner := Vector3(sx * (ARENA_HALF - 1.5), 3.0, sz * (ARENA_HALF - 1.5))
			_add_box(corner, Vector3(2.0, 6.0, 2.0), _wall_material)
			_add_decor(corner + Vector3(0.0, 2.35, 0.0), Vector3(2.2, 0.12, 2.2), _trim_magenta)

	var crates: Array[Vector3] = [
		Vector3(-8.0, 0.65, -6.0),
		Vector3(8.0, 0.65, -6.0),
		Vector3(-15.0, 0.65, 5.0),
		Vector3(15.0, 0.65, 5.0),
		Vector3(-6.0, 0.65, 11.0),
		Vector3(7.0, 0.65, 11.0),
		Vector3(-19.0, 0.65, -15.0),
		Vector3(19.0, 0.65, -15.0),
		Vector3(-2.0, 0.65, -15.0),
		Vector3(12.0, 0.65, -19.0),
		Vector3(-13.0, 0.65, -19.0),
		Vector3(-21.0, 0.65, 17.0),
		Vector3(21.0, 0.65, 17.0),
	]
	for crate in crates:
		_add_box(crate, Vector3(1.7, 1.3, 1.7), _crate_material)

	_add_box(Vector3(12.0, 1.75, -19.0), Vector3(1.2, 1.0, 1.2), _crate_material)
	_add_box(Vector3(-19.0, 1.75, -15.0), Vector3(1.2, 1.0, 1.2), _crate_material)

	_add_box(Vector3(-14.0, 0.65, -1.0), Vector3(7.0, 1.3, 0.7), _crate_material)
	_add_box(Vector3(14.0, 0.65, -1.0), Vector3(7.0, 1.3, 0.7), _crate_material)
	_add_box(Vector3(0.0, 0.65, 4.5), Vector3(0.7, 1.3, 7.0), _crate_material)

	var pillars: Array[Vector3] = [
		Vector3(0.0, 2.0, -7.0),
		Vector3(-20.0, 2.0, 9.0),
		Vector3(20.0, 2.0, 9.0),
		Vector3(-10.0, 2.0, -21.0),
		Vector3(10.0, 2.0, -21.0),
	]
	for pillar in pillars:
		_add_box(pillar, Vector3(1.4, 4.0, 1.4), _pillar_material)
		_add_decor(pillar + Vector3(0.0, 2.03, 0.0), Vector3(1.55, 0.1, 1.55), _trim_magenta)


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
	player.position = PLAYER_SPAWN
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
	hud.set_crystals(SHARD_TOTAL - shards_left, SHARD_TOTAL)
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
	get_tree().create_timer(STALKER_RESPAWN).timeout.connect(_respawn_stalker)


func _respawn_stalker() -> void:
	if is_inside_tree() and state == "playing":
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
		hud.show_end(false, elapsed, score, kills, SHARD_TOTAL - shards_left, SHARD_TOTAL)


func _win() -> void:
	state = "won"
	Sfx.play("win", 1.0, -4.0)
	if player != null:
		player.set_active(false)
	await get_tree().create_timer(0.55).timeout
	if is_inside_tree() and state == "won":
		hud.show_end(true, elapsed, score, kills, SHARD_TOTAL, SHARD_TOTAL)


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
