extends CanvasLayer
## All HUD elements are generated in code so the project stays asset-free.

signal resume_requested
signal restart_requested
signal next_level_requested
signal menu_requested

const Ui := preload("res://scripts/ui_theme.gd")
const SettingsPanelScript := preload("res://scripts/settings_panel.gd")

const CYAN := Color(0.35, 0.95, 1.0)
const MAGENTA := Color(1.0, 0.3, 0.78)
const RED := Color(1.0, 0.3, 0.42)
const INK := Color(0.85, 0.92, 1.0)
const DIM := Color(0.5, 0.6, 0.76)

var _score_label: Label
var _level_label: Label
var _crystal_label: Label
var _time_label: Label
var _health_bar: ProgressBar
var _health_label: Label
var _toast_box: VBoxContainer
var _toast_title: Label
var _toast_sub: Label
var _toast_tween: Tween
var _end_overlay: Control
var _end_title: Label
var _end_level_label: Label
var _end_body: Label
var _end_primary: Button
var _end_secondary: Button
var _damage_flash: ColorRect
var _damage_tween: Tween
var _crosshair: Control
var _pause_overlay: Control
var _pause_level_label: Label
var _settings_panel: Control

var _level_name := ""
var _end_won := false
var _end_final := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_damage_flash(root)
	_build_crosshair(root)
	_build_score_panel(root)
	_build_status_panel(root)
	_build_health_panel(root)
	_build_hint(root)
	_build_toast(root)
	_build_end_overlay(root)
	_build_pause_overlay(root)
	_build_settings(root)


func _build_damage_flash(root: Control) -> void:
	_damage_flash = ColorRect.new()
	_damage_flash.color = Color(1.0, 0.1, 0.2, 0.0)
	_damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_damage_flash)


func _build_crosshair(root: Control) -> void:
	_crosshair = Control.new()
	_crosshair.anchor_left = 0.5
	_crosshair.anchor_top = 0.5
	_crosshair.anchor_right = 0.5
	_crosshair.anchor_bottom = 0.5
	_crosshair.offset_left = -16.0
	_crosshair.offset_top = -16.0
	_crosshair.offset_right = 16.0
	_crosshair.offset_bottom = 16.0
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_crosshair)

	var segments := [
		Rect2(15, 1, 2, 6),
		Rect2(15, 25, 2, 6),
		Rect2(1, 15, 6, 2),
		Rect2(25, 15, 6, 2),
		Rect2(15, 15, 2, 2),
	]
	for rect in segments:
		var tick := ColorRect.new()
		tick.color = Color(CYAN.r, CYAN.g, CYAN.b, 0.9)
		tick.position = rect.position
		tick.size = rect.size
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_crosshair.add_child(tick)


func _build_score_panel(root: Control) -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(30.0, 22.0)
	box.add_theme_constant_override("separation", -2)
	root.add_child(box)

	var brand := _label("CRYSTAL RUSH", 14, CYAN)
	box.add_child(brand)

	_level_label = _label("LEVEL 1 / 3", 12, DIM)
	box.add_child(_level_label)

	_score_label = _label("SCORE  00000", 30, INK)
	box.add_child(_score_label)


func _build_status_panel(root: Control) -> void:
	var box := VBoxContainer.new()
	box.anchor_left = 1.0
	box.anchor_right = 1.0
	box.offset_left = -360.0
	box.offset_right = -30.0
	box.offset_top = 20.0
	box.offset_bottom = 104.0
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_theme_constant_override("separation", 0)
	root.add_child(box)

	_crystal_label = _label("SHARDS  0 / 12", 24, INK)
	_crystal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_crystal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_crystal_label)

	_time_label = _label("TIME  0:00.00", 16, DIM)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_time_label)


func _build_health_panel(root: Control) -> void:
	var box := VBoxContainer.new()
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 30.0
	box.offset_right = 370.0
	box.offset_top = -96.0
	box.offset_bottom = -30.0
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 6)
	root.add_child(box)

	_health_label = _label("INTEGRITY  100", 14, DIM)
	box.add_child(_health_label)

	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(320.0, 16.0)
	_health_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_health_bar.max_value = 100.0
	_health_bar.value = 100.0
	_health_bar.show_percentage = false
	_health_bar.add_theme_stylebox_override("background", _box(Color(0.04, 0.06, 0.1, 0.9), Color(0.18, 0.3, 0.42, 0.7), 2))
	_health_bar.add_theme_stylebox_override("fill", _box(CYAN, Color(0.7, 1.0, 1.0, 1.0), 2))
	box.add_child(_health_bar)


