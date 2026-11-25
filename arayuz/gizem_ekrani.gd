class_name GizemEkrani
extends Control
## Rastgele olay: hikâye metni ve seçenekler, ardından sonuç.

signal bitti

var kosu: Kosu
var _olay: Dictionary
var _secenek_kutusu: VBoxContainer
var _metin: Label
var _secici: DesteSecici
var _devam: Button


func _init(p_kosu: Kosu) -> void:
	kosu = p_kosu
	size = Vector2(1280, 720)


func _ready() -> void:
	_olay = kosu.gizem_sec()
	add_child(Masa.new(false))
	var b := Arayuz.etiket(self, 42, _olay["baslik"], Color("#c38bff"))
	b.position = Vector2(0, 100)
	b.size = Vector2(1280, 50)

	_metin = Arayuz.etiket(self, 19, _olay["metin"], Color("#e8e0f8"))
	_metin.position = Vector2(240, 175)
	_metin.size = Vector2(800, 90)
	_metin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_secenek_kutusu = VBoxContainer.new()
	_secenek_kutusu.position = Vector2(340, 300)
	_secenek_kutusu.add_theme_constant_override("separation", 16)
	add_child(_secenek_kutusu)
	for s in _olay["secenekler"]:
		var btn := Arayuz.buton(s["metin"], Vector2(600, 64), Color("#2a1f45"), Color("#9a5bd1"), 16)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_secildi.bind(s))
		_secenek_kutusu.add_child(btn)


func _secildi(s: Dictionary) -> void:
	if s.get("deste_sec", "") == "cikar" and kosu.kart_cikarilabilir_mi(kosu.insan):
		_secici = DesteSecici.new("Destenden çıkarılacak kartı seç", kosu.deste(kosu.insan),
			func(_k): return true)
		_secici.secildi.connect(func(i: int):
			kosu.kart_cikar(kosu.insan, i)
			_sonuc(kosu.gizem_uygula(s["id"]))
		)
		add_child(_secici)
		return
	_sonuc(kosu.gizem_uygula(s["id"]))


func _sonuc(metin: String) -> void:
	_secenek_kutusu.queue_free()
	_metin.text = metin
	_devam = Arayuz.buton("Devam", Vector2(220, 56))
	_devam.position = Vector2(530, 340)
	_devam.pressed.connect(func(): bitti.emit())
	add_child(_devam)


## Arayüz testi için: ilk seçeneği seçer, sonra devam eder
func otomatik_adim() -> void:
	if _devam:
		bitti.emit()
	elif _secici and is_instance_valid(_secici):
		_secici.otomatik_adim()
	else:
		_secildi(_olay["secenekler"][0])
