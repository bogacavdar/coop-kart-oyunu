class_name Ipucu
extends CanvasLayer
## Açıklama balonu: fareyle bir şeyin üstüne gelince yanında çıkan küçük kutu.
## Kullanım: Ipucu.baglan(kontrol, func(): return "metin")

const SOZLUK := {
	"zirh": "[color=#6fa8ff]Zırh[/color]: Gelen hasarı önce zırh emer. Her tur başında sıfırlanır.",
	"aggro": "[color=#ffb347]Dikkat Çekme[/color]: Bu tur düşmanın tek kişilik saldırıları bu oyuncuya yönelir.",
	"isaret": "[color=#c38bff]İşaret[/color]: Bu tur düşmana yapılan her saldırı fazladan hasar verir.",
	"zayif": "[color=#c38bff]Zayıflatma[/color]: Bu tur düşmanın her vuruşunun hasarı azalır.",
	"sersem": "[color=#c38bff]Hareketsiz[/color]: Düşman bu tur hiçbir şey yapamaz.",
	"kalkan": "[color=#9fc8ff]Kalkan[/color]: Düşmanın kalkanı, oyuncuların hasarını önce emer. Düşmanın bir sonraki hamlesinde biter.",
	"guc": "[color=#ff8a6a]Güç[/color]: Düşmanın bütün saldırılarına eklenir ve kalıcıdır. Savaş uzadıkça artar.",
	"mana": "[color=#8fc1ff]Mana[/color]: Kart oynamak için harcanır. Her tur 1 artar (en fazla 6). Harcanmayan mana sonraki tura kalmaz.",
	"sira": "[color=#e8c27a]Tur sırası[/color]: Önce Koruma, sonra Kontrol, sonra Saldırı, en son İyileştirme kartları işlenir. Ardından düşman hamlesini yapar.",
}

static var _ornek: Ipucu
var _panel: PanelContainer
var _yazi: RichTextLabel
var _sahip: Control


func _init() -> void:
	layer = 120
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", Arayuz.kutu_stili(Color(0.05, 0.03, 0.09, 0.96), Color("#b8a060"), 2, 8))
	_panel.visible = false
	add_child(_panel)
	_yazi = RichTextLabel.new()
	_yazi.bbcode_enabled = true
	_yazi.fit_content = true
	_yazi.scroll_active = false
	_yazi.custom_minimum_size = Vector2(300, 0)
	_yazi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_yazi.add_theme_font_size_override("normal_font_size", 14)
	_yazi.add_theme_font_size_override("bold_font_size", 15)
	_panel.add_child(_yazi)


static func baglan(kontrol: Control, metin: Callable) -> void:
	kontrol.mouse_entered.connect(func(): goster(kontrol, metin.call()))
	kontrol.mouse_exited.connect(func(): gizle(kontrol))
	kontrol.tree_exiting.connect(func(): gizle(kontrol))


static func goster(kontrol: Control, metin: String) -> void:
	if metin == "" or not kontrol.is_inside_tree():
		return
	if _ornek == null or not is_instance_valid(_ornek):
		_ornek = Ipucu.new()
		kontrol.get_tree().root.add_child(_ornek)
	_ornek._goster(kontrol, metin)


static func gizle(kontrol: Control = null) -> void:
	if _ornek and is_instance_valid(_ornek):
		if kontrol == null or _ornek._sahip == kontrol:
			_ornek._panel.visible = false
			_ornek._sahip = null


func _goster(kontrol: Control, metin: String) -> void:
	_sahip = kontrol
	_yazi.text = metin
	_panel.visible = true
	_panel.reset_size()
	var alan := kontrol.get_global_rect()
	var boyut := _panel.get_combined_minimum_size()
	var ekran := Vector2(1280, 720)
	var konum := Vector2(alan.end.x + 12, alan.position.y)
	if konum.x + boyut.x > ekran.x - 8:
		konum.x = alan.position.x - boyut.x - 12
	if konum.x < 8:
		konum.x = clampf(alan.get_center().x - boyut.x / 2.0, 8, ekran.x - boyut.x - 8)
		konum.y = alan.position.y - boyut.y - 10
	konum.y = clampf(konum.y, 8, ekran.y - boyut.y - 8)
	_panel.position = konum


## Kartın açıklaması: başlık, işlenme sırası ve kartta geçen terimler
static func kart_metni(k: CardData) -> String:
	var satirlar: PackedStringArray = []
	satirlar.append("[b]%s[/b]  ·  %d mana  ·  %s" % [k.kart_adi, k.mana, CardData.sinif_adi(k.sinif)])
	satirlar.append(k.aciklama_metni())
	satirlar.append("")
	var sira_aciklamasi := {
		CardData.Tip.KORUMA: "turda ilk işlenen kartlardan.",
		CardData.Tip.KONTROL: "korumadan sonra, saldırılardan önce işlenir.",
		CardData.Tip.SALDIRI: "koruma ve kontrolden sonra işlenir.",
		CardData.Tip.IYILESTIRME: "turda en son işlenir, düşmandan hemen önce.",
	}
	satirlar.append("[color=#e8c27a]%s kartı[/color]: %s" % [CardData.tip_adi(k.tip), sira_aciklamasi[k.tip]])
	if k.hedef == CardData.Hedef.MUTTEFIK:
		satirlar.append("[color=#7dffa0]Hedefli[/color]: Seçtikten sonra bir koltuğa tıkla.")
	var terimler: Array[String] = []
	match k.etki:
		CardData.Etki.ZIRH: terimler.append("zirh")
		CardData.Etki.AGGRO: terimler.append_array(["aggro", "zirh"])
		CardData.Etki.ISARET: terimler.append("isaret")
		CardData.Etki.ZAYIFLAT: terimler.append("zayif")
		CardData.Etki.SERSEMLET: terimler.append("sersem")
		CardData.Etki.HASAR: terimler.append("kalkan")
	if k.ek_etki in [CardData.EkEtki.KENDINE_ZIRH, CardData.EkEtki.TAKIMA_ZIRH] and not terimler.has("zirh"):
		terimler.append("zirh")
	for t in terimler:
		satirlar.append(SOZLUK[t])
	if k.guclendirildi_mi():
		satirlar.append("[color=#ffd84a]Güçlendirilmiş kart.[/color]")
	return "\n".join(satirlar)
