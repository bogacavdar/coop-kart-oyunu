class_name Kayit
extends RefCounted
## Koşular arası kalıcı ilerleme: istatistikler, açılan kademe ve kilidi açılan kart/tılsımlar.
## Cihazda user://kayit.json dosyasında tutulur (tarayıcıda tarayıcının deposunda).

const DOSYA := "user://kayit.json"
## Her bu kadar kazanılan savaşta (bütün koşular toplamı) sıradaki kilit açılır
const SAVAS_BASINA_KILIT := 4
## Başta kilitli olan içerik, açılma sırasıyla
const KILIT_SIRASI: Array[Dictionary] = [
	{"tur": "kart", "id": "kontrol_ay_tutulmasi", "ad": "Ağ Oku (Okçu kartı)"},
	{"tur": "tilsim", "id": "mana_kristali", "ad": "Mana Kristali (tılsım)"},
	{"tur": "kart", "id": "hasarci_supernova", "ad": "Ejder Ateşi (Büyücü kartı)"},
	{"tur": "kart", "id": "destek_yenilenme", "ad": "Yenilenme (Şifacı kartı)"},
	{"tur": "tilsim", "id": "savas_borusu", "ad": "Savaş Borusu (tılsım)"},
	{"tur": "kart", "id": "tank_dag_gibi", "ad": "Kale Gibi (Savaşçı kartı)"},
	{"tur": "kart", "id": "kontrol_kader_cizgisi", "ad": "Avcı İşareti (Okçu kartı)"},
	{"tur": "tilsim", "id": "bilge_kitabi", "ad": "Bilge Kitabı (tılsım)"},
	{"tur": "kart", "id": "destek_koruyucu_melek", "ad": "Koruma Büyüsü (Şifacı kartı)"},
	{"tur": "kart", "id": "tank_meydan_okuma", "ad": "Meydan Okuma (Savaşçı kartı)"},
	{"tur": "kart", "id": "hasarci_gunes_patlamasi", "ad": "Ateş Fırtınası (Büyücü kartı)"},
]

var veri := {
	"kosu": 0,
	"zafer": 0,
	"kazanilan_savas": 0,
	"acik_kademe": 0,
	"en_yuksek_zafer_kademesi": -1,
	"acilan": 0,
}


static func yukle() -> Kayit:
	var k := Kayit.new()
	if FileAccess.file_exists(DOSYA):
		var okunan = JSON.parse_string(FileAccess.get_file_as_string(DOSYA))
		if okunan is Dictionary:
			for anahtar in k.veri:
				if okunan.has(anahtar):
					k.veri[anahtar] = int(okunan[anahtar])
	return k


func kaydet() -> void:
	var f := FileAccess.open(DOSYA, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(veri))


func deger(anahtar: String) -> int:
	return int(veri.get(anahtar, 0))


## Henüz kilidi açılmamış kart ve tılsım id'leri
func kilitli_idler() -> Array[String]:
	var liste: Array[String] = []
	for i in range(deger("acilan"), KILIT_SIRASI.size()):
		liste.append(KILIT_SIRASI[i]["id"])
	return liste


## Sıradaki kilide kaç savaş kaldı (hepsi açıksa -1)
func siradaki_kilide_kalan() -> int:
	if deger("acilan") >= KILIT_SIRASI.size():
		return -1
	return (deger("acilan") + 1) * SAVAS_BASINA_KILIT - deger("kazanilan_savas")


## Koşu bitince çağrılır. Neler açıldığını döndürür: {"yeni_kademe": int (-1 yoksa), "acilanlar": [ad]}
func kosu_bitti(kazandi: bool, kademe: int, kazanilan_savas: int, dosyaya_yaz: bool = true) -> Dictionary:
	var sonuc := {"yeni_kademe": -1, "acilanlar": []}
	veri["kosu"] = deger("kosu") + 1
	veri["kazanilan_savas"] = deger("kazanilan_savas") + kazanilan_savas
	if kazandi:
		veri["zafer"] = deger("zafer") + 1
		veri["en_yuksek_zafer_kademesi"] = maxi(deger("en_yuksek_zafer_kademesi"), kademe)
		if kademe >= deger("acik_kademe") and deger("acik_kademe") < Kademe.MAKS:
			veri["acik_kademe"] = mini(kademe + 1, Kademe.MAKS)
			sonuc["yeni_kademe"] = deger("acik_kademe")
	var hedef := mini(KILIT_SIRASI.size(), int(deger("kazanilan_savas") / float(SAVAS_BASINA_KILIT)))
	while deger("acilan") < hedef:
		sonuc["acilanlar"].append(KILIT_SIRASI[deger("acilan")]["ad"])
		veri["acilan"] = deger("acilan") + 1
	if dosyaya_yaz:
		kaydet()
	return sonuc
