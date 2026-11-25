class_name SavasMotoru
extends RefCounted
## Savaşın bütün kuralları burada. Arayüzden bağımsızdır:
## ileride multiplayer'da bu sınıfı sadece host çalıştıracak,
## diğer oyuncular yalnızca kart_sec() isteği yollayacak.
##
## turu_coz() olan biten her şeyi sırayla bir olay listesi olarak döndürür,
## arayüz bu olayları tek tek canlandırır.

const EL_BOYUTU := 4
const MAKS_MANA := 6
const KOPYA_SAYISI := 2
const BOSS_CANI_OYUNCU_BASI := 65

var oyuncular: Array[Oyuncu] = []
var boss: Boss
var tur := 1
var bitti := false
## Bu tur boss'un tekil saldırılarını üstüne çeken oyuncu (-1 = yok)
var aggro := -1
var rng := RandomNumberGenerator.new()


func _init(kart_havuzu: Dictionary) -> void:
	rng.randomize()
	var siniflar: Array[int] = [
		CardData.Sinif.TANK, CardData.Sinif.DESTEK,
		CardData.Sinif.HASARCI, CardData.Sinif.KONTROLCU,
	]
	var canlar := {
		CardData.Sinif.TANK: 60,
		CardData.Sinif.DESTEK: 40,
		CardData.Sinif.HASARCI: 35,
		CardData.Sinif.KONTROLCU: 40,
	}
	for i in siniflar.size():
		var sinif := siniflar[i]
		var o := Oyuncu.new(i, sinif, canlar[sinif])
		for kart in kart_havuzu.get(sinif, []):
			for k in KOPYA_SAYISI:
				o.deste.append(kart.duplicate())
		o.deste.shuffle()
		oyuncular.append(o)
	boss = Boss.new(BOSS_CANI_OYUNCU_BASI * oyuncular.size())
	_tur_baslat()


# --- Oyuncu girdileri ------------------------------------------------------

func kart_sec(oyuncu_no: int, kart: CardData, hedef_oyuncu: int = -1) -> bool:
	if bitti:
		return false
	var o := oyuncular[oyuncu_no]
	if not o.hayatta() or not o.el.has(kart) or kart.mana > o.mana:
		return false
	if kart.hedef == CardData.Hedef.MUTTEFIK:
		if hedef_oyuncu < 0 or hedef_oyuncu >= oyuncular.size():
			return false
		if not oyuncular[hedef_oyuncu].hayatta():
			return false
	else:
		hedef_oyuncu = -1
	o.secilen = kart
	o.secilen_hedef = hedef_oyuncu
	return true


func secimi_kaldir(oyuncu_no: int) -> void:
	oyuncular[oyuncu_no].secilen = null
	oyuncular[oyuncu_no].secilen_hedef = -1


func hepsi_hazir() -> bool:
	for o in oyuncular:
		if o.hayatta() and o.secilen == null:
			return false
	return true


func canli_oyuncular() -> Array[Oyuncu]:
	var liste: Array[Oyuncu] = []
	for o in oyuncular:
		if o.hayatta():
			liste.append(o)
	return liste


# --- Tur çözümleme ---------------------------------------------------------

func turu_coz() -> Array[Dictionary]:
	var olaylar: Array[Dictionary] = []
	if bitti:
		return olaylar

	var hamleler: Array[Dictionary] = []
	for o in oyuncular:
		if o.hayatta() and o.secilen != null:
			hamleler.append({"oyuncu": o.no, "kart": o.secilen, "hedef_oyuncu": o.secilen_hedef})

	for h in TurnResolver.sirala(hamleler):
		_kart_uygula(h, olaylar)
		if boss.can <= 0:
			break

	# Oynanan kartlar atılanlara gider
	for o in oyuncular:
		if o.secilen != null:
			o.el.erase(o.secilen)
			o.atilan.append(o.secilen)
			o.secilen = null
			o.secilen_hedef = -1

	if boss.can <= 0:
		bitti = true
		olaylar.append({"tip": "zafer"})
		return olaylar

	_boss_hamlesi(olaylar)

	if canli_oyuncular().is_empty():
		bitti = true
		olaylar.append({"tip": "yenilgi"})
		return olaylar

	tur += 1
	_tur_baslat()
	olaylar.append({"tip": "yeni_tur"})
	return olaylar


func _kart_uygula(h: Dictionary, olaylar: Array[Dictionary]) -> void:
	var o: Oyuncu = oyuncular[h["oyuncu"]]
	var kart: CardData = h["kart"]
	olaylar.append({
		"tip": "kart", "oyuncu": o.no, "kart_adi": kart.kart_adi,
		"metin": "%s: %s" % [o.ad, kart.kart_adi],
	})

	match kart.etki:
		CardData.Etki.HASAR:
			var miktar := kart.deger + boss.isaret
			boss.can = maxi(0, boss.can - miktar)
			olaylar.append({"tip": "boss_hasar", "miktar": miktar, "can": boss.can})

		CardData.Etki.ISARET:
			boss.isaret += kart.deger
			_boss_durum_olayi(olaylar, "Boss işaretlendi: saldırılar +%d" % boss.isaret)

		CardData.Etki.ZAYIFLAT:
			boss.zayiflik += kart.deger
			_boss_durum_olayi(olaylar, "Boss zayıfladı: hasarı -%d" % boss.zayiflik)

		CardData.Etki.SERSEMLET:
			boss.sersem = true
			_boss_durum_olayi(olaylar, "Boss sersemledi!")

		CardData.Etki.AGGRO:
			aggro = o.no
			o.zirh += kart.deger
			_oyuncu_olayi(olaylar, "zirh", o, kart.deger)
			_boss_durum_olayi(olaylar, "%s boss'un dikkatini çekti" % o.ad)

		CardData.Etki.ZIRH:
			for t in _hedefler(o, kart, h["hedef_oyuncu"]):
				t.zirh += kart.deger
				_oyuncu_olayi(olaylar, "zirh", t, kart.deger)

		CardData.Etki.IYILESTIRME:
			for t in _hedefler(o, kart, h["hedef_oyuncu"]):
				var iyilesen := t.iyiles(kart.deger)
				_oyuncu_olayi(olaylar, "iyilestir", t, iyilesen)


