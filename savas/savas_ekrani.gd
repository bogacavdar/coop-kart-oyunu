class_name SavasEkrani
extends Control
## Savaş ekranı: masanın ortasında düşman, etrafında 4 koltuk.
## Sen alttaki koltuktasın, diğer 3 sınıfı botlar oynar.
## Botlar tur başında planlarını yapar ve koltuklarının altında gösterir,
## sen de onlara göre kartlarını seçersin.

signal savas_bitti(motor: SavasMotoru)

const BOSS_MERKEZI := Vector2(640, 285)
## Koltukların portre merkezleri: alt (sen), sol, üst, sağ
const KOLTUK_MERKEZLERI: Array[Vector2] = [
	Vector2(498, 520), Vector2(150, 285), Vector2(640, 64), Vector2(1130, 285),
]
const EL_Y := 668.0
const EL_ARALIK := 132.0
const EL_OLCEK := 0.72

var motor: SavasMotoru
var insan := 0
var hedef_bekleyen: CardData = null
var oynatiliyor := false

var _boss: BossGorunumu
var _boss_ad: Label
var _boss_bar: ProgressBar
var _boss_can: Label
var _boss_durum: Label
var _niyet_kutu: PanelContainer
var _niyet: Label
var _log: RichTextLabel
var _tur_label: Label
var _bilgi: Label
var _buton: Button
var _koltuklar: Array[Koltuk] = []
var _el_katmani: Control
var _efekt_katmani: Control
var _hedef_bandi: PanelContainer
var _hedef_yazisi: Label


func _ready() -> void:
	size = Vector2(1280, 720)
	add_child(Masa.new())


## Oyun akışı savaşı buradan başlatır
func baslat(kurulum: Dictionary, p_insan: int) -> void:
	insan = p_insan
	motor = SavasMotoru.new(kurulum)
	_arayuzu_kur()
	_log_yaz("[b]Tur 1[/b] başladı. Rakip: %s" % motor.boss.ad)
	for m in motor.baslangic_mesajlari:
		_log_yaz("[color=#e8c27a]%s[/color]" % m)
	if not motor.tilsimlar.is_empty():
		var serit := Tilsimlar.serit(motor.tilsimlar, 34.0)
		serit.position = Vector2(20, 140)
		add_child(serit)
	_botlari_planla()
	_hepsini_guncelle()


## Arayüz testi için: senin yerine bot gibi oynar
func otomatik_adim() -> void:
	if motor == null or oynatiliyor or motor.bitti:
		return
	var o := motor.oyuncular[insan]
	if o.hayatta():
		Bot.planla(motor, o)
	_turu_oyna()


# --- Arayüz kurulumu -------------------------------------------------------

