class_name BossGorunumu
extends Control
## Masanın ortasındaki düşman. ComfyUI görselleri gelene kadar her yaratık
## basit şekillerle koddan çizilir (golem, goblin, trol, cadı, ork, ejder).
## `gorsel` alanına bir Texture2D verilirse çizim yerine o gösterilir.

const BOYUT := Vector2(360, 240)

var yaricap := 92.0
var sekil := "ejder"
var ana_renk := Color("#7a1c14")
var goz_renk := Color("#ffd040")
var gorsel: Texture2D
## game-icons.net'ten düşman ikonu (varliklar/ikonlar/dusman_<sekil>.svg)
var ikon: Texture2D
var _zaman := 0.0
var _nabiz := 0.0
var _temel_konum := Vector2.ZERO
var _tween: Tween


func _init() -> void:
	size = BOYUT
	pivot_offset = BOYUT / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Düşman tanımındaki görünüm ayarlarını uygular
func ayarla(g: Dictionary) -> void:
	sekil = str(g.get("sekil", "ejder"))
	ana_renk = Color(str(g.get("renk", "#7a1c14")))
	goz_renk = Color(str(g.get("goz", "#ffd040")))
	yaricap = float(g.get("yaricap", 92.0))
	var yol := "res://varliklar/ikonlar/dusman_%s.svg" % sekil
	ikon = load(yol) if ResourceLoader.exists(yol) else null


func yerlestir(merkez: Vector2) -> void:
	_temel_konum = merkez - BOYUT / 2.0
	position = _temel_konum


func _process(delta: float) -> void:
	_zaman += delta
	_nabiz = 0.5 + 0.5 * sin(_zaman * 2.2)
	queue_redraw()


func _draw() -> void:
	# Arkadaki renkli hale
	for i in 8:
		var hale := goz_renk
		hale.a = 0.025 + 0.015 * _nabiz
		draw_circle(BOYUT / 2.0, yaricap + 40 - i * 6, hale)

	if gorsel:
		var r := Vector2(yaricap, yaricap) * 1.2
		draw_texture_rect(gorsel, Rect2(BOYUT / 2.0 - r, r * 2), false)
		return

	if ikon:
		var r := Vector2(yaricap, yaricap) * 1.25
		var alan := Rect2(BOYUT / 2.0 - r, r * 2)
		var zemin := ana_renk.darkened(0.55)
		zemin.a = 0.85
		draw_circle(BOYUT / 2.0, yaricap * 1.05, zemin)
		draw_arc(BOYUT / 2.0, yaricap * 1.05, 0, TAU, 64, goz_renk.darkened(0.2), 3.0)
		draw_texture_rect(ikon, Rect2(alan.position + Vector2(5, 7), alan.size), false, Color(0, 0, 0, 0.55))
		draw_texture_rect(ikon, alan, false, ana_renk.lightened(0.55))
		return

	match sekil:
		"golem": _golem()
		"goblin": _goblin_cetesi()
		"trol": _trol()
		"cadi": _cadi()
		"ork": _ork()
		_: _ejder()


# --- Çizim yardımcıları (koordinatlar 92 yarıçapa göre, merkezden) ---------

func _p(noktalar: Array) -> PackedVector2Array:
	var m := BOYUT / 2.0
	var o := yaricap / 92.0
	var sonuc := PackedVector2Array()
	for n in noktalar:
		sonuc.append(m + n * o)
	return sonuc


func _poly(noktalar: Array, renk: Color) -> void:
	draw_colored_polygon(_p(noktalar), renk)


func _ayna(noktalar: Array) -> Array:
	return noktalar.map(func(n): return Vector2(-n.x, n.y))


func _ayna_etrafinda(noktalar: Array, c: Vector2) -> Array:
	return noktalar.map(func(n): return Vector2(2 * c.x - n.x, n.y))


func _daire(merkez: Vector2, r: float, renk: Color) -> void:
	var o := yaricap / 92.0
	draw_circle(BOYUT / 2.0 + merkez * o, r * o, renk)


func _cizgi(noktalar: Array, renk: Color, kalinlik: float) -> void:
	draw_polyline(_p(noktalar), renk, kalinlik * yaricap / 92.0)


