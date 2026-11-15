extends SceneTree
## Headless integration checks for menus, settings, level select, and the 20-level campaign.

const LEVELS := preload("res://scripts/level_data.gd")

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


func _collect_all(crystals: Array, player: Node) -> void:
	for crystal in crystals:
		if is_instance_valid(crystal):
			crystal._on_body_entered(player)


func _layout_problem(data: Dictionary) -> String:
	var half := float(data["arena_half"])
	var spawn: Vector3 = data["player_spawn"]
	if absf(spawn.x) > half - 1.0 or absf(spawn.z) > half - 1.0:
		return "player spawn outside arena"

	var shards: Array = data["shards"]
	var crates: Array = data["crates"]
	var pillars: Array = data["pillars"]
	if shards.size() < 5:
		return "too few shards"

	for point in shards:
		if absf(point.x) > half - 1.0 or absf(point.z) > half - 1.0:
			return "shard outside arena"
		if Vector2(point.x, point.z).distance_to(Vector2(spawn.x, spawn.z)) < 2.5:
			return "shard too close to player spawn"
	for point in crates:
		if absf(point.x) > half - 1.0 or absf(point.z) > half - 1.0:
			return "crate outside arena"
	for i in shards.size():
		for j in range(i + 1, shards.size()):
			if Vector2(shards[i].x, shards[i].z).distance_to(Vector2(shards[j].x, shards[j].z)) < 1.8:
				return "shards overlap"
	for shard in shards:
		for crate in crates:
			if Vector2(shard.x, shard.z).distance_to(Vector2(crate.x, crate.z)) < 1.6:
				return "crate blocks a shard"
	for pillar in pillars:
		var center: Vector3 = pillar["center"]
		if absf(center.x) > half - 1.0 or absf(center.z) > half - 1.0:
			return "pillar outside arena"
	for point in data["spawns"]:
		if absf(point.x) > half - 1.0 or absf(point.z) > half - 1.0:
			return "enemy spawn outside arena"
	return ""


