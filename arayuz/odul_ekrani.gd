class_name OdulEkrani
extends Control
## Savaş sonrası ödül: 3 karttan birini seç ya da geç.

signal secildi(kart: CardData)

var _kartlar: Array[CardData]
var _alt_metin: String


func _init(kartlar: Array[CardData], alt_metin: String) -> void:
	_kartlar = kartlar
	_alt_metin = alt_metin
	size = Vector2(1280, 720)


func _ready() -> void:
	add_child(Masa.new(false))
	var b := Arayuz.etiket(self, 40, "Zafer! Destene bir kart ekle", Arayuz.ALTIN)
	b.position = Vector2(0, 60)
	b.size = Vector2(1280, 50)
	var a := Arayuz.etiket(self, 16, _alt_metin, Color("#c8c0e0"))
	a.position = Vector2(0, 112)
	a.size = Vector2(1280, 24)

	for i in _kartlar.size():
		var v := CardView.new()
		v.setup(_kartlar[i])
		add_child(v)
		v.yerlestir(Vector2(640 + (i - (_kartlar.size() - 1) / 2.0) * 270, 360), 1.0)
		v.card_clicked.connect(func(_v):
			Ses.cal(self, "sec")
			Ipucu.gizle()
			secildi.emit(_kartlar[i])
		)

	var gec := Arayuz.buton("Kart alma, geç", Vector2(220, 50), Color("#2a2450"), Color("#7a6fd0"), 17)
	gec.position = Vector2(530, 580)
	gec.pressed.connect(func(): secildi.emit(null))
	add_child(gec)


## Arayüz testi için
func otomatik_adim() -> void:
	secildi.emit(_kartlar[0] if not _kartlar.is_empty() else null)
