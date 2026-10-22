class_name DialogStyle
extends RefCounted
## Gives a ConfirmationDialog a heading (glyph + title) and an accent colour
## so each kind of dialog reads at a glance: red = destructive, orange = unsaved
## changes, blue = rename, green = commit.

const DANGER := Color(0.94, 0.36, 0.36)
const WARNING := Color(1.0, 0.64, 0.26)
const INFO := Color(0.46, 0.72, 1.0)
const SUCCESS := Color(0.45, 0.86, 0.56)


## Returns the message label (null when no message is wanted).
static func apply(dialog: ConfirmationDialog, accent: Color, glyph: String, heading: String,
		with_message: bool, input: Control = null) -> Label:
	dialog.get_label().visible = false

	var panel := dialog.get_theme_stylebox("panel", "AcceptDialog").duplicate() as StyleBoxFlat
	panel.border_color = accent
	dialog.add_theme_stylebox_override("panel", panel)

	var ok := dialog.get_ok_button()
	ok.theme_type_variation = "CreateAction"
	ok.add_theme_stylebox_override("normal", _fill(accent))
	ok.add_theme_stylebox_override("hover", _fill(accent.lightened(0.2)))
	ok.add_theme_stylebox_override("pressed", _fill(accent))
	ok.custom_minimum_size = Vector2(140, 46)
	dialog.get_cancel_button().custom_minimum_size = Vector2(112, 46)

	var margin := MarginContainer.new()
	margin.name = "Content"
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 16)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var badge := Label.new()
	badge.text = glyph
	badge.custom_minimum_size = Vector2(34, 34)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_color_override("font_color", Color(0.05, 0.06, 0.1))
	badge.add_theme_font_size_override("font_size", 22)
	var badge_style := _fill(accent)
	badge_style.set_corner_radius_all(17)
	badge_style.content_margin_left = 0
	badge_style.content_margin_right = 0
	badge_style.content_margin_top = 0
	badge_style.content_margin_bottom = 0
	badge.add_theme_stylebox_override("normal", badge_style)
	head.add_child(badge)
	var title := Label.new()
	title.text = heading
	title.add_theme_color_override("font_color", accent)
	title.add_theme_font_size_override("font_size", 26)
	head.add_child(title)
	layout.add_child(head)

	var message: Label = null
	if with_message:
		message = Label.new()
		message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		message.custom_minimum_size = Vector2(440, 0)
		message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layout.add_child(message)

	if input != null:
		if input.get_parent() != null:
			input.get_parent().remove_child(input)
		input.custom_minimum_size = Vector2(0, 48)
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layout.add_child(input)

	dialog.add_child(margin)
	return message


static func _fill(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(7)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
