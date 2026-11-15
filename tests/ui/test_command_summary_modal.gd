extends SceneTree

const CommandSummaryModal = preload("res://features/dialogue/command_summary_modal.gd")

func _init() -> void:
	_run_tests()

func _run_tests() -> void:
	print("--- Running CommandSummaryModal Test ---")
	var scene: PackedScene = load("res://features/dialogue/command_summary_modal.tscn")
	if scene == null:
		push_error("Failed to load command_summary_modal.tscn")
		quit(1)
		return
	var modal: CommandSummaryModal = scene.instantiate() as CommandSummaryModal
	if modal == null:
		push_error("Failed to instantiate CommandSummaryModal")
		quit(1)
		return
	root.add_child(modal)
	await process_frame
	
	# Verify initial state
	assert(modal.slides.size() >= 1, "Should have at least 1 slide")
	assert(modal.current_slide_index == 0, "Initial slide should be 0")
	print("Initial slide loaded successfully: ", modal.title_label.text)
	
	# Test casting command
	modal._on_cast_command_pressed()
	assert(modal.has_executed_current_slide == true, "Should have executed current slide")
	print("Cast command triggered")
	
	# Test canvas animation completion simulation
	modal._on_canvas_animation_finished()
	assert(modal.outcome_panel.visible == true, "Outcome panel should be visible")
	print("Outcome panel revealed successfully")
	
	# Test slide navigation
	if modal.slides.size() > 1:
		modal._on_next_slide_pressed()
		assert(modal.current_slide_index == 1, "Should navigate to slide 1")
		print("Navigated to slide 1: ", modal.title_label.text)
		modal._on_prev_slide_pressed()
		assert(modal.current_slide_index == 0, "Should navigate back to slide 0")
		print("Navigated back to slide 0")
	
	# Test reset animation
	modal._on_reset_animation_pressed()
	assert(modal.has_executed_current_slide == false, "Should reset executed state")
	print("Reset animation succeeded")
	
	print("=== ALL CommandSummaryModal TESTS PASSED! ===")
	quit(0)
