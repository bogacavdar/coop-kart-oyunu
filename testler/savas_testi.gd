extends SceneTree
## Otomatik test: savaşı birçok kez kendi kendine oynatır.
## 1) Rastgele kart seçen takım  2) Dört bot  3) Bir rastgele oyuncu + üç bot
## Hata varsa GitHub derlemesi kırmızıya döner; sonuçlar kaba bir denge fikri verir.
## Çalıştırma: godot --headless --script res://testler/savas_testi.gd

const OYUN_SAYISI := 200


func _initialize() -> void:
	var havuz := KartHavuzu.yukle("res://kartlar/veriler")
	var kart_sayisi := 0
	for s in havuz:
		kart_sayisi += havuz[s].size()
	print("TEST: %d kart, %d sınıf yüklendi" % [kart_sayisi, havuz.size()])
	if kart_sayisi < 20 or havuz.size() < 4:
		push_error("TEST HATASI: kartlar eksik yüklendi")

	_rapor("rastgele takım", havuz, 0)
	_rapor("4 bot", havuz, 4)
	_rapor("1 rastgele + 3 bot", havuz, 3)
	print("TEST TAMAM")
	quit()


## bot_sayisi: kaç oyuncuyu bot oynar (son oyuncular bot olur)
func _rapor(ad: String, havuz: Dictionary, bot_sayisi: int) -> void:
	var zafer := 0
	var toplam_tur := 0
	for oyun in OYUN_SAYISI:
		var motor := SavasMotoru.new(havuz)
		while not motor.bitti and motor.tur < 80:
			for o in motor.oyuncular:
				if not o.hayatta():
					continue
				if o.no >= motor.oyuncular.size() - bot_sayisi:
					Bot.planla(motor, o)
				else:
					_rastgele_sec(motor, o)
				if o.harcanan_mana() > o.mana:
					push_error("TEST HATASI: mana aşıldı")
			motor.turu_coz()
		if not motor.bitti:
			push_error("TEST HATASI: savaş 80 turda bitmedi")
		if motor.boss.can <= 0:
			zafer += 1
		toplam_tur += motor.tur
	print("TEST: %s %d/%d kazandı, ortalama %.1f tur" % [ad, zafer, OYUN_SAYISI, float(toplam_tur) / OYUN_SAYISI])


func _rastgele_sec(motor: SavasMotoru, o: Oyuncu) -> void:
	while o.oynayabilir_mi():
		var kalan := o.kalan_mana()
		var uygun: Array = o.el.filter(func(k): return not o.secili_mi(k) and k.mana <= kalan)
		var kart: CardData = uygun.pick_random()
		var hedef := -1
		if kart.hedef == CardData.Hedef.MUTTEFIK:
			hedef = motor.canli_oyuncular().pick_random().no
		if not motor.kart_sec(o.no, kart, hedef):
			push_error("TEST HATASI: geçerli kart reddedildi: " + kart.kart_adi)
			return
