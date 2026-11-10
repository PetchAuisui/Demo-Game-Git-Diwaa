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
	var cmd_font := load("res://assets/fonts/VT323-Regular.ttf") as Font
	var thai_fallback := load("res://assets/fonts/ChakraPetch-Regular.ttf") as Font
	if cmd_font != null:
		var fv := FontVariation.new()
		fv.base_font = cmd_font
		if thai_fallback != null:
			fv.fallbacks = [thai_fallback]
		return fv
	if thai_fallback != null:
		return thai_fallback
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray(["Menlo", "Consolas", "DejaVu Sans Mono"])
	return sys
