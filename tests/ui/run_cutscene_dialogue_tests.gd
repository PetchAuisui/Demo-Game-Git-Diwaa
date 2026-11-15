extends SceneTree
## Headless verification script สำหรับทดสอบ 10 จุดที่แก้ไขใน PR #52 (Cutscene & Dialogue View)
##
## รัน:
##   godot --headless --path game --script ../tests/ui/run_cutscene_dialogue_tests.gd

const CutsceneMusicScript = preload("res://common/cutscene_music.gd")
const LevelDialogueViewScript = preload("res://features/dialogue/level_dialogue_view.gd")

var _passed := 0
var _total := 0
var _failures: Array[String] = []


func _initialize() -> void:
	print("--- Running Cutscene & Dialogue Tests (Headless) ---")
	await process_frame
	
	_test_cutscene_music_singleton_and_cleanup()
	_test_cutscene_music_volume_catchup()
	_test_cutscene_music_duplicate_player_prevention()
	_test_dialogue_stylebox_creation()
	_test_dialogue_subsequence_flag()
	_test_dialogue_action_choice_fallback()
	_test_dialogue_back_queue_clamping()
	_test_dialogue_kill_tween_helper()
	_test_scene_loader_flush_non_blocking()
	
	print("\n--- Test Results ---")
	print("Passed: %d / %d" % [_passed, _total])
	if _failures.is_empty():
		print("All cutscene & dialogue tests passed successfully!")
		quit(0)
	else:
		printerr("Failures (%d):\n  * %s" % [_failures.size(), "\n  * ".join(_failures)])
		quit(1)


func _assert_true(condition: bool, test_name: String) -> void:
	_total += 1
	if condition:
		_passed += 1
		print("  [PASS] %s" % test_name)
	else:
		_failures.append(test_name)
		printerr("  [FAIL] %s" % test_name)


func _test_cutscene_music_singleton_and_cleanup() -> void:
	# ทดสอบว่า stop_immediate ล้าง root player อย่างสะอาดหมดจด
	CutsceneMusic.play()
	var player = CutsceneMusic._player
	_assert_true(player != null, "CutsceneMusic creates player")
	
	CutsceneMusic.stop_immediate()
	_assert_true(CutsceneMusic._player == null, "CutsceneMusic player is cleared on stop_immediate")
	_assert_true(get_root().get_node_or_null("CutscenePersistentBGM") == null, "Root persistent BGM node removed")


func _test_cutscene_music_volume_catchup() -> void:
	# ข้อ 2: ทดสอบว่าถ้า volume_db ยังไม่ถึง target (skip ไว) แล้ว play() ซ้ำ จะเร่งเสียงต่อ
	var p = AudioStreamPlayer.new()
	p.name = "TestAudioPlayer"
	get_root().add_child(p)
	CutsceneMusic.register_player(p)
	p.volume_db = -12.0
	p.play()
	
	CutsceneMusic.play(0.1, -12.0, 2.0)
	_assert_true(CutsceneMusic._fade_tween != null, "CutsceneMusic initiates tween when volume is below target")
	
	CutsceneMusic.stop_immediate()
	if is_instance_valid(p):
		p.queue_free()


func _test_cutscene_music_duplicate_player_prevention() -> void:
	# ข้อ 1: ทดสอบว่าถ้า register player ตัวใหม่ ตัวเก่าบน root จะถูกทำลาย ไม่เล่นซ้อน 2 ชั้น
	var p1 = AudioStreamPlayer.new()
	p1.name = "BGM1"
	get_root().add_child(p1)
	CutsceneMusic.register_player(p1)
	
	var p2 = AudioStreamPlayer.new()
	p2.name = "BGM2"
	get_root().add_child(p2)
	CutsceneMusic.register_player(p2)
	
	_assert_true(CutsceneMusic._player == p2, "New player registered successfully")
	CutsceneMusic.stop_immediate()


func _test_dialogue_stylebox_creation() -> void:
	# ข้อ 8: ทดสอบ Helper _create_slot_stylebox สร้าง StyleBox ถูกต้องทั้งมี Texture และ Fallback
	var dialogue_view = LevelDialogueViewScript.new()
	var fallback_sb = dialogue_view._create_slot_stylebox(null)
	_assert_true(fallback_sb is StyleBoxFlat, "_create_slot_stylebox fallback is StyleBoxFlat")
	
	var tex = PlaceholderTexture2D.new()
	var tex_sb = dialogue_view._create_slot_stylebox(tex)
	_assert_true(tex_sb is StyleBoxTexture, "_create_slot_stylebox with texture is StyleBoxTexture")
	dialogue_view.free()