func _build_hint(root: Control) -> void:
	var hint := _label("WASD  move      SHIFT  sprint      SPACE  jump      LMB  shoot      ESC  pause      R  restart", 14, DIM)
	hint.anchor_left = 0.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_top = -46.0
	hint.offset_bottom = -18.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)


func _build_toast(root: Control) -> void:
	_toast_box = VBoxContainer.new()
	_toast_box.anchor_left = 0.5
	_toast_box.anchor_right = 0.5
	_toast_box.offset_left = -380.0
	_toast_box.offset_right = 380.0
	_toast_box.offset_top = 104.0
	_toast_box.offset_bottom = 196.0
	_toast_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_toast_box.add_theme_constant_override("separation", 0)
	root.add_child(_toast_box)

	_toast_title = _label("CRYSTAL RUSH", 38, INK)
	_toast_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toast_box.add_child(_toast_title)

	_toast_sub = _label("Collect all 12 shards.", 17, CYAN)
	_toast_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toast_box.add_child(_toast_sub)


func _build_end_overlay(root: Control) -> void:
	_end_overlay = Control.new()
	_end_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_end_overlay.visible = false
	root.add_child(_end_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.02, 0.04, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600.0, 430.0)
	panel.add_theme_stylebox_override("panel", Ui.panel_style(CYAN))
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	_end_title = Ui.label("SECTOR CLEARED", 40, CYAN)
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_end_title)

	_end_level_label = Ui.label("LEVEL 1 / 3", 14, DIM)
	_end_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_end_level_label)

	var rule := ColorRect.new()
	rule.color = Color(CYAN.r, CYAN.g, CYAN.b, 0.35)
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	content.add_child(rule)

	_end_body = Ui.label("", 19, INK)
	_end_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_end_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(_end_body)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	content.add_child(buttons)

	_end_primary = Ui.button("NEXT LEVEL", CYAN)
	_end_primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_primary.pressed.connect(_on_end_primary_pressed)
	buttons.add_child(_end_primary)

	_end_secondary = Ui.button("MAIN MENU", MAGENTA)
	_end_secondary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_secondary.pressed.connect(_on_end_secondary_pressed)
	buttons.add_child(_end_secondary)


func _build_pause_overlay(root: Control) -> void:
	_pause_overlay = Control.new()
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.visible = false
	root.add_child(_pause_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.015, 0.03, 0.76)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480.0, 0.0)
	panel.add_theme_stylebox_override("panel", Ui.panel_style(CYAN))
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var title := Ui.label("PAUSED", 42, CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(title)

	_pause_level_label = Ui.label("", 14, DIM)
	_pause_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_pause_level_label)

	var rule := ColorRect.new()
	rule.color = Color(CYAN.r, CYAN.g, CYAN.b, 0.35)
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	content.add_child(rule)

	var resume := Ui.button("RESUME", CYAN)
	resume.pressed.connect(_on_resume_pressed)
	content.add_child(resume)

	var restart := Ui.button("RESTART LEVEL", Ui.MAGENTA)
	restart.pressed.connect(_on_restart_pressed)
	content.add_child(restart)

	var settings := Ui.button("SETTINGS", Ui.CYAN)
	settings.pressed.connect(_on_pause_settings_pressed)
	content.add_child(settings)

	var menu := Ui.button("MAIN MENU", Ui.RED)
	menu.pressed.connect(_on_menu_pressed)
	content.add_child(menu)


func _build_settings(root: Control) -> void:
	_settings_panel = SettingsPanelScript.new()
	root.add_child(_settings_panel)


func _on_resume_pressed() -> void:
	Sfx.play("ui")
	resume_requested.emit()


func _on_restart_pressed() -> void:
	Sfx.play("ui")
	restart_requested.emit()


func _on_pause_settings_pressed() -> void:
	Sfx.play("ui")
	_settings_panel.open()


func _on_menu_pressed() -> void:
	Sfx.play("ui_back")
	menu_requested.emit()


func _on_end_primary_pressed() -> void:
	Sfx.play("ui")
	if _end_won and not _end_final:
		next_level_requested.emit()
	else:
		restart_requested.emit()


func _on_end_secondary_pressed() -> void:
	Sfx.play("ui_back")
	menu_requested.emit()


func set_level(index: int, total: int, title: String) -> void:
	_level_name = title
	_level_label.text = "LEVEL %d / %d  -  %s" % [index, total, title]


func set_score(value: int) -> void:
	_score_label.text = "SCORE  %05d" % value


func set_crystals(collected: int, total: int) -> void:
	_crystal_label.text = "SHARDS  %d / %d" % [collected, total]


