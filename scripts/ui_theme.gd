class_name UiTheme
extends RefCounted
## Shared neon UI styling helpers.

const CYAN := Color(0.35, 0.95, 1.0)
const MAGENTA := Color(1.0, 0.3, 0.78)
const RED := Color(1.0, 0.3, 0.42)
const INK := Color(0.86, 0.92, 1.0)
const DIM := Color(0.5, 0.6, 0.76)
const DARK := Color(0.02, 0.025, 0.045, 0.96)


static func label(text: String, size: int, color: Color = INK) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_constant_override("outline_size", maxi(2, size / 7))
	node.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04, 0.9))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func button(text: String, accent: Color = CYAN) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(0.0, 50.0)
	node.add_theme_font_size_override("font_size", 18)
	node.add_theme_color_override("font_color", INK)
	node.add_theme_color_override("font_hover_color", Color.WHITE)
	node.add_theme_color_override("font_pressed_color", accent)
	node.add_theme_color_override("font_focus_color", Color.WHITE)
	node.add_theme_stylebox_override("normal", button_style(Color(0.035, 0.05, 0.085, 0.92), Color(accent.r, accent.g, accent.b, 0.32)))
	node.add_theme_stylebox_override("hover", button_style(Color(accent.r, accent.g, accent.b, 0.16), accent, 2))
	node.add_theme_stylebox_override("pressed", button_style(Color(accent.r, accent.g, accent.b, 0.28), accent, 2))
	node.add_theme_stylebox_override("focus", button_style(Color(accent.r, accent.g, accent.b, 0.06), Color(accent.r, accent.g, accent.b, 0.8), 2))
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return node


static func button_style(bg: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(3)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


static func panel_style(accent: Color = CYAN, alpha: float = 0.97) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.042, 0.075, alpha)
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 30.0
	style.content_margin_bottom = 30.0
	return style


static func slider_track() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.13, 0.95)
	style.set_corner_radius_all(2)
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


static func slider_fill(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style
