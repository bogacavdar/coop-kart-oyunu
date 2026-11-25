extends Control
## Test sahnesi: klasördeki tüm kartları yükleyip bir el olarak gösterir.
## Kart seçip "Turu Oyna"ya basınca çözümleme sırasını Output paneline yazar.
## Kullanım: yeni bir sahne oluştur, kök düğüm Control olsun, bu scripti bağla, F6.

@export_dir var kart_klasoru := "res://kartlar/veriler"

var _el: HBoxContainer
var _secilenler: Array[CardView] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var arka := ColorRect.new()
	arka.color = Color("#0f0d1a")
	arka.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(arka)

	var kutu := VBoxContainer.new()
	kutu.set_anchors_preset(Control.PRESET_FULL_RECT)
	kutu.alignment = BoxContainer.ALIGNMENT_CENTER
	kutu.add_theme_constant_override("separation", 40)
	add_child(kutu)

	_el = HBoxContainer.new()
	_el.alignment = BoxContainer.ALIGNMENT_CENTER
	_el.add_theme_constant_override("separation", 20)
	kutu.add_child(_el)

	var buton := Button.new()
	buton.text = "Turu Oyna"
	buton.custom_minimum_size = Vector2(200, 50)
	buton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buton.pressed.connect(_turu_oyna)
	kutu.add_child(buton)

	_kartlari_yukle()


func _kartlari_yukle() -> void:
	var klasor := kart_klasoru.trim_suffix("/") + "/"
	for dosya in DirAccess.get_files_at(klasor):
		dosya = dosya.trim_suffix(".remap")  # dışa aktarılmış oyunda gerekli
		if not dosya.ends_with(".tres"):
			continue
		var veri := load(klasor + dosya) as CardData
		if veri == null:
			continue
		var kart := CardView.new()
		kart.setup(veri)
		kart.card_clicked.connect(_on_kart_tiklandi)
		_el.add_child(kart)


func _on_kart_tiklandi(kart: CardView) -> void:
	if kart in _secilenler:
		_secilenler.erase(kart)
		kart.set_secili(false)
	else:
		_secilenler.append(kart)
		kart.set_secili(true)


func _turu_oyna() -> void:
	# Test için her seçili kartı farklı bir oyuncu oynamış gibi sayıyoruz.
	var hamleler: Array[Dictionary] = []
	for i in _secilenler.size():
		hamleler.append({"oyuncu": i, "kart": _secilenler[i].data, "hedef_oyuncu": -1})

	print("--- Tur çözümleniyor ---")
	for hamle in TurnResolver.sirala(hamleler):
		var kart: CardData = hamle["kart"]
		print("Oyuncu %d: %s (%s)" % [hamle["oyuncu"] + 1, kart.kart_adi, CardData.tip_adi(kart.tip)])
	print("Boss hamlesi")

	for kart in _secilenler:
		kart.set_secili(false)
	_secilenler.clear()
