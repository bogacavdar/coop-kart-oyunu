class_name Boss
extends RefCounted
## Savaştaki düşmanın durumu (normal, elit ya da boss). Tanımı Dusmanlar'dan gelir.

var id: String
var ad: String
## "normal", "elit" veya "boss"
var tip: String
var can: int
var max_can: int
## Kalıcı güç: bütün saldırılarına eklenir
var guc := 0
var guc_artisi := 1
## Kalkan: oyuncuların hasarını emer, boss'un bir sonraki hamlesinde sıfırlanır
var zirh := 0
## Bu tura özel durumlar (her tur başında sıfırlanır)
var isaret := 0
var zayiflik := 0
var sersem := false
## Kalıcı: her tur sonunda bu kadar hasar alır (kalkanı deler), sonra 1 azalır
var zehir := 0
## Bir önceki tur sersemlediyse bu tur sersemletilemez
var bagisik := false
var hamleler: Array = []
var gorunum: Dictionary = {}
## Bir sonraki hamle
var niyet: Dictionary = {}


func _init(tanim: Dictionary, oyuncu_sayisi: int) -> void:
	id = tanim["id"]
	ad = tanim["ad"]
	tip = tanim["tip"]
	max_can = int(tanim["can"]) * oyuncu_sayisi
	can = max_can
	guc_artisi = int(tanim.get("guc_artisi", 1))
	hamleler = tanim["hamleler"]
	gorunum = tanim.get("gorunum", {})


func durum_metni() -> String:
	var parcalar: PackedStringArray = []
	if zirh > 0:
		parcalar.append("Kalkan %d" % zirh)
	if guc > 0:
		parcalar.append("Güç +%d" % guc)
	if isaret > 0:
		parcalar.append("İşaretli +%d" % isaret)
	if zayiflik > 0:
		parcalar.append("Zayıf -%d" % zayiflik)
	if zehir > 0:
		parcalar.append("Zehir %d" % zehir)
	if sersem:
		parcalar.append("Sersem")
	elif bagisik:
		parcalar.append("Sersemlemeye bağışık")
	return " · ".join(parcalar)
