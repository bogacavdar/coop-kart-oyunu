class_name Koltuk
extends Control
## Masadaki bir oyuncunun yeri: yuvarlak portre, isim, can barı, değerler ve plan.
## Senin koltuğun yatay (elinin üstünde), diğerleri dikey.

signal tiklandi(no: int)

const PORTRE := 76.0

var no: int
var renk: Color
var yatay: bool
var _portre: Panel
var _portre_stil: StyleBoxFlat
var _harf: Label
var _ikon: TextureRect
var _ad: Label
var _bar: ProgressBar
var _deger: Label
var _plan: Label
var _mana_metni := ""
var _nabiz: Tween
var _hedef_rozeti: Label


func _init(p_no: int, p_renk: Color, p_yatay: bool) -> void:
	no = p_no
	renk = p_renk
	yatay = p_yatay
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(340, 82) if yatay else Vector2(230, 180)

	_portre = Panel.new()
	_portre.size = Vector2(PORTRE, PORTRE)
	_portre.position = Vector2(0, 3) if yatay else Vector2((size.x - PORTRE) / 2.0, 0)
	_portre.pivot_offset = _portre.size / 2.0
	_portre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portre_stil = StyleBoxFlat.new()
	_portre_stil.bg_color = renk.darkened(0.55)
	_portre_stil.set_corner_radius_all(int(PORTRE / 2))
	_portre_stil.set_border_width_all(4)
	_portre_stil.border_color = renk
	_portre_stil.shadow_color = Color(0, 0, 0, 0.5)
	_portre_stil.shadow_size = 8
	_portre.add_theme_stylebox_override("panel", _portre_stil)
	add_child(_portre)

	_harf = Label.new()
	_harf.set_anchors_preset(Control.PRESET_FULL_RECT)
	_harf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_harf.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_harf.add_theme_font_size_override("font_size", 34)
	_harf.add_theme_color_override("font_color", renk.lightened(0.4))
	_harf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portre.add_child(_harf)

	_ikon = TextureRect.new()
	_ikon.position = Vector2(13, 13)
	_ikon.size = Vector2(PORTRE - 26, PORTRE - 26)
	_ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ikon.self_modulate = renk.lightened(0.45)
	_ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portre.add_child(_ikon)

	var x0 := PORTRE + 12.0 if yatay else 0.0
	var y0 := 2.0 if yatay else PORTRE + 4.0
	var gen := size.x - x0
	var hiza: int = HORIZONTAL_ALIGNMENT_LEFT if yatay else HORIZONTAL_ALIGNMENT_CENTER

	_ad = _etiket(Rect2(x0, y0, gen, 24), 17, hiza)
	_ad.add_theme_color_override("font_color", renk.lightened(0.3))

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.position = Vector2(x0 + (0.0 if yatay else 30.0), y0 + 27)
	_bar.size = Vector2(gen - (20.0 if yatay else 60.0), 12)
	var dolgu := StyleBoxFlat.new()
	dolgu.bg_color = Color("#3fae6a")
	dolgu.set_corner_radius_all(4)
	var zemin := StyleBoxFlat.new()
	zemin.bg_color = Color(0, 0, 0, 0.55)
	zemin.set_corner_radius_all(4)
	_bar.add_theme_stylebox_override("fill", dolgu)
	_bar.add_theme_stylebox_override("background", zemin)
	add_child(_bar)

	_deger = _etiket(Rect2(x0, y0 + 41, gen, 18), 13, hiza)
	_hedef_rozeti = Label.new()
	_hedef_rozeti.text = "HEDEF"
	_hedef_rozeti.add_theme_font_size_override("font_size", 13)
	_hedef_rozeti.add_theme_color_override("font_color", Color("#0b0915"))
	var rozet_stil := StyleBoxFlat.new()
	rozet_stil.bg_color = Color("#7dffa0")
	rozet_stil.set_corner_radius_all(6)
	rozet_stil.set_content_margin_all(3)
	_hedef_rozeti.add_theme_stylebox_override("normal", rozet_stil)
	_hedef_rozeti.position = _portre.position + Vector2(PORTRE / 2.0 - 24, -16)
	_hedef_rozeti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hedef_rozeti.visible = false
	add_child(_hedef_rozeti)

	_plan = _etiket(Rect2(x0, y0 + 60, gen, 38), 12, hiza)
	_plan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_plan.add_theme_color_override("font_color", Color("#d8d0f0"))


func _etiket(alan: Rect2, boyut: int, hiza: int) -> Label:
	var l := Label.new()
	l.position = alan.position
	l.size = alan.size
	l.horizontal_alignment = hiza
	l.add_theme_font_size_override("font_size", boyut)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


## Koltuğu, portresinin ortası verilen noktaya gelecek şekilde yerleştirir
func merkeze_yerlestir(merkez: Vector2) -> void:
	position = merkez - (_portre.position + _portre.size / 2.0)


func portre_merkezi() -> Vector2:
	return position + _portre.position + _portre.size / 2.0


func guncelle(o: Oyuncu, sen: bool, hedef_modu: bool, plan: String) -> void:
	if _ikon.texture == null:
		var yol := "res://varliklar/ikonlar/sinif_%d.svg" % o.sinif
		if ResourceLoader.exists(yol):
			_ikon.texture = load(yol)
	_harf.text = "" if _ikon.texture else o.ad.substr(0, 1)
	_ad.text = o.ad + (" (Sen)" if sen else " (Bot)")
	_mana_metni = "Mana %d/%d" % [o.kalan_mana(), o.mana]
	degerleri_goster(o.can, o.max_can, o.zirh)
	if o.hayatta():
		modulate = Color.WHITE
		_plan.text = plan
	else:
		modulate = Color(1, 1, 1, 0.35)
		_plan.text = "Düştü"

	_nabiz_ayarla(hedef_modu and o.hayatta())
	if hedef_modu and o.hayatta():
		_portre_stil.border_color = Color("#7dffa0")
		_portre_stil.set_border_width_all(6)
	elif sen:
		_portre_stil.border_color = Color.GOLD
		_portre_stil.set_border_width_all(5)
	else:
		_portre_stil.border_color = renk
		_portre_stil.set_border_width_all(4)


func _nabiz_ayarla(acik: bool) -> void:
	_hedef_rozeti.visible = acik
	if acik:
		if _nabiz and _nabiz.is_valid():
			return
		_nabiz = _portre.create_tween().set_loops()
		_nabiz.tween_property(_portre, "scale", Vector2.ONE * 1.12, 0.35)
		_nabiz.tween_property(_portre, "scale", Vector2.ONE, 0.35)
	else:
		if _nabiz:
			_nabiz.kill()
			_nabiz = null
		_portre.scale = Vector2.ONE


func degerleri_goster(can: int, max_can: int, zirh: int) -> void:
	_bar.max_value = max_can
	_bar.value = can
	var parcalar: PackedStringArray = ["Can %d/%d" % [can, max_can]]
	if zirh > 0:
		parcalar.append("Zırh %d" % zirh)
	parcalar.append(_mana_metni)
	_deger.text = " · ".join(parcalar)


func dus() -> void:
	modulate = Color(1, 1, 1, 0.35)
	_plan.text = "Düştü"


func parlat() -> void:
	_portre.modulate = Color(2.2, 1.4, 1.4)
	var tw := _portre.create_tween()
	tw.tween_property(_portre, "scale", Vector2.ONE * 1.15, 0.08)
	tw.tween_property(_portre, "scale", Vector2.ONE, 0.12)
	tw.parallel().tween_property(_portre, "modulate", Color.WHITE, 0.25)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tiklandi.emit(no)
