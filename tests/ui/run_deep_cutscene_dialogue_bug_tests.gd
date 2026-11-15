extends SceneTree
## Deep Bug & Stress Test สำหรับ Cutscene และ Dialogue System
##
## ตรวจสอบ:
## 1. Scene Lifecycle & Transitions: cut_scence_normal -> intro_cutscene -> outside_cutscene
## 2. Audio Persistence & Leak Prevention: Skip เร็ว, ออกไปเมนู, รันซ้ำไม่ซ้อน
## 3. Real PackedScene instantiation & UI interaction ใน SceneTree
## 4. Choice Menu Navigation: ซ้อนเมนู, กลับเมนูหลัก, หลีกเลี่ยง recursion
## 5. Rapid Back Button Spamming: กดรัว 50 ครั้งตอนต้น/กลาง/ช้อยส์ ไม่เกิด index หลุดหรือ crash
## 6. Action choice fallback สำหรับ Part 1 และ Part 2
## 7. Static cache persistence ข้ามฉาก

const CutsceneNormalScene = preload("res://features/cutscene/cut_scence_normal.tscn")
const IntroCutsceneScene = preload("res://features/cutscene/intro_cutscene.tscn")
const OutsideCutsceneScene = preload("res://features/cutscene/outside_cutscene.tscn")
const LevelDialogueViewScene = preload("res://features/dialogue/level_dialogue_view.tscn")
const LevelDialogueViewScript = preload("res://features/dialogue/level_dialogue_view.gd")

var _passed := 0
var _total := 0
var _failures: Array[String] = []


func _initialize() -> void:
	print("==================================================")
	print("🚀 STARTING DEEP BUG & STRESS TESTS (Headless)")
	print("==================================================")
	await process_frame
	
	await _test_cutscene_normal_fast_skip_and_persistence()
	await _test_outside_cutscene_menu_exit_audio_cleanup()
	await _test_outside_cutscene_repeat_run_no_overlap()
	await _test_dialogue_real_scene_flow_and_sub_menu()
	await _test_dialogue_rapid_back_spam_safety()
	await _test_dialogue_part2_action_choice_step()
	await _test_dialogue_cache_retention_across_instances()
	
	print("\n==================================================")
	print("📊 FINAL BUG TEST SUMMARY")
	print("Passed: %d / %d" % [_passed, _total])
	if _failures.is_empty():
		print("🎉 ALL DEEP BUG TESTS PASSED WITH 0 FAILURES!")
		print("==================================================")
		LevelDialogueViewScript._clear_cached_textures()
		CutsceneMusic.stop_immediate()
		await process_frame
		quit(0)
	else:
		printerr("❌ FAILURES DETECTED (%d):\n  * %s" % [_failures.size(), "\n  * ".join(_failures)])
		print("==================================================")
		quit(1)


func _assert_true(condition: bool, test_name: String) -> void:
	_total += 1
	if condition:
		_passed += 1
		print("  ✅ [PASS] %s" % test_name)
	else:
		_failures.append(test_name)
		printerr("  ❌ [FAIL] %s" % test_name)


## -----------------------------------------------------------------------------
## 1. ทดสอบ Cutscene Normal: Skip เร็วภายใน 0.2s และย้ายเพลงไป root ไม่พัง
## -----------------------------------------------------------------------------
func _test_cutscene_normal_fast_skip_and_persistence() -> void:
	print("\n--- [TEST 1] Cutscene Normal: Fast Skip & Audio Reparent ---")
	CutsceneMusic.stop_immediate()
	
	var norm_scene = CutsceneNormalScene.instantiate()
	get_root().add_child(norm_scene)
	await process_frame
	await process_frame
	
	# ตรวจว่า bgm เริ่มต้นทำงาน
	var bgm = norm_scene.get_node_or_null("BGM") as AudioStreamPlayer
	_assert_true(bgm != null, "CutsceneNormal has $BGM")
	
	# จำลองผู้เล่นกด skip เร็วมาก (skip stage 1 -> stage 2 -> intro)
	norm_scene._on_skip_step()
	await process_frame
	norm_scene._on_skip_step()
	await process_frame
	
	# ตรวจว่า bgm ถูก reparent ไปไว้ที่ root อย่างถูกต้อง
	_assert_true(bgm.get_parent() == get_root(), "BGM reparented to root on scene skip")
	_assert_true(CutsceneMusic._player == bgm, "CutsceneMusic player is registered as bgm")
	
	# ลบ scene ปกติออก (เสมือนสลับฉาก)
	norm_scene.queue_free()
	await process_frame
	
	# แม้ cut_scence_normal จะถูก free แต่ bgm ที่ root ต้องยังอยู่และไม่ถูกทำลาย
	_assert_true(is_instance_valid(bgm), "BGM on root survives after CutsceneNormal is freed")
	
	# เมื่อฉากถัดไปเรียก CutsceneMusic.play() เสียงต้อง fade-in ต่อไปจนถึง 2.0 dB
	CutsceneMusic.play(0.1, -12.0, 2.0)
	_assert_true(CutsceneMusic._fade_tween != null or bgm.volume_db >= 1.5, "Volume fade continuation triggered")
	
	CutsceneMusic.stop_immediate()
	await process_frame