func _hedefler(o: Oyuncu, kart: CardData, hedef_no: int) -> Array[Oyuncu]:
	var liste: Array[Oyuncu] = []
	match kart.hedef:
		CardData.Hedef.KENDISI:
			liste.append(o)
		CardData.Hedef.MUTTEFIK:
			if hedef_no >= 0 and oyuncular[hedef_no].hayatta():
				liste.append(oyuncular[hedef_no])
		CardData.Hedef.TUM_TAKIM:
			liste = canli_oyuncular()
	return liste


func _boss_hamlesi(olaylar: Array[Dictionary]) -> void:
	var n := boss.niyet
	if boss.sersem:
		olaylar.append({"tip": "boss_hamle", "metin": "%s sersem, bu tur saldıramadı!" % boss.ad})
		return

	match n.get("tur", ""):
		"tekil":
			var hedef_no: int = n["hedef"]
			var metin: String = n["metin"]
			if aggro >= 0 and oyuncular[aggro].hayatta() and aggro != hedef_no:
				hedef_no = aggro
				metin += " (Tank'a yöneldi!)" if oyuncular[aggro].sinif == CardData.Sinif.TANK else " (yön değiştirdi!)"
			if not oyuncular[hedef_no].hayatta():
				hedef_no = canli_oyuncular().pick_random().no
			olaylar.append({"tip": "boss_hamle", "metin": metin})
			_oyuncuya_vur(hedef_no, maxi(0, int(n["hasar"]) - boss.zayiflik), olaylar)
		"alan":
			olaylar.append({"tip": "boss_hamle", "metin": n["metin"]})
			for o in canli_oyuncular():
				_oyuncuya_vur(o.no, maxi(0, int(n["hasar"]) - boss.zayiflik), olaylar)
		"guc":
			boss.guc += 3
			olaylar.append({"tip": "boss_hamle", "metin": n["metin"]})
			_boss_durum_olayi(olaylar, "Boss güçlendi")


func _oyuncuya_vur(no: int, miktar: int, olaylar: Array[Dictionary]) -> void:
	var o := oyuncular[no]
	var emilen := o.hasar_al(miktar)
	var olay := _oyuncu_durumu(o)
	olay["tip"] = "oyuncu_hasar"
	olay["miktar"] = miktar - emilen
	olay["emilen"] = emilen
	olaylar.append(olay)
	if not o.hayatta():
		olaylar.append({"tip": "olum", "oyuncu": o.no, "metin": "%s düştü!" % o.ad})


# --- Tur başlangıcı ve boss niyeti -----------------------------------------

func _tur_baslat() -> void:
	boss.isaret = 0
	boss.zayiflik = 0
	boss.sersem = false
	aggro = -1
	# Savaş uzadıkça boss sertleşir
	if tur > 1 and tur % 3 == 1:
		boss.guc += 1
	for o in oyuncular:
		o.zirh = 0
		o.mana = mini(tur + 1, MAKS_MANA)
		if o.hayatta():
			o.kart_cek(EL_BOYUTU - o.el.size())
	_niyet_belirle()


func _niyet_belirle() -> void:
	var canlilar := canli_oyuncular()
	if canlilar.is_empty():
		return
	var hedef: Oyuncu = canlilar[rng.randi_range(0, canlilar.size() - 1)]
	var zar := rng.randi_range(1, 100)
	var h := 0
	if zar <= 45 or tur == 1:
		h = 10 + boss.guc
		boss.niyet = {"tur": "tekil", "hedef": hedef.no, "hasar": h,
			"metin": "Kuyruklu Yıldız -> %s (%d hasar)" % [hedef.ad, h]}
	elif zar <= 65:
		h = 18 + boss.guc
		boss.niyet = {"tur": "tekil", "hedef": hedef.no, "hasar": h,
			"metin": "Kara Delik -> %s (%d hasar)" % [hedef.ad, h]}
	elif zar <= 90:
		h = 5 + int(boss.guc / 2.0)
		boss.niyet = {"tur": "alan", "hasar": h,
			"metin": "Satürn Halkası -> Tüm takım (%d hasar)" % h}
	else:
		boss.niyet = {"tur": "guc", "metin": "Güç Topluyor (+3 güç)"}


# --- Olay yardımcıları -----------------------------------------------------

func _oyuncu_durumu(o: Oyuncu) -> Dictionary:
	return {"oyuncu": o.no, "can": o.can, "max_can": o.max_can, "zirh": o.zirh}


func _oyuncu_olayi(olaylar: Array[Dictionary], tip: String, o: Oyuncu, miktar: int) -> void:
	var olay := _oyuncu_durumu(o)
	olay["tip"] = tip
	olay["miktar"] = miktar
	olaylar.append(olay)


func _boss_durum_olayi(olaylar: Array[Dictionary], metin: String) -> void:
	olaylar.append({"tip": "boss_durum", "metin": metin, "durum": boss.durum_metni()})
