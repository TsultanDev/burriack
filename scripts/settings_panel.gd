extends Control
## Reusable neon settings overlay shared by the main menu and the pause screen.

signal closed

const Ui := preload("res://scripts/ui_theme.gd")

var _sensitivity_slider: HSlider
var _sensitivity_value: Label
var _volume_slider: HSlider
var _volume_value: Label
var _fullscreen_check: CheckBox


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()
	Settings.changed.connect(_sync)
	_sync()


func open() -> void:
	_sync()
	visible = true
	if _sensitivity_slider != null:
		_sensitivity_slider.grab_focus()


func close() -> void:
	if not visible:
		return
	Settings.save_settings()
	visible = false
	closed.emit()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.014, 0.03, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560.0, 0.0)
	panel.add_theme_stylebox_override("panel", Ui.panel_style(Ui.CYAN))
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var title := Ui.label("SETTINGS", 40, Ui.CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(title)

	var subtitle := Ui.label("SYSTEM CONFIGURATION", 13, Ui.DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(subtitle)

	_add_rule(content)

	_sensitivity_value = Ui.label("1.00x", 17, Ui.INK)
	_sensitivity_slider = _add_slider(content, "MOUSE SENSITIVITY", _sensitivity_value, 0.2, 3.0, 0.05)
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	_sensitivity_slider.drag_ended.connect(_on_drag_ended)

	_volume_value = Ui.label("80%", 17, Ui.INK)
	_volume_slider = _add_slider(content, "MASTER VOLUME", _volume_value, 0.0, 1.0, 0.01)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_volume_slider.drag_ended.connect(_on_drag_ended)

	var fullscreen_row := HBoxContainer.new()
	fullscreen_row.add_theme_constant_override("separation", 8)
	content.add_child(fullscreen_row)

	_fullscreen_check = CheckBox.new()
	_fullscreen_check.text = "FULLSCREEN"
	_fullscreen_check.add_theme_font_size_override("font_size", 17)
	_fullscreen_check.add_theme_color_override("font_color", Ui.INK)
	_fullscreen_check.add_theme_color_override("font_hover_color", Color.WHITE)
	_fullscreen_check.add_theme_color_override("font_pressed_color", Ui.CYAN)
	_fullscreen_check.add_theme_color_override("font_focus_color", Color.WHITE)
	_fullscreen_check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	fullscreen_row.add_child(_fullscreen_check)

	_add_rule(content)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	content.add_child(buttons)

	var reset := Ui.button("RESET DEFAULTS", Ui.MAGENTA)
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(_on_reset_pressed)
	buttons.add_child(reset)

	var back := Ui.button("BACK", Ui.CYAN)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(_on_back_pressed)
	buttons.add_child(back)


func _add_slider(parent: VBoxContainer, title_text: String, value_label: Label, minimum: float, maximum: float, step: float) -> HSlider:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	parent.add_child(header)

	var label := Ui.label(title_text, 14, Ui.DIM)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)

	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(value_label)

	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.custom_minimum_size = Vector2(0.0, 24.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slider.add_theme_stylebox_override("slider", Ui.slider_track())
	slider.add_theme_stylebox_override("grabber_area", Ui.slider_fill(Ui.CYAN))
	slider.add_theme_stylebox_override("grabber_area_highlight", Ui.slider_fill(Color.WHITE))
	parent.add_child(slider)
	return slider


func _add_rule(parent: VBoxContainer) -> void:
	var rule := ColorRect.new()
	rule.color = Color(Ui.CYAN.r, Ui.CYAN.g, Ui.CYAN.b, 0.3)
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	parent.add_child(rule)


func _on_sensitivity_changed(value: float) -> void:
	Settings.set_sensitivity(value, false)
	_sensitivity_value.text = "%.2fx" % value


func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value, false)
	_volume_value.text = "%d%%" % roundi(value * 100.0)


func _on_drag_ended(_value_changed: bool) -> void:
	Settings.save_settings()


func _on_fullscreen_toggled(pressed: bool) -> void:
	Sfx.play("ui")
	Settings.set_fullscreen(pressed)


func _on_reset_pressed() -> void:
	Sfx.play("ui")
	Settings.reset_defaults()
	_sync()


func _on_back_pressed() -> void:
	Sfx.play("ui_back")
	close()


func _sync() -> void:
	if _sensitivity_slider == null:
		return
	_sensitivity_slider.set_value_no_signal(Settings.sensitivity)
	_sensitivity_value.text = "%.2fx" % Settings.sensitivity
	_volume_slider.set_value_no_signal(Settings.master_volume)
	_volume_value.text = "%d%%" % roundi(Settings.master_volume * 100.0)
	_fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
