class_name PixelFx
extends Sprite2D
## เอฟเฟกต์ pixel art แบบเล่นครั้งเดียว (sprite sheet ที่ทำจาก pixelfx) — เล่นจบแล้วลบตัวเองทิ้ง
## ใช้: PixelFx.spawn(parent, "banish", ตำแหน่งเท้า, สเกล)
## จุด pivot ของแต่ละเอฟเฟกต์ (เช่น พื้น/เท้า) จะวางตรงตำแหน่งที่ส่งมา
##
## ไฟล์ภาพอยู่ที่ res://assets/fx/<name>.png — ทำใหม่ได้ด้วย pixelfx:
##   node tools/render.mjs <category>/<effect> --sheet [--opts '{"palette": [...]}']
## แล้วคัดลอกค่า frameSize/columns/frames/fps/pivot จาก meta.pixelfx ใน JSON มาใส่ EFFECTS

const DIR := "res://assets/fx/%s.png"
## ที่มาของแต่ละไฟล์ (pixelfx id): banish = arcane/magic-circle-cast (สีทอง) · boss_hit = arcane/mana-burst
## boss_down = shadow/dark-explosion · imp_spawn = spawn/spawn-portal · chaos_wave = explosions/plasma-explosion
## shield = impacts/shield-block · damage = impacts/blunt-hit · gate_open = explosions/firework-burst
## commit_sparkle = pickups/collect-burst · stage_sparkle = pickups/collect-burst (สีฟ้า) · confetti = ui/confetti
## imp_poof = spawn/poof (สีม่วง) · imp_idle = critters/slime (สีเงามืด, hop 10) · spell_bolt = projectiles/plasma-shot (สีทอง)
## vel_circle = arcane/rune-circle (สีทอง)
## boss_idle = critters/door-golem (วาดใหม่สำหรับเกมนี้: ประตูหินมีชีวิต — ต้นฉบับอยู่ที่ tools/pixelfx/door-golem.js)
const EFFECTS := {
	"banish": {"size": Vector2i(200, 220), "columns": 12, "frames": 118, "fps": 30, "pivot": Vector2(100, 192)},
	"boss_down": {"size": Vector2i(280, 248), "columns": 11, "frames": 115, "fps": 30, "pivot": Vector2(140, 206)},
	"boss_hit": {"size": Vector2i(208, 150), "columns": 7, "frames": 55, "fps": 30, "pivot": Vector2(104, 124)},
	"chaos_wave": {"size": Vector2i(224, 200), "columns": 7, "frames": 52, "fps": 30, "pivot": Vector2(112, 100)},
	"commit_sparkle": {"size": Vector2i(112, 108), "columns": 7, "frames": 42, "fps": 30, "pivot": Vector2(56, 94)},
	"confetti": {"size": Vector2i(200, 140), "columns": 9, "frames": 103, "fps": 30, "pivot": Vector2(100, 126)},
	"damage": {"size": Vector2i(128, 88), "columns": 5, "frames": 28, "fps": 30, "pivot": Vector2(64, 72)},
	"gate_open": {"size": Vector2i(240, 248), "columns": 11, "frames": 109, "fps": 30, "pivot": Vector2(120, 100)},
	"imp_spawn": {"size": Vector2i(208, 150), "columns": 10, "frames": 115, "fps": 30, "pivot": Vector2(104, 122)},
	"shield": {"size": Vector2i(148, 104), "columns": 5, "frames": 34, "fps": 30, "pivot": Vector2(40, 88)},
	"stage_sparkle": {"size": Vector2i(112, 108), "columns": 7, "frames": 42, "fps": 30, "pivot": Vector2(56, 94)},
	"imp_poof": {"size": Vector2i(112, 92), "columns": 7, "frames": 49, "fps": 30, "pivot": Vector2(56, 80)},
	# ตัวละครวนลูป (loop = true เล่นซ้ำไม่จบ ต้อง queue_free เอง)
	"boss_idle": {"size": Vector2i(136, 120), "columns": 8, "frames": 72, "fps": 30, "pivot": Vector2(68, 112), "loop": true},
	"imp_idle": {"size": Vector2i(112, 88), "columns": 7, "frames": 54, "fps": 30, "pivot": Vector2(56, 72), "loop": true},
	"vel_circle": {"size": Vector2i(136, 100), "columns": 10, "frames": 120, "fps": 30, "pivot": Vector2(68, 80), "loop": true},
	"spell_bolt": {"size": Vector2i(144, 60), "columns": 4, "frames": 24, "fps": 30, "pivot": Vector2(108, 30), "loop": true},
}

static var _textures: Dictionary = {}

var _fps := 30.0
var _count := 1
var _time := 0.0
var _first := 0
var _loop := false


## สร้างเอฟเฟกต์ใต้ parent ที่ตำแหน่ง at (พิกัด local ของ parent) — คืน null ถ้าไม่มีไฟล์ภาพ
## start_seconds: ข้ามช่วงต้นของเอฟเฟกต์ (เช่น วงเวทที่ใช้เวลาวาดนาน ให้เข้าจังหวะทันที)
static func spawn(parent: Node, effect: String, at: Vector2, scale_by: float = 2.0,
		start_seconds: float = 0.0, flip: bool = false) -> PixelFx:
	var spec: Dictionary = EFFECTS.get(effect, {})
	var texture := _texture(effect)
	if spec.is_empty() or texture == null or parent == null:
		return null
	var fx := PixelFx.new()
	fx.texture = texture
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.centered = false
	fx.hframes = int(spec["columns"])
	fx.vframes = int(ceil(float(spec["frames"]) / float(spec["columns"])))
	fx._count = int(spec["frames"])
	fx._fps = float(spec["fps"])
	fx._loop = bool(spec.get("loop", false))
	fx._first = clampi(int(start_seconds * fx._fps), 0, fx._count - 1)
	fx.frame = fx._first
	var pivot: Vector2 = spec["pivot"]
	fx.offset = -pivot
	fx.flip_h = flip
	if flip:
		fx.offset.x = pivot.x - float((spec["size"] as Vector2i).x)
	fx.scale = Vector2.ONE * scale_by
	fx.position = at
	fx.z_index = 5
	parent.add_child(fx)
	return fx


static func _texture(effect: String) -> Texture2D:
	if _textures.has(effect):
		return _textures[effect]
	var path := DIR % effect
	var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_textures[effect] = texture
	return texture


## หยุดภาพทั้งเกมชั่วครู่ตอนโดนตี (hit-stop) ให้รู้สึกหนัก — ใช้เวลาจริง ไม่ขึ้นกับ time_scale
static func hit_stop(tree: SceneTree, seconds: float = 0.08, slow: float = 0.05) -> void:
	if tree == null:
		return
	Engine.time_scale = slow
	tree.create_timer(seconds, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)


func _process(delta: float) -> void:
	_time += delta
	var index := _first + int(_time * _fps)
	if _loop:
		index %= _count
	elif index >= _count:
		queue_free()
		return
	frame = index
