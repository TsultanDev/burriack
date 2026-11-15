extends CanvasLayer
## All HUD elements are generated in code so the project stays asset-free.

const CYAN := Color(0.35, 0.95, 1.0)
const RED := Color(1.0, 0.3, 0.42)
const INK := Color(0.85, 0.92, 1.0)
const DIM := Color(0.5, 0.6, 0.76)

var _score_label: Label
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
var _end_body: Label
var _damage_flash: ColorRect
var _damage_tween: Tween
var _crosshair: Control


func _ready() -> void:
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
	var hint := _label("WASD  move      SHIFT  sprint      SPACE  jump      LMB  shoot      R  restart", 14, DIM)
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
	_end_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_overlay.visible = false
	root.add_child(_end_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.02, 0.04, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560.0, 330.0)
	panel.add_theme_stylebox_override("panel", _box(Color(0.035, 0.05, 0.09, 0.96), CYAN, 4))
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	_end_title = _label("ARENA CLEARED", 40, CYAN)
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_end_title)

	var rule := ColorRect.new()
	rule.color = Color(CYAN.r, CYAN.g, CYAN.b, 0.35)
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	content.add_child(rule)

	_end_body = _label("", 19, INK)
	_end_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_end_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(_end_body)

	var restart := _label("PRESS  R  TO RUN IT AGAIN", 16, CYAN)
	restart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(restart)


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


func show_end(won: bool, seconds: float, score: int, kills: int, crystals: int, total: int) -> void:
	_end_title.text = "ARENA CLEARED" if won else "SYSTEM FAILURE"
	_end_title.add_theme_color_override("font_color", CYAN if won else RED)
	var minutes := floori(seconds / 60.0)
	var time_text := "%d:%05.2f" % [minutes, fmod(seconds, 60.0)]
	_end_body.text = "TIME        %s\nSCORE       %d\nSTALKERS    %d\nSHARDS      %d / %d" % [time_text, score, kills, crystals, total]
	_toast_box.visible = false
	_crosshair.visible = false
	_end_overlay.visible = true
	_end_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_end_overlay, "modulate:a", 1.0, 0.45)


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
