class_name Kosu
extends RefCounted
## Bir roguelite koşusunun bütün verisi ve kuralları:
## takımın canı ve desteleri, yol haritası, ödüller, dinlenme ve gizem olayları.
## Arayüzden bağımsızdır, testler bunu doğrudan çalıştırır.

const SINIFLAR: Array[int] = [
	CardData.Sinif.TANK, CardData.Sinif.DESTEK, CardData.Sinif.HASARCI, CardData.Sinif.KONTROLCU,
]
const SINIF_CANLARI := {
	CardData.Sinif.TANK: 60,
	CardData.Sinif.DESTEK: 40,
	CardData.Sinif.HASARCI: 35,
	CardData.Sinif.KONTROLCU: 40,
}
## Haritanın her katmanında çıkabilecek durak tipleri (alttan üste)
const KATMAN_TIPLERI := [
	["savas"],
	["savas", "gizem"],
	["savas", "elit", "dinlenme", "gizem"],
	["savas", "gizem", "elit", "savas"],
	["elit", "savas", "gizem"],
	["dinlenme"],
	["boss"],
]
const GIZEMLER: Array[String] = ["peri_pinari", "kara_ayna", "yasli_munzevi", "eski_sandik"]
const MIN_DESTE := 6

var rng := RandomNumberGenerator.new()
var havuz: Dictionary
## Senin sınıfın (-1: herkes bot, testlerde)
var insan := -1
## Her sınıf için: {"sinif", "can", "max_can", "deste": Array[CardData]}
var takim: Array[Dictionary] = []
## Katmanlar; her durak: {"tip", "katman", "sira", "sonraki": [sira], "ziyaret": bool}
var harita: Array = []
var katman := -1
var sira := -1
var bitti := false
var kazandi := false
var kazanilan_savas := 0
## Zorluk kademesi ve henüz kilidi açılmamış kart/tılsım id'leri
var kademe := 0
var kilitli: Array = []
## Takımın tılsımları (id listesi)
var tilsimlar: Array[String] = []


func _init(p_havuz: Dictionary, p_insan: int, p_kademe: int = 0, p_kilitli: Array = []) -> void:
	rng.randomize()
	havuz = p_havuz
	insan = p_insan
	kademe = p_kademe
	kilitli = p_kilitli
	for s in SINIFLAR:
		var can: int = SINIF_CANLARI[s]
		var baslangic_cani := int(ceil(can * 0.9)) if kademe >= 7 else can
		takim.append({"sinif": s, "can": baslangic_cani, "max_can": can, "deste": baslangic_destesi(havuz, s)})
	_harita_olustur()


static func baslangic_destesi(p_havuz: Dictionary, sinif: int) -> Array[CardData]:
	var d: Array[CardData] = []
	for kart in p_havuz.get(sinif, []):
		if kart.baslangic:
			for i in 2:
				d.append(kart.duplicate())
	return d


func bot_mu(sinif: int) -> bool:
	return sinif != insan


# --- Harita ---------------------------------------------------------------

func _harita_olustur() -> void:
	harita.clear()
	for k in KATMAN_TIPLERI.size():
		var tipler: Array = KATMAN_TIPLERI[k]
		var adet := 1 if k == KATMAN_TIPLERI.size() - 1 else 3
		var dizi: Array = []
		for j in adet:
			dizi.append({
				"tip": tipler[rng.randi_range(0, tipler.size() - 1)],
				"katman": k, "sira": j, "sonraki": [], "ziyaret": false,
			})
		harita.append(dizi)
	# Her durak aynı şeritteki durağa bağlanır, bazen komşu şeride de
	for k in harita.size() - 1:
		var sonraki_katman: Array = harita[k + 1]
		for d in harita[k]:
			if sonraki_katman.size() == 1:
				d["sonraki"] = [0]
				continue
			var bag: Array = [d["sira"]]
			for komsu in [d["sira"] - 1, d["sira"] + 1]:
				if komsu >= 0 and komsu < sonraki_katman.size() and rng.randf() < 0.4:
					bag.append(komsu)
			d["sonraki"] = bag


func gidilebilir() -> Array[Dictionary]:
	var liste: Array[Dictionary] = []
	if katman < 0:
		for d in harita[0]:
			liste.append(d)
	elif katman + 1 < harita.size():
		for j in harita[katman][sira]["sonraki"]:
			liste.append(harita[katman + 1][j])
	return liste


func git(d: Dictionary) -> void:
	katman = d["katman"]
	sira = d["sira"]
	d["ziyaret"] = true


# --- Savaş ----------------------------------------------------------------

