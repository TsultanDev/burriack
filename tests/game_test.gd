extends SceneTree
## Headless integration checks for the core game loop.

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS  ", message)
	else:
		_failures += 1
		print("FAIL  ", message)


func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	await physics_frame

	var main = current_scene
	var player = get_first_node_in_group("player")
	var crystals := main.get_node("Pickups").get_children()
	var enemies := get_nodes_in_group("enemies")

	_check(main != null, "main scene loads")
	_check(player != null, "player spawns")
	_check(crystals.size() == 12, "12 shards spawned (got %d)" % crystals.size())
	_check(enemies.size() == 5, "5 stalkers spawned (got %d)" % enemies.size())
	_check(main.get_node("Arena").get_child_count() > 20, "arena geometry built")

	var start_position: Vector3 = player.global_position
	Input.action_press("move_forward")
	for i in 20:
		await physics_frame
	Input.action_release("move_forward")
	_check(player.global_position.distance_to(start_position) > 0.5, "player moves with input")

	player._invulnerable = 0.0
	player.take_damage(10)
	_check(player.health == 90, "player takes damage (health %d)" % player.health)

	var target = enemies[0]
	player.yaw = 0.0
	player.pitch = -0.1
	await physics_frame
	await physics_frame
	var forward: Vector3 = -player.camera.global_transform.basis.z
	target.global_position = player.camera.global_position + forward * 6.0
	await physics_frame
	await physics_frame
	forward = -player.camera.global_transform.basis.z
	target.global_position = player.camera.global_position + forward * 6.0
	await physics_frame
	var score_before: int = main.score
	player._shoot()
	player._shoot()
	for i in 5:
		await physics_frame
	_check(main.kills >= 1, "shooting destroys a stalker (kills %d)" % main.kills)
	_check(main.score >= score_before + 75, "stalker kill adds score")

	for crystal in crystals:
		if is_instance_valid(crystal):
			crystal._on_body_entered(player)
	for i in 5:
		await process_frame
	_check(main.shards_left == 0, "all shards collected")
	await create_timer(1.0).timeout
	_check(main.state == "won", "win state reached")
	_check(main.hud._end_overlay.visible, "win overlay shown")

	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	player = get_first_node_in_group("player")
	main = current_scene
	for i in 6:
		player._invulnerable = 0.0
		player.take_damage(25)
	await create_timer(1.2).timeout
	_check(player.health == 0, "player can be defeated")
	_check(main.state == "lost", "lose state reached")
	_check(main.hud._end_overlay.visible, "lose overlay shown")

	print("\n%s (%d failure(s))" % ["ALL CHECKS PASSED" if _failures == 0 else "CHECKS FAILED", _failures])
	quit(1 if _failures > 0 else 0)
