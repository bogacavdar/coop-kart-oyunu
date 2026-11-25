class_name Masa
extends Control
## Arka plan: yıldızlı gökyüzü ve ortada altın kenarlı, burç çemberli oval masa.
## İleride ComfyUI'dan gelen bir masa görseliyle değiştirilebilir.

const MERKEZ := Vector2(640, 320)
const YARICAP := Vector2(590, 285)

var _yildizlar: Array[Vector3] = []  # x, y, boyut
## false ise sadece yıldızlı gökyüzü çizilir (harita, ödül ekranları)
var masa_ciz := true


func _init(p_masa_ciz: bool = true) -> void:
	masa_ciz = p_masa_ciz
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 160:
		_yildizlar.append(Vector3(rng.randf() * 1280, rng.randf() * 720, rng.randf_range(0.5, 1.8)))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0b0915"))
	for y in _yildizlar:
		draw_circle(Vector2(y.x, y.y), y.z, Color(1, 1, 1, 0.15 + y.z * 0.2))

	if not masa_ciz:
		return
	# Masa: gölge, altın kenar, kadife yüzey, iç halka
	_elips(MERKEZ + Vector2(0, 14), YARICAP + Vector2(18, 18), Color(0, 0, 0, 0.5))
	_elips(MERKEZ, YARICAP + Vector2(16, 16), Color("#b08d3c"))
	_elips(MERKEZ, YARICAP + Vector2(6, 6), Color("#5c4720"))
	_elips(MERKEZ, YARICAP, Color("#251c3f"))
	_elips(MERKEZ, YARICAP * 0.66, Color("#2d2250"))

	# Burç çemberi ve 12 bölme çizgisi
	var oran := YARICAP.y / YARICAP.x
	draw_set_transform(MERKEZ, 0.0, Vector2(1, oran))
	var r := YARICAP.x * 0.86
	draw_arc(Vector2.ZERO, r, 0, TAU, 160, Color(0.69, 0.55, 0.24, 0.45), 3.0)
	draw_arc(Vector2.ZERO, r - 34, 0, TAU, 160, Color(0.69, 0.55, 0.24, 0.3), 2.0)
	for i in 12:
		var aci := TAU * i / 12.0
		var yon := Vector2(cos(aci), sin(aci))
		draw_line(yon * (r - 34), yon * r, Color(0.69, 0.55, 0.24, 0.45), 2.0)
		draw_circle(yon * (r - 17), 4.0, Color(0.85, 0.7, 0.35, 0.5))
	draw_set_transform(Vector2.ZERO)


func _elips(merkez: Vector2, yaricap: Vector2, renk: Color) -> void:
	var noktalar := PackedVector2Array()
	for i in 96:
		var aci := TAU * i / 96.0
		noktalar.append(merkez + Vector2(cos(aci) * yaricap.x, sin(aci) * yaricap.y))
	draw_colored_polygon(noktalar, renk)
