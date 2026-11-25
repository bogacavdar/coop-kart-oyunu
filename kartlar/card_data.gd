class_name CardData
extends Resource
## Bir kartın tüm verisi. Her kart için ayrı bir .tres dosyası oluşturulur.
## Denge ayarı = bu dosyadaki sayıları değiştirmek.

enum Sinif { TANK, DESTEK, HASARCI, KONTROLCU }

## Tip sırası aynı zamanda tur içindeki çözümleme sırasıdır:
## önce koruma, sonra kontrol (zayıflat/işaretle), sonra saldırı, en son iyileştirme.
enum Tip { KORUMA, KONTROL, SALDIRI, IYILESTIRME }

enum Hedef { BOSS, MUTTEFIK, KENDISI, TUM_TAKIM }

@export var id: StringName
@export var kart_adi: String = "Yeni Kart"
## Açıklamada {deger} yazarsan, kartın değeriyle otomatik değişir.
@export_multiline var aciklama: String = ""
@export_range(0, 10) var mana: int = 1
@export var sinif: Sinif = Sinif.TANK
@export var tip: Tip = Tip.SALDIRI
@export var hedef: Hedef = Hedef.BOSS
## Hasar, heal, zırh miktarı vb.
@export var deger: int = 0
## ComfyUI'dan gelen görsel
@export var gorsel: Texture2D


func aciklama_metni() -> String:
	return aciklama.format({"deger": deger})


static func tip_adi(t: Tip) -> String:
	match t:
		Tip.KORUMA: return "Koruma"
		Tip.KONTROL: return "Kontrol"
		Tip.SALDIRI: return "Saldırı"
		Tip.IYILESTIRME: return "İyileştirme"
	return ""


static func sinif_adi(s: Sinif) -> String:
	match s:
		Sinif.TANK: return "Tank"
		Sinif.DESTEK: return "Destek"
		Sinif.HASARCI: return "Hasarcı"
		Sinif.KONTROLCU: return "Kontrolcü"
	return ""
