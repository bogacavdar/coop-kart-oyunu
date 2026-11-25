class_name DinlenmeEkrani
extends Control
## Kamp ateşi: ya takım dinlenir ya da bir kart güçlendirilir.

signal bitti

var kosu: Kosu
var _secici: DesteSecici


func _init(p_kosu: Kosu) -> void:
	kosu = p_kosu
	size = Vector2(1280, 720)


func _ready() -> void:
	add_child(Masa.new(false))
	var b := Arayuz.etiket(self, 42, "Kamp Ateşi", Color("#ffb347"))
	b.position = Vector2(0, 90)
	b.size = Vector2(1280, 50)
	var a := Arayuz.etiket(self, 17, "Kamp ateşinin başında kısa bir mola. Ne yapacaksınız?", Color("#c8c0e0"))
	a.position = Vector2(0, 145)
	a.size = Vector2(1280, 24)

	var dinlen := Arayuz.secenek_butonu("Dinlen",
		"Bütün takım max canının %%%d'i kadar iyileşir." % int(kosu.dinlenme_orani() * 100), Color("#3fae6a"), Vector2(320, 200))
	dinlen.position = Vector2(290, 250)
	dinlen.pressed.connect(_dinlen)
	add_child(dinlen)

	var guclendir := Arayuz.secenek_butonu("Güçlendir",
		"Destenden bir kartı kalıcı olarak güçlendir. Botlar da birer kartını güçlendirir.", Color("#e8c27a"), Vector2(320, 200))
	guclendir.position = Vector2(670, 250)
	guclendir.pressed.connect(_guclendir)
	add_child(guclendir)


func _dinlen() -> void:
	kosu.dinlen()
	bitti.emit()


func _guclendir() -> void:
	_secici = DesteSecici.new("Güçlendirilecek kartı seç", kosu.deste(kosu.insan),
		func(k: CardData): return not k.guclendirildi_mi())
	_secici.secildi.connect(func(i: int):
		kosu.kart_guclendir(kosu.insan, i)
		kosu.botlar_guclendirsin()
		bitti.emit()
	)
	add_child(_secici)


## Arayüz testi için: güçlendirme akışını dener
func otomatik_adim() -> void:
	if _secici and is_instance_valid(_secici):
		_secici.otomatik_adim()
	else:
		_guclendir()
