class_name Masa
extends Control
## Arka plan: meşalelerle aydınlanan taş duvarlı bir salon ve ortada
## ahşap kenarlı, yeşil çuha kaplı bir savaş masası (üstünde pusula gülü).
## İleride ComfyUI'dan gelen bir arka plan görseliyle değiştirilebilir.

const MERKEZ := Vector2(640, 320)
const YARICAP := Vector2(590, 285)
const MESALELER: Array[Vector2] = [Vector2(60, 150), Vector2(1220, 150)]
const PIRINC := Color(0.78, 0.62, 0.32)

## false ise sadece salon çizilir (harita, ödül ekranları)
var masa_ciz := true
var _zaman := 0.0


func _init(p_masa_ciz: bool = true) -> void:
	masa_ciz = p_masa_ciz
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_zaman += delta
	queue_redraw()


func _draw() -> void:
	# Taş duvar
	draw_rect(Rect2(Vector2.ZERO, size), Color("#15110d"))
	for sira in 19:
		var y := sira * 40.0
		var x := -48.0 if sira % 2 == 1 else 0.0
		while x < size.x:
			var tas := Rect2(x + 2, y + 2, 92, 36)
			var ton := 0.03 + 0.02 * sin(x * 0.37 + y * 0.11)
			draw_rect(tas, Color(1.0, 0.88, 0.7, ton))
			draw_rect(tas, Color(0, 0, 0, 0.35), false, 2.0)
			x += 96.0

	# Meşaleler
	for i in MESALELER.size():
		var m := MESALELER[i]
		var titreme := 0.85 + 0.15 * sin(_zaman * 9.0 + i * 2.0) * sin(_zaman * 5.3 + i)
		for k in 10:
			draw_circle(m, (230 - k * 20) * titreme, Color(1.0, 0.55, 0.2, 0.025))
		draw_rect(Rect2(m + Vector2(-6, 0), Vector2(12, 46)), Color("#4a2e18"))
		draw_rect(Rect2(m + Vector2(-10, -4), Vector2(20, 8)), Color("#2c2c30"))
		var alev := PackedVector2Array([
			m + Vector2(-11, -4), m + Vector2(11, -4),
			m + Vector2(4 + 3 * sin(_zaman * 11.0 + i), -26 * titreme),
			m + Vector2(-2 * sin(_zaman * 7.0), -40 * titreme),
			m + Vector2(-6, -22 * titreme)])
		draw_colored_polygon(alev, Color(1.0, 0.6, 0.15, 0.9))
		draw_circle(m + Vector2(0, -12), 6, Color(1.0, 0.9, 0.5, 0.9))

	# Üst ve alt kenarı karart
	for k in 6:
		var h := 30.0 - k * 5.0
		draw_rect(Rect2(0, 0, size.x, h), Color(0, 0, 0, 0.12))
		draw_rect(Rect2(0, size.y - h, size.x, h), Color(0, 0, 0, 0.12))

	if not masa_ciz:
		return

	# Masa: gölge, ahşap kenar, yeşil çuha
	_elips(MERKEZ + Vector2(0, 16), YARICAP + Vector2(20, 20), Color(0, 0, 0, 0.55))
	_elips(MERKEZ, YARICAP + Vector2(18, 18), Color("#6b4423"))
	_elips(MERKEZ, YARICAP + Vector2(9, 9), Color("#4a2c16"))
	_elips(MERKEZ, YARICAP, Color("#1d3826"))
	_elips(MERKEZ, YARICAP * 0.66, Color("#22422c"))

	# Pirinç halka ve pusula gülü
	var oran := YARICAP.y / YARICAP.x
	draw_set_transform(MERKEZ, 0.0, Vector2(1, oran))
	var r := YARICAP.x * 0.86
	var halka := PIRINC
	halka.a = 0.5
	draw_arc(Vector2.ZERO, r, 0, TAU, 160, halka, 3.0)
	halka.a = 0.3
	draw_arc(Vector2.ZERO, r - 30, 0, TAU, 160, halka, 2.0)
	for i in 16:
		var aci := TAU * i / 16.0
		var yon := Vector2(cos(aci), sin(aci))
		var uzun := i % 4 == 0
		halka.a = 0.45 if uzun else 0.25
		draw_line(yon * (r - 30), yon * (r + (14.0 if uzun else 0.0)), halka, 3.0 if uzun else 2.0)
	draw_set_transform(Vector2.ZERO)


func _elips(merkez: Vector2, yaricap: Vector2, renk: Color) -> void:
	var noktalar := PackedVector2Array()
	for i in 96:
		var aci := TAU * i / 96.0
		noktalar.append(merkez + Vector2(cos(aci) * yaricap.x, sin(aci) * yaricap.y))
	draw_colored_polygon(noktalar, renk)
