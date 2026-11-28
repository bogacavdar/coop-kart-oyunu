extends SceneTree
## Kart gücü ölçümü: her ödül kartından 2 kopya, sahibinin başlangıç destesine eklenir;
## 4 bot iki elit düşmana karşı savaşır. Sonuç, kartsız (sadece başlangıç destesi) takımla karşılaştırılır.
## Fark ne kadar büyükse kart o kadar güçlü. Sıralamanın başı ve sonu dengelenmesi gereken kartlardır.
## Çalıştırma: godot --headless --script res://testler/denge_testi.gd

const OYUN := 600
const DUSMANLAR := ["ork_savas_beyi", "kemik_ejderi"]


func _initialize() -> void:
	var havuz := KartHavuzu.yukle("res://kartlar/veriler")
	var taban := _olc(havuz, null)
	print("DENGE: taban (başlangıç desteleri) -> zafer %%%d, ort. %.1f tur, ort. kalan takım canı %.0f" % [
		taban["zafer"], taban["tur"], taban["can"]])
	var sonuclar: Array = []
	for s in havuz:
		for kart in havuz[s]:
			if kart.baslangic:
				continue
			var r := _olc(havuz, kart)
			# Tek sayı: kazanma farkı + kalan can farkı (canın 175 üzerinden yüzdesi) + hız
			r["puan"] = (r["zafer"] - taban["zafer"]) + (r["can"] - taban["can"]) / 1.75 + (taban["tur"] - r["tur"]) * 3.0
			r["kart"] = kart
			sonuclar.append(r)
	sonuclar.sort_custom(func(a, b): return a["puan"] > b["puan"])
	print("DENGE: kart | sınıf | mana | puan | zafer | tur | kalan can")
	for r in sonuclar:
		var k: CardData = r["kart"]
		print("DENGE: %-18s | %-7s | %d | %+6.1f | %%%3d | %4.1f | %3.0f" % [
			k.kart_adi, CardData.sinif_adi(k.sinif), k.mana, r["puan"], r["zafer"], r["tur"], r["can"]])
	print("DENGE TAMAM")
	quit()


func _olc(havuz: Dictionary, kart: CardData) -> Dictionary:
	var zafer := 0
	var tur := 0
	var can := 0
	for i in OYUN:
		var kurulum := SavasMotoru.hizli_kurulum(havuz, DUSMANLAR[i % DUSMANLAR.size()])
		kurulum["tohum"] = 1000 + i  # kartlı ve kartsız takım aynı zarlarla oynar
		if kart:
			for v in kurulum["oyuncular"]:
				if v["sinif"] == kart.sinif:
					v["deste"].append(kart.duplicate())
					v["deste"].append(kart.duplicate())
		var motor := SavasMotoru.new(kurulum)
		while not motor.bitti and motor.tur < 80:
			for o in motor.oyuncular:
				if o.hayatta():
					Bot.planla(motor, o)
			motor.turu_coz()
		if motor.boss.can <= 0:
			zafer += 1
		tur += motor.tur
		for o in motor.oyuncular:
			can += o.can
	return {"zafer": zafer * 100 / OYUN, "tur": tur / float(OYUN), "can": can / float(OYUN)}