func _goz(merkez: Vector2, r: float) -> void:
	var hale := goz_renk
	hale.a = 0.35
	_daire(merkez, r * (1.7 + 0.4 * _nabiz), hale)
	_daire(merkez, r, goz_renk)
	_daire(merkez, r * 0.45, goz_renk.lightened(0.7))


# --- Yaratıklar ------------------------------------------------------------

func _golem() -> void:
	var koyu := ana_renk.darkened(0.3)
	_daire(Vector2(-72, 12), 36, koyu)
	_daire(Vector2(72, 12), 36, koyu)
	_poly([Vector2(-55, -70), Vector2(10, -85), Vector2(60, -60), Vector2(74, 10),
		Vector2(50, 78), Vector2(-45, 82), Vector2(-76, 20)], ana_renk)
	_poly([Vector2(-30, -104), Vector2(28, -108), Vector2(36, -64), Vector2(-32, -60)], ana_renk.lightened(0.08))
	_cizgi([Vector2(-32, -24), Vector2(-12, 0), Vector2(-22, 34)], koyu, 3)
	_cizgi([Vector2(24, -44), Vector2(36, -12), Vector2(28, 10)], koyu, 3)
	_cizgi([Vector2(10, 40), Vector2(30, 62)], koyu, 3)
	_goz(Vector2(-13, -86), 6)
	_goz(Vector2(13, -86), 6)
	var run := goz_renk
	run.a = 0.5 + 0.4 * _nabiz
	_poly([Vector2(0, -12), Vector2(13, 8), Vector2(0, 28), Vector2(-13, 8)], run)


func _goblin_kafasi(c: Vector2, s: float, renk: Color) -> void:
	var kulak := [c + Vector2(-26, -4) * s, c + Vector2(-72, -34) * s, c + Vector2(-24, 16) * s]
	_poly(kulak, renk.darkened(0.15))
	_poly(_ayna_etrafinda(kulak, c), renk.darkened(0.15))
	_daire(c, 34 * s, renk)
	_poly([c + Vector2(-18, 12) * s, c + Vector2(18, 12) * s, c + Vector2(0, 24) * s], Color(0.15, 0.05, 0.05))
	for dx in [-10.0, 0.0, 10.0]:
		_poly([c + Vector2(dx - 3, 12) * s, c + Vector2(dx + 3, 12) * s, c + Vector2(dx, 18) * s], Color("#f0e8d0"))
	_goz(c + Vector2(-12, -6) * s, 5 * s)
	_goz(c + Vector2(12, -6) * s, 5 * s)


func _goblin_cetesi() -> void:
	_goblin_kafasi(Vector2(-78, 18), 0.78, ana_renk.darkened(0.2))
	_goblin_kafasi(Vector2(78, 18), 0.78, ana_renk.darkened(0.2))
	_goblin_kafasi(Vector2(0, -12), 1.05, ana_renk)


func _trol() -> void:
	var koyu := ana_renk.darkened(0.25)
	_daire(Vector2(0, 40), 78, koyu)
	_daire(Vector2(-84, 46), 30, koyu.darkened(0.1))
	_daire(Vector2(84, 46), 30, koyu.darkened(0.1))
	_daire(Vector2(0, -42), 44, ana_renk)
	_poly([Vector2(-40, -62), Vector2(40, -62), Vector2(32, -48), Vector2(-32, -48)], koyu)
	_goz(Vector2(-15, -52), 6)
	_goz(Vector2(15, -52), 6)
	_daire(Vector2(0, -36), 11, ana_renk.lightened(0.12))
	_cizgi([Vector2(-22, -16), Vector2(0, -12), Vector2(22, -16)], koyu.darkened(0.3), 3)
	var dis := [Vector2(-22, -16), Vector2(-13, -16), Vector2(-18, -36)]
	_poly(dis, Color("#eee4c8"))
	_poly(_ayna(dis), Color("#eee4c8"))


