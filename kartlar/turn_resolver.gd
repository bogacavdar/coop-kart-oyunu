class_name TurnResolver
extends RefCounted
## Turda oynanan kartları tip sırasına göre dizer:
## Koruma -> Kontrol -> Saldırı -> İyileştirme (sonra boss hamlesi).
## Aynı tipteki kartlar oyuncu sırasına göre işlenir.
##
## Her hamle şu şekilde bir sözlüktür:
##   { "oyuncu": 0, "kart": CardData, "hedef_oyuncu": -1 }
## hedef_oyuncu: müttefike oynanan kartlarda hedef oyuncunun numarası, değilse -1.


static func sirala(oynanan: Array[Dictionary]) -> Array[Dictionary]:
	var sirali: Array[Dictionary] = oynanan.duplicate()
	sirali.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var tip_a: int = a["kart"].tip
		var tip_b: int = b["kart"].tip
		if tip_a != tip_b:
			return tip_a < tip_b
		return a["oyuncu"] < b["oyuncu"]
	)
	return sirali
