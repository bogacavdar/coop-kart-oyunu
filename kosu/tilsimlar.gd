class_name Tilsimlar
extends RefCounted
## Tılsımlar: koşu boyunca bütün takıma kalıcı bonus veren eşyalar.
## Etkileri SavasMotoru (savaş başı / tur başı) ve Kosu (alınınca / savaş sonu) uygular.
## İkonlar: varliklar/ikonlar/tilsim_<id>.svg

const LISTE := {
	"demir_yuzuk": {"ad": "Demir Yüzük",
		"aciklama": "Her savaşın ilk turunda bütün takım 6 zırh kazanır."},
	"mana_kristali": {"ad": "Mana Kristali",
		"aciklama": "Her savaşın ilk turunda herkesin 1 fazla manası olur."},
	"sifaci_kolyesi": {"ad": "Şifacının Kolyesi",
		"aciklama": "Kazanılan her savaştan sonra bütün takım 8 can iyileşir."},
	"avci_pusulasi": {"ad": "Avcı Pusulası",
		"aciklama": "Her turun başında düşman 2 işaret alır: o tur her saldırı +2 hasar verir."},
	"ejder_pulu": {"ad": "Ejder Pulu",
		"aciklama": "Düşmanın bütün vuruşları 2 daha az hasar verir."},
	"savas_borusu": {"ad": "Savaş Borusu",
		"aciklama": "Her savaşın başında düşman canının %10'unu kaybeder."},
	"altin_kase": {"ad": "Altın Kase",
		"aciklama": "Alındığında bütün takımın max canı 8 artar."},
	"bilge_kitabi": {"ad": "Bilge Kitabı",
		"aciklama": "Herkesin eli 4 yerine 5 kart olur."},
}


static func ad(id: String) -> String:
	return LISTE.get(id, {}).get("ad", id)


static func aciklama(id: String) -> String:
	return LISTE.get(id, {}).get("aciklama", "")


static func ipucu(id: String) -> String:
	return "[b][color=#e8c27a]%s[/color][/b]\n%s" % [ad(id), aciklama(id)]


static func ikon(id: String) -> Texture2D:
	var yol := "res://varliklar/ikonlar/tilsim_%s.svg" % id
	return load(yol) if ResourceLoader.exists(yol) else null


## Sahip olunan tılsımları ipuçlu küçük ikonlar halinde gösteren bir satır
static func serit(idler: Array, boyut: float = 38.0) -> HBoxContainer:
	var satir := HBoxContainer.new()
	satir.add_theme_constant_override("separation", 6)
	for id in idler:
		var kutu := Panel.new()
		kutu.custom_minimum_size = Vector2(boyut, boyut)
		kutu.add_theme_stylebox_override("panel", Arayuz.kutu_stili(Color(0.12, 0.08, 0.04, 0.9), Arayuz.ALTIN, 2, int(boyut / 2)))
		var t := TextureRect.new()
		t.texture = ikon(id)
		t.position = Vector2(6, 6)
		t.size = Vector2(boyut - 12, boyut - 12)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.self_modulate = Color("#ffd98a")
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kutu.add_child(t)
		Ipucu.baglan(kutu, ipucu.bind(id))
		satir.add_child(kutu)
	return satir
