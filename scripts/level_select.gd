extends Control
## PvZ-style campaign map: two pages of ten levels with a boss at the end of each.

signal level_chosen(index: int)
signal closed

const Ui := preload("res://scripts/ui_theme.gd")
const LEVELS := preload("res://scripts/level_data.gd")

var _page := 1
var _grid: GridContainer
var _page_label: Label
var _progress_label: Label
var _previous_button: Button
var _next_button: Button
var _level_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


func open() -> void:
	_page = GameState.page_of(GameState.unlocked_level)
	_refresh()
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.014, 0.03, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980.0, 0.0)
	panel.add_theme_stylebox_override("panel", Ui.panel_style(Ui.CYAN))
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	content.add_child(header)

	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -6)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)

	var title := Ui.label("SELECT LEVEL", 38, Ui.CYAN)
	titles.add_child(title)

	var subtitle := Ui.label("TWO PAGES  -  TEN LEVELS EACH  -  BOSS AT THE END", 12, Ui.DIM)
	titles.add_child(subtitle)

	_progress_label = Ui.label("UNLOCKED  1 / 20", 14, Ui.INK)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_progress_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_progress_label)

	_add_rule(content)

	var page_row := HBoxContainer.new()
	page_row.add_theme_constant_override("separation", 12)
	content.add_child(page_row)

	_previous_button = Ui.button("<  PREVIOUS PAGE", Ui.MAGENTA)
	_previous_button.custom_minimum_size = Vector2(190.0, 38.0)
	_previous_button.add_theme_font_size_override("font_size", 13)
	_previous_button.pressed.connect(_on_previous_page)
	page_row.add_child(_previous_button)

	_page_label = Ui.label("PAGE 1 / 2", 17, Ui.INK)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_row.add_child(_page_label)

	_next_button = Ui.button("NEXT PAGE  >", Ui.MAGENTA)
	_next_button.custom_minimum_size = Vector2(190.0, 38.0)
	_next_button.add_theme_font_size_override("font_size", 13)
	_next_button.pressed.connect(_on_next_page)
	page_row.add_child(_next_button)

	_grid = GridContainer.new()
	_grid.columns = GameState.LEVELS_PER_PAGE / 2
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	content.add_child(_grid)

	_add_rule(content)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	content.add_child(footer)

	var back := Ui.button("BACK", Ui.CYAN)
	back.custom_minimum_size = Vector2(230.0, 46.0)
	back.pressed.connect(_on_back_pressed)
	footer.add_child(back)

	var hint := Ui.label("CLEAR A LEVEL TO UNLOCK THE NEXT. BOSS LEVELS CLOSE EACH PAGE.", 12, Ui.DIM)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(hint)


func _refresh() -> void:
	for child in _grid.get_children():
		child.free()
	_level_buttons.clear()

	var first_index := (_page - 1) * GameState.LEVELS_PER_PAGE + 1
	for slot in range(1, GameState.LEVELS_PER_PAGE + 1):
		var index := first_index + slot - 1
		var button := _make_level_button(index, slot)
		_grid.add_child(button)
		_level_buttons.append(button)

	_page_label.text = "PAGE %d / %d" % [_page, GameState.PAGES]
	_progress_label.text = "UNLOCKED  %d / %d" % [GameState.unlocked_level, GameState.TOTAL_LEVELS]
	_previous_button.disabled = _page <= 1
	_next_button.disabled = _page >= GameState.PAGES


func _make_level_button(index: int, slot: int) -> Button:
	var boss := slot == GameState.LEVELS_PER_PAGE
	var unlocked := GameState.is_unlocked(index)
	var cleared := GameState.is_cleared(index)
	var accent := Ui.RED if boss else (Ui.CYAN if _page == 1 else Ui.MAGENTA)
	var button := Ui.button("", accent)
	button.custom_minimum_size = Vector2(174.0, 78.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = not unlocked
	if unlocked:
		button.pressed.connect(_on_level_pressed.bind(index))

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 8.0
	content.offset_right = -8.0
	content.offset_top = 5.0
	content.offset_bottom = -5.0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", -2)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var number := GameState.level_label(index)
	var number_label := Ui.label(number, 24, accent if unlocked else Ui.DIM)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(number_label)

	var display_name := str(LEVELS.get_level(index - 1)["name"])
	if boss:
		display_name = "BOSS  " + display_name
	var name_label := Ui.label(display_name, 9, Ui.DIM)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(name_label)

	var state_text := "LOCKED"
	var state_color := Ui.DIM
	if cleared:
		state_text = "CLEARED"
		state_color = Ui.CYAN
	elif unlocked:
		state_text = "READY"
		state_color = Color.WHITE
	var state_label := Ui.label(state_text, 9, state_color)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(state_label)

	return button


func _on_previous_page() -> void:
	if _page <= 1:
		return
	Sfx.play("ui")
	_page -= 1
	_refresh()


func _on_next_page() -> void:
	if _page >= GameState.PAGES:
		return
	Sfx.play("ui")
	_page += 1
	_refresh()


func _on_level_pressed(index: int) -> void:
	if not GameState.is_unlocked(index):
		return
	Sfx.play("ui")
	level_chosen.emit(index)


func _on_back_pressed() -> void:
	Sfx.play("ui_back")
	close()


func _add_rule(parent: VBoxContainer) -> void:
	var rule := ColorRect.new()
	rule.color = Color(Ui.CYAN.r, Ui.CYAN.g, Ui.CYAN.b, 0.3)
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	parent.add_child(rule)