func _arayuzu_kur() -> void:
	_boss = BossGorunumu.new()
	add_child(_boss)
	_boss.ayarla(motor.boss.gorunum)
	_boss.yerlestir(BOSS_MERKEZI)

	var boss_alani := Control.new()
	boss_alani.position = BOSS_MERKEZI - Vector2(150, 110)
	boss_alani.size = Vector2(300, 200)
	add_child(boss_alani)
	Ipucu.baglan(boss_alani, _boss_ipucu)

	_boss_ad = _etiket_at(Rect2(440, 386, 400, 30), 24)
	_boss_ad.add_theme_color_override("font_color", Color("#e8c27a"))
	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.position = Vector2(500, 420)
	_boss_bar.size = Vector2(280, 16)
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar.add_theme_stylebox_override("fill", _bar_stili(Color("#c0392b")))
	_boss_bar.add_theme_stylebox_override("background", _bar_stili(Color(0, 0, 0, 0.6)))
	add_child(_boss_bar)
	_boss_can = _etiket_at(Rect2(440, 437, 400, 20), 14)
	_boss_durum = _etiket_at(Rect2(440, 456, 400, 20), 14)
	_boss_durum.add_theme_color_override("font_color", Color("#c38bff"))

	# Niyet balonu
	_niyet_kutu = PanelContainer.new()
	_niyet_kutu.position = Vector2(790, 150)
	_niyet_kutu.mouse_filter = Control.MOUSE_FILTER_STOP
	Ipucu.baglan(_niyet_kutu, _niyet_ipucu)
	_niyet_kutu.add_theme_stylebox_override("panel", _kutu_stili(Color(0.1, 0.05, 0.02, 0.85), Color("#ffb347")))
	add_child(_niyet_kutu)
	Arayuz.susle(_niyet_kutu, Color("#ffb347"), Arayuz.PANEL_CERCEVESI, -6.0)
	_niyet = Label.new()
	_niyet.custom_minimum_size = Vector2(210, 0)
	_niyet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_niyet.add_theme_font_size_override("font_size", 15)
	_niyet.add_theme_color_override("font_color", Color("#ffb347"))
	_niyet_kutu.add_child(_niyet)

	# Koltuklar
	for o in motor.oyuncular:
		var k := Koltuk.new(o.no, CardView.SINIF_RENKLERI.get(o.sinif, Color.GRAY), o.no == insan)
		k.tiklandi.connect(_on_koltuk_tiklandi)
		add_child(k)
		k.merkeze_yerlestir(KOLTUK_MERKEZLERI[(o.no - insan + 4) % 4])
		_koltuklar.append(k)

	# Sol üst: tur ve bilgi
	_tur_label = _etiket_at(Rect2(20, 10, 200, 34), 26)
	_tur_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_bilgi = _etiket_at(Rect2(20, 46, 330, 90), 15)
	_bilgi.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_bilgi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Sol alt: savaş günlüğü
	var log_panel := PanelContainer.new()
	log_panel.position = Vector2(14, 585)
	log_panel.size = Vector2(250, 122)
	log_panel.add_theme_stylebox_override("panel", _kutu_stili(Color(0.05, 0.04, 0.1, 0.8), Color("#3a3360")))
	add_child(log_panel)
	Arayuz.susle(log_panel, Color("#8a7fd0"), Arayuz.PANEL_CERCEVESI, -6.0)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 12)
	_log.add_theme_font_size_override("bold_font_size", 12)
	log_panel.add_child(_log)

	# Sağ alt: tur bitirme butonu
	_buton = Button.new()
	_buton.text = "Turu Oyna"
	_buton.position = Vector2(1050, 610)
	_buton.size = Vector2(210, 70)
	_buton.add_theme_font_size_override("font_size", 22)
	_buton.add_theme_stylebox_override("normal", _kutu_stili(Color("#5c4720"), Color("#e8c27a")))
	_buton.add_theme_stylebox_override("hover", _kutu_stili(Color("#7a5f2a"), Color("#ffe39a")))
	_buton.add_theme_stylebox_override("pressed", _kutu_stili(Color("#3d2f15"), Color("#e8c27a")))
	_buton.add_theme_stylebox_override("disabled", _kutu_stili(Color("#2a2418"), Color("#5c4720")))
	_buton.pressed.connect(_turu_oyna)
	Ipucu.baglan(_buton, func(): return Ipucu.SOZLUK["sira"])
	add_child(_buton)
	Arayuz.susle(_buton, Color("#ffe39a"), Arayuz.BUTON_CERCEVESI, 4.0)

	# Hedef seçme bandı (müttefik kartı seçilince görünür)
	_hedef_bandi = PanelContainer.new()
	_hedef_bandi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hedef_bandi.add_theme_stylebox_override("panel", _kutu_stili(Color(0.02, 0.12, 0.06, 0.92), Color("#7dffa0")))
	_hedef_bandi.z_index = 60
	_hedef_bandi.visible = false
	add_child(_hedef_bandi)
	Arayuz.susle(_hedef_bandi, Color("#7dffa0"), Arayuz.PANEL_CERCEVESI, -6.0)
	_hedef_yazisi = Label.new()
	_hedef_yazisi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hedef_yazisi.add_theme_font_size_override("font_size", 19)
	_hedef_yazisi.add_theme_color_override("font_color", Color("#c8ffd8"))
	_hedef_bandi.add_child(_hedef_yazisi)

	_el_katmani = Control.new()
	_el_katmani.size = Vector2(1280, 720)
	_el_katmani.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_el_katmani)

	_efekt_katmani = Control.new()
	_efekt_katmani.size = Vector2(1280, 720)
	_efekt_katmani.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_efekt_katmani.z_index = 100
	add_child(_efekt_katmani)


