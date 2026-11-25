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

var oyuncular: Array[Oyuncu] = []
var boss: Boss
var tur := 1
var bitti := false
## Bu tur boss'un tekil saldırılarını üstüne çeken oyuncu (-1 = yok)
var aggro := -1
var rng := RandomNumberGenerator.new()
## Takımın tılsımları ve savaş başında ne yaptıkları (günlüğe yazılır)
var tilsimlar: Array = []
var baslangic_mesajlari: PackedStringArray = []
var el_boyutu := EL_BOYUTU
## Zorluk kademesi (Kademe sınıfına bakınız)
var kademe := 0
var hasar_carpani := 1.0


## kurulum: {"oyuncular": [{"sinif", "can", "max_can", "deste"}], "dusman": "id"}
func _init(kurulum: Dictionary) -> void:
	rng.randomize()
	tilsimlar = kurulum.get("tilsimlar", [])
	kademe = int(kurulum.get("kademe", 0))
	if kademe >= 2:
		hasar_carpani = 1.1
	if tilsimlar.has("bilge_kitabi"):
		el_boyutu = EL_BOYUTU + 1
	var liste: Array = kurulum["oyuncular"]
	for i in liste.size():
		var v: Dictionary = liste[i]
		var o := Oyuncu.new(i, int(v["sinif"]), int(v["max_can"]))
		o.can = int(v["can"])
		for kart in v["deste"]:
			o.deste.append(kart.duplicate())
		o.deste.shuffle()
		oyuncular.append(o)
	boss = Boss.new(Dusmanlar.tanim(kurulum["dusman"]), oyuncular.size())
	_kademe_uygula()
	_tur_baslat()
	_savas_basi_tilsimlari()


func _kademe_uygula() -> void:
	if kademe >= 1 and boss.tip == "elit":
		_boss_canini_carp(1.2)
	if kademe >= 4:
		boss.guc += 1
	if kademe >= 5 and boss.tip == "boss":
		_boss_canini_carp(1.15)
	if kademe >= 8 and boss.tip != "normal":
		boss.guc += 2
	if kademe >= 9 and boss.tip == "normal":
		_boss_canini_carp(1.15)
	if kademe >= 10 and boss.tip == "boss":
		boss.guc_artisi += 2


func _boss_canini_carp(carpan: float) -> void:
	boss.max_can = int(boss.max_can * carpan)
	boss.can = boss.max_can


func _savas_basi_tilsimlari() -> void:
	if tilsimlar.has("demir_yuzuk"):
		for o in oyuncular:
			o.zirh += 6
		baslangic_mesajlari.append("Demir Yüzük: takım 6 zırh kazandı.")
	if tilsimlar.has("mana_kristali"):
		for o in oyuncular:
			o.mana += 1
		baslangic_mesajlari.append("Mana Kristali: herkesin bu tur 1 fazla manası var.")
	if tilsimlar.has("savas_borusu"):
		var kayip := int(boss.max_can * 0.1)
		boss.can -= kayip
		baslangic_mesajlari.append("Savaş Borusu: %s %d can kaybetti." % [boss.ad, kayip])


## Testler için: başlangıç desteleriyle, tam canla tek bir savaş kurulumu
static func hizli_kurulum(havuz: Dictionary, dusman: String = Dusmanlar.BOSS) -> Dictionary:
	var liste: Array = []
	for s in Kosu.SINIFLAR:
		var can: int = Kosu.SINIF_CANLARI[s]
		liste.append({"sinif": s, "can": can, "max_can": can, "deste": Kosu.baslangic_destesi(havuz, s)})
	return {"oyuncular": liste, "dusman": dusman}


# --- Oyuncu girdileri ------------------------------------------------------

func kart_sec(oyuncu_no: int, kart: CardData, hedef_oyuncu: int = -1) -> bool:
	if bitti:
		return false
	var o := oyuncular[oyuncu_no]
	if not o.hayatta() or not o.el.has(kart) or o.secili_mi(kart):
		return false
	if kart.mana > o.kalan_mana():
		return false
	if kart.hedef == CardData.Hedef.MUTTEFIK:
		if hedef_oyuncu < 0 or hedef_oyuncu >= oyuncular.size():
			return false
		if not oyuncular[hedef_oyuncu].hayatta():
			return false
	else:
		hedef_oyuncu = -1
	o.secimler.append({"kart": kart, "hedef": hedef_oyuncu})
	return true


func secimi_kaldir(oyuncu_no: int, kart: CardData) -> void:
	var o := oyuncular[oyuncu_no]
	for i in o.secimler.size():
		if o.secimler[i]["kart"] == kart:
			o.secimler.remove_at(i)
			return