func _run() -> void:
	var settings = root.get_node_or_null("Settings")
	var game_state = root.get_node_or_null("GameState")
	_check(settings != null, "settings autoload is available")
	_check(game_state != null, "campaign autoload is available")
	if settings == null or game_state == null:
		print("\nCHECKS FAILED (missing autoloads)")
		quit(1)
		return

	game_state.reset_progress()
	settings.reset_defaults()
	_check(game_state.TOTAL_LEVELS == 20, "campaign has 20 levels")
	_check(LEVELS.count() == 20, "level data has 20 definitions")
	_check(game_state.page_of(10) == 1 and game_state.page_of(11) == 2, "level indices map to two pages")
	_check(game_state.level_label(1) == "1-1" and game_state.level_label(20) == "2-10", "level labels use page-slot format")

	var boss_flags_ok := true
	var layout_problem := ""
	for index in range(1, 21):
		var data: Dictionary = LEVELS.get_level(index - 1)
		var should_be_boss := index % 10 == 0
		if data.has("boss") != should_be_boss:
			boss_flags_ok = false
		var problem := _layout_problem(data)
		if not problem.is_empty() and layout_problem.is_empty():
			layout_problem = "%s (%s)" % [problem, data["name"]]
	_check(boss_flags_ok, "level 10 and level 20 are bosses")
	_check(layout_problem.is_empty(), "all 20 generated layouts are valid %s" % layout_problem)

	await _load_scene("res://scenes/main_menu.tscn")
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	var menu = current_scene
	_check(menu != null, "main menu loads")
	_check(menu._settings_panel != null, "menu owns a settings panel")
	_check(menu._level_select != null, "menu owns a level select panel")
	_check(menu._buttons.size() == 3, "menu has play/settings/exit buttons")
	var play_button: Button = menu._buttons[0]
	var exit_button: Button = menu._buttons[2]
	var screen_rect := root.get_visible_rect()
	print("INFO  test viewport is ", screen_rect.size)
	_check(screen_rect.size.x <= 1280 and screen_rect.size.y <= 720, "test viewport is 720p or smaller")
	_check(screen_rect.encloses(play_button.get_global_rect()), "menu play button fits on screen")
	_check(screen_rect.encloses(exit_button.get_global_rect()), "menu exit button fits on screen")
	_check(play_button.text == "PLAY CAMPAIGN" and exit_button.text == "EXIT", "menu buttons are labelled")

	menu._on_play_pressed()
	await process_frame
	var select_panel: Control = menu._level_select._grid.get_parent().get_parent()
	_check(screen_rect.encloses(select_panel.get_global_rect()), "level select panel fits a 720p window")
	_check(menu._level_select.visible, "play opens the level select page")
	_check(menu._level_select._page == 1, "level select starts on page 1")
	_check(menu._level_select._level_buttons.size() == 10, "page 1 shows ten levels")
	_check(not menu._level_select._level_buttons[0].disabled, "level 1-1 is unlocked")
	_check(menu._level_select._level_buttons[1].disabled, "level 1-2 starts locked")
	_check(screen_rect.encloses(menu._level_select._level_buttons[0].get_global_rect()), "level button fits on screen")
	menu._level_select._on_next_page()
	_check(menu._level_select._page == 2, "next page advances to page 2")
	_check(menu._level_select._level_buttons[0].disabled, "page 2 starts locked")
	menu._level_select._on_previous_page()
	await _press_escape()
	_check(not menu._level_select.visible, "Esc closes the level select")

	menu._settings_panel.open()
	var settings_panel_box: Control = menu._settings_panel.get_child(1).get_child(0)
	_check(screen_rect.encloses(settings_panel_box.get_global_rect()), "settings panel fits a 720p window")
	_check(menu._settings_panel.visible, "settings panel opens")
	menu._settings_panel._sensitivity_slider.value = 1.5
	_check(is_equal_approx(settings.sensitivity, 1.5), "sensitivity slider updates settings")
	menu._settings_panel._low_graphics_check.button_pressed = true
	_check(settings.low_graphics, "low spec checkbox updates settings")
	_check(root.msaa_3d == Viewport.MSAA_DISABLED, "low spec disables MSAA")
	_check(is_equal_approx(root.scaling_3d_scale, 0.7), "low spec lowers 3D render scale")
	_check(not menu.sun.shadow_enabled and not menu.world_environment.environment.glow_enabled, "low spec disables menu shadows and glow")
	settings.save_settings()
	settings.low_graphics = false
	settings.load_settings()
	_check(settings.low_graphics, "low spec setting persists")
	await _press_escape()
	_check(not menu._settings_panel.visible, "Esc closes the menu settings panel")
	settings.reset_defaults()
	_check(not settings.low_graphics and root.msaa_3d == Viewport.MSAA_4X, "reset restores high graphics")

	menu._on_play_pressed()
	menu._level_select._on_level_pressed(1)
	await create_timer(0.7).timeout
	await process_frame

	var main = current_scene
	var player = get_first_node_in_group("player")
	var crystals: Array = main.get_node("Pickups").get_children()
	var enemies: Array = get_nodes_in_group("enemies")
	var level_one: Dictionary = LEVELS.get_level(0)

	_check(main != null, "level select loads the first level")
	_check(game_state.current_level == 1, "campaign starts at level 1")
	_check(main.level_index == 1, "level builder reads level 1")
	_check(player != null, "player spawns")
	_check(crystals.size() == level_one["shards"].size(), "level 1 spawns the configured shard count")
	_check(enemies.size() == int(level_one["enemy_count"]), "level 1 spawns the configured stalker count")
	_check(int(enemies[0].max_health) == int(level_one["enemy_health"]), "level 1 stalker health configured")
	_check(main.get_node("Arena").get_child_count() > 20, "arena geometry built")
	_check(main.hud._level_label.text.contains("LEVEL 1-1"), "HUD shows the page-slot label")
	_check(not main.hud._boss_box.visible, "boss bar hidden on a normal level")

	settings.set_low_graphics(true)
	_check(not main.sun.shadow_enabled and not main.world_environment.environment.glow_enabled, "low spec applies in game")
	_check(not main.rim_cyan.visible and not main.rim_magenta.visible, "low spec disables rim lights")
	settings.set_low_graphics(false)
	_check(main.sun.shadow_enabled and main.world_environment.environment.glow_enabled, "high spec restores in game")

	var start_position: Vector3 = player.global_position
	player._invulnerable = 999.0
	Input.action_press("move_forward")
	for i in 20:
		await physics_frame
	Input.action_release("move_forward")
	_check(player.global_position.distance_to(start_position) > 0.5, "player moves with input")

	player.health = 100
	player._invulnerable = 0.0
	player.take_damage(10)
	_check(player.health == 90, "player takes damage (health %d)" % player.health)
	player._invulnerable = 999.0

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

	_collect_all(crystals, player)
	for i in 5:
		await process_frame
	_check(main.shards_left == 0, "all level 1 shards collected")
	await create_timer(1.0).timeout
	_check(main.state == "won", "level 1 win state reached")
	_check(main.hud._end_overlay.visible, "win overlay shown")
	_check(main.hud._end_primary.text == "NEXT LEVEL", "win offers the next level")
	_check(game_state.unlocked_level >= 2, "winning unlocks the next level")

	main.hud._on_end_primary_pressed()
	for i in 3:
		await process_frame
	await physics_frame

	main = current_scene
	player = get_first_node_in_group("player")
	crystals = main.get_node("Pickups").get_children()
	enemies = get_nodes_in_group("enemies")
	var level_two: Dictionary = LEVELS.get_level(1)
	_check(game_state.current_level == 2, "next level advances the campaign")
	_check(main.level_index == 2, "level builder reads level 2")
	_check(crystals.size() == level_two["shards"].size(), "level 2 spawns the configured shard count")
	_check(enemies.size() == int(level_two["enemy_count"]), "level 2 spawns the configured stalker count")
	_check(int(enemies[0].touch_damage) == int(level_two["enemy_damage"]), "level 2 stalker damage configured")

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

	game_state.select_level(10)
	await _load_scene("res://scenes/main.tscn")
	main = current_scene
	player = get_first_node_in_group("player")
	player._invulnerable = 999.0
	crystals = main.get_node("Pickups").get_children()
	enemies = get_nodes_in_group("enemies")
	var boss_level: Dictionary = LEVELS.get_level(9)
	_check(main.level_index == 10, "level builder reads boss level 1-10")
	_check(main.boss_alive and main.boss != null and main.boss.is_boss, "boss level spawns a boss")
	_check(main.boss.max_health == int(boss_level["boss"]["health"]), "boss health configured")
	_check(main.boss.visual.scale.x > 1.5, "boss uses a larger body")
	_check(main.hud._boss_box.visible, "boss health bar shown")
	_check(screen_rect.encloses(main.hud._boss_box.get_global_rect()), "boss health bar fits on screen")
	_check(main.hud._boss_name_label.text.contains("OVERSEER"), "boss name shown")
	_check(enemies.size() == int(boss_level["enemy_count"]) + 1, "boss level also spawns minions")

	_collect_all(crystals, player)
	for i in 5:
		await process_frame
	await create_timer(0.8).timeout
	_check(main.state == "playing", "collecting all shards does not win while the boss lives")
	_check(main.shards_left == 0, "boss level shards collected")

	main.boss.take_hit(999, main.boss.global_position)
	for i in 5:
		await process_frame
	await create_timer(1.0).timeout
	_check(main.state == "won", "boss level wins after the boss dies")
	_check(not main.boss_alive and not main.hud._boss_box.visible, "boss bar hides after the boss dies")
	_check(main.hud._end_title.text == "PAGE CLEARED", "boss victory clears the page")
	_check(main.hud._end_primary.text == "NEXT PAGE", "boss victory offers the next page")
	_check(game_state.unlocked_level >= 11, "boss victory unlocks page 2")

	main.hud._on_end_primary_pressed()
	for i in 3:
		await process_frame
	await physics_frame
	main = current_scene
	_check(game_state.current_level == 11, "next page advances to level 2-1")
	_check(main.level_index == 11, "level builder reads level 11")
	_check(main.hud._level_label.text.contains("LEVEL 2-1"), "HUD shows page 2 level label")

	main._go_to_menu()
	for i in 3:
		await process_frame
	menu = current_scene
	menu._on_play_pressed()
	await process_frame
	_check(menu._level_select._page == 2, "level select opens on the unlocked page")
	_check(not menu._level_select._level_buttons[0].disabled, "level 2-1 is unlocked")
	await _press_escape()

	game_state.select_level(20)
	await _load_scene("res://scenes/main.tscn")
	main = current_scene
	player = get_first_node_in_group("player")
	player._invulnerable = 999.0
	crystals = main.get_node("Pickups").get_children()
	_check(main.level_index == 20, "level builder reads final boss level 2-10")
	_check(main.boss_alive and main.boss.max_health == int(LEVELS.get_level(19)["boss"]["health"]), "final boss configured")
	_collect_all(crystals, player)
	for i in 5:
		await process_frame
	main.boss.take_hit(999, main.boss.global_position)
	for i in 5:
		await process_frame
	await create_timer(1.0).timeout
	_check(main.state == "won", "final boss level win state reached")
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

	settings.reset_defaults()
	game_state.reset_progress()
	print("\n%s (%d failure(s))" % ["ALL CHECKS PASSED" if _failures == 0 else "CHECKS FAILED", _failures])
	quit(1 if _failures > 0 else 0)
