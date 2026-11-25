extends SceneTree
## Arayüz testi: savaş ekranını açar, Destek sınıfını seçer ve birkaç turu
## animasyonlarıyla birlikte oynatır. Ekran kodunda hata varsa yakalar.

var sahne: Node
var sure := 0.0
var basladi := false


func _initialize() -> void:
	sahne = load("res://savas.tscn").instantiate()
	root.add_child(sahne)


func _process(delta: float) -> bool:
	sure += delta
	if not basladi and sure > 0.3:
		sahne._savasi_baslat(CardData.Sinif.DESTEK)
		basladi = true
		return false
	if not basladi:
		return false
	var motor: SavasMotoru = sahne.motor
	if motor.bitti or motor.tur > 4 or sure > 60.0:
		print("ARAYUZ TESTI TAMAM: tur %d, boss canı %d" % [motor.tur, motor.boss.can])
		return true
	if not sahne.oynatiliyor:
		var o: Oyuncu = motor.oyuncular[sahne.insan]
		if o.hayatta():
			# Önce hedef seçme akışını dene: elde müttefik kartı varsa karta "tıkla", sonra koltuğa
			for kart in o.el:
				if kart.hedef == CardData.Hedef.MUTTEFIK and kart.mana <= o.kalan_mana():
					var v := CardView.new()
					v.setup(kart)
					sahne._on_kart_tiklandi(v)
					sahne._on_koltuk_tiklandi((sahne.insan + 1) % 4)
					v.free()
					break
			Bot.planla(motor, o)
		sahne._hepsini_guncelle()
		sahne._turu_oyna()
	return false
