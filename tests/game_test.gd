extends SceneTree
## Headless integration checks for menus, settings, and the three-level campaign.

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS  ", message)
	else:
		_failures += 1
		print("FAIL  ", message)


func _load_scene(path: String) -> void:
	change_scene_to_file(path)
	await process_frame
	await process_frame
	await physics_frame


func _press_escape() -> void:
	var down := InputEventKey.new()
	down.keycode = KEY_ESCAPE
	down.physical_keycode = KEY_ESCAPE
	down.pressed = true
	Input.parse_input_event(down)
	var up := down.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	await process_frame


func _run() -> void:
	var settings = root.get_node_or_null("Settings")
	var game_state = root.get_node_or_null("GameState")
	_check(settings != null, "settings autoload is available")
	_check(game_state != null, "campaign autoload is available")
	if settings == null or game_state == null:
		print("\nCHECKS FAILED (missing autoloads)")
		quit(1)
		return

	await _load_scene("res://scenes/main_menu.tscn")
	var menu = current_scene
	_check(menu != null, "main menu loads")
	_check(menu._settings_panel != null, "menu owns a settings panel")
	_check(menu._buttons.size() == 3, "menu has play/settings/exit buttons")
	var play_button: Button = menu._buttons[0]
	var exit_button: Button = menu._buttons[2]
	var screen_rect := root.get_visible_rect()
	_check(screen_rect.encloses(play_button.get_global_rect()), "menu play button fits on screen")
	_check(screen_rect.encloses(exit_button.get_global_rect()), "menu exit button fits on screen")
	_check(play_button.text == "PLAY CAMPAIGN" and exit_button.text == "EXIT", "menu buttons are labelled")

	menu._settings_panel.open()
	_check(menu._settings_panel.visible, "settings panel opens")
	menu._settings_panel._sensitivity_slider.value = 1.5
	_check(is_equal_approx(settings.sensitivity, 1.5), "sensitivity slider updates settings")
	await _press_escape()
	_check(not menu._settings_panel.visible, "Esc closes the menu settings panel")
	settings.reset_defaults()

	menu._on_play_pressed()
	await create_timer(0.7).timeout
	await process_frame

	var main = current_scene
	var player = get_first_node_in_group("player")
	var crystals: Array = main.get_node("Pickups").get_children()
	var enemies: Array = get_nodes_in_group("enemies")

	_check(main != null, "campaign loads the first level")
	_check(game_state.current_level == 1, "campaign starts at level 1")
	_check(main.level_index == 1, "level builder reads level 1")
	_check(player != null, "player spawns")
	_check(crystals.size() == 8, "level 1 spawns 8 shards (got %d)" % crystals.size())
	_check(enemies.size() == 3, "level 1 spawns 3 stalkers (got %d)" % enemies.size())
	_check(int(enemies[0].max_health) == 2, "level 1 stalker health configured")
	_check(main.get_node("Arena").get_child_count() > 20, "arena geometry built")
	_check(main.hud._level_label.text.contains("LEVEL 1 / 3"), "HUD shows the level label")

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

	await _press_escape()
	_check(main.paused and paused, "Esc pauses the scene tree")
	_check(main.hud._pause_overlay.visible, "pause overlay shown")
	main.hud._on_pause_settings_pressed()
	_check(main.hud.is_settings_open(), "pause menu opens settings")
	await _press_escape()
	_check(not main.hud.is_settings_open() and main.paused, "Esc closes pause settings and stays paused")
	await _press_escape()
	_check(not main.paused and not paused, "Esc resumes the scene tree")
	_check(not main.hud._pause_overlay.visible, "pause overlay hidden")

	for crystal in crystals:
		if is_instance_valid(crystal):
			crystal._on_body_entered(player)
	for i in 5:
		await process_frame
	_check(main.shards_left == 0, "all level 1 shards collected")
	await create_timer(1.0).timeout
	_check(main.state == "won", "level 1 win state reached")
	_check(main.hud._end_overlay.visible, "win overlay shown")
	_check(main.hud._end_primary.text == "NEXT LEVEL", "win offers the next level")

	main.hud._on_end_primary_pressed()
	for i in 3:
		await process_frame
	await physics_frame

	main = current_scene
	player = get_first_node_in_group("player")
	crystals = main.get_node("Pickups").get_children()
	enemies = get_nodes_in_group("enemies")
	_check(game_state.current_level == 2, "next level advances the campaign")
	_check(main.level_index == 2, "level builder reads level 2")
	_check(crystals.size() == 10, "level 2 spawns 10 shards (got %d)" % crystals.size())
	_check(enemies.size() == 5, "level 2 spawns 5 stalkers (got %d)" % enemies.size())
	_check(int(enemies[0].touch_damage) == 16, "level 2 stalker damage configured")

	for i in 6:
		player._invulnerable = 0.0
		player.take_damage(25)
	await create_timer(1.2).timeout
	_check(player.health == 0, "player can be defeated")
	_check(main.state == "lost", "lose state reached")
	_check(main.hud._end_overlay.visible, "lose overlay shown")
	_check(main.hud._end_primary.text == "RETRY LEVEL", "lose offers a retry")

	main.hud._on_end_primary_pressed()
	for i in 3:
		await process_frame
	await physics_frame
	main = current_scene
	_check(game_state.current_level == 2, "retry stays on the current level")
	_check(main.level_index == 2, "retry reloads level 2")

	main._go_to_menu()
	for i in 3:
		await process_frame
	_check(current_scene != null and current_scene.name == "MainMenu", "main menu button returns to the menu")

	game_state.current_level = 3
	game_state.total_score = 0
	await _load_scene("res://scenes/main.tscn")
	main = current_scene
	player = get_first_node_in_group("player")
	crystals = main.get_node("Pickups").get_children()
	enemies = get_nodes_in_group("enemies")
	_check(main.level_index == 3, "level builder reads level 3")
	_check(crystals.size() == 12, "level 3 spawns 12 shards (got %d)" % crystals.size())
	_check(enemies.size() == 7, "level 3 spawns 7 stalkers (got %d)" % enemies.size())
	_check(int(enemies[0].max_health) == 3, "level 3 stalker health configured")
	_check(float(enemies[0].speed) > 3.5 and float(enemies[0].speed) < 4.5, "level 3 stalker speed configured")

	for crystal in crystals:
		if is_instance_valid(crystal):
			crystal._on_body_entered(player)
	for i in 5:
		await process_frame
	await create_timer(1.0).timeout
	_check(main.state == "won", "final level win state reached")
	_check(main.hud._end_final, "final level flagged as campaign end")
	_check(main.hud._end_title.text == "CAMPAIGN COMPLETE", "campaign completion title shown")
	_check(main.hud._end_primary.text == "PLAY AGAIN", "campaign completion offers replay")
	_check(game_state.total_score > 0, "campaign total score accumulates")

	main.hud._on_end_primary_pressed()
	for i in 3:
		await process_frame
	await physics_frame
	main = current_scene
	_check(game_state.current_level == 1, "play again resets the campaign")
	_check(main.level_index == 1, "play again loads level 1")

	print("\n%s (%d failure(s))" % ["ALL CHECKS PASSED" if _failures == 0 else "CHECKS FAILED", _failures])
	quit(1 if _failures > 0 else 0)

