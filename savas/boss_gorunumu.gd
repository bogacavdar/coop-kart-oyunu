class_name BossGorunumu
extends Control
## Masanın ortasındaki boss: halkalı, nabız gibi parlayan karanlık bir gezegen.
## ComfyUI görseli hazır olunca `gorsel` alanına verilirse gezegenin yerine o çizilir.

const BOYUT := Vector2(360, 240)

var yaricap := 92.0
var gorsel: Texture2D
var _zaman := 0.0
var _temel_konum := Vector2.ZERO
var _tween: Tween


func _init() -> void:
	size = BOYUT
	pivot_offset = BOYUT / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func yerlestir(merkez: Vector2) -> void:
	_temel_konum = merkez - BOYUT / 2.0
	position = _temel_konum


func _process(delta: float) -> void:
	_zaman += delta
	queue_redraw()


func _draw() -> void:
	var m := BOYUT / 2.0
	var nabiz := 0.5 + 0.5 * sin(_zaman * 2.2)

	# Dış parıltı
	for i in 8:
		draw_circle(m, yaricap + 46 - i * 6, Color(0.75, 0.25, 0.5, 0.035 + 0.02 * nabiz))

	# Halkanın arka yarısı (gezegenin arkasında kalır)
	_halka(m, PI, TAU)

	if gorsel:
		draw_texture_rect(gorsel, Rect2(m - Vector2(yaricap, yaricap), Vector2(yaricap, yaricap) * 2), false)
	else:
		draw_circle(m, yaricap, Color("#2e1533"))
		draw_circle(m + Vector2(-14, -18), yaricap * 0.8, Color("#3f1d45"))
		draw_circle(m + Vector2(-28, -34), yaricap * 0.5, Color("#52275a"))
		draw_circle(m + Vector2(-38, -46), yaricap * 0.2, Color("#6a3672"))
		# Gözler
		for dx in [-30.0, 30.0]:
			var g := m + Vector2(dx, 4)
			draw_circle(g, 13 + 3 * nabiz, Color(1, 0.45, 0.15, 0.35))
			draw_circle(g, 8, Color(1, 0.6, 0.2))
			draw_circle(g, 3.5, Color(1, 0.95, 0.75))

	# Halkanın ön yarısı
	_halka(m, 0, PI)


func _halka(m: Vector2, bas: float, son: float) -> void:
	draw_set_transform(m, -0.22, Vector2(1, 0.27))
	draw_arc(Vector2.ZERO, yaricap * 1.75, bas, son, 64, Color("#c9a24a"), 16.0)
	draw_arc(Vector2.ZERO, yaricap * 1.5, bas, son, 64, Color("#8a6d2e"), 10.0)
	draw_arc(Vector2.ZERO, yaricap * 1.95, bas, son, 64, Color(0.79, 0.64, 0.29, 0.4), 6.0)
	draw_set_transform(Vector2.ZERO)


## Hasar alınca sarsılır ve kızarır
func vur() -> void:
	if _tween:
		_tween.kill()
	position = _temel_konum
	modulate = Color(2.0, 1.1, 1.1)
	_tween = create_tween()
	for i in 4:
		_tween.tween_property(self, "position", _temel_konum + Vector2(randf_range(-9, 9), randf_range(-5, 5)), 0.04)
	_tween.tween_property(self, "position", _temel_konum, 0.04)
	_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.2)


## Saldırırken büyüyüp geri döner
func saldir() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * 1.15, 0.15).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2.ONE, 0.2)