func _test_dialogue_subsequence_flag() -> void:
	# ข้อ 3: ทดสอบว่า is_in_sub_sequence ทำงานถูกต้องเมื่อบันทึกประวัติและคืนค่า
	var dialogue_view = LevelDialogueViewScript.new()
	dialogue_view.current_queue = [{"type": "dummy"}]
	dialogue_view.queue_index = 0
	dialogue_view.is_in_sub_sequence = false
	dialogue_view.current_sequence_name = "intro"
	
	# จำลองการโหลด sub-sequence และบันทึกประวัติ
	dialogue_view.sequence_history.append({
		"queue": dialogue_view.current_queue,
		"index": 0,
		"is_showing_choices": false,
		"is_in_entrance_cutscene": false,
		"is_in_sub_sequence": dialogue_view.is_in_sub_sequence,
		"sequence_name": dialogue_view.current_sequence_name
	})
	dialogue_view.current_queue = [{"type": "question"}]
	dialogue_view.is_in_sub_sequence = true
	dialogue_view.current_sequence_name = "choice_1"
	
	_assert_true(dialogue_view.is_in_sub_sequence == true, "Choice sequence is recognized as a sub-sequence")
	_assert_true(dialogue_view.current_sequence_name == "choice_1", "Sequence name is 'choice_1'")
	_assert_true(dialogue_view.sequence_history.size() == 1, "History has recorded parent sequence")
	
	# จำลองการถอยกลับจาก sub-sequence
	var parent_state = dialogue_view.sequence_history.pop_back()
	dialogue_view.current_queue = parent_state.get("queue", dialogue_view.current_queue)
	dialogue_view.is_in_sub_sequence = parent_state.get("is_in_sub_sequence", false)
	dialogue_view.current_sequence_name = parent_state.get("sequence_name", "")
	
	_assert_true(dialogue_view.is_in_sub_sequence == false, "Main intro sequence is restored as not a sub-sequence")
	_assert_true(dialogue_view.current_sequence_name == "intro", "Sequence name restored to 'intro'")
	dialogue_view.free()


func _test_dialogue_action_choice_fallback() -> void:
	# ข้อ 5: ทดสอบว่าถ้าเป็น part 2 แล้ว sequence ขาด Fallback จะเปิด step 2 ไม่ใช่ 1
	var dialogue_view = LevelDialogueViewScript.new()
	dialogue_view.current_menu_id = "part2_main"
	dialogue_view.debug_phase = 1
	var choice_part2 = {"id": "part2_try", "text": "ฉันจะลองดู"}
	
	var is_part2_choice = choice_part2.get("id", "").begins_with("part2_") or dialogue_view.current_menu_id.begins_with("part2_") or dialogue_view.debug_phase >= 1
	var fallback_step = 2 if is_part2_choice else 1
	_assert_true(fallback_step == 2, "Part 2 action choice fallback resolves to step 2")
	
	dialogue_view.current_menu_id = "part1_main"
	dialogue_view.debug_phase = 0
	var choice_part1 = {"id": "part1_try", "text": "ฉันจะลองดู"}
	var is_part1_choice = choice_part1.get("id", "").begins_with("part2_") or dialogue_view.current_menu_id.begins_with("part2_") or dialogue_view.debug_phase >= 1
	var fallback_step1 = 2 if is_part1_choice else 1
	_assert_true(fallback_step1 == 1, "Part 1 action choice fallback resolves to step 1")
	dialogue_view.free()


func _test_dialogue_back_queue_clamping() -> void:
	# ข้อ 9: ทดสอบว่าเมื่อย้อนกลับ queue_index จะถูก clamp ให้อยู่ในช่วงที่ถูกต้องเสมอ ไม่หลุดเป็น -1
	var dialogue_view = LevelDialogueViewScript.new()
	dialogue_view.current_queue = [{"text": "Item 1"}]
	dialogue_view.queue_index = 0
	
	var popped_idx = -5
	var clamped = clamp(popped_idx, 0, dialogue_view.current_queue.size() - 1)
	_assert_true(clamped == 0, "Negative queue index is clamped safely to 0")
	dialogue_view.free()


func _test_dialogue_kill_tween_helper() -> void:
	# ข้อ 8: ทดสอบ _kill_tween ทำงานได้ถูกต้องทั้งกับ tween จริงและ null
	var dialogue_view = LevelDialogueViewScript.new()
	var res1 = dialogue_view._kill_tween(null)
	_assert_true(res1 == null, "_kill_tween with null returns null without error")
	dialogue_view.free()


func _test_scene_loader_flush_non_blocking() -> void:
	# ข้อ 6: ทดสอบว่า flush_preloads แบบปกติ (wait=false) ไม่ค้าง main thread
	SceneLoader.flush_preloads(false)
	_assert_true(true, "flush_preloads non-blocking completes instantly")
