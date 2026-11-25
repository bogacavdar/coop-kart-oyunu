class_name TilsimEkrani
extends Control
## Elit savaş sonrası: 3 tılsımdan birini seç.

signal secildi(id: String)

var _secenekler: Array[String]
var _baslik: String
var _alt: String


func _init(secenekler: Array[String], baslik: String = "Elit yenildi! Bir tılsım seç",
		alt: String = "Tılsımlar bütün takıma koşu sonuna kadar bonus verir.") -> void:
	_secenekler = secenekler
	_baslik = baslik
	_alt = alt
	size = Vector2(1280, 720)


func _ready() -> void:
	add_child(Masa.new(false))
	var b := Arayuz.etiket(self, 40, _baslik, Arayuz.ALTIN)
	b.position = Vector2(0, 90)
	b.size = Vector2(1280, 50)
	var a := Arayuz.etiket(self, 17, _alt, Color("#c8c0e0"))
	a.position = Vector2(0, 145)
	a.size = Vector2(1280, 24)

	var genislik := 300.0
	var bosluk := 30.0
	var toplam := _secenekler.size() * genislik + (_secenekler.size() - 1) * bosluk
	for i in _secenekler.size():
		var id := _secenekler[i]
		var btn := Arayuz.secenek_butonu(Tilsimlar.ad(id), Tilsimlar.aciklama(id), Color("#e8c27a"),
			Vector2(genislik, 270), Tilsimlar.ikon(id))
		btn.position = Vector2(640 - toplam / 2.0 + i * (genislik + bosluk), 230)
		btn.pressed.connect(func(): secildi.emit(id))
		add_child(btn)

	if _secenekler.is_empty():
		var devam := Arayuz.buton("Devam", Vector2(220, 56))
		devam.position = Vector2(530, 330)
		devam.pressed.connect(func(): secildi.emit(""))
		add_child(devam)


## Arayüz testi için
func otomatik_adim() -> void:
	secildi.emit(_secenekler[0] if not _secenekler.is_empty() else "")
