class_name Yardakci
extends RefCounted
## Bossun çağırdığı küçük düşman. Yaşadığı sürece bossun önünde siper olur:
## tek hedefli vuruşlar önce ona gider. Her tur rastgele bir oyuncuya vurur.

## Savaş içinde benzersiz numara (arayüz eşleştirmesi için)
var no: int
var ad: String
var can: int
var max_can: int
var hasar: int
var gorunum: Dictionary = {}
## Çağrıldığı tur saldırmaz
var yeni := true


func _init(p_no: int, tanim: Dictionary, can_carpani: float, hasar_carpani: float) -> void:
	no = p_no
	ad = tanim["ad"]
	max_can = maxi(1, int(round(int(tanim["can"]) * can_carpani)))
	can = max_can
	hasar = maxi(1, int(round(int(tanim["hasar"]) * hasar_carpani)))
	gorunum = tanim.get("gorunum", {})


func hayatta() -> bool:
	return can > 0
