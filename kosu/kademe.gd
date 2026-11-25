class_name Kademe
extends RefCounted
## Zorluk kademeleri. Her kademe, kendisinden öncekilerin hepsini de içerir.
## Etkileri SavasMotoru (düşman) ve Kosu (iyileşme, can) uygular.

const MAKS := 10

const ACIKLAMALAR: Array[String] = [
	"Normal zorluk.",
	"Elitlerin canı %20 fazla.",
	"Bütün düşmanlar %10 daha sert vurur.",
	"Kamp ateşinde dinlenmek %20 iyileştirir (%30 yerine).",
	"Düşmanlar savaşa 1 güçle başlar.",
	"Kızıl Ejder'in canı %15 fazla.",
	"Düşen oyuncular savaştan sonra sadece 1 canla kalkar.",
	"Takım koşuya canının %90'ıyla başlar.",
	"Elitler ve Kızıl Ejder fazladan 2 güçle başlar.",
	"Normal düşmanların canı %15 fazla.",
	"Kızıl Ejder çok daha hızlı öfkelenir.",
]


static func baslik(k: int) -> String:
	return "Kademe %d" % k if k > 0 else "Kademe 0 (Normal)"


## Bu kademede geçerli bütün kuralların listesi
static func tum_kurallar(k: int) -> String:
	if k <= 0:
		return ACIKLAMALAR[0]
	var satirlar: PackedStringArray = []
	for i in range(1, k + 1):
		satirlar.append("%d. %s" % [i, ACIKLAMALAR[i]])
	return "\n".join(satirlar)