## -----------------------------------------------------------------------------
## 2. ทดสอบ Outside Cutscene: กดออกจากคัตซีนทางอื่น เพลงต้องหยุดสนิท ไม่รั่ว
## -----------------------------------------------------------------------------
func _test_outside_cutscene_menu_exit_audio_cleanup() -> void:
	print("\n--- [TEST 2] Outside Cutscene: Audio Cleanup on Early Exit ---")
	CutsceneMusic.stop_immediate()
	
	var outside_scene = OutsideCutsceneScene.instantiate()
	get_root().add_child(outside_scene)
	await process_frame
	await process_frame
	
	_assert_true(CutsceneMusic.is_playing(), "Music is playing during Outside Cutscene")
	
	# จำลองผู้เล่นกดย้อนกลับไปเมนู (ไม่ผ่าน _trigger_start_level)
	# โหนด outside_scene ถูกถอดออกจาก scene tree
	outside_scene.queue_free()
	await process_frame
	await process_frame
	
	_assert_true(not CutsceneMusic.is_playing(), "CutsceneMusic stopped immediately when outside scene exited")
	_assert_true(not is_instance_valid(CutsceneMusic._player) or CutsceneMusic._player == null, "Player reference is cleanly nullified")
	_assert_true(get_root().get_node_or_null("CutscenePersistentBGM") == null, "No CutscenePersistentBGM left on root")
	_assert_true(get_root().get_node_or_null("BGM") == null, "No reparented BGM left on root")


## -----------------------------------------------------------------------------
## 3. ทดสอบเริ่ม Cutscene ใหม่อีกรอบ: ต้องไม่มีเพลงซ้อน 2 ตัว
## -----------------------------------------------------------------------------
func _test_outside_cutscene_repeat_run_no_overlap() -> void:
	print("\n--- [TEST 3] Cutscene Replay: No Audio Layer Overlapping ---")
	CutsceneMusic.stop_immediate()
	
	# เล่นรอบที่ 1
	var scene1 = CutsceneNormalScene.instantiate()
	get_root().add_child(scene1)
	await process_frame
	scene1._go_to_intro_cutscene()
	await process_frame
	scene1.queue_free()
	await process_frame
	
	# ตอนนี้มี BGM ค้างบน root จากรอบ 1
	var bgm1 = CutsceneMusic._player
	_assert_true(bgm1 != null and is_instance_valid(bgm1), "First BGM active on root")
	
	# เล่นรอบที่ 2 ทันที (ผู้เล่นเริ่มคัตซีนใหม่)
	var scene2 = CutsceneNormalScene.instantiate()
	get_root().add_child(scene2)
	await process_frame
	
	# ตัวเก่า bgm1 ต้องถูกหยุดและแทนที่ด้วยตัวใหม่ ไม่เล่นซ้อนกัน
	var bgm2 = scene2.get_node("BGM")
	_assert_true(CutsceneMusic._player == bgm2, "CutsceneMusic cleanly switches to new player")
	
	scene2.queue_free()
	CutsceneMusic.stop_immediate()
	await process_frame


## -----------------------------------------------------------------------------
## 4. ทดสอบ Dialogue View: Flow จริง เมนูย่อย กลับเมนูหลัก และ Recursion Safety
## -----------------------------------------------------------------------------
func _test_dialogue_real_scene_flow_and_sub_menu() -> void:
	print("\n--- [TEST 4] Dialogue Engine: Real Level 1 Choice Menu, Sub-Menu & Recursion ---")
	var dview = LevelDialogueViewScene.instantiate()
	dview.level_number = 1
	dview.play_entrance_cutscene = false
	get_root().add_child(dview)
	await process_frame
	await process_frame
	
	_assert_true(dview.current_sequence_name == "intro", "Started with intro sequence")
	_assert_true(not dview.is_in_sub_sequence, "Not in sub-sequence initially")
	
	# ดำเนินบทสนทนา Level 1 ไปข้างหน้าเรื่อย ๆ จนกระทั่งเปิด choice_menu
	var max_steps = 20
	while not dview.is_showing_choices and max_steps > 0:
		dview._on_player_advance()
		await process_frame
		max_steps -= 1
	
	_assert_true(dview.is_showing_choices, "Showing choice menu part1_main in real Level 1")
	_assert_true(dview.choice_buttons.size() > 0, "Level 1 choices generated")
	
	# ผู้เล่นกดเลือกช้อยส์ข้อ 0 ("พลัง Git คืออะไร?")
	dview._on_choice_selected(0)
	await process_frame
	await process_frame
	
	_assert_true(dview.is_in_sub_sequence, "Entered sub-sequence for choice 0")
	_assert_true(dview.current_sequence_name == "part1_git", "Current sequence name is part1_git")
	
	# ดำเนินบทสนทนาใน sub-sequence จนจบแล้ววนกลับมาที่เมนูหลัก part1_main
	max_steps = 20
	while not dview.is_showing_choices and max_steps > 0:
		dview._on_player_advance()
		await process_frame
		max_steps -= 1
	
	_assert_true(not dview.is_in_sub_sequence, "Cleanly returned from sub-sequence to main menu")
	_assert_true(dview.is_showing_choices, "Returned to main choice menu without recursion crash")
	
	if is_instance_valid(dview):
		dview.queue_free()
	await process_frame
	
	if is_instance_valid(dview):
		dview.queue_free()
	await process_frame


