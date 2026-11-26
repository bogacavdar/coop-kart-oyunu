class_name HaritaEkrani
extends Control
## Yol haritası: alttan yukarı 7 katman, en üstte boss.
## Gidilebilecek duraklar parlar; birine tıklayınca oraya gidilir.

signal dugum_secildi(d: Dictionary)

const TIP_BILGI := {
	"savas": ["Savaş", Color("#c0504a")],
	"elit": ["Elit", Color("#e08a2e")],
	"dinlenme": ["Dinlen", Color("#3fae6a")],
	"gizem": ["?", Color("#9a5bd1")],
	"boss": ["BOSS", Color("#e8c27a")],
}

const DURAK_ACIKLAMALARI := {
	"savas": "[b]Savaş[/b]\nNormal bir düşmanla karşılaşırsınız. Kazanınca destene bir kart seçersin.",
	"elit": "[b]Elit Savaş[/b]\nÇok daha güçlü bir düşman. Kazanınca 3 tılsımdan birini ve bir kart seçersin.",
	"dinlenme": "[b]Kamp Ateşi[/b]\nYa takım dinlenip iyileşir ya da bir kartını kalıcı olarak güçlendirirsin.",
	"gizem": "[b]Gizemli Olay[/b]\nRastgele bir olay. İyi de olabilir, bedeli olan bir fırsat da.",
	"boss": "[b]Bölüm Boss'u[/b]\n1. bölümde Kızıl Ejder, 2. bölümde Lich Kral. Savaş uzadıkça öfkelenirler.",
}

var kosu: Kosu
var _konumlar := {}
var _cizgiler: Control


func _init(p_kosu: Kosu) -> void:
	kosu = p_kosu
	size = Vector2(1280, 720)


func _ready() -> void:
	add_child(Masa.new(false))

	var baslik := Arayuz.etiket(self, 30, "Bölüm %d: %s" % [kosu.bolum, Kosu.bolum_adi(kosu.bolum)], Arayuz.ALTIN)
	baslik.position = Vector2(20, 14)
	baslik.size = Vector2(500, 40)
	var kademe_etiketi := Arayuz.etiket(self, 18, Kademe.baslik(kosu.kademe), Color("#ff9a7a"))
	kademe_etiketi.position = Vector2(1040, 20)
	kademe_etiketi.size = Vector2(220, 30)
	kademe_etiketi.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kademe_etiketi.mouse_filter = Control.MOUSE_FILTER_STOP
	Ipucu.baglan(kademe_etiketi, func(): return "[b]%s[/b]\n%s" % [Kademe.baslik(kosu.kademe), Kademe.tum_kurallar(kosu.kademe)])
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var alt := Arayuz.etiket(self, 14, "Parlayan duraklardan birini seç.", Color("#c8c0e0"))
	alt.position = Vector2(20, 54)
	alt.size = Vector2(300, 20)
	alt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	_takim_paneli()
	_lejant()

	# Durak konumları
	for k in kosu.harita.size():
		var katman: Array = kosu.harita[k]
		for d in katman:
			var x: float = 640.0 + (d["sira"] - (katman.size() - 1) / 2.0) * 220.0
			if katman.size() > 1:
				x += sin(k * 1.7 + d["sira"] * 2.3) * 28.0
			_konumlar[Vector2i(k, d["sira"])] = Vector2(x, 655.0 - k * 95.0)

	_cizgiler = Control.new()
	_cizgiler.size = size
	_cizgiler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cizgiler.draw.connect(_cizgileri_ciz)
	add_child(_cizgiler)

	var gidilebilir := {}
	for d in kosu.gidilebilir():
		gidilebilir[Vector2i(d["katman"], d["sira"])] = true

	for k in kosu.harita.size():
		for d in kosu.harita[k]:
			var anahtar := Vector2i(k, d["sira"])
			_durak_ekle(d, _konumlar[anahtar], gidilebilir.has(anahtar))


func _durak_ekle(d: Dictionary, merkez: Vector2, acik: bool) -> void:
	var bilgi: Array = TIP_BILGI[d["tip"]]
	var renk: Color = bilgi[1]
	var boss: bool = d["tip"] == "boss"
	var cap := 96.0 if boss else 66.0
	var b := Button.new()
	b.text = bilgi[0]
	b.size = Vector2(cap, cap)
	b.position = merkez - b.size / 2.0
	b.pivot_offset = b.size / 2.0
	b.add_theme_font_size_override("font_size", 22 if boss else 16)
	b.add_theme_color_override("font_color", Color.WHITE)
	var yaricap := int(cap / 2)
	var zemin := renk.darkened(0.15) if d["ziyaret"] else renk.darkened(0.6)
	var kenar := Color.GOLD if acik else renk
	b.add_theme_stylebox_override("normal", Arayuz.kutu_stili(zemin, kenar, 4 if acik else 2, yaricap))
	b.add_theme_stylebox_override("hover", Arayuz.kutu_stili(renk.darkened(0.3), Color("#ffe39a"), 5, yaricap))
	b.add_theme_stylebox_override("pressed", Arayuz.kutu_stili(renk, Color.GOLD, 5, yaricap))
	b.add_theme_stylebox_override("disabled", Arayuz.kutu_stili(zemin, kenar, 2, yaricap))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.disabled = not acik
	if not acik and not d["ziyaret"]:
		b.modulate = Color(1, 1, 1, 0.45)
	if acik:
		var tw := b.create_tween().set_loops()
		tw.tween_property(b, "scale", Vector2.ONE * 1.1, 0.5)
		tw.tween_property(b, "scale", Vector2.ONE, 0.5)
		b.pressed.connect(func():
			Ses.cal(b, "tikla")
			dugum_secildi.emit(d)
		)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	Ipucu.baglan(b, func(): return DURAK_ACIKLAMALARI[d["tip"]])
	add_child(b)


