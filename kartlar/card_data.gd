class_name CardData
extends Resource
## Bir kartın tüm verisi. Her kart için ayrı bir .tres dosyası oluşturulur.
## Denge ayarı = bu dosyadaki sayıları değiştirmek.

enum Sinif { TANK, DESTEK, HASARCI, KONTROLCU }

## Tip sırası aynı zamanda tur içindeki çözümleme sırasıdır:
## önce koruma, sonra kontrol (zayıflat/işaretle), sonra saldırı, en son iyileştirme.
enum Tip { KORUMA, KONTROL, SALDIRI, IYILESTIRME }

enum Hedef { BOSS, MUTTEFIK, KENDISI, TUM_TAKIM }

## Kartın ne yaptığı
## (Yeni etkiler hep sona eklenir: .tres dosyaları sayıyla kaydeder.)
## ZEHIR: düşmana zehir yükler; her tur sonunda zehir kadar hasar alır, zehir 1 azalır.
## ZIRH_HASARI: oynayanın o anki zırhı + deger kadar hasar verir.
enum Etki { HASAR, IYILESTIRME, ZIRH, AGGRO, ISARET, ZAYIFLAT, SERSEMLET, ZEHIR, ZIRH_HASARI }

## Ana etkiden sonra uygulanan ikinci etki (isteğe bağlı)
## SONRAKI_MANA / TAKIMA_MANA: gelecek tur fazladan mana (kendine / bütün takıma)
enum EkEtki { YOK, KENDINE_ZIRH, TAKIMA_ZIRH, KENDINE_CAN, TAKIMA_CAN, BOSSA_HASAR,
	ZEHIR, SONRAKI_MANA, TAKIMA_MANA, ISARET, ZAYIFLAT }

@export var id: StringName
@export var kart_adi: String = "Yeni Kart"
## Açıklamada {deger} yazarsan, kartın değeriyle otomatik değişir.
@export_multiline var aciklama: String = ""
@export_range(0, 10) var mana: int = 1
@export var sinif: Sinif = Sinif.TANK
@export var tip: Tip = Tip.SALDIRI
@export var hedef: Hedef = Hedef.BOSS
@export var etki: Etki = Etki.HASAR
## Hasar, heal, zırh miktarı vb.
@export var deger: int = 0
## İkinci etki ve değeri. Açıklamada {ek} yazarsan ek değerle değişir.
@export var ek_etki: EkEtki = EkEtki.YOK
@export var ek_deger: int = 0
## Başlangıç destesinde mi? (değilse ödül olarak çıkar)
@export var baslangic := false
## Ödül olarak en erken hangi bölümde çıkar
@export var bolum := 1
## ComfyUI'dan gelen görsel
@export var gorsel: Texture2D


## Kartın görseli: elle verilmiş bir görsel varsa o, yoksa varliklar/ikonlar/<id>.svg
func resim() -> Texture2D:
	if gorsel:
		return gorsel
	var yol := "res://varliklar/ikonlar/%s.svg" % id
	if ResourceLoader.exists(yol):
		return load(yol)
	return null


func aciklama_metni() -> String:
	return aciklama.format({"deger": deger, "ek": ek_deger})


func guclendirildi_mi() -> bool:
	return kart_adi.ends_with("+")


## Kartın güçlendirilmiş kopyasını döndürür (adı "+" ile biter)
func guclendirilmis() -> CardData:
	var k: CardData = duplicate()
	k.kart_adi = kart_adi + "+"
	if deger > 0:
		k.deger = deger + maxi(2, ceili(deger * 0.35))
	if ek_deger > 0:
		k.ek_deger = ek_deger + maxi(1, ceili(ek_deger * 0.35))
	if deger == 0:
		k.mana = maxi(0, mana - 1)
	return k


static func tip_adi(t: Tip) -> String:
	match t:
		Tip.KORUMA: return "Koruma"
		Tip.KONTROL: return "Kontrol"
		Tip.SALDIRI: return "Saldırı"
		Tip.IYILESTIRME: return "İyileştirme"
	return ""


static func sinif_adi(s: Sinif) -> String:
	match s:
		Sinif.TANK: return "Savaşçı"
		Sinif.DESTEK: return "Şifacı"
		Sinif.HASARCI: return "Büyücü"
		Sinif.KONTROLCU: return "Okçu"
	return ""