func _cadi() -> void:
	_poly([Vector2(-88, 110), Vector2(-30, -10), Vector2(30, -10), Vector2(88, 110)], ana_renk.darkened(0.25))
	_cizgi([Vector2(72, 110), Vector2(98, -56)], Color("#5a3a1e"), 7)
	var kure := goz_renk
	kure.a = 0.3
	_daire(Vector2(99, -66), 26 + 6 * _nabiz, kure)
	_daire(Vector2(99, -66), 13, goz_renk)
	_daire(Vector2(0, -16), 28, Color(0.03, 0.02, 0.05))
	_poly([Vector2(-78, -40), Vector2(78, -40), Vector2(62, -27), Vector2(-62, -27)], ana_renk)
	_poly([Vector2(-40, -40), Vector2(40, -40), Vector2(20, -96), Vector2(48, -122), Vector2(4, -102)], ana_renk)
	_goz(Vector2(-10, -18), 5)
	_goz(Vector2(10, -18), 5)


func _ork() -> void:
	var metal := Color("#3c3c44")
	_daire(Vector2(-78, 44), 36, metal)
	_daire(Vector2(78, 44), 36, metal)
	_poly([Vector2(-50, -40), Vector2(50, -40), Vector2(56, 20), Vector2(30, 54),
		Vector2(-30, 54), Vector2(-56, 20)], ana_renk)
	var boynuz := [Vector2(-44, -68), Vector2(-96, -116), Vector2(-58, -52)]
	_poly(boynuz, Color("#d8c8a0"))
	_poly(_ayna(boynuz), Color("#d8c8a0"))
	_poly([Vector2(-57, -34), Vector2(-46, -76), Vector2(0, -92), Vector2(46, -76), Vector2(57, -34)], metal)
	_goz(Vector2(-19, -14), 7)
	_goz(Vector2(19, -14), 7)
	var dis := [Vector2(-26, 42), Vector2(-15, 42), Vector2(-22, 18)]
	_poly(dis, Color("#eee4c8"))
	_poly(_ayna(dis), Color("#eee4c8"))
	_cizgi([Vector2(8, -34), Vector2(30, 2)], Color("#8a2a20"), 3)


func _ejder() -> void:
	var kanat := [Vector2(-30, -20), Vector2(-172, -104), Vector2(-150, -44), Vector2(-168, 8),
		Vector2(-122, 0), Vector2(-112, 42), Vector2(-60, 30)]
	_poly(kanat, ana_renk.darkened(0.4))
	_poly(_ayna(kanat), ana_renk.darkened(0.4))
	var kemik := ana_renk.darkened(0.6)
	_cizgi([Vector2(-30, -20), Vector2(-150, -44)], kemik, 3)
	_cizgi([Vector2(-30, -20), Vector2(-122, 0)], kemik, 3)
	_cizgi([Vector2(30, -20), Vector2(150, -44)], kemik, 3)
	_cizgi([Vector2(30, -20), Vector2(122, 0)], kemik, 3)
	_poly([Vector2(-42, 116), Vector2(42, 116), Vector2(30, 20), Vector2(-30, 20)], ana_renk.darkened(0.12))
	var boynuz := [Vector2(-34, -34), Vector2(-72, -106), Vector2(-18, -44)]
	_poly(boynuz, Color("#d8c8a0"))
	_poly(_ayna(boynuz), Color("#d8c8a0"))
	_poly([Vector2(-46, -40), Vector2(46, -40), Vector2(56, 0), Vector2(36, 40), Vector2(18, 72),
		Vector2(-18, 72), Vector2(-36, 40), Vector2(-56, 0)], ana_renk)
	for dx in [-12.0, 12.0]:
		_poly([Vector2(dx - 7, -40), Vector2(dx, -60), Vector2(dx + 7, -40)], ana_renk.darkened(0.3))
	_poly([Vector2(-22, 28), Vector2(22, 28), Vector2(16, 72), Vector2(-16, 72)], ana_renk.lightened(0.1))
	_goz(Vector2(-22, -8), 8)
	_goz(Vector2(22, -8), 8)
	_daire(Vector2(-8, 62), 3, Color.BLACK)
	_daire(Vector2(8, 62), 3, Color.BLACK)
	_daire(Vector2(0, 88), 10 + 6 * _nabiz, Color(1.0, 0.55, 0.15, 0.25 + 0.25 * _nabiz))


# --- Animasyonlar ----------------------------------------------------------

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
