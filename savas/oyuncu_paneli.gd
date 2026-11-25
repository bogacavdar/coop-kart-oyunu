class_name OyuncuPaneli
extends PanelContainer
## Ekranın altındaki oyuncu kutusu: isim, can barı, zırh, mana, seçilen kart.

signal tiklandi(no: int)

var no: int
var renk: Color
var _stil: StyleBoxFlat
var _ad: Label
var _bar: ProgressBar
var _can: Label
var _zirh: Label
var _mana: Label
var _secim: Label


func _init(p_no: int, p_renk: Color) -> void:
	no = p_no
	renk = p_renk
	custom_minimum_size = Vector2(0, 112)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP

	_stil = StyleBoxFlat.new()
	_stil.bg_color = Color("#1e1b2e")
	_stil.set_corner_radius_all(10)
	_stil.set_border_width_all(3)
	_stil.border_color = renk.darkened(0.3)
	_stil.set_content_margin_all(10)
	add_theme_stylebox_override("panel", _stil)

	var dikey := VBoxContainer.new()
	dikey.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dikey)

	_ad = _etiket(dikey, 17)
	_ad.add_theme_color_override("font_color", renk.lightened(0.3))

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 14)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dolgu := StyleBoxFlat.new()
	dolgu.bg_color = Color("#3fae6a")
	dolgu.set_corner_radius_all(4)
	var zemin := StyleBoxFlat.new()
	zemin.bg_color = Color("#2a2a35")
	zemin.set_corner_radius_all(4)
	_bar.add_theme_stylebox_override("fill", dolgu)
	_bar.add_theme_stylebox_override("background", zemin)
	dikey.add_child(_bar)

	var satir := HBoxContainer.new()
	satir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	satir.add_theme_constant_override("separation", 14)
	dikey.add_child(satir)
	_can = _etiket(satir, 14)
	_zirh = _etiket(satir, 14)
	_zirh.add_theme_color_override("font_color", Color("#6fa8ff"))
	_mana = _etiket(satir, 14)
	_mana.add_theme_color_override("font_color", Color("#8fc1ff"))

	_secim = _etiket(dikey, 13)
	_secim.modulate = Color(1, 1, 1, 0.8)


func _etiket(ebeveyn: Control, boyut: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", boyut)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ebeveyn.add_child(l)
	return l


func guncelle(o: Oyuncu, aktif: bool, hedef_modu: bool, secim_metni: String) -> void:
	_ad.text = ("» " if aktif else "") + o.ad
	degerleri_goster(o.can, o.max_can, o.zirh)
	_mana.text = "Mana %d" % o.mana
	if o.hayatta():
		modulate = Color.WHITE
		_secim.text = secim_metni
	else:
		modulate = Color(1, 1, 1, 0.4)
		_secim.text = "Düştü"

	if aktif:
		_stil.border_color = Color.GOLD
	elif hedef_modu and o.hayatta():
		_stil.border_color = Color("#7dffa0")
	else:
		_stil.border_color = renk.darkened(0.3)


func degerleri_goster(can: int, max_can: int, zirh: int) -> void:
	_bar.max_value = max_can
	_bar.value = can
	_can.text = "Can %d/%d" % [can, max_can]
	_zirh.text = "Zırh %d" % zirh if zirh > 0 else ""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tiklandi.emit(no)
