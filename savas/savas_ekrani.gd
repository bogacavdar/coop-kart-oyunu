extends Control
## Savaş ekranı. Şimdilik 4 oyuncuyu tek bilgisayardan sırayla yönetiyorsun:
## aktif oyuncunun elinden manası yettiği kadar kart seç,
## müttefik kartlarında hedef oyuncunun paneline tıkla. Herkes seçince "Turu Oyna".

const KART_KLASORU := "res://kartlar/veriler"

var motor: SavasMotoru
var aktif := 0
var hedef_bekleyen: CardData = null
var oynatiliyor := false

var _boss_panel: PanelContainer
var _boss_ad: Label
var _boss_bar: ProgressBar
var _boss_can: Label
var _boss_durum: Label
var _niyet: Label
var _log: RichTextLabel
var _tur_label: Label
var _bilgi: Label
var _buton: Button
var _paneller: Array[OyuncuPaneli] = []
var _el: HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	motor = SavasMotoru.new(KartHavuzu.yukle(KART_KLASORU))
	_arayuzu_kur()
	_log_yaz("[b]Tur 1[/b] başladı. Boss: %s" % motor.boss.ad)
	_hepsini_guncelle()


# --- Arayüz kurulumu -------------------------------------------------------

func _arayuzu_kur() -> void:
	var arka := ColorRect.new()
	arka.color = Color("#0f0d1a")
	arka.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(arka)

	var kenar := MarginContainer.new()
	kenar.set_anchors_preset(Control.PRESET_FULL_RECT)
	for yon in ["left", "right", "top", "bottom"]:
		kenar.add_theme_constant_override("margin_" + yon, 12)
	add_child(kenar)

	var dikey := VBoxContainer.new()
	dikey.add_theme_constant_override("separation", 8)
	kenar.add_child(dikey)

	# Üst sıra: boss + savaş günlüğü
	var ust := HBoxContainer.new()
	ust.custom_minimum_size = Vector2(0, 170)
	ust.add_theme_constant_override("separation", 12)
	dikey.add_child(ust)

	_boss_panel = PanelContainer.new()
	_boss_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_panel.add_theme_stylebox_override("panel", _kutu_stili(Color("#2a1830"), Color("#8a3a5a")))
	ust.add_child(_boss_panel)

	var boss_v := VBoxContainer.new()
	boss_v.alignment = BoxContainer.ALIGNMENT_CENTER
	_boss_panel.add_child(boss_v)
	_boss_ad = _etiket(boss_v, 24)
	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.custom_minimum_size = Vector2(0, 22)
	_boss_bar.add_theme_stylebox_override("fill", _bar_stili(Color("#c0392b")))
	_boss_bar.add_theme_stylebox_override("background", _bar_stili(Color("#3a2a2a")))
	boss_v.add_child(_boss_bar)
	_boss_can = _etiket(boss_v, 15)
	_boss_durum = _etiket(boss_v, 15)
	_boss_durum.add_theme_color_override("font_color", Color("#c38bff"))
	_niyet = _etiket(boss_v, 18)
	_niyet.add_theme_color_override("font_color", Color("#ffb347"))

	var log_panel := PanelContainer.new()
	log_panel.custom_minimum_size = Vector2(400, 0)
	log_panel.add_theme_stylebox_override("panel", _kutu_stili(Color("#161424"), Color("#33304a")))
	ust.add_child(log_panel)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 13)
	_log.add_theme_font_size_override("bold_font_size", 13)
	log_panel.add_child(_log)

	# Orta sıra: tur, bilgi, buton
	var orta := HBoxContainer.new()
	orta.add_theme_constant_override("separation", 12)
	dikey.add_child(orta)
	_tur_label = _etiket(orta, 20)
	_tur_label.custom_minimum_size = Vector2(90, 0)
	_tur_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_bilgi = _etiket(orta, 16)
	_bilgi.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_bilgi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buton = Button.new()
	_buton.text = "Turu Oyna"
	_buton.custom_minimum_size = Vector2(180, 40)
	_buton.pressed.connect(_turu_oyna)
	orta.add_child(_buton)

	# Oyuncu panelleri
	var sira := HBoxContainer.new()
	sira.add_theme_constant_override("separation", 10)
	dikey.add_child(sira)
	for o in motor.oyuncular:
		var p := OyuncuPaneli.new(o.no, CardView.SINIF_RENKLERI.get(o.sinif, Color.GRAY))
		p.tiklandi.connect(_on_panel_tiklandi)
		sira.add_child(p)
		_paneller.append(p)

	# Aktif oyuncunun eli
	_el = HBoxContainer.new()
	_el.alignment = BoxContainer.ALIGNMENT_CENTER
	_el.add_theme_constant_override("separation", 16)
	_el.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dikey.add_child(_el)


