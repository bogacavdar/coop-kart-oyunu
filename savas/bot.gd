class_name Bot
extends RefCounted
## Basit yapay zekâ: boss'un niyetine bakarak kartlara puan verir,
## manası bitene kadar mana başına en verimli kartı seçer.
## Multiplayer gelince boş koltukları bu doldurur.


static func planla(motor: SavasMotoru, o: Oyuncu) -> void:
	o.secimler.clear()
	if not o.hayatta():
		return
	while o.oynayabilir_mi():
		var en_iyi: CardData = null
		var en_iyi_hedef := -1
		var en_iyi_puan := -1.0
		var kalan := o.kalan_mana()
		for kart in o.el:
			if o.secili_mi(kart) or kart.mana > kalan:
				continue
			var sonuc := _degerlendir(motor, o, kart)
			var puan: float = (float(sonuc[0]) + _ek_puan(motor, o, kart)) / (kart.mana + 1.0)
			if puan > en_iyi_puan:
				en_iyi_puan = puan
				en_iyi = kart
				en_iyi_hedef = sonuc[1]
		if en_iyi == null or en_iyi_puan <= 0.0:
			return
		if not motor.kart_sec(o.no, en_iyi, en_iyi_hedef):
			return


## [puan, hedef_oyuncu] döndürür
static func _degerlendir(motor: SavasMotoru, o: Oyuncu, kart: CardData) -> Array:
	var niyet := motor.boss.niyet
	var niyet_tur: String = niyet.get("tur", "")
	var niyet_hasar: int = niyet.get("hasar", 0)
	var niyet_hedef: int = niyet.get("hedef", -1)
	var canlilar := motor.canli_oyuncular()
	var niyet_hedefleri: Array = niyet.get("hedefler", [])
	if niyet_tur == "tekil":
		niyet_hedefleri = [niyet_hedef]
	elif niyet_tur == "alan":
		niyet_hedefleri = canlilar.map(func(c): return c.no)
	var etkilenen := niyet_hedefleri.size()

	match kart.etki:
		CardData.Etki.HASAR:
			return [float(kart.deger), -1]

		CardData.Etki.ISARET:
			# Takımda genelde 2-3 saldırı kartı oynanır
			return [kart.deger * 2.0, -1]

		CardData.Etki.ZAYIFLAT:
			return [float(mini(kart.deger, niyet_hasar) * etkilenen) * 1.2, -1]

		CardData.Etki.SERSEMLET:
			if motor.boss.bagisik or motor.boss.sersem:
				return [0.0, -1]
			return [float(niyet_hasar * etkilenen) * 0.8, -1]

		CardData.Etki.AGGRO:
			if niyet_tur == "tekil" and niyet_hedef >= 0 and niyet_hedef != o.no:
				var tehlikede := motor.oyuncular[niyet_hedef].can <= niyet_hasar
				return [kart.deger + niyet_hasar * (0.8 if tehlikede else 0.4), -1]
			return [kart.deger * (0.8 if niyet_tur == "tekil" else 0.3), -1]

		CardData.Etki.ZIRH:
			if kart.hedef == CardData.Hedef.TUM_TAKIM:
				return [kart.deger * (etkilenen + canlilar.size() * 0.2), -1]
			var hedef_no := o.no
			if kart.hedef == CardData.Hedef.MUTTEFIK and niyet_tur == "tekil" \
					and niyet_hedef >= 0 and motor.oyuncular[niyet_hedef].hayatta():
				hedef_no = niyet_hedef
			var tehdit := niyet_hedefleri.has(hedef_no)
			var hedef_param := hedef_no if kart.hedef == CardData.Hedef.MUTTEFIK else -1
			return [kart.deger * (1.1 if tehdit else 0.3), hedef_param]

		CardData.Etki.IYILESTIRME:
			if kart.hedef == CardData.Hedef.TUM_TAKIM:
				var toplam := 0
				for c in canlilar:
					toplam += mini(kart.deger, c.max_can - c.can)
				return [float(toplam), -1]
			var en_eksik: Oyuncu = o
			if kart.hedef == CardData.Hedef.MUTTEFIK:
				for c in canlilar:
					if c.max_can - c.can > en_eksik.max_can - en_eksik.can:
						en_eksik = c
			var eksik := en_eksik.max_can - en_eksik.can
			var hedef_param := en_eksik.no if kart.hedef == CardData.Hedef.MUTTEFIK else -1
			return [mini(kart.deger, eksik) * 1.2, hedef_param]

	return [0.0, -1]


## İkinci etkinin kabaca değeri
static func _ek_puan(motor: SavasMotoru, o: Oyuncu, kart: CardData) -> float:
	var ek := kart.ek_deger
	match kart.ek_etki:
		CardData.EkEtki.KENDINE_ZIRH:
			return ek * 0.6
		CardData.EkEtki.TAKIMA_ZIRH:
			return ek * motor.canli_oyuncular().size() * 0.5
		CardData.EkEtki.KENDINE_CAN:
			return mini(ek, o.max_can - o.can) * 1.0
		CardData.EkEtki.TAKIMA_CAN:
			var toplam := 0
			for c in motor.canli_oyuncular():
				toplam += mini(ek, c.max_can - c.can)
			return float(toplam)
		CardData.EkEtki.BOSSA_HASAR:
			return float(ek)
	return 0.0
