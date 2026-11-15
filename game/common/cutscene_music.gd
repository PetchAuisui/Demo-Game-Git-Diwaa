class_name CutsceneMusic
extends RefCounted

## ตัวจัดการเล่นเพลง Cutscene แบบต่อเนื่องข้ามฉาก (Persistent Cutscene BGM)
## เล่นเสียง gitdiwa-sound+effect.MP3 ต่อเนื่องตั้งแต่ฉากหมู่บ้าน (cut_scence_normal)
## ลอดผ่านฉากห้องสมุด (intro_cutscene) จนถึงฉากหอคอยไตเติล (outside_cutscene)
## และตัดเสียงหยุดทันทีเมื่อเปลี่ยนฉากเข้าสู่เกม

const BGM_AUDIO_PATH: String = "res://assets/audio/gitdiwa-sound+effect.MP3"
const PLAYER_NODE_NAME: String = "CutscenePersistentBGM"
const DEFAULT_TARGET_DB: float = 2.0
const DEFAULT_START_DB: float = -12.0

static var _player: AudioStreamPlayer = null
static var _fade_tween: Tween = null


## ลงทะเบียน AudioStreamPlayer ที่มีอยู่แล้ว (เช่น จากฉากหมู่บ้าน)
static func register_player(player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return
	if _player != null and is_instance_valid(_player) and _player != player:
		_player.stop()
		var tree := Engine.get_main_loop() as SceneTree
		if tree and tree.root and _player.get_parent() == tree.root:
			_player.queue_free()
	_player = player


## เริ่มเล่นเพลง Cutscene (หากเล่นอยู่แล้วจะไม่เริ่มใหม่ เล่นต่อเนื่องอย่างไร้รอยต่อ)
static func play(fade_in_duration: float = 1.0, start_db: float = DEFAULT_START_DB, target_db: float = DEFAULT_TARGET_DB) -> void:
	var player := _get_or_create_player()
	if player == null:
		return
	
	# ป้องกันกรณีที่โหนดกำลังรอเข้า SceneTree
	if not player.is_inside_tree():
		var on_enter := func():
			if _player == player and is_instance_valid(player) and not player.is_queued_for_deletion():
				CutsceneMusic.play(fade_in_duration, start_db, target_db)
		if not player.tree_entered.is_connected(on_enter):
			player.tree_entered.connect(on_enter, CONNECT_ONE_SHOT)
		return
	
	# หากเพลงกำลังเล่นอยู่แล้ว
	if player.playing:
		# หากระดับเสียงยังไม่ถึง target_db (เช่น ผู้เล่นกด skip เข้าฉากใหม่ระหว่างกำลัง fade-in) ให้เฟดเสียงต่อจนถึง target_db
		if player.volume_db < target_db - 0.5:
			if _fade_tween and _fade_tween.is_valid():
				_fade_tween.kill()
			_fade_tween = player.create_tween()
			_fade_tween.tween_property(player, "volume_db", target_db, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_fade_tween.tween_callback(func():
				_fade_tween = null
			)
		return
	
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null
	
	player.volume_db = start_db
	player.play()
	print("[CutsceneMusic] 🎵 เริ่มเล่นเสียงเพลง Cutscene ต่อเนื่องข้ามฉาก...")
	
	_fade_tween = player.create_tween()
	_fade_tween.tween_property(player, "volume_db", target_db, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_callback(func():
		_fade_tween = null
	)


## ตรวจสอบว่าเพลงกำลังเล่นอยู่หรือไม่
static func is_playing() -> bool:
	return _player != null and is_instance_valid(_player) and _player.playing


## หยุดเพลงทันที
static func stop_immediate() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null
	if _player and is_instance_valid(_player):
		_player.stop()
		_player.stream = null
		var tree := Engine.get_main_loop() as SceneTree
		if tree and tree.root and _player.get_parent() == tree.root:
			_player.queue_free()
		_player = null
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var extra_bgm = tree.root.get_node_or_null("BGM")
		if extra_bgm and is_instance_valid(extra_bgm):
			if extra_bgm is AudioStreamPlayer:
				extra_bgm.stop()
			extra_bgm.queue_free()
		var extra_persistent = tree.root.get_node_or_null(PLAYER_NODE_NAME)
		if extra_persistent and is_instance_valid(extra_persistent):
			if extra_persistent is AudioStreamPlayer:
				extra_persistent.stop()
			extra_persistent.queue_free()
	_player = null


static func _get_or_create_player() -> AudioStreamPlayer:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	
	if _player != null and is_instance_valid(_player):
		return _player
	
	var existing := tree.root.get_node_or_null(PLAYER_NODE_NAME) as AudioStreamPlayer
	if existing == null:
		existing = tree.root.get_node_or_null("BGM") as AudioStreamPlayer
	if existing != null:
		_player = existing
		return _player
	
	var player := AudioStreamPlayer.new()
	player.name = PLAYER_NODE_NAME
	
	if ResourceLoader.exists(BGM_AUDIO_PATH):
		player.stream = load(BGM_AUDIO_PATH)
	else:
		push_warning("[CutsceneMusic] ไม่พบ stream เสียง: %s" % BGM_AUDIO_PATH)
	
	player.tree_exiting.connect(func():
		if _player == player:
			_player = null
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
			_fade_tween = null
	)
	tree.root.add_child.call_deferred(player)
	_player = player
	
	return _player