func _etiket(ebeveyn: Control, boyut: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", boyut)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ebeveyn.add_child(l)
	return l


func _kutu_stili(zemin: Color, kenar: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = zemin
	s.border_color = kenar
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	s.set_content_margin_all(10)
	return s


func _bar_stili(renk: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = renk
	s.set_corner_radius_all(4)
	return s


# --- Ekranı güncelleme -----------------------------------------------------

func _hepsini_guncelle() -> void:
	var b := motor.boss
	_boss_ad.text = b.ad
	_boss_bar.max_value = b.max_can
	_boss_bar.value = b.can
	_boss_can.text = "Can: %d / %d" % [b.can, b.max_can]
	_boss_durum.text = b.durum_metni()
	_niyet.text = "Sonraki hamle: " + str(b.niyet.get("metin", ""))
	_tur_label.text = "Tur %d" % motor.tur
	for i in _paneller.size():
		var o := motor.oyuncular[i]
		_paneller[i].guncelle(o, i == aktif and not oynatiliyor, hedef_bekleyen != null, _secim_metni(o))
	_el_guncelle()
	_bilgi_guncelle()
	_buton.disabled = oynatiliyor or motor.bitti


func _secim_metni(o: Oyuncu) -> String:
	if o.secimler.is_empty():
		return "Kart seçilmedi"
	var parcalar: PackedStringArray = []
	for s in o.secimler:
		var metin: String = (s["kart"] as CardData).kart_adi
		if s["hedef"] >= 0:
			metin += " -> " + motor.oyuncular[s["hedef"]].ad
		parcalar.append(metin)
	return ", ".join(parcalar)


func _el_guncelle() -> void:
	for c in _el.get_children():
		_el.remove_child(c)
		c.queue_free()
	if oynatiliyor or motor.bitti:
		return
	var o := motor.oyuncular[aktif]
	if not o.hayatta():
		return
	for kart in o.el:
		var v := CardView.new()
		v.setup(kart)
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var secili := o.secili_mi(kart)
		v.set_secili(secili or kart == hedef_bekleyen)
		if not secili and kart.mana > o.kalan_mana():
			v.modulate = Color(1, 1, 1, 0.4)
		v.card_clicked.connect(_on_kart_tiklandi)
		_el.add_child(v)


func _bilgi_guncelle() -> void:
	if motor.bitti:
		_bilgi.text = ""
	elif oynatiliyor:
		_bilgi.text = "Tur oynanıyor..."
	elif hedef_bekleyen != null:
		_bilgi.text = "%s için hedef seç: bir oyuncu paneline tıkla" % hedef_bekleyen.kart_adi
	elif motor.hepsi_hazir():
		_bilgi.text = "Herkes hazır. Turu Oyna'ya bas."
	else:
		var o := motor.oyuncular[aktif]
		_bilgi.text = "%s kart seçiyor (kalan mana %d). Diğer oyuncuya geçmek için paneline tıkla." % [o.ad, o.kalan_mana()]


# --- Girdiler --------------------------------------------------------------

func _on_kart_tiklandi(v: CardView) -> void:
	if oynatiliyor or motor.bitti:
		return
	var o := motor.oyuncular[aktif]
	var kart := v.data
	# Seçili karta veya hedef bekleyen karta tekrar tıklamak seçimi geri alır
	if kart == hedef_bekleyen:
		hedef_bekleyen = null
		_hepsini_guncelle()
		return
	if o.secili_mi(kart):
		motor.secimi_kaldir(aktif, kart)
		_hepsini_guncelle()
		return
	if kart.mana > o.kalan_mana():
		_bilgi.text = "Yeterli mana yok (%d gerekli, %d kaldı)." % [kart.mana, o.kalan_mana()]
		return
	if kart.hedef == CardData.Hedef.MUTTEFIK:
		hedef_bekleyen = kart
		_hepsini_guncelle()
		return
	hedef_bekleyen = null
	if motor.kart_sec(aktif, kart) and not o.oynayabilir_mi():
		_sonraki_oyuncu()
	_hepsini_guncelle()


func _on_panel_tiklandi(no: int) -> void:
	if oynatiliyor or motor.bitti:
		return
	if hedef_bekleyen != null:
		if motor.kart_sec(aktif, hedef_bekleyen, no):
			hedef_bekleyen = null
			if not motor.oyuncular[aktif].oynayabilir_mi():
				_sonraki_oyuncu()
		_hepsini_guncelle()
		return
	if motor.oyuncular[no].hayatta():
		aktif = no
		_hepsini_guncelle()


func _sonraki_oyuncu() -> void:
	var adet := motor.oyuncular.size()
	for adim in range(1, adet + 1):
		var i := (aktif + adim) % adet
		var o := motor.oyuncular[i]
		if o.hayatta() and o.oynayabilir_mi():
			aktif = i
			return


func _ilk_canli() -> int:
	for o in motor.oyuncular:
		if o.hayatta():
			return o.no
	return 0


# --- Tur oynatma ve animasyon ----------------------------------------------

func _turu_oyna() -> void:
	if oynatiliyor or motor.bitti:
		return
	oynatiliyor = true
	hedef_bekleyen = null
	_hepsini_guncelle()
	var olaylar := motor.turu_coz()
	for olay in olaylar:
		await _olay_oynat(olay)
	oynatiliyor = false
	aktif = _ilk_canli()
	if not motor.bitti:
		_hepsini_guncelle()


func _olay_oynat(olay: Dictionary) -> void:
	var p: OyuncuPaneli = _paneller[olay["oyuncu"]] if olay.has("oyuncu") else null
	match olay["tip"]:
		"kart":
			_log_yaz(olay["metin"])
			_ucan_yazi(olay["kart_adi"], Color.WHITE, p)
			_parlat(p)
			await _bekle(0.45)
		"boss_hasar":
			_boss_bar.value = olay["can"]
			_boss_can.text = "Can: %d / %d" % [olay["can"], motor.boss.max_can]
			_ucan_yazi("-%d" % olay["miktar"], Color("#ff5a5a"), _boss_panel)
			_parlat(_boss_panel)
			await _bekle(0.4)
		"boss_durum":
			_boss_durum.text = olay["durum"]
			_log_yaz("[color=#c38bff]%s[/color]" % olay["metin"])
			_ucan_yazi(olay["metin"], Color("#c38bff"), _boss_panel)
			await _bekle(0.45)
		"zirh":
			p.degerleri_goster(olay["can"], olay["max_can"], olay["zirh"])
			_ucan_yazi("+%d zırh" % olay["miktar"], Color("#6fa8ff"), p)
			await _bekle(0.3)
		"iyilestir":
			p.degerleri_goster(olay["can"], olay["max_can"], olay["zirh"])
			_ucan_yazi("+%d can" % olay["miktar"], Color("#5aff8a"), p)
			await _bekle(0.3)
		"boss_hamle":
			_niyet.text = olay["metin"]
			_log_yaz("[color=#ffb347]%s[/color]" % olay["metin"])
			_parlat(_boss_panel)
			await _bekle(0.6)
		"oyuncu_hasar":
			p.degerleri_goster(olay["can"], olay["max_can"], olay["zirh"])
			_ucan_yazi("-%d" % olay["miktar"], Color("#ff5a5a"), p)
			if olay["emilen"] > 0:
				_ucan_yazi("%d engellendi" % olay["emilen"], Color("#6fa8ff"), p)
			_parlat(p)
			await _bekle(0.4)
		"olum":
			_log_yaz("[color=#ff5a5a]%s[/color]" % olay["metin"])
			p.modulate = Color(1, 1, 1, 0.4)
			await _bekle(0.4)
		"yeni_tur":
			_log_yaz("[b]Tur %d[/b] başladı." % motor.tur)
		"zafer":
			_log_yaz("[color=#5aff8a][b]Boss yenildi![/b][/color]")
			_sonuc_goster(true)
		"yenilgi":
			_log_yaz("[color=#ff5a5a][b]Takım düştü.[/b][/color]")
			_sonuc_goster(false)


func _bekle(sure: float) -> void:
	await get_tree().create_timer(sure).timeout


func _log_yaz(metin: String) -> void:
	_log.append_text(metin + "\n")


func _ucan_yazi(metin: String, renk: Color, hedef: Control) -> void:
	if hedef == null:
		return
	var l := Label.new()
	l.text = metin
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 100
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", renk)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	var merkez := hedef.global_position + hedef.size / 2.0
	l.global_position = merkez + Vector2(randf_range(-70, 10), randf_range(-20, 0))
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 50, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


func _parlat(c: Control) -> void:
	if c == null:
		return
	c.self_modulate = Color(1.8, 1.8, 1.8)
	var tw := c.create_tween()
	tw.tween_property(c, "self_modulate", Color.WHITE, 0.3)


func _sonuc_goster(zafer: bool) -> void:
	_buton.disabled = true
	var perde := ColorRect.new()
	perde.color = Color(0, 0, 0, 0.75)
	perde.set_anchors_preset(Control.PRESET_FULL_RECT)
	perde.mouse_filter = Control.MOUSE_FILTER_STOP
	perde.z_index = 200
	add_child(perde)

	var orta := CenterContainer.new()
	orta.set_anchors_preset(Control.PRESET_FULL_RECT)
	perde.add_child(orta)

	var kutu := VBoxContainer.new()
	kutu.add_theme_constant_override("separation", 20)
	orta.add_child(kutu)

	var baslik := _etiket(kutu, 56)
	baslik.text = "ZAFER!" if zafer else "YENİLDİNİZ"
	baslik.add_theme_color_override("font_color", Color("#5aff8a") if zafer else Color("#ff5a5a"))

	var alt := _etiket(kutu, 20)
	if zafer:
		alt.text = "%s %d turda yenildi." % [motor.boss.ad, motor.tur]
	else:
		alt.text = "Boss'un kalan canı: %d / %d" % [motor.boss.can, motor.boss.max_can]

	var tekrar := Button.new()
	tekrar.text = "Yeniden Başla"
	tekrar.custom_minimum_size = Vector2(220, 50)
	tekrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tekrar.pressed.connect(func(): get_tree().reload_current_scene())
	kutu.add_child(tekrar)