func _cizgileri_ciz() -> void:
	for k in kosu.harita.size() - 1:
		for d in kosu.harita[k]:
			var bas: Vector2 = _konumlar[Vector2i(k, d["sira"])]
			for j in d["sonraki"]:
				var son: Vector2 = _konumlar[Vector2i(k + 1, j)]
				var gecildi: bool = d["ziyaret"] and kosu.harita[k + 1][j]["ziyaret"]
				var renk := Color(0.95, 0.8, 0.45, 0.95) if gecildi else Color(0.8, 0.7, 0.5, 0.3)
				_cizgiler.draw_dashed_line(bas, son, renk, 4.0 if gecildi else 2.0, 9.0)


func _takim_paneli() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 100)
	var panel_stili := Arayuz.kutu_stili(Color(0.06, 0.04, 0.12, 0.85), Color("#3a3360"))
	panel_stili.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_stili)
	add_child(panel)
	Arayuz.susle(panel, Color("#b8a060"), Arayuz.PANEL_CERCEVESI, -6.0)
	var dikey := VBoxContainer.new()
	dikey.add_theme_constant_override("separation", 8)
	panel.add_child(dikey)
	Arayuz.etiket(dikey, 18, "Takım", Arayuz.ALTIN).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	for v in kosu.takim:
		var s: int = v["sinif"]
		var renk: Color = CardView.SINIF_RENKLERI[s]
		var satir := Arayuz.etiket(dikey, 15, "%s%s   %d/%d can · %d kart" % [
			CardData.sinif_adi(s), " (Sen)" if s == kosu.insan else "",
			v["can"], v["max_can"], (v["deste"] as Array).size()], renk.lightened(0.35))
		satir.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(230, 8)
		bar.max_value = v["max_can"]
		bar.value = v["can"]
		var dolgu := StyleBoxFlat.new()
		dolgu.bg_color = Color("#3fae6a")
		bar.add_theme_stylebox_override("fill", dolgu)
		dikey.add_child(bar)

	var deste_btn := Arayuz.buton("Desteni Gör", Vector2(230, 42), Color("#2a2450"), Color("#7a6fd0"), 16)
	deste_btn.pressed.connect(func():
		add_child(DesteSecici.new("Destenin kartları", kosu.deste(kosu.insan)))
	)
	dikey.add_child(deste_btn)
	if not kosu.tilsimlar.is_empty():
		Arayuz.etiket(dikey, 15, "Tılsımlar", Arayuz.ALTIN).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		dikey.add_child(Tilsimlar.serit(kosu.tilsimlar, 34.0))
	var savas := Arayuz.etiket(dikey, 13, "Kazanılan savaş: %d" % kosu.kazanilan_savas, Color("#a8a0c0"))
	savas.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _lejant() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(1040, 100)
	var panel_stili := Arayuz.kutu_stili(Color(0.06, 0.04, 0.12, 0.85), Color("#3a3360"))
	panel_stili.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_stili)
	add_child(panel)
	Arayuz.susle(panel, Color("#b8a060"), Arayuz.PANEL_CERCEVESI, -6.0)
	var dikey := VBoxContainer.new()
	panel.add_child(dikey)
	var aciklamalar := {
		"savas": "Savaş: normal düşman",
		"elit": "Elit: zor, ödülü tılsım",
		"dinlenme": "Dinlen: can veya kart güçlendir",
		"gizem": "?: rastgele olay",
		"boss": "BOSS: " + ("Lich Kral" if kosu.bolum >= 2 else "Kızıl Ejder"),
	}
	for tip in aciklamalar:
		var l := Arayuz.etiket(dikey, 13, aciklamalar[tip], (TIP_BILGI[tip][1] as Color).lightened(0.3))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


## Arayüz testi için: gidilebilen ilk durağa gider
func otomatik_adim() -> void:
	var liste := kosu.gidilebilir()
	if not liste.is_empty():
		dugum_secildi.emit(liste[0])