func savas_kurulumu(tip: String) -> Dictionary:
	var dusman: String
	match tip:
		"elit":
			dusman = Dusmanlar.ELIT[rng.randi_range(0, Dusmanlar.ELIT.size() - 1)]
		"boss":
			dusman = Dusmanlar.BOSS
		_:
			dusman = Dusmanlar.NORMAL[rng.randi_range(0, Dusmanlar.NORMAL.size() - 1)]
	var liste: Array = []
	for v in takim:
		liste.append({"sinif": v["sinif"], "can": v["can"], "max_can": v["max_can"], "deste": v["deste"]})
	return {"oyuncular": liste, "dusman": dusman, "tilsimlar": tilsimlar.duplicate(), "kademe": kademe}


## Savaş bittikten sonra canları takıma geri yazar. Düşenler çeyrek canla kalkar.
func savas_sonucu(motor: SavasMotoru, tip: String) -> void:
	if motor.boss.can > 0:
		bitti = true
		kazandi = false
		return
	kazanilan_savas += 1
	for o in motor.oyuncular:
		var v := takim[o.no]
		var kalkis := 1 if kademe >= 6 else maxi(1, int(v["max_can"] / 4.0))
		v["can"] = o.can if o.hayatta() else kalkis
		if tilsimlar.has("sifaci_kolyesi"):
			v["can"] = mini(v["max_can"], v["can"] + 8)
	if tip == "boss":
		bitti = true
		kazandi = true


# --- Tılsımlar ------------------------------------------------------------

func tilsim_secenekleri(adet: int = 3) -> Array[String]:
	var aday: Array = Tilsimlar.LISTE.keys().filter(func(id): return not tilsimlar.has(id) and not kilitli.has(id))
	var liste: Array[String] = []
	while liste.size() < adet and not aday.is_empty():
		var i := rng.randi_range(0, aday.size() - 1)
		liste.append(aday[i])
		aday.remove_at(i)
	return liste


func tilsim_ekle(id: String) -> void:
	if id == "" or tilsimlar.has(id):
		return
	tilsimlar.append(id)
	if id == "altin_kase":
		for v in takim:
			v["max_can"] += 8
			v["can"] += 8


# --- Kartlar --------------------------------------------------------------

func deste(sinif: int) -> Array:
	return takim[sinif]["deste"]


func odul_secenekleri(sinif: int) -> Array[CardData]:
	var aday: Array = havuz.get(sinif, []).filter(func(k): return not k.baslangic and not kilitli.has(String(k.id)))
	var liste: Array[CardData] = []
	while liste.size() < 3 and not aday.is_empty():
		var i := rng.randi_range(0, aday.size() - 1)
		liste.append(aday[i])
		aday.remove_at(i)
	return liste


func kart_ekle(sinif: int, kart: CardData) -> void:
	deste(sinif).append(kart.duplicate())


func botlara_odul_ver() -> void:
	for v in takim:
		if bot_mu(v["sinif"]):
			var secenekler := odul_secenekleri(v["sinif"])
			if not secenekler.is_empty():
				kart_ekle(v["sinif"], secenekler[rng.randi_range(0, secenekler.size() - 1)])


func kart_guclendir(sinif: int, indeks: int) -> void:
	var d := deste(sinif)
	d[indeks] = (d[indeks] as CardData).guclendirilmis()


func _rastgele_guclendir(sinif: int) -> void:
	var d := deste(sinif)
	var adaylar: Array[int] = []
	for i in d.size():
		if not (d[i] as CardData).guclendirildi_mi():
			adaylar.append(i)
	if not adaylar.is_empty():
		kart_guclendir(sinif, adaylar[rng.randi_range(0, adaylar.size() - 1)])


func botlar_guclendirsin() -> void:
	for v in takim:
		if bot_mu(v["sinif"]):
			_rastgele_guclendir(v["sinif"])


func kart_cikarilabilir_mi(sinif: int) -> bool:
	return deste(sinif).size() > MIN_DESTE


func kart_cikar(sinif: int, indeks: int) -> void:
	if kart_cikarilabilir_mi(sinif):
		deste(sinif).remove_at(indeks)


## Botlar destelerindeki en verimsiz kartı çıkarır
func botlar_kart_cikarsin() -> void:
	for v in takim:
		if not bot_mu(v["sinif"]) or not kart_cikarilabilir_mi(v["sinif"]):
			continue
		var d := deste(v["sinif"])
		var en_kotu := 0
		var en_kotu_puan := INF
		for i in d.size():
			var k: CardData = d[i]
			var puan := (k.deger + k.ek_deger + 3.0) / (k.mana + 1.0)
			if puan < en_kotu_puan:
				en_kotu_puan = puan
				en_kotu = i
		d.remove_at(en_kotu)