func _boss_ipucu() -> String:
	if motor == null:
		return ""
	var b := motor.boss
	var unvan := {"normal": "Düşman", "elit": "Elit düşman", "boss": "Boss"}
	var satirlar: PackedStringArray = ["[b]%s[/b]  ·  %s  ·  Can %d/%d" % [b.ad, unvan.get(b.tip, ""), b.can, b.max_can]]
	if b.zirh > 0:
		satirlar.append(Ipucu.SOZLUK["kalkan"])
	if b.guc > 0:
		satirlar.append(Ipucu.SOZLUK["guc"])
	if b.isaret > 0:
		satirlar.append(Ipucu.SOZLUK["isaret"])
	if b.zayiflik > 0:
		satirlar.append(Ipucu.SOZLUK["zayif"])
	if b.sersem or b.bagisik:
		satirlar.append(Ipucu.SOZLUK["sersem"])
	if motor.tur > SavasMotoru.OFKE_TURU:
		satirlar.append(Ipucu.SOZLUK["ofke"])
	satirlar.append("Sağdaki turuncu balon bir sonraki hamlesini gösterir.")
	return "\n".join(satirlar)


func _niyet_ipucu() -> String:
	if motor == null:
		return ""
	var aciklama := {
		"tekil": "Tek bir oyuncuya vurur. Savaşçının dikkat çeken kartları bu saldırıyı üstüne alır; zırh hasarı azaltır.",
		"cift": "Aynı anda iki oyuncuya vurur. İkisine de zırh vermek iyi bir fikir.",
		"alan": "Bütün takıma vurur. Takıma zırh ya da can veren kartlar burada parlar.",
		"guc": "Kalıcı olarak güçlenir. Bu tur saldırmayacak: düşmana yüklenme zamanı!",
		"kalkan": "Kendine kalkan kazanır. Kalkan bir sonraki turunuzda vuruşlarınızı emer.",
		"iyiles": "Kendini iyileştirir. Bu tur saldırmayacak: düşmana yüklenme zamanı!",
		"emme": "Tek bir oyuncuya vurur ve verdiği hasar kadar iyileşir. Zırh hem hasarı hem iyileşmeyi azaltır.",
	}
	var tur: String = motor.boss.niyet.get("tur", "")
	var metin := "[b]Sıradaki hamle[/b]\n" + str(aciklama.get(tur, ""))
	if tur in ["tekil", "cift", "alan", "emme"]:
		metin += "\n" + Ipucu.SOZLUK["zayif"]
	return metin


