extends SceneTree
## Arayüz testi: oyunu açar ve bütün akışı (harita, savaş, ödül, dinlenme, gizem,
## deste seçici) senin yerine adım adım oynar. Ekran kodundaki hataları yakalar.

var oyun: Node
var sure := 0.0
var bekleme := 0.0
var adim := 0


func _initialize() -> void:
	Engine.time_scale = 6.0
	oyun = load("res://oyun.tscn").instantiate()
	root.add_child(oyun)


func _process(delta: float) -> bool:
	sure += delta / Engine.time_scale
	bekleme -= delta
	if oyun.sonuc_ekraninda or sure > 100.0:
		print("ARAYUZ TESTI TAMAM: %d adım, kazanılan savaş %d, koşu %s" % [
			adim, oyun.kosu.kazanilan_savas if oyun.kosu else 0,
			"bitti" if oyun.sonuc_ekraninda else "zaman doldu"])
		return true
	if bekleme <= 0.0:
		bekleme = 0.6
		adim += 1
		oyun.otomatik_adim()
	return false
