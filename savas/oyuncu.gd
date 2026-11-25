class_name Oyuncu
extends RefCounted
## Bir oyuncunun savaş içindeki durumu.

var no: int
var sinif: int
var ad: String
var can: int
var max_can: int
var zirh := 0
var mana := 0
var deste: Array[CardData] = []
var el: Array[CardData] = []
var atilan: Array[CardData] = []
## Bu tur seçilen kartlar: [{"kart": CardData, "hedef": int}]
## hedef: müttefike oynanan kartta hedef oyuncu, değilse -1
var secimler: Array[Dictionary] = []


func _init(p_no: int, p_sinif: int, p_can: int) -> void:
	no = p_no
	sinif = p_sinif
	ad = CardData.sinif_adi(p_sinif)
	can = p_can
	max_can = p_can


func hayatta() -> bool:
	return can > 0


func harcanan_mana() -> int:
	var toplam := 0
	for s in secimler:
		toplam += (s["kart"] as CardData).mana
	return toplam


func kalan_mana() -> int:
	return mana - harcanan_mana()


func secili_mi(kart: CardData) -> bool:
	for s in secimler:
		if s["kart"] == kart:
			return true
	return false


## Kalan manayla oynanabilecek, henüz seçilmemiş kart var mı?
func oynayabilir_mi() -> bool:
	var kalan := kalan_mana()
	for kart in el:
		if not secili_mi(kart) and kart.mana <= kalan:
			return true
	return false


func kart_cek(adet: int) -> void:
	for i in adet:
		if deste.is_empty():
			if atilan.is_empty():
				return
			deste = atilan.duplicate()
			deste.shuffle()
			atilan.clear()
		el.append(deste.pop_back())


## Hasarı önce zırh emer. Zırhın emdiği miktarı döndürür.
func hasar_al(miktar: int) -> int:
	var emilen := mini(zirh, miktar)
	zirh -= emilen
	can = maxi(0, can - (miktar - emilen))
	return emilen


## Gerçekten iyileşen miktarı döndürür (max canı aşamaz).
func iyiles(miktar: int) -> int:
	var once := can
	can = mini(max_can, can + miktar)
	return can - once
