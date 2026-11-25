class_name Boss
extends RefCounted
## Boss'un savaş içindeki durumu.

var ad := "Satürn'ün Gölgesi"
var can: int
var max_can: int
## Kalıcı güç: boss'un bütün saldırılarına eklenir
var guc := 0
## Bu tura özel durumlar (her tur başında sıfırlanır)
var isaret := 0
var zayiflik := 0
var sersem := false
## Bir sonraki hamle: {"tur", "hedef", "hasar", "metin"}
var niyet: Dictionary = {}


func _init(p_can: int) -> void:
	can = p_can
	max_can = p_can


func durum_metni() -> String:
	var parcalar: PackedStringArray = []
	if guc > 0:
		parcalar.append("Güç +%d" % guc)
	if isaret > 0:
		parcalar.append("İşaretli +%d" % isaret)
	if zayiflik > 0:
		parcalar.append("Zayıf -%d" % zayiflik)
	if sersem:
		parcalar.append("Sersem")
	return " · ".join(parcalar)
