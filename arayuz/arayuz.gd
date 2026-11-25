class_name Arayuz
extends RefCounted
## Ekranlarda ortak kullanılan küçük yardımcılar.

const ALTIN := Color("#e8c27a")


static func etiket(ebeveyn: Node, boyut: int, metin: String = "", renk: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = metin
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", boyut)
	l.add_theme_color_override("font_color", renk)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ebeveyn.add_child(l)
	return l


static func kutu_stili(zemin: Color, kenar: Color, kalinlik: int = 2, yaricap: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = zemin
	s.border_color = kenar
	s.set_border_width_all(kalinlik)
	s.set_corner_radius_all(yaricap)
	s.set_content_margin_all(10)
	return s


static func buton(metin: String, boyut: Vector2, renk: Color = Color("#5c4720"), kenar: Color = ALTIN, font: int = 20) -> Button:
	var b := Button.new()
	b.text = metin
	b.custom_minimum_size = boyut
	b.size = boyut
	b.add_theme_font_size_override("font_size", font)
	b.add_theme_stylebox_override("normal", kutu_stili(renk, kenar))
	b.add_theme_stylebox_override("hover", kutu_stili(renk.lightened(0.2), kenar.lightened(0.3)))
	b.add_theme_stylebox_override("pressed", kutu_stili(renk.darkened(0.3), kenar))
	b.add_theme_stylebox_override("disabled", kutu_stili(renk.darkened(0.5), kenar.darkened(0.5)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


## Başlık + açıklama içeren büyük seçim butonu
static func secenek_butonu(baslik: String, aciklama: String, renk: Color, boyut: Vector2, ikon: Texture2D = null) -> Button:
	var b := buton("", boyut, renk.darkened(0.65), renk)
	var ic := VBoxContainer.new()
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.alignment = BoxContainer.ALIGNMENT_CENTER
	ic.add_theme_constant_override("separation", 10)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)
	if ikon:
		var t := TextureRect.new()
		t.texture = ikon
		t.custom_minimum_size = Vector2(0, 64)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.self_modulate = renk.lightened(0.45)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.add_child(t)
	etiket(ic, 24, baslik, renk.lightened(0.4))
	var ac := etiket(ic, 15, aciklama, Color("#e0d8f0"))
	ac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ac.custom_minimum_size = Vector2(boyut.x - 30, 0)
	return b