func _etiket(ebeveyn: Control, boyut: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", boyut)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ebeveyn.add_child(l)
	return l


func _etiket_at(alan: Rect2, boyut: int) -> Label:
	var l := _etiket(self, boyut)
	l.position = alan.position
	l.size = alan.size
	return l


func _kutu_stili(zemin: Color, kenar: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = zemin
	s.border_color = kenar
	s.set_border_width_all(2)
	s.set_corner_radius_all(12)
	s.set_content_margin_all(10)
	return s


func _bar_stili(renk: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = renk
	s.set_corner_radius_all(5)
	return s


# --- Ekranı güncelleme -----------------------------------------------------

func _botlari_planla() -> void:
	for o in motor.oyuncular:
		if o.no != insan and o.hayatta():
			Bot.planla(motor, o)


func _hepsini_guncelle() -> void:
	var b := motor.boss
	var unvan := {"elit": "ELİT · ", "boss": "BOSS · "}
	_boss_ad.text = unvan.get(b.tip, "") + b.ad
	_boss_bar.max_value = b.max_can
	_boss_bar.value = b.can
	_boss_can.text = "Can: %d / %d" % [b.can, b.max_can]
	_boss_durum.text = b.durum_metni()
	_niyet.text = "Sonraki hamle:\n" + str(b.niyet.get("metin", ""))
	_niyet_kutu.visible = not motor.bitti
	_tur_label.text = "Tur %d" % motor.tur
	for o in motor.oyuncular:
		_koltuklar[o.no].guncelle(o, o.no == insan, hedef_bekleyen != null, _plan_metni(o))
	_el_guncelle()
	_bilgi_guncelle()
	_hedef_bandi_guncelle()
	_buton.disabled = oynatiliyor or motor.bitti


func _hedef_bandi_guncelle() -> void:
	_hedef_bandi.visible = hedef_bekleyen != null and not oynatiliyor
	if not _hedef_bandi.visible:
		return
	var ne := "zırh" if hedef_bekleyen.etki == CardData.Etki.ZIRH else "can"
	_hedef_yazisi.text = "%s: kime %s vereceksin?\nYeşil parlayan bir koltuğa tıkla  (iptal: sağ tık)" % [hedef_bekleyen.kart_adi, ne]
	_hedef_bandi.reset_size()
	_hedef_bandi.position = Vector2(640, 182) - _hedef_bandi.size / 2.0


func _plan_metni(o: Oyuncu) -> String:
	if o.secimler.is_empty():
		return "Kart seç" if o.no == insan else "Plan: pas"
	var parcalar: PackedStringArray = []
	for s in o.secimler:
		var metin: String = (s["kart"] as CardData).kart_adi
		if s["hedef"] >= 0:
			metin += " -> " + motor.oyuncular[s["hedef"]].ad
		parcalar.append(metin)
	return ("Seçim: " if o.no == insan else "Plan: ") + ", ".join(parcalar)


func _el_guncelle() -> void:
	for c in _el_katmani.get_children():
		_el_katmani.remove_child(c)
		c.queue_free()
	if oynatiliyor or motor.bitti:
		return
	var o := motor.oyuncular[insan]
	if not o.hayatta():
		return
	var n := o.el.size()
	for i in n:
		var kart := o.el[i]
		var v := CardView.new()
		v.setup(kart)
		var secili := o.secili_mi(kart) or kart == hedef_bekleyen
		v.set_secili(secili)
		if not o.secili_mi(kart) and kart.mana > o.kalan_mana():
			v.modulate = Color(0.55, 0.55, 0.6)
		var kayma := i - (n - 1) / 2.0
		var merkez := Vector2(640 + kayma * EL_ARALIK, EL_Y + kayma * kayma * 6 - (34.0 if secili else 0.0))
		v.temel_z = i
		v.z_index = i
		v.card_clicked.connect(_on_kart_tiklandi)
		_el_katmani.add_child(v)
		v.yerlestir(merkez, EL_OLCEK, kayma * 0.05, 120.0)


func _bilgi_guncelle() -> void:
	var o := motor.oyuncular[insan]
	if motor.bitti:
		_bilgi.text = ""
	elif oynatiliyor:
		_bilgi.text = "Tur oynanıyor..."
	elif hedef_bekleyen != null:
		_bilgi.text = "%s için hedef seç: bir koltuğa tıkla." % hedef_bekleyen.kart_adi
	elif not o.hayatta():
		_bilgi.text = "Düştün. Botlar savaşmaya devam ediyor, Turu Oyna'ya bas."
	elif not o.oynayabilir_mi():
		_bilgi.text = "Hazırsın. Turu Oyna'ya bas."
	else:
		_bilgi.text = "Kart seç (kalan mana %d). Bot arkadaşlarının planı koltuklarının altında yazıyor." % o.kalan_mana()


# --- Girdiler --------------------------------------------------------------

func _on_kart_tiklandi(v: CardView) -> void:
	if oynatiliyor or motor.bitti:
		return
	var o := motor.oyuncular[insan]
	var kart := v.data
	if kart == hedef_bekleyen:
		hedef_bekleyen = null
		_hepsini_guncelle()
		return
	if o.secili_mi(kart):
		motor.secimi_kaldir(insan, kart)
		_hepsini_guncelle()
		return
	if kart.mana > o.kalan_mana():
		_bilgi.text = "Yeterli mana yok (%d gerekli, %d kaldı)." % [kart.mana, o.kalan_mana()]
		return
	Ses.cal(self, "sec")
	if kart.hedef == CardData.Hedef.MUTTEFIK:
		hedef_bekleyen = kart
		_hepsini_guncelle()
		return
	hedef_bekleyen = null
	motor.kart_sec(insan, kart)
	_hepsini_guncelle()


func _unhandled_input(event: InputEvent) -> void:
	if hedef_bekleyen == null:
		return
	var iptal := event.is_action_pressed("ui_cancel")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		iptal = true
	if iptal:
		hedef_bekleyen = null
		_hepsini_guncelle()
		get_viewport().set_input_as_handled()


func _on_koltuk_tiklandi(no: int) -> void:
	if oynatiliyor or motor.bitti or hedef_bekleyen == null:
		return
	if motor.kart_sec(insan, hedef_bekleyen, no):
		Ses.cal(self, "sec", -4.0, 1.2)
		hedef_bekleyen = null
	_hepsini_guncelle()


# --- Tur oynatma ve animasyon ----------------------------------------------

func _turu_oyna() -> void:
	if oynatiliyor or motor.bitti:
		return
	oynatiliyor = true
	hedef_bekleyen = null
	Ipucu.gizle()
	Ses.cal(self, "tikla")
	_hepsini_guncelle()
	var olaylar := motor.turu_coz()
	for olay in olaylar:
		await _olay_oynat(olay)
	oynatiliyor = false
	if not motor.bitti:
		_botlari_planla()
		_hepsini_guncelle()


func _olay_oynat(olay: Dictionary) -> void:
	var k: Koltuk = _koltuklar[olay["oyuncu"]] if olay.has("oyuncu") else null
	match olay["tip"]:
		"kart":
			Ses.cal(self, "kart")
			_log_yaz(olay["metin"])
			_ucan_kart(olay["kart"], k.portre_merkezi())
			k.parlat()
			await _bekle(0.55)
		"boss_hasar":
			_boss_bar.value = olay["can"]
			_boss_can.text = "Can: %d / %d" % [olay["can"], motor.boss.max_can]
			_boss_durum.text = olay["durum"]
			_boss.vur()
			Ses.cal(self, "vurus")
			_ucan_yazi("-%d" % olay["miktar"], Color("#ff5a5a"), BOSS_MERKEZI, 34)
			if olay["emilen"] > 0:
				_ucan_yazi("%d kalkana çarptı" % olay["emilen"], Color("#9fc8ff"), BOSS_MERKEZI + Vector2(0, 40), 16)
			await _bekle(0.35)
		"boss_iyiles":
			Ses.cal(self, "sifa", -4.0, 0.7)
			_boss_bar.value = olay["can"]
			_boss_can.text = "Can: %d / %d" % [olay["can"], motor.boss.max_can]
			_ucan_yazi("+%d can" % olay["miktar"], Color("#5aff8a"), BOSS_MERKEZI, 30)
			await _bekle(0.4)
		"boss_durum":
			_boss_durum.text = olay["durum"]
			Ses.cal(self, "buyu")
			_log_yaz("[color=#c38bff]%s[/color]" % olay["metin"])
			_ucan_yazi(olay["metin"], Color("#c38bff"), BOSS_MERKEZI + Vector2(0, -70), 20)
			await _bekle(0.5)
		"zirh":
			k.degerleri_goster(olay["can"], olay["max_can"], olay["zirh"])
			Ses.cal(self, "zirh", -8.0)
			_ucan_yazi("+%d zırh" % olay["miktar"], Color("#6fa8ff"), k.portre_merkezi(), 22)
			await _bekle(0.3)
		"iyilestir":
			k.degerleri_goster(olay["can"], olay["max_can"], olay["zirh"])
			Ses.cal(self, "sifa", -8.0)
			_ucan_yazi("+%d can" % olay["miktar"], Color("#5aff8a"), k.portre_merkezi(), 22)
			await _bekle(0.3)
		"boss_hamle":
			_niyet.text = olay["metin"]
			_log_yaz("[color=#ffb347]%s[/color]" % olay["metin"])
			_boss.saldir()
			Ses.cal(self, "kukreme", -2.0)
			await _bekle(0.5)
		"oyuncu_hasar":
			await _mermi(BOSS_MERKEZI, k.portre_merkezi())
			Ses.cal(self, "darbe")
			k.degerleri_goster(olay["can"], olay["max_can"], olay["zirh"])
			k.parlat()
			_ucan_yazi("-%d" % olay["miktar"], Color("#ff5a5a"), k.portre_merkezi(), 30)
			if olay["emilen"] > 0:
				_ucan_yazi("%d engellendi" % olay["emilen"], Color("#6fa8ff"), k.portre_merkezi() + Vector2(0, 34), 16)
			await _bekle(0.25)
		"olum":
			_log_yaz("[color=#ff5a5a]%s[/color]" % olay["metin"])
			k.dus()
			await _bekle(0.4)
		"yeni_tur":
			_log_yaz("[b]Tur %d[/b] başladı." % motor.tur)
		"zafer":
			_log_yaz("[color=#5aff8a][b]%s yenildi![/b][/color]" % motor.boss.ad)
			_boss.ol()
			Ses.cal(self, "zafer", 0.0)
			await _sonuc_goster(true)
		"yenilgi":
			_log_yaz("[color=#ff5a5a][b]Takım düştü.[/b][/color]")
			Ses.cal(self, "yenilgi", 0.0)
			await _sonuc_goster(false)


func _bekle(sure: float) -> void:
	await get_tree().create_timer(sure).timeout


func _log_yaz(metin: String) -> void:
	_log.append_text(metin + "\n")


## Oynanan kart koltuktan masanın ortasına uçar ve kaybolur
func _ucan_kart(kart: CardData, kaynak: Vector2) -> void:
	var v := CardView.new()
	v.setup(kart)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_efekt_katmani.add_child(v)
	v.yerlestir(kaynak, 0.3)
	var hedef := BOSS_MERKEZI + Vector2(randf_range(-60, 60), 10) - v.size / 2.0
	var tw := v.create_tween()
	tw.set_parallel()
	tw.tween_property(v, "position", hedef, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(v, "scale", Vector2.ONE * 0.55, 0.3)
	tw.chain().tween_property(v, "modulate:a", 0.0, 0.3).set_delay(0.3)
	tw.chain().tween_callback(v.queue_free)


## Boss'tan oyuncuya giden ateş topu
func _mermi(bas: Vector2, son: Vector2) -> void:
	var m := Panel.new()
	m.size = Vector2(26, 26)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#ffb347")
	s.set_corner_radius_all(13)
	s.shadow_color = Color(1, 0.4, 0.1, 0.8)
	s.shadow_size = 10
	m.add_theme_stylebox_override("panel", s)
	_efekt_katmani.add_child(m)
	m.position = bas - m.size / 2.0
	var tw := m.create_tween()
	tw.tween_property(m, "position", son - m.size / 2.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	m.queue_free()


func _ucan_yazi(metin: String, renk: Color, konum: Vector2, boyut: int) -> void:
	var l := Label.new()
	l.text = metin
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", boyut)
	l.add_theme_color_override("font_color", renk)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 7)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(300, boyut + 10)
	_efekt_katmani.add_child(l)
	l.position = konum - l.size / 2.0 + Vector2(randf_range(-25, 25), randf_range(-10, 5))
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 55, 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.45)
	tw.chain().tween_callback(l.queue_free)


func _sonuc_goster(zafer: bool) -> void:
	_buton.disabled = true
	_niyet_kutu.visible = false
	var perde := ColorRect.new()
	perde.color = Color(0, 0, 0, 0.0)
	perde.size = Vector2(1280, 720)
	perde.mouse_filter = Control.MOUSE_FILTER_STOP
	perde.z_index = 300
	add_child(perde)
	var baslik := Arayuz.etiket(perde, 72, "ZAFER!" if zafer else "YENİLDİNİZ",
		Color("#5aff8a") if zafer else Color("#ff5a5a"))
	baslik.position = Vector2(0, 300)
	baslik.size = Vector2(1280, 100)
	baslik.add_theme_constant_override("outline_size", 10)
	var tw := perde.create_tween()
	tw.tween_property(perde, "color:a", 0.6, 0.4)
	await _bekle(1.8)
	savas_bitti.emit(motor)