## Herkes ya manasını bitirdi ya da oynayacak kartı kalmadı mı?
func hepsi_hazir() -> bool:
	for o in oyuncular:
		if o.hayatta() and o.oynayabilir_mi():
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
		if not o.hayatta():
			continue
		for i in o.secimler.size():
			var s := o.secimler[i]
			hamleler.append({"oyuncu": o.no, "kart": s["kart"], "hedef_oyuncu": s["hedef"], "sira": i})

	for h in TurnResolver.sirala(hamleler):
		_kart_uygula(h, olaylar)
		if boss.can <= 0:
			break

	# Oynanan kartlar atılanlara gider
	for o in oyuncular:
		for s in o.secimler:
			o.el.erase(s["kart"])
			o.atilan.append(s["kart"])
		o.secimler.clear()

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
		"tip": "kart", "oyuncu": o.no, "kart": kart, "kart_adi": kart.kart_adi,
		"metin": "%s: %s" % [o.ad, kart.kart_adi],
	})

	match kart.etki:
		CardData.Etki.HASAR:
			_bossa_vur(kart.deger + boss.isaret, olaylar)

		CardData.Etki.ISARET:
			boss.isaret += kart.deger
			_boss_durum_olayi(olaylar, "Düşman işaretlendi: saldırılar +%d" % boss.isaret)

		CardData.Etki.ZAYIFLAT:
			boss.zayiflik += kart.deger
			_boss_durum_olayi(olaylar, "Düşman zayıfladı: hasarı -%d" % boss.zayiflik)

		CardData.Etki.SERSEMLET:
			if boss.bagisik:
				_boss_durum_olayi(olaylar, "Düşman bu tur bağışık, sersemlemedi!")
			else:
				boss.sersem = true
				_boss_durum_olayi(olaylar, "Düşman kıpırdayamıyor!")

		CardData.Etki.AGGRO:
			aggro = o.no
			o.zirh += kart.deger
			_oyuncu_olayi(olaylar, "zirh", o, kart.deger)
			_boss_durum_olayi(olaylar, "%s düşmanın dikkatini çekti" % o.ad)

		CardData.Etki.ZIRH:
			for t in _hedefler(o, kart, h["hedef_oyuncu"]):
				t.zirh += kart.deger
				_oyuncu_olayi(olaylar, "zirh", t, kart.deger)

		CardData.Etki.IYILESTIRME:
			for t in _hedefler(o, kart, h["hedef_oyuncu"]):
				var iyilesen := t.iyiles(kart.deger)
				_oyuncu_olayi(olaylar, "iyilestir", t, iyilesen)

	if boss.can <= 0:
		return
	var ek := kart.ek_deger
	match kart.ek_etki:
		CardData.EkEtki.KENDINE_ZIRH:
			o.zirh += ek
			_oyuncu_olayi(olaylar, "zirh", o, ek)
		CardData.EkEtki.TAKIMA_ZIRH:
			for t in canli_oyuncular():
				t.zirh += ek
				_oyuncu_olayi(olaylar, "zirh", t, ek)
		CardData.EkEtki.KENDINE_CAN:
			_oyuncu_olayi(olaylar, "iyilestir", o, o.iyiles(ek))
		CardData.EkEtki.TAKIMA_CAN:
			for t in canli_oyuncular():
				_oyuncu_olayi(olaylar, "iyilestir", t, t.iyiles(ek))
		CardData.EkEtki.BOSSA_HASAR:
			_bossa_vur(ek, olaylar)


