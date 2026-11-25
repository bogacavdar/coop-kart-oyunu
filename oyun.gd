extends Control
## Oyunun ana akışı: sınıf seçimi -> yol haritası -> savaş / dinlenme / gizem -> ödül -> ... -> boss.
## Ekranlar burada açılıp kapanır, koşunun verisi Kosu'da tutulur.

const KART_KLASORU := "res://kartlar/veriler"

var havuz: Dictionary
var kosu: Kosu
var aktif_ekran: Control
var sonuc_ekraninda := false
var _son_tip := ""


func _ready() -> void:
	size = Vector2(1280, 720)
	havuz = KartHavuzu.yukle(KART_KLASORU)
	_sinif_secimi_goster()


func _ekrani_degistir(yeni: Control) -> void:
	if aktif_ekran and is_instance_valid(aktif_ekran):
		aktif_ekran.queue_free()
	aktif_ekran = yeni
	add_child(yeni)


# --- Sınıf seçimi ----------------------------------------------------------

func _sinif_secimi_goster() -> void:
	var ekran := Control.new()
	ekran.size = size
	_ekrani_degistir(ekran)
	ekran.add_child(Masa.new())
	var perde := ColorRect.new()
	perde.color = Color(0, 0, 0, 0.55)
	perde.size = size
	ekran.add_child(perde)

	var b := Arayuz.etiket(ekran, 48, "Ejderin İni", Arayuz.ALTIN)
	b.position = Vector2(0, 110)
	b.size = Vector2(1280, 60)
	var a := Arayuz.etiket(ekran, 18,
		"Sınıfını seç. Diğer üç sınıfı bot takım arkadaşların oynayacak. Dağın derinliklerine inin ve Kızıl Ejder'i yenin.",
		Color("#d8d0f0"))
	a.position = Vector2(140, 180)
	a.size = Vector2(1000, 50)
	a.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var aciklamalar := {
		CardData.Sinif.TANK: "Düşmanın saldırılarını üstüne çeker, takımı kalkanıyla korur.",
		CardData.Sinif.DESTEK: "Şifa büyüleriyle takımı iyileştirir ve korur.",
		CardData.Sinif.HASARCI: "Ateş ve buz büyüleriyle düşmanı eritir. Kırılgandır.",
		CardData.Sinif.KONTROLCU: "Düşmanı işaretler, zehirli oklarla zayıflatır, okla yere çiviler.",
	}
	for i in Kosu.SINIFLAR.size():
		var s := Kosu.SINIFLAR[i]
		var renk: Color = CardView.SINIF_RENKLERI[s]
		var ikon_yolu := "res://varliklar/ikonlar/sinif_%d.svg" % s
		var ikon: Texture2D = load(ikon_yolu) if ResourceLoader.exists(ikon_yolu) else null
		var btn := Arayuz.secenek_butonu(CardData.sinif_adi(s), aciklamalar[s], renk, Vector2(240, 250), ikon)
		btn.position = Vector2(120 + i * 270, 270)
		btn.pressed.connect(_kosu_baslat.bind(s))
		ekran.add_child(btn)


	var krediler := Arayuz.buton("Krediler", Vector2(160, 44), Color("#2a2450"), Color("#7a6fd0"), 16)
	krediler.position = Vector2(560, 600)
	krediler.pressed.connect(_kredileri_goster)
	ekran.add_child(krediler)


func _kredileri_goster() -> void:
	var perde := ColorRect.new()
	perde.color = Color(0.02, 0.01, 0.06, 0.95)
	perde.size = size
	perde.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(perde)
	var b := Arayuz.etiket(perde, 34, "Krediler", Arayuz.ALTIN)
	b.position = Vector2(0, 90)
	b.size = Vector2(1280, 44)
	var metin := FileAccess.get_file_as_string("res://KREDILER.txt")
	var l := Arayuz.etiket(perde, 16, metin, Color("#e0d8f0"))
	l.position = Vector2(190, 160)
	l.size = Vector2(900, 400)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var kapat := Arayuz.buton("Kapat", Vector2(180, 48))
	kapat.position = Vector2(550, 600)
	kapat.pressed.connect(perde.queue_free)
	perde.add_child(kapat)


func _kosu_baslat(sinif: int) -> void:
	kosu = Kosu.new(havuz, sinif)
	_haritayi_goster()


# --- Akış ------------------------------------------------------------------

func _haritayi_goster() -> void:
	var h := HaritaEkrani.new(kosu)
	h.dugum_secildi.connect(_dugum_secildi)
	_ekrani_degistir(h)


func _dugum_secildi(d: Dictionary) -> void:
	kosu.git(d)
	_son_tip = d["tip"]
	match _son_tip:
		"savas", "elit", "boss":
			var s := SavasEkrani.new()
			s.savas_bitti.connect(_savas_bitti)
			_ekrani_degistir(s)
			s.baslat(kosu.savas_kurulumu(_son_tip), kosu.insan)
		"dinlenme":
			var e := DinlenmeEkrani.new(kosu)
			e.bitti.connect(_haritayi_goster)
			_ekrani_degistir(e)
		"gizem":
			var e := GizemEkrani.new(kosu)
			e.bitti.connect(_haritayi_goster)
			_ekrani_degistir(e)


func _savas_bitti(motor: SavasMotoru) -> void:
	kosu.savas_sonucu(motor, _son_tip)
	if kosu.bitti:
		_kosu_sonu_goster()
		return
	kosu.botlara_odul_ver()
	var alt := "Bot arkadaşların da kendi ödüllerini seçti."
	if _son_tip == "elit":
		alt = "Elit yenildi: herkesin max canı +5 arttı. " + alt
	var o := OdulEkrani.new(kosu.odul_secenekleri(kosu.insan), alt)
	o.secildi.connect(func(kart: CardData):
		if kart:
			kosu.kart_ekle(kosu.insan, kart)
		_haritayi_goster()
	)
	_ekrani_degistir(o)


func _kosu_sonu_goster() -> void:
	sonuc_ekraninda = true
	var ekran := Control.new()
	ekran.size = size
	_ekrani_degistir(ekran)
	ekran.add_child(Masa.new(false))
	var zafer := kosu.kazandi
	var b := Arayuz.etiket(ekran, 64, "KOŞU KAZANILDI!" if zafer else "KOŞU BİTTİ",
		Color("#5aff8a") if zafer else Color("#ff5a5a"))
	b.position = Vector2(0, 200)
	b.size = Vector2(1280, 80)
	var metin := "Kızıl Ejder yenildi! Ozanlar bu zaferi yıllarca anlatacak." if zafer \
		else "Takım %d. katmanda düştü." % (kosu.katman + 1)
	var a := Arayuz.etiket(ekran, 20, metin + "\nKazanılan savaş: %d" % kosu.kazanilan_savas, Color("#d8d0f0"))
	a.position = Vector2(0, 300)
	a.size = Vector2(1280, 60)
	var yeni := Arayuz.buton("Yeni Koşu", Vector2(240, 60))
	yeni.position = Vector2(520, 420)
	yeni.pressed.connect(func(): get_tree().reload_current_scene())
	ekran.add_child(yeni)


## Arayüz testi için: o anki ekranda bir adım ilerler
func otomatik_adim() -> void:
	if kosu == null:
		_kosu_baslat(CardData.Sinif.DESTEK)
	elif aktif_ekran and is_instance_valid(aktif_ekran) and aktif_ekran.has_method("otomatik_adim"):
		aktif_ekran.otomatik_adim()