func set_time(seconds: float) -> void:
	var minutes := floori(seconds / 60.0)
	_time_label.text = "TIME  %d:%05.2f" % [minutes, fmod(seconds, 60.0)]


func set_health(current: int, maximum: int) -> void:
	_health_bar.max_value = float(maximum)
	_health_bar.value = float(current)
	_health_label.text = "INTEGRITY  %d" % current
	var ratio := float(current) / float(maximum)
	var color := CYAN if ratio > 0.35 else RED
	_health_bar.add_theme_stylebox_override("fill", _box(color, Color(color.r + 0.3, color.g + 0.3, color.b + 0.3, 1.0), 2))


func flash_damage() -> void:
	if _damage_tween != null and _damage_tween.is_valid():
		_damage_tween.kill()
	_damage_flash.color = Color(1.0, 0.08, 0.16, 0.3)
	_damage_tween = create_tween()
	_damage_tween.tween_property(_damage_flash, "color:a", 0.0, 0.38)


func ping_crystal() -> void:
	_crystal_label.add_theme_color_override("font_color", Color.WHITE)
	var tween := create_tween()
	tween.tween_interval(0.09)
	tween.tween_callback(func() -> void: _crystal_label.add_theme_color_override("font_color", INK))


func show_toast(title: String, subtitle: String, hold: float = 3.2) -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_title.text = title
	_toast_sub.text = subtitle
	_toast_box.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(hold)
	_toast_tween.tween_property(_toast_box, "modulate:a", 0.0, 0.8)


func show_pause(show: bool, title: String) -> void:
	if show:
		_settings_panel.close()
		_pause_level_label.text = title
		_end_overlay.visible = false
		_pause_overlay.visible = true
		_pause_overlay.modulate.a = 0.0
		create_tween().tween_property(_pause_overlay, "modulate:a", 1.0, 0.16)
		_crosshair.visible = false
	else:
		_pause_overlay.visible = false
		_settings_panel.close()
		_crosshair.visible = true


func is_settings_open() -> bool:
	return _settings_panel != null and _settings_panel.visible


func close_settings() -> void:
	if _settings_panel != null:
		_settings_panel.close()


func show_end(won: bool, seconds: float, score: int, kills: int, crystals: int, total: int, level_index: int, is_final: bool, campaign_total: int) -> void:
	_end_won = won
	_end_final = is_final and won
	if won and _end_final:
		_end_title.text = "CAMPAIGN COMPLETE"
	elif won:
		_end_title.text = "SECTOR CLEARED"
	else:
		_end_title.text = "SYSTEM FAILURE"
	var accent := CYAN if won else RED
	_end_title.add_theme_color_override("font_color", accent)
	_style_button(_end_primary, accent)

	_end_level_label.text = "LEVEL %d / %d  -  %s" % [level_index, GameState.TOTAL_LEVELS, _level_name]
	var minutes := floori(seconds / 60.0)
	var time_text := "%d:%05.2f" % [minutes, fmod(seconds, 60.0)]
	_end_body.text = "TIME        %s\nSCORE       %d\nSTALKERS    %d\nSHARDS      %d / %d\n\nCAMPAIGN TOTAL   %d" % [time_text, score, kills, crystals, total, campaign_total]

	if not won:
		_end_primary.text = "RETRY LEVEL"
	elif _end_final:
		_end_primary.text = "PLAY AGAIN"
	else:
		_end_primary.text = "NEXT LEVEL"
	_end_secondary.text = "MAIN MENU"

	_pause_overlay.visible = false
	_settings_panel.close()
	_toast_box.visible = false
	_crosshair.visible = false
	_end_overlay.visible = true
	_end_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_end_overlay, "modulate:a", 1.0, 0.45)


func _style_button(node: Button, accent: Color) -> void:
	node.add_theme_color_override("font_pressed_color", accent)
	node.add_theme_stylebox_override("normal", Ui.button_style(Color(0.035, 0.05, 0.085, 0.92), Color(accent.r, accent.g, accent.b, 0.32)))
	node.add_theme_stylebox_override("hover", Ui.button_style(Color(accent.r, accent.g, accent.b, 0.16), accent, 2))
	node.add_theme_stylebox_override("pressed", Ui.button_style(Color(accent.r, accent.g, accent.b, 0.28), accent, 2))
	node.add_theme_stylebox_override("focus", Ui.button_style(Color(accent.r, accent.g, accent.b, 0.06), Color(accent.r, accent.g, accent.b, 0.8), 2))


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", maxi(2, size / 7))
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04, 0.9))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
