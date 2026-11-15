extends Area3D
## Floating shard. Collect every shard to clear the arena.

signal collected(crystal: Area3D, value: int)

@export var value := 100
@export var spin_speed := 1.8

var _taken := false
var _time := 0.0
var _base_y := 0.0
var _gem_mat: StandardMaterial3D

@onready var visual: Node3D = $Visual
@onready var gem: MeshInstance3D = $Visual/Gem
@onready var light: OmniLight3D = $Visual/Light


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_time = randf() * TAU
	_base_y = visual.position.y

	var source := gem.mesh.surface_get_material(0)
	if source is StandardMaterial3D:
		_gem_mat = source.duplicate()
		gem.material_override = _gem_mat


func _process(delta: float) -> void:
	_time += delta
	visual.rotation.y += spin_speed * delta
	visual.position.y = _base_y + sin(_time * 2.2) * 0.14
	if not _taken:
		light.light_energy = 1.6 + sin(_time * 3.0) * 0.4


func _on_body_entered(body: Node3D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	set_deferred("monitoring", false)
	collected.emit(self, value)
	Sfx.play("pickup", randf_range(0.95, 1.12), -5.0)
	light.light_energy = 7.0
	light.omni_range = 9.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "scale", Vector3.ONE * 2.4, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "position:y", visual.position.y + 0.9, 0.28)
	tween.tween_property(light, "light_energy", 0.0, 0.28)
	if _gem_mat != null:
		tween.tween_property(_gem_mat, "albedo_color:a", 0.0, 0.24)
	tween.chain().tween_callback(queue_free)
