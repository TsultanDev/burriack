class_name Player
extends CharacterBody3D
## Third-person arena runner. Physics body stays upright; the visual mesh
## turns towards movement while the camera rig handles mouse look.

signal health_changed(current: int, maximum: int)
signal died

const MAX_HEALTH := 100
const SPRING_LENGTH := 4.4

@export var move_speed := 6.6
@export var sprint_speed := 10.4
@export var ground_acceleration := 52.0
@export var air_acceleration := 16.0
@export var gravity := 26.0
@export var jump_velocity := 9.0
@export var mouse_sensitivity := 0.0024
@export var fire_cooldown := 0.17

@onready var visual: Node3D = $Visual
@onready var rig: Node3D = $CameraRig
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D

var health := MAX_HEALTH
var alive := true
var active := true
var yaw := 0.0
var pitch := -0.18

var _cooldown := 0.0
var _invulnerable := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _walk_time := 0.0
var _shake := 0.0
var _recoil := 0.0
var _was_on_floor := true


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spring_arm.rotation.x = pitch
	rig.rotation.y = yaw
	health_changed.emit(health, MAX_HEALTH)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -1.2, 0.45)
	elif event.is_action_pressed("ui_cancel") and alive:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if alive and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not alive:
		return

	rig.rotation.y = yaw
	spring_arm.rotation.x = pitch

	var input := Vector2.ZERO
	if active:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish := Basis(Vector3.UP, rig.rotation.y) * Vector3(input.x, 0.0, input.y)
	if wish.length_squared() > 1.0:
		wish = wish.normalized()
	var sprinting := active and Input.is_action_pressed("sprint") and wish.length_squared() > 0.01
	var target := wish * (sprint_speed if sprinting else move_speed)
	var accel := ground_acceleration if is_on_floor() else air_acceleration
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1

	_coyote = 0.12 if is_on_floor() else maxf(0.0, _coyote - delta)
	if active and Input.is_action_just_pressed("jump"):
		_jump_buffer = 0.12
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)
	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity
		_jump_buffer = 0.0
		_coyote = 0.0
		Sfx.play("jump", randf_range(0.95, 1.08), -13.0)

	move_and_slide()

	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		_land()
	_was_on_floor = on_floor

	_update_visual(delta, horizontal, sprinting)
	_update_combat(delta)


func _update_visual(delta: float, horizontal: Vector3, sprinting: bool) -> void:
	var planar := horizontal.length()
	if planar > 0.5:
		var target_yaw := atan2(-horizontal.x, -horizontal.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 1.0 - exp(-16.0 * delta))
		_walk_time += delta * (12.0 if sprinting else 8.0)
		var bob := absf(sin(_walk_time)) * (0.075 if sprinting else 0.05)
		visual.position.y = lerpf(visual.position.y, bob, 1.0 - exp(-20.0 * delta))
		visual.rotation.x = lerpf(visual.rotation.x, -0.12 if sprinting else -0.05, 1.0 - exp(-10.0 * delta))
	else:
		visual.position.y = lerpf(visual.position.y, 0.0, 1.0 - exp(-10.0 * delta))
		visual.rotation.x = lerpf(visual.rotation.x, 0.0, 1.0 - exp(-10.0 * delta))

	if _invulnerable > 0.0:
		visual.visible = fmod(_invulnerable * 22.0, 2.0) >= 1.0
	else:
		visual.visible = true


func _update_combat(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_shake = move_toward(_shake, 0.0, delta * 3.5)
	_recoil = move_toward(_recoil, 0.0, delta * 3.0)

	var shake_offset := Vector3.ZERO
	if _shake > 0.0:
		shake_offset = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * _shake * 0.12
	camera.h_offset = shake_offset.x
	camera.v_offset = shake_offset.y
	spring_arm.spring_length = SPRING_LENGTH + _recoil * 0.08

	if active and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed("shoot") and _cooldown <= 0.0:
		_shoot()


func _shoot() -> void:
	_cooldown = fire_cooldown
	_recoil = 1.0
	_shake = maxf(_shake, 0.18)

	var origin := camera.global_position
	var forward := -camera.global_transform.basis.z
	var aim_end := origin + forward * 90.0
	var exclude: Array[RID] = [get_rid()]
	var query := PhysicsRayQueryParameters3D.create(origin, aim_end, 1 | 4, exclude)
	var result := get_world_3d().direct_space_state.intersect_ray(query)

	var end := aim_end
	if not result.is_empty():
		end = result.position
		var collider = result.collider
		if collider != null and collider.has_method("take_hit"):
			collider.take_hit(1, result.position)
		_spawn_spark(end, Color(0.35, 0.95, 1.0), 0.1)
	else:
		_spawn_spark(end, Color(0.35, 0.95, 1.0), 0.07)

	var muzzle := global_position + Vector3.UP * 0.25 + forward * 0.55
	_spawn_tracer(muzzle, end)
	Sfx.play("shoot", randf_range(0.92, 1.08), -10.0)


func _spawn_tracer(from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.05:
		return
	var instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.035, 0.035, length)
	instance.mesh = box

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.35, 1.0, 1.0, 0.95)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 1.0, 1.0)
	mat.emission_energy_multiplier = 4.0
	mat.no_depth_test = true
	instance.material_override = mat

	get_tree().current_scene.add_child(instance)
	instance.global_position = (from + to) * 0.5
	if from.distance_squared_to(to) > 0.001:
		instance.look_at(to, Vector3.UP)

	var tween := instance.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.12)
	tween.parallel().tween_property(mat, "emission_energy_multiplier", 0.0, 0.12)
	tween.tween_callback(instance.queue_free)


func _spawn_spark(position: Vector3, color: Color, size: float) -> void:
	var instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	instance.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(color.r, color.g, color.b, 0.9)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mat.no_depth_test = true
	instance.material_override = mat

	get_tree().current_scene.add_child(instance)
	instance.global_position = position

	var tween := instance.create_tween()
	tween.set_parallel(true)
	tween.tween_property(instance, "scale", Vector3.ONE * 2.6, 0.18)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.18)
	tween.chain().tween_callback(instance.queue_free)


func _land() -> void:
	visual.scale = Vector3(1.12, 0.82, 1.12)
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func take_damage(amount: int) -> void:
	if not alive or not active or _invulnerable > 0.0:
		return
	health = maxi(0, health - amount)
	_invulnerable = 0.75
	_shake = 0.85
	health_changed.emit(health, MAX_HEALTH)
	Sfx.play("hurt", randf_range(0.9, 1.1), -5.0)
	if health <= 0:
		_die()


func _die() -> void:
	alive = false
	active = false
	velocity = Vector3.ZERO
	visual.visible = false
	collision_layer = 0
	collision_mask = 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_spawn_spark(global_position + Vector3.UP * 0.2, Color(0.4, 1.0, 1.0), 0.3)
	died.emit()


func set_active(value: bool) -> void:
	active = value
	if not value:
		velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif alive:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