# --- Dinlenme ve gizem ----------------------------------------------------

func dinlenme_orani() -> float:
	return 0.2 if kademe >= 3 else 0.3


func dinlen() -> void:
	for v in takim:
		v["can"] = mini(v["max_can"], v["can"] + int(ceil(v["max_can"] * dinlenme_orani())))


func _herkese_hasar(miktar: int) -> void:
	for v in takim:
		v["can"] = maxi(1, v["can"] - miktar)


func gizem_sec() -> Dictionary:
	var id: String = GIZEMLER[rng.randi_range(0, GIZEMLER.size() - 1)]
	match id:
		"peri_pinari":
			return {"id": id, "baslik": "Peri Pınarı",
				"metin": "Ormanın derinliklerinde, etrafında perilerin dans ettiği ışıl ışıl bir pınar buldunuz.",
				"secenekler": [
					{"id": "ic", "metin": "İç: herkes 12 can iyileşir"},
					{"id": "dilek", "metin": "Pınara altın at, dilek tut: herkes rastgele bir kart kazanır, ama 6 can kaybeder"},
				]}
		"kara_ayna":
			return {"id": id, "baslik": "Kara Ayna",
				"metin": "Terk edilmiş bir kulenin tepesinde duran kapkara bir ayna, size geleceğinizi göstermeyi teklif ediyor.",
				"secenekler": [
					{"id": "bak", "metin": "Bak: herkesin rastgele bir kartı güçlenir, ama herkes 8 can kaybeder"},
					{"id": "gec", "metin": "Arkana bakmadan geç"},
				]}
		"eski_sandik":
			if tilsim_secenekleri(1).is_empty():
				return gizem_sec()
			return {"id": id, "baslik": "Eski Sandık",
				"metin": "Bir mağaranın dibinde paslı zincirlerle bağlı eski bir sandık buldunuz. Kilidin etrafında tuzak mekanizmaları var.",
				"secenekler": [
					{"id": "sandik", "metin": "Zorla aç: rastgele bir tılsım kazanırsınız, ama tuzak herkese 10 hasar verir"},
					{"id": "gec", "metin": "Dokunmadan geç"},
				]}
		_:
			return {"id": "yasli_munzevi", "baslik": "Yaşlı Münzevi",
				"metin": "Mağarasında tek başına yaşayan yaşlı bir münzevi yükünüzü hafifletmeyi teklif ediyor. \"Gereksiz olanı bırak\" diyor.",
				"secenekler": [
					{"id": "fal", "metin": "Bilgeliğini dinle: destenden bir kartı çıkar (botlar da en zayıf kartını çıkarır)", "deste_sec": "cikar"},
					{"id": "gec", "metin": "Teşekkür edip yola devam et"},
				]}


## Seçeneğin etkisini uygular ve sonucu anlatan metni döndürür.
## "fal" seçeneğinde senin kartını arayüz kart_cikar() ile ayrıca çıkarır.
func gizem_uygula(secenek_id: String) -> String:
	match secenek_id:
		"ic":
			for v in takim:
				v["can"] = mini(v["max_can"], v["can"] + 12)
			return "Peri suyu yorgunluğunuzu aldı. Herkes 12 can iyileşti."
		"dilek":
			for v in takim:
				var secenekler := odul_secenekleri(v["sinif"])
				if not secenekler.is_empty():
					kart_ekle(v["sinif"], secenekler[rng.randi_range(0, secenekler.size() - 1)])
			_herkese_hasar(6)
			return "Periler dileğinizi kabul etti ama bedelini aldı. Herkes yeni bir kart kazandı, 6 can kaybetti."
		"bak":
			for v in takim:
				_rastgele_guclendir(v["sinif"])
			_herkese_hasar(8)
			return "Aynadaki görüntü içinizi ürpertti ama güçlendirdi. Herkesin bir kartı güçlendi, herkes 8 can kaybetti."
		"sandik":
			var bulunan := tilsim_secenekleri(1)
			_herkese_hasar(10)
			if bulunan.is_empty():
				return "Sandık boş çıktı ve tuzak çalıştı. Herkes 10 can kaybetti."
			tilsim_ekle(bulunan[0])
			return "Tuzak patladı ama sandıktan bir tılsım çıktı: %s! (%s)" % [Tilsimlar.ad(bulunan[0]), Tilsimlar.aciklama(bulunan[0])]
		"fal":
			botlar_kart_cikarsin()
			return "Münzevi başını salladı. \"Hafiflediniz\" dedi ve mağarasına çekildi."
	return "Yolunuza devam ettiniz."
