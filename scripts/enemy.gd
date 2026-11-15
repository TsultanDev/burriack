class_name Stalker
extends CharacterBody3D
## Hovering hunter. Chases the player and deals contact damage.

signal destroyed(at: Vector3)

@export var speed := 3.3
@export var max_health := 2
@export var touch_damage := 18
@export var touch_range := 1.3

var player: Player
var health := 2
var active := true

var _time := 0.0
var _touch_cd := 0.0
var _flash := 0.0
var _hit_stun := 0.0
var _knockback := Vector3.ZERO
var _eye_mat: StandardMaterial3D

@onready var visual: Node3D = $Visual
@onready var eye: MeshInstance3D = $Visual/Eye
@onready var ring: MeshInstance3D = $Visual/Ring
@onready var light: OmniLight3D = $Visual/Light


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Player
	health = max_health
	_time = randf() * TAU
	speed *= randf_range(0.9, 1.12)

	var source := eye.mesh.surface_get_material(0)
	if source is StandardMaterial3D:
		_eye_mat = source.duplicate()
		eye.material_override = _eye_mat


func _physics_process(delta: float) -> void:
	if not active:
		return
	_time += delta
	_touch_cd = maxf(0.0, _touch_cd - delta)
	_hit_stun = maxf(0.0, _hit_stun - delta)

	var to := Vector3.ZERO
	var distance := 999.0
	var dir := Vector3.ZERO
	var has_target: bool = player != null and is_instance_valid(player) and player.alive
	if has_target:
		to = player.global_position - global_position
		to.y = 0.0
		distance = to.length()
		if distance > 0.01:
			dir = to / distance

	var wish := Vector3.ZERO
	if has_target and _hit_stun <= 0.0 and distance > 0.9:
		wish = dir * speed

	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not is_instance_valid(other):
			continue
		var away: Vector3 = global_position - (other as Node3D).global_position
		away.y = 0.0
		var gap: float = away.length()
		if gap > 0.01 and gap < 1.5:
			wish += (away / gap) * (1.5 - gap) * 3.0

	_knockback = _knockback.move_toward(Vector3.ZERO, 18.0 * delta)
	wish += _knockback
	velocity.x = wish.x
	velocity.z = wish.z
	velocity.y = 0.0
	move_and_slide()

	if dir.length_squared() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-dir.x, -dir.z), 1.0 - exp(-8.0 * delta))
	visual.position.y = sin(_time * 3.6) * 0.1
	ring.rotation.y += delta * 2.4
	ring.rotation.x = 0.32 + sin(_time * 1.7) * 0.18

	if has_target and distance < touch_range and _touch_cd <= 0.0:
		_touch_cd = 0.9
		player.take_damage(touch_damage)
		_hit_stun = 0.2

	_flash = maxf(0.0, _flash - delta * 6.0)
	if _eye_mat != null:
		_eye_mat.emission_energy_multiplier = 4.0 + sin(_time * 6.0) * 1.5 + _flash * 12.0
	light.light_energy = 1.0 + sin(_time * 5.0) * 0.25 + _flash * 3.0


func take_hit(amount: int, hit_position: Vector3) -> void:
	if not active:
		return
	health -= amount
	_flash = 1.0
	_hit_stun = 0.14
	var push := global_position - hit_position
	push.y = 0.0
	if push.length_squared() > 0.01:
		_knockback = push.normalized() * 3.5
	Sfx.play("enemy_hit", randf_range(0.9, 1.1), -8.0)
	if health <= 0:
		_die()


func _die() -> void:
	active = false
	collision_layer = 0
	collision_mask = 0
	destroyed.emit(global_position)
	Sfx.play("enemy_die", randf_range(0.9, 1.1), -6.0)
	set_physics_process(false)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "scale", Vector3.ONE * 2.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(light, "light_energy", 9.0, 0.22)
	tween.tween_property(light, "omni_range", 13.0, 0.22)
	tween.chain().tween_callback(queue_free)
