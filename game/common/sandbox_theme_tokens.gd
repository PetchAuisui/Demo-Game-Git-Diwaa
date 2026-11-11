class_name SandboxThemeTokens
extends RefCounted
## Design tokens and styling helpers matching the authentic Git-Diwaa theme.

# Authentic Colors from Checkpoint01.tscn
const TOP_BAR_BG := Color(0.18, 0.13, 0.08, 0.96)
const TOP_BAR_BORDER := Color(0.91, 0.69, 0.27, 1.0)

const CARD_BG := Color(0.025, 0.031, 0.055, 0.9)
const CARD_BORDER := Color(0.37, 0.42, 0.67, 0.9)

const TERMINAL_BG := Color(0.008, 0.011, 0.019, 0.97)
const TERMINAL_BORDER := Color(0.94, 0.68, 0.25, 1.0)

const INPUT_BG := Color(0.03, 0.04, 0.065, 1.0)
const BUTTON_BG := Color(0.12, 0.14, 0.23, 0.96)
const BUTTON_BORDER := Color(0.48, 0.53, 0.78, 1.0)

# Text Colors
const GOLD_TITLE := Color(1.0, 0.79, 0.35, 1.0)
const BRAND_TEXT := Color(1.0, 0.96, 0.83, 1.0)
const LEVEL_GREEN := Color(0.7, 1.0, 0.67, 1.0)
const PROMPT_GREEN := Color(0.31, 0.95, 0.62, 1.0)
const SUBTITLE_TEXT := Color(0.68, 0.73, 0.85, 1.0)
const TEXT_SECONDARY := Color(0.60, 0.64, 0.72, 1.0)
const PRIMARY_TEXT := Color(0.87, 0.90, 0.95, 1.0)
const ERROR_TEXT := Color(0.98, 0.40, 0.48, 1.0)

# Git File State Colors
const STATE_UNTRACKED := Color(0.98, 0.40, 0.48, 1.0)
const STATE_MODIFIED := Color(1.0, 0.79, 0.35, 1.0)
const STATE_ADDED := Color(0.31, 0.95, 0.62, 1.0)
const STATE_DELETED := Color(0.85, 0.30, 0.30, 1.0)
const STATE_RENAMED := Color(0.35, 0.75, 0.95, 1.0)


static func create_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.border_color = CARD_BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(18)
	return style


static func create_terminal_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TERMINAL_BG
	style.border_color = TERMINAL_BORDER
	style.set_border_width_all(5)
	style.set_corner_radius_all(12)
	style.content_margin_left = 27
	style.content_margin_top = 21
	style.content_margin_right = 27
	style.content_margin_bottom = 21
	return style


static func create_input_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = INPUT_BG
	style.set_corner_radius_all(9)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style


static func create_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BUTTON_BG
	style.border_color = BUTTON_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.content_margin_left = 21
	style.content_margin_right = 21
	return style


static func create_terminal_font() -> Font:
	var cmd_font := load("res://assets/fonts/TA-8-bit.ttf") as Font
	var thai_fallback := create_terminal_thai_font()
	if cmd_font != null:
		var fv := FontVariation.new()
		fv.base_font = cmd_font
		fv.variation_embolden = 0.25
		if thai_fallback != null:
			fv.fallbacks = [thai_fallback]
		return fv
	if thai_fallback != null:
		return thai_fallback
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray(["Menlo", "Consolas", "DejaVu Sans Mono"])
	return sys


static func create_terminal_thai_font() -> Font:
	var chakra := load("res://assets/fonts/ChakraPetch-Regular.ttf") as Font
	if chakra == null:
		return null
	var fv := FontVariation.new()
	fv.base_font = chakra
	fv.variation_embolden = 0.2
	fv.spacing_top = 4
	fv.spacing_bottom = 2
	return fv


static func append_terminal_styled_text(
	rich_label: RichTextLabel,
	text: String,
	thai_font: Font,
	thai_font_size: int = 22
) -> void:
	if rich_label == null or text.is_empty():
		return
	if thai_font == null or not _has_thai(text):
		rich_label.add_text(text)
		return
	var lines := text.split("\n", true)
	for i in lines.size():
		if i > 0:
			rich_label.add_text("\n")
		if not lines[i].is_empty():
			_append_terminal_styled_line(rich_label, lines[i], thai_font, thai_font_size)


static func _append_terminal_styled_line(
	rich_label: RichTextLabel,
	line: String,
	thai_font: Font,
	thai_font_size: int
) -> void:
	var n := line.length()
	var thai_mask := PackedByteArray()
	thai_mask.resize(n)
	for i in n:
		thai_mask[i] = 1 if _is_thai(line.unicode_at(i)) else 0

	# Attach sentence punctuation/spaces surrounding Thai text so Thai phrases keep consistent ChakraPetch sizing.
	for i in n:
		if thai_mask[i] != 0:
			continue
		var cp := line.unicode_at(i)
		if cp == 0x28: # '(' before Thai
			var next_idx := i + 1
			while next_idx < n and line.unicode_at(next_idx) == 0x20:
				next_idx += 1
			if next_idx < n and _is_thai(line.unicode_at(next_idx)):
				thai_mask[i] = 1
		elif _is_neutral_punct(cp):
			var has_thai_before := i > 0 and thai_mask[i - 1] == 1
			var look := i + 1
			while look < n and _is_neutral_punct(line.unicode_at(look)):
				look += 1
			var has_thai_after := look < n and _is_thai(line.unicode_at(look))
			if (has_thai_before and (look == n or has_thai_after)) or (cp == 0x20 and (has_thai_before or has_thai_after)):
				thai_mask[i] = 1

	var start := 0
	while start < n:
		var use_thai := thai_mask[start] == 1
		var end := start + 1
		while end < n and (thai_mask[end] == 1) == use_thai:
			end += 1
		var chunk := line.substr(start, end - start)
		if use_thai:
			rich_label.push_font(thai_font, thai_font_size)
			rich_label.add_text(chunk)
			rich_label.pop()
		else:
			rich_label.add_text(chunk)
		start = end


static func _is_thai(cp: int) -> bool:
	return cp >= 0x0E00 and cp <= 0x0E7F


static func _has_thai(text: String) -> bool:
	for i in text.length():
		if _is_thai(text.unicode_at(i)):
			return true
	return false


static func _is_neutral_punct(cp: int) -> bool:
	return cp == 0x20 or cp == 0x2E or cp == 0x2C or cp == 0x3A or cp == 0x3B or cp == 0x29 or cp == 0x21 or cp == 0x3F