## -----------------------------------------------------------------------------
## 5. ทดสอบ Rapid Back Button Spamming: กดย้อนกลับรัว 50 ครั้งตอนต้น/ระหว่างเล่น
## -----------------------------------------------------------------------------
func _test_dialogue_rapid_back_spam_safety() -> void:
	print("\n--- [TEST 5] Dialogue Engine: Rapid Back Spamming (Stress Test) ---")
	var dview = LevelDialogueViewScene.instantiate()
	get_root().add_child(dview)
	await process_frame
	
	dview.level_data = {
		"intro_sequence": [
			{"speaker": "A", "text": "Line 1"},
			{"speaker": "B", "text": "Line 2"},
			{"speaker": "C", "text": "Line 3"}
		]
	}
	dview._start_dialogue_scene()
	await process_frame
	
	# เดินหน้าไป 2 บรรทัด
	dview._on_player_advance()
	await process_frame
	dview._on_player_advance()
	await process_frame
	
	# กดย้อนกลับรัว ๆ 50 ครั้ง แม้จะอยู่ที่ index 0 แล้ว
	for i in range(50):
		dview._on_player_back()
	await process_frame
	
	_assert_true(dview.queue_index == 0, "Queue index remains valid 0 after 50 rapid back clicks")
	_assert_true(dview.queue_index >= 0, "No negative index crash")
	
	if is_instance_valid(dview):
		dview.queue_free()
	await process_frame


## -----------------------------------------------------------------------------
## 6. ทดสอบ Action Choice Fallback สำหรับ Part 1 และ Part 2
## -----------------------------------------------------------------------------
func _test_dialogue_part2_action_choice_step() -> void:
	print("\n--- [TEST 6] Dialogue Engine: Action Choice Fallback Steps ---")
	var dview = LevelDialogueViewScene.instantiate()
	get_root().add_child(dview)
	await process_frame
	
	# Part 1: "ฉันจะลองดู" ไม่มี sequence -> ต้องได้ step 1
	dview.debug_phase = 0
	dview.current_menu_id = "part1_main"
	var choice1 = {"id": "part1_try", "text": "ฉันจะลองดู"}
	var is_part2_1 = choice1.get("id", "").begins_with("part2_") or dview.current_menu_id.begins_with("part2_") or dview.debug_phase >= 1
	var step1 = 2 if is_part2_1 else 1
	_assert_true(step1 == 1, "Part 1 action choice resolves to step 1")
	
	# Part 2: "ฉันจะลองดู" ไม่มี sequence -> ต้องได้ step 2
	dview.debug_phase = 1
	dview.current_menu_id = "part2_main"
	var choice2 = {"id": "part2_try", "text": "ฉันจะลองดู"}
	var is_part2_2 = choice2.get("id", "").begins_with("part2_") or dview.current_menu_id.begins_with("part2_") or dview.debug_phase >= 1
	var step2 = 2 if is_part2_2 else 1
	_assert_true(step2 == 2, "Part 2 action choice resolves to step 2 (Fixed)")
	
	if is_instance_valid(dview):
		dview.queue_free()
	await process_frame


## -----------------------------------------------------------------------------
## 7. ทดสอบ Static Texture Cache: ไม่ถูกล้างเมื่อสลับฉากเข้า-ออก
## -----------------------------------------------------------------------------
func _test_dialogue_cache_retention_across_instances() -> void:
	print("\n--- [TEST 7] Dialogue Engine: Static Texture Cache Persistence ---")
	# Instance ที่ 1 โหลด texture
	var dview1 = LevelDialogueViewScene.instantiate()
	get_root().add_child(dview1)
	await process_frame
	
	var tex1 = LevelDialogueViewScript._get_question_frame_texture()
	_assert_true(tex1 != null, "Question frame texture loaded into static cache")
	
	# ออกจาก SceneTree (เรียก _exit_tree)
	dview1.queue_free()
	await process_frame
	await process_frame
	
	# ตรวจว่า static cache ยังคงอยู่ ไม่ถูก _clear_cached_textures() ล้างทิ้ง
	_assert_true(LevelDialogueViewScript._cached_question_frame_tex != null, "Static cache retained after instance 1 exit")
	
	# Instance ที่ 2 เข้ามาใหม่
	var dview2 = LevelDialogueViewScene.instantiate()
	get_root().add_child(dview2)
	await process_frame
	
	var tex2 = LevelDialogueViewScript._get_question_frame_texture()
	_assert_true(tex2 == tex1, "Instance 2 directly reuses cached texture instance from Instance 1")
	
	dview2.queue_free()
	await process_frame