## Boss'a hasar: önce kalkanı emer
func _bossa_vur(miktar: int, olaylar: Array[Dictionary]) -> void:
	var emilen := mini(boss.zirh, miktar)
	boss.zirh -= emilen
	var net := miktar - emilen
	boss.can = maxi(0, boss.can - net)
	olaylar.append({"tip": "boss_hasar", "miktar": net, "emilen": emilen, "can": boss.can, "durum": boss.durum_metni()})


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
	boss.zirh = 0  # önceki turun kalkanı biter
	if boss.sersem:
		olaylar.append({"tip": "boss_hamle", "metin": "%s sersem, bu tur bir şey yapamadı!" % boss.ad})
		return

	var hasar := maxi(0, int(n.get("hasar", 0)) - boss.zayiflik)
	match n.get("tur", ""):
		"tekil":
			var hedef_no: int = n["hedef"]
			var metin: String = n["metin"]
			if aggro >= 0 and oyuncular[aggro].hayatta() and aggro != hedef_no:
				hedef_no = aggro
				metin += " (%s üstüne çekti!)" % oyuncular[aggro].ad
			if not oyuncular[hedef_no].hayatta():
				hedef_no = canli_oyuncular().pick_random().no
			olaylar.append({"tip": "boss_hamle", "metin": metin})
			_oyuncuya_vur(hedef_no, hasar, olaylar)
		"cift":
			olaylar.append({"tip": "boss_hamle", "metin": n["metin"]})
			for no in n["hedefler"]:
				if oyuncular[no].hayatta():
					_oyuncuya_vur(no, hasar, olaylar)
		"alan":
			olaylar.append({"tip": "boss_hamle", "metin": n["metin"]})
			for o in canli_oyuncular():
				_oyuncuya_vur(o.no, hasar, olaylar)
		"guc":
			boss.guc += int(n["miktar"])
			olaylar.append({"tip": "boss_hamle", "metin": n["metin"]})
			_boss_durum_olayi(olaylar, "%s güçlendi" % boss.ad)
		"kalkan":
			boss.zirh += int(n["miktar"])
			olaylar.append({"tip": "boss_hamle", "metin": n["metin"]})
			_boss_durum_olayi(olaylar, "%s kalkan kazandı" % boss.ad)
		"iyiles":
			var once := boss.can
			boss.can = mini(boss.max_can, boss.can + int(n["miktar"]))
			olaylar.append({"tip": "boss_hamle", "metin": n["metin"]})
			olaylar.append({"tip": "boss_iyiles", "miktar": boss.can - once, "can": boss.can})


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

const OFKE_TURU := 15


func _tur_baslat() -> void:
	boss.isaret = 0
	boss.zayiflik = 0
	boss.bagisik = boss.sersem
	boss.sersem = false
	# Savaş çok uzarsa düşman öfkelenir: her tur güçlenir (sonsuz savaşı önler)
	if tur > OFKE_TURU:
		boss.guc += 3
	aggro = -1
	# Savaş uzadıkça boss sertleşir
	if tur > 1 and tur % 2 == 1:
		boss.guc += boss.guc_artisi
	for o in oyuncular:
		o.zirh = 0
		o.mana = mini(tur, MAKS_MANA)
		if o.hayatta():
			o.kart_cek(el_boyutu - o.el.size())
	if tilsimlar.has("avci_pusulasi"):
		boss.isaret += 2
	if tilsimlar.has("ejder_pulu"):
		boss.zayiflik += 2
	_niyet_belirle()


func _niyet_belirle() -> void:
	var canlilar := canli_oyuncular()
	if canlilar.is_empty():
		return
	# Ağırlıklı rastgele hamle seçimi
	var adaylar: Array = []
	var toplam := 0
	for h in boss.hamleler:
		if tur == 1 and h.get("ilk_tur_yok", false):
			continue
		adaylar.append(h)
		toplam += int(h["agirlik"])
	var secilen: Dictionary = adaylar[0]
	var zar := rng.randi_range(1, toplam)
	for h in adaylar:
		zar -= int(h["agirlik"])
		if zar <= 0:
			secilen = h
			break

	var ad: String = secilen["ad"]
	var n := {"tur": secilen["tur"]}
	match secilen["tur"]:
		"tekil":
			var hedef: Oyuncu = canlilar[rng.randi_range(0, canlilar.size() - 1)]
			var h := int(round(int(secilen["hasar"]) * hasar_carpani)) + boss.guc
			n["hedef"] = hedef.no
			n["hasar"] = h
			n["metin"] = "%s -> %s (%d hasar)" % [ad, hedef.ad, h]
		"cift":
			var karisik := canlilar.duplicate()
			karisik.shuffle()
			var hedefler: Array[int] = []
			var adlar: PackedStringArray = []
			for o in karisik.slice(0, 2):
				hedefler.append(o.no)
				adlar.append(o.ad)
			var h := int(round(int(secilen["hasar"]) * hasar_carpani)) + boss.guc
			n["hedefler"] = hedefler
			n["hasar"] = h
			n["metin"] = "%s -> %s (her birine %d hasar)" % [ad, " ve ".join(adlar), h]
		"alan":
			var h := int(round(int(secilen["hasar"]) * hasar_carpani)) + int(boss.guc / 2.0)
			n["hasar"] = h
			n["metin"] = "%s -> Tüm takım (%d hasar)" % [ad, h]
		"guc":
			n["miktar"] = int(secilen["miktar"])
			n["metin"] = "%s (+%d güç)" % [ad, n["miktar"]]
		"kalkan":
			n["miktar"] = int(secilen["miktar"]) + boss.guc
			n["metin"] = "%s (+%d kalkan)" % [ad, n["miktar"]]
		"iyiles":
			n["miktar"] = int(secilen["miktar"])
			n["metin"] = "%s (+%d can)" % [ad, n["miktar"]]
	boss.niyet = n


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
