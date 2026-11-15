class_name CutsceneMusic
extends RefCounted

## ตัวจัดการเล่นเพลง Cutscene แบบต่อเนื่องข้ามฉาก (Persistent Cutscene BGM)
## เล่นเสียง gitdiwa-sound+effect.MP3 ต่อเนื่องตั้งแต่ฉากหมู่บ้าน (cut_scence_normal)
## ลอดผ่านฉากห้องสมุด (intro_cutscene) จนถึงฉากหอคอยไตเติล (outside_cutscene)
## และค่อย ๆ เฟดเสียงออกตอนท้าย

const BGM_AUDIO_PATH: String = "res://assets/audio/gitdiwa-sound+effect.MP3"
const PLAYER_NODE_NAME: String = "CutscenePersistentBGM"
const DEFAULT_TARGET_DB: float = 2.0
const DEFAULT_START_DB: float = -12.0

static var _player: AudioStreamPlayer = null
static var _fade_tween: Tween = null
static var _is_fading_out: bool = false


## ลงทะเบียน AudioStreamPlayer ที่มีอยู่แล้ว (เช่น จากฉากหมู่บ้าน)
static func register_player(player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return
	_player = player
	_is_fading_out = false


## เริ่มเล่นเพลง Cutscene (หากเล่นอยู่แล้วจะไม่เริ่มใหม่ เล่นต่อเนื่องอย่างไร้รอยต่อ)
static func play(fade_in_duration: float = 1.0, start_db: float = DEFAULT_START_DB, target_db: float = DEFAULT_TARGET_DB) -> void:
	var player := _get_or_create_player()
	if player == null:
		return
	
	# ป้องกันกรณีที่โหนดกำลังรอเข้า SceneTree
	if not player.is_inside_tree():
		var callable := Callable(CutsceneMusic, "play").bind(fade_in_duration, start_db, target_db)
		if not player.tree_entered.is_connected(callable):
			player.tree_entered.connect(callable, CONNECT_ONE_SHOT)
		return
	
	# หากเพลงกำลังเล่นอยู่และไม่ได้กำลังเฟดออก ให้เล่นต่อเนื่อง ไม่เริ่มใหม่
	if player.playing and not _is_fading_out:
		return
	
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null
	
	_is_fading_out = false
	
	if not player.playing:
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
	var player := _get_or_create_player()
	return player != null and is_instance_valid(player) and player.playing


## ค่อย ๆ เฟดเสียงออกตอนท้าย (Fade-out)
static func fade_out(duration: float = 1.0, min_db: float = -40.0) -> void:
	var player := _get_or_create_player()
	if player == null or not is_instance_valid(player) or not player.playing:
		_is_fading_out = false
		return
	if _is_fading_out:
		return
	
	_is_fading_out = true
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null
	
	_fade_tween = player.create_tween()
	_fade_tween.tween_property(player, "volume_db", min_db, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_fade_tween.tween_callback(func():
		if player and is_instance_valid(player):
			if player.playing:
				player.stop()
			player.stream = null
			var tree := Engine.get_main_loop() as SceneTree
			if tree and tree.root and player.get_parent() == tree.root:
				player.queue_free()
		_player = null
		_fade_tween = null
		_is_fading_out = false
		print("[CutsceneMusic] 🎵 เพลง Cutscene เฟดจบเรียบร้อย")
	)


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
	_is_fading_out = false


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
