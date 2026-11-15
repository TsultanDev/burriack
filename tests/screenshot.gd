extends SceneTree
## Test helper: loads the menu, level select, and a level, then saves one frame of each.

func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	change_scene_to_file("res://scenes/main_menu.tscn")
	for i in 60:
		await process_frame
	await _save("tests/shot_menu.png")

	var menu = current_scene
	if menu != null and menu._level_select != null:
		menu._on_play_pressed()
		for i in 12:
			await process_frame
		await _save("tests/shot_select.png")
		menu._level_select.close()

	var game_state = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.current_level = 1
	change_scene_to_file("res://scenes/main.tscn")
	for i in 60:
		await process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _save("tests/shot_main.png")
	quit()


func _save(relative_path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://" + relative_path)
	var error := image.save_png(path)
	print("saved ", path, " err=", error)
