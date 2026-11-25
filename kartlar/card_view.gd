class_name CardView
extends Control
## Kartın görünümü. Sahne dosyası gerektirmez, arayüzünü koddan kurar.
## Kullanım:
##   var kart := CardView.new()
##   kart.setup(load("res://kartlar/veriler/kalkan_duvari.tres"))
##   add_child(kart)

signal card_clicked(card: CardView)

const CARD_SIZE := Vector2(200, 300)
const HOVER_SCALE := 1.08

## Her sınıfın çerçeve rengi
const SINIF_RENKLERI := {
	CardData.Sinif.TANK: Color("#4a7bd1"),
	CardData.Sinif.DESTEK: Color("#3fae6a"),
	CardData.Sinif.HASARCI: Color("#d1494a"),
	CardData.Sinif.KONTROLCU: Color("#9a5bd1"),
}

var data: CardData
var secili := false

## Elde yerleşim için: hover'da kart bu değerlere göre büyür/kalkar
var temel_olcek := 1.0
var temel_konum := Vector2.ZERO
var temel_rotasyon := 0.0
var temel_z := 0
## 0'dan büyükse hover'da kart bu kadar piksel yukarı kalkar ve tam boyuta gelir
var yukselme := 0.0

var _frame_style: StyleBoxFlat
var _art: TextureRect
var _name_label: Label
var _type_label: Label
var _desc_label: Label
var _mana_label: Label
var _tween: Tween


func _init() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	resized.connect(func(): pivot_offset = size / 2.0)


func setup(card_data: CardData) -> void:
	data = card_data
	_refresh()


## Kartın görsel ortası `merkez` noktasına gelecek şekilde yerleştirir.
func yerlestir(merkez: Vector2, olcek: float, rotasyon: float = 0.0, p_yukselme: float = 0.0) -> void:
	temel_olcek = olcek
	temel_rotasyon = rotasyon
	yukselme = p_yukselme
	temel_konum = merkez - size / 2.0
	position = temel_konum
	scale = Vector2.ONE * olcek
	rotation = rotasyon


func set_secili(deger: bool) -> void:
	secili = deger
	_frame_style.border_color = Color.GOLD if secili else _sinif_rengi().darkened(0.3)
	_frame_style.set_border_width_all(5 if secili else 3)


# --- Arayüz kurulumu ---------------------------------------------------------

func _build() -> void:
	# Çerçeve
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_style = StyleBoxFlat.new()
	_frame_style.bg_color = Color("#1e1b2e")
	_frame_style.set_corner_radius_all(12)
	_frame_style.set_border_width_all(3)
	frame.add_theme_stylebox_override("panel", _frame_style)
	add_child(frame)

	# İsim
	_name_label = _make_label(Vector2(12, 8), Vector2(176, 28), 16)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Görsel alanı
	_art = TextureRect.new()
	_art.position = Vector2(12, 40)
	_art.size = Vector2(176, 130)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)

	# Sınıf + tip satırı
	_type_label = _make_label(Vector2(12, 174), Vector2(176, 20), 12)
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.modulate = Color(1, 1, 1, 0.7)

	# Açıklama
	_desc_label = _make_label(Vector2(14, 198), Vector2(172, 92), 13)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Mana taşı (sol üst köşe)
	var mana_gem := Panel.new()
	mana_gem.position = Vector2(-10, -10)
	mana_gem.size = Vector2(40, 40)
	mana_gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gem_style := StyleBoxFlat.new()
	gem_style.bg_color = Color("#2a6fd6")
	gem_style.set_corner_radius_all(20)
	gem_style.set_border_width_all(2)
	gem_style.border_color = Color("#bcd6ff")
	mana_gem.add_theme_stylebox_override("panel", gem_style)
	add_child(mana_gem)

	_mana_label = Label.new()
	_mana_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mana_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mana_label.add_theme_font_size_override("font_size", 20)
	_mana_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mana_gem.add_child(_mana_label)


func _make_label(pos: Vector2, label_size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = label_size
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _refresh() -> void:
	if data == null:
		return
	_name_label.text = data.kart_adi
	_mana_label.text = str(data.mana)
	_type_label.text = "%s · %s" % [CardData.sinif_adi(data.sinif), CardData.tip_adi(data.tip)]
	_desc_label.text = data.aciklama_metni()
	_art.texture = data.gorsel
	set_secili(secili)


func _sinif_rengi() -> Color:
	if data == null:
		return Color.GRAY
	return SINIF_RENKLERI.get(data.sinif, Color.GRAY)


# --- Etkileşim --------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(self)


func _on_hover(ustunde: bool) -> void:
	if _tween:
		_tween.kill()
	z_index = 50 if ustunde else temel_z
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if yukselme > 0.0:
		var olcek := 1.0 if ustunde else temel_olcek
		var konum := temel_konum - Vector2(0, yukselme) if ustunde else temel_konum
		_tween.tween_property(self, "scale", Vector2.ONE * olcek, 0.12)
		_tween.tween_property(self, "position", konum, 0.12)
		_tween.tween_property(self, "rotation", 0.0 if ustunde else temel_rotasyon, 0.12)
	else:
		var hedef := Vector2.ONE * temel_olcek * (HOVER_SCALE if ustunde else 1.0)
		_tween.tween_property(self, "scale", hedef, 0.12)
