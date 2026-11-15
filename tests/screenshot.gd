extends SceneTree
## Test helper: loads the game, lets it settle, then saves a frame.

func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 45:
		await process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://tests/shot_main.png")
	var error := image.save_png(path)
	print("saved ", path, " err=", error)
	quit()
