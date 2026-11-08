extends Control

## StartDustParticles: ละอองเวทมนตร์ลอยระยิบระยับในพื้นที่สีดำรอบหน้าต่างหลัก
## นุ่มนวล ไม่สว่างมาก ไม่ลอยเข้าไปบดบังหน้าต่างหรือแถบเมนู

class DustParticle:
	var pos: Vector2 = Vector2.ZERO
	var vy: float = -12.0
	var sway_speed: float = 1.0
	var sway_amp: float = 0.5
	var sway_offset: float = 0.0
	var size: float = 2.0
	var base_alpha: float = 0.2
	var pulse_speed: float = 1.5
	var pulse_offset: float = 0.0
	var color: Color = Color.WHITE
	var time: float = 0.0

@export var particle_count: int = 45
@export var window_anchor_path: NodePath = ^"../WindowAnchor"

var _particles: Array[DustParticle] = []
var _window_anchor: Control = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node(window_anchor_path):
		_window_anchor = get_node(window_anchor_path) as Control
	_init_particles()
	queue_redraw()

func _init_particles() -> void:
	if _particles.is_empty():
		for i in range(particle_count):
			_particles.append(_spawn_particle(true))

func _get_window_rect() -> Rect2:
	if _window_anchor and _window_anchor.is_inside_tree():
		return _window_anchor.get_rect()
	var w: float = size.x
	var h: float = size.y
	var ww: float = 1688.0
	var wh: float = 840.0
	return Rect2((w - ww) * 0.5, (h - wh) * 0.5, ww, wh)

func _spawn_particle(randomize_initial_y: bool = false) -> DustParticle:
	var w: float = size.x if size.x > 0.0 else 1920.0
	var h: float = size.y if size.y > 0.0 else 1080.0
	var win_rect: Rect2 = _get_window_rect()
	var top_y: float = 48.0
	var bot_y: float = max(top_y, h - 36.0)
	
	var zone: int = randi() % 4
	var p_pos: Vector2 = Vector2.ZERO
	
	match zone:
		0: # Left black margin
			var max_x: float = max(0.0, win_rect.position.x - 2.0)
			p_pos.x = randf_range(0.0, max_x) if max_x > 0.0 else 0.0
			p_pos.y = randf_range(top_y, bot_y)
		1: # Right black margin
			var min_x: float = min(w, win_rect.end.x + 2.0)
			p_pos.x = randf_range(min_x, w) if min_x < w else w
			p_pos.y = randf_range(top_y, bot_y)
		2: # Top black margin
			p_pos.x = randf_range(0.0, w)
			var max_y: float = max(top_y, win_rect.position.y - 2.0)
			p_pos.y = randf_range(top_y, max_y) if max_y > top_y else top_y
		3: # Bottom black margin
			p_pos.x = randf_range(0.0, w)
			var min_y: float = min(bot_y, win_rect.end.y + 2.0)
			p_pos.y = randf_range(min_y, bot_y) if min_y < bot_y else bot_y
	
	if not randomize_initial_y:
		if zone == 0 or zone == 1:
			p_pos.y = randf_range(bot_y - 80.0, bot_y)
		elif zone == 3:
			p_pos.y = randf_range(min(bot_y, win_rect.end.y), bot_y)
	
	var palette: Array[Color] = [
		Color(0.96, 0.72, 0.35),
		Color(0.85, 0.75, 0.50),
		Color(0.68, 0.78, 0.95),
		Color(0.80, 0.70, 0.92),
		Color(0.92, 0.88, 0.80)
	]
	
	var p: DustParticle = DustParticle.new()
	p.pos = p_pos
	p.vy = randf_range(-8.0, -20.0)
	p.sway_speed = randf_range(0.8, 1.8)
	p.sway_amp = randf_range(0.3, 0.8)
	p.sway_offset = randf_range(0.0, TAU)
	p.size = randf_range(1.5, 3.0)
	p.base_alpha = randf_range(0.12, 0.28) # ไม่สว่างมาก สบายตา
	p.pulse_speed = randf_range(1.2, 2.5)
	p.pulse_offset = randf_range(0.0, TAU)
	p.color = palette[randi() % palette.size()]
	p.time = randf_range(0.0, 100.0)
	return p

func _process(delta: float) -> void:
	var w: float = size.x if size.x > 0.0 else 1920.0
	var h: float = size.y if size.y > 0.0 else 1080.0
	var win_rect: Rect2 = _get_window_rect()
	var top_y: float = 48.0
	var bot_y: float = max(top_y, h - 36.0)
	
	for i in range(_particles.size()):
		var p: DustParticle = _particles[i]
		p.time += delta
		p.pos.y += p.vy * delta
		p.pos.x += sin(p.time * p.sway_speed + p.sway_offset) * p.sway_amp
		
		var px: float = p.pos.x
		var py: float = p.pos.y
		if py < top_y or px < -10.0 or px > w + 10.0 or win_rect.has_point(Vector2(px, py)):
			_particles[i] = _spawn_particle(false)
	
	queue_redraw()

func _draw() -> void:
	if _particles.is_empty():
		_init_particles()
	var win_rect: Rect2 = _get_window_rect()
	var top_y: float = 48.0
	var bot_y: float = size.y - 36.0 if size.y > 0.0 else 1044.0
	
	for p in _particles:
		var pos: Vector2 = p.pos
		if pos.y < top_y or pos.y > bot_y:
			continue
		if win_rect.has_point(pos):
			continue
		
		var pulse: float = (sin(p.time * p.pulse_speed + p.pulse_offset) + 1.0) * 0.5
		var alpha: float = p.base_alpha * (0.6 + 0.4 * pulse)
		var col: Color = p.color
		col.a = alpha
		
		var sz: float = p.size
		if sz <= 2.0:
			draw_rect(Rect2(pos.x, pos.y, sz, sz), col)
		else:
			var halo_col: Color = col
			halo_col.a = alpha * 0.35
			draw_rect(Rect2(pos.x - 1.0, pos.y - 1.0, sz + 2.0, sz + 2.0), halo_col)
			draw_rect(Rect2(pos.x, pos.y, sz, sz), col)
