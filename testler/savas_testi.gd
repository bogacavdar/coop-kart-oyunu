extends SceneTree
## Otomatik test: savaşı birçok kez kendi kendine oynatır.
## 1) Rastgele kart seçen takım  2) Dört bot  3) Bir rastgele oyuncu + üç bot
## Hata varsa GitHub derlemesi kırmızıya döner; sonuçlar kaba bir denge fikri verir.
## Çalıştırma: godot --headless --script res://testler/savas_testi.gd

const OYUN_SAYISI := 200


func _initialize() -> void:
	var havuz := KartHavuzu.yukle("res://kartlar/veriler")
	var kart_sayisi := 0
	for s in havuz:
		kart_sayisi += havuz[s].size()
	print("TEST: %d kart, %d sınıf yüklendi" % [kart_sayisi, havuz.size()])
	if kart_sayisi < 48 or havuz.size() < 4:
		push_error("TEST HATASI: kartlar eksik yüklendi")

	_rapor("rastgele takım", havuz, 0)
	_rapor("4 bot", havuz, 4)
	_rapor("1 rastgele + 3 bot", havuz, 3)
	for d in Dusmanlar.NORMAL + Dusmanlar.ELIT + Dusmanlar.NORMAL_2 + Dusmanlar.ELIT_2 + [Dusmanlar.BOSS_2]:
		_dusman_raporu(havuz, d)
	_tilsim_raporu(havuz)
	_kosu_raporu(havuz)
	_kosu_raporu(havuz, 5, 80)
	_kosu_raporu(havuz, 10, 80)
	_kayit_testi()
	print("TEST TAMAM")
	quit()


## bot_sayisi: kaç oyuncuyu bot oynar (son oyuncular bot olur)
func _rapor(ad: String, havuz: Dictionary, bot_sayisi: int) -> void:
	var zafer := 0
	var toplam_tur := 0
	for oyun in OYUN_SAYISI:
		var motor := SavasMotoru.new(SavasMotoru.hizli_kurulum(havuz))
		while not motor.bitti and motor.tur < 80:
			for o in motor.oyuncular:
				if not o.hayatta():
					continue
				if o.no >= motor.oyuncular.size() - bot_sayisi:
					Bot.planla(motor, o)
				else:
					_rastgele_sec(motor, o)
				if o.harcanan_mana() > o.mana:
					push_error("TEST HATASI: mana aşıldı")
			motor.turu_coz()
		if not motor.bitti:
			push_error("TEST HATASI: savaş 80 turda bitmedi")
		if motor.boss.can <= 0:
			zafer += 1
		toplam_tur += motor.tur
	print("TEST: %s %d/%d kazandı, ortalama %.1f tur" % [ad, zafer, OYUN_SAYISI, float(toplam_tur) / OYUN_SAYISI])


func _rastgele_sec(motor: SavasMotoru, o: Oyuncu) -> void:
	while o.oynayabilir_mi():
		var kalan := o.kalan_mana()
		var uygun: Array = o.el.filter(func(k): return not o.secili_mi(k) and k.mana <= kalan)
		var kart: CardData = uygun.pick_random()
		var hedef := -1
		if kart.hedef == CardData.Hedef.MUTTEFIK:
			hedef = motor.canli_oyuncular().pick_random().no
		if not motor.kart_sec(o.no, kart, hedef):
			push_error("TEST HATASI: geçerli kart reddedildi: " + kart.kart_adi)
			return


## Tek bir düşmana karşı, tam canla, 4 botun kazanma oranı
func _dusman_raporu(havuz: Dictionary, dusman: String) -> void:
	var zafer := 0
	var toplam_tur := 0
	var kalan_can := 0
	for oyun in 100:
		var motor := SavasMotoru.new(SavasMotoru.hizli_kurulum(havuz, dusman))
		_botlarla_oyna(motor)
		if motor.boss.can <= 0:
			zafer += 1
		toplam_tur += motor.tur
		for o in motor.oyuncular:
			kalan_can += o.can
	print("TEST: %s -> 4 bot %d/100, ort. %.1f tur, ort. kalan takım canı %d/175" % [
		dusman, zafer, toplam_tur / 100.0, kalan_can / 100])


func _botlarla_oyna(motor: SavasMotoru) -> void:
	while not motor.bitti and motor.tur < 80:
		for o in motor.oyuncular:
			if o.hayatta():
				Bot.planla(motor, o)
		motor.turu_coz()
	if not motor.bitti:
		push_error("TEST HATASI: savaş 80 turda bitmedi")


## Bütün koşuyu 4 botla baştan sona oynatır
func _kosu_raporu(havuz: Dictionary, kademe: int = 0, sayi: int = 150) -> void:
	var kazanilan := 0
	var bolum2 := 0
	var toplam_tilsim := 0
	var olum_katmani := {}
	for i in sayi:
		var kosu := Kosu.new(havuz, -1, kademe)
		kosu.tilsim_ekle(kosu.tilsim_secenekleri().pick_random())
		var adim := 0
		while not kosu.bitti and adim < 40:
			adim += 1
			var secenekler := kosu.gidilebilir()
			if secenekler.is_empty():
				push_error("TEST HATASI: harita çıkmaza girdi")
				break
			var d: Dictionary = secenekler.pick_random()
			kosu.git(d)
			match d["tip"]:
				"savas", "elit", "boss":
					var motor := SavasMotoru.new(kosu.savas_kurulumu(d["tip"]))
					_botlarla_oyna(motor)
					kosu.savas_sonucu(motor, d["tip"])
					if kosu.bolum_gecisi_bekliyor:
						bolum2 += 1
						kosu.sonraki_bolume_gec()
						var bt := kosu.tilsim_secenekleri()
						if not bt.is_empty():
							kosu.tilsim_ekle(bt.pick_random())
						continue
					if not kosu.bitti:
						kosu.botlara_odul_ver()
						if d["tip"] == "elit":
							var tilsimlar := kosu.tilsim_secenekleri()
							if not tilsimlar.is_empty():
								kosu.tilsim_ekle(tilsimlar.pick_random())
				"dinlenme":
					if randf() < 0.5:
						kosu.dinlen()
					else:
						kosu.botlar_guclendirsin()
				"gizem":
					var g := kosu.gizem_sec()
					var s: Dictionary = g["secenekler"].pick_random()
					kosu.gizem_uygula(s["id"])
		if not kosu.bitti:
			push_error("TEST HATASI: koşu bitmedi")
		if kosu.kazandi:
			kazanilan += 1
		else:
			var yer := "%d-%d" % [kosu.bolum, kosu.katman]
			olum_katmani[yer] = olum_katmani.get(yer, 0) + 1
		toplam_tilsim += kosu.tilsimlar.size()
		for v in kosu.takim:
			for k in v["deste"]:
				if not (k is CardData):
					push_error("TEST HATASI: destede geçersiz kart")
	print("TEST: KOŞU kademe %d -> 4 bot: %d/%d 2. bölüme ulaştı, %d/%d koşuyu kazandı; ort. %.1f tılsım; düşülen yerler (bölüm-katman): %s" % [
		kademe, bolum2, sayi, kazanilan, sayi, toplam_tilsim / float(sayi), str(olum_katmani)])


## Bütün tılsımlar açıkken boss savaşı: hata çıkıyor mu, ne kadar güçlendiriyor?
func _tilsim_raporu(havuz: Dictionary) -> void:
	var zafer := 0
	for oyun in 100:
		var kurulum := SavasMotoru.hizli_kurulum(havuz)
		kurulum["tilsimlar"] = Tilsimlar.LISTE.keys()
		var motor := SavasMotoru.new(kurulum)
		if motor.oyuncular[0].el.size() != 5:
			push_error("TEST HATASI: Bilge Kitabı eli 5 yapmadı")
		_botlarla_oyna(motor)
		if motor.boss.can <= 0:
			zafer += 1
	print("TEST: bütün tılsımlarla boss -> 4 bot %d/100" % zafer)


## Kalıcı ilerleme: kademe açma ve kilitler doğru işliyor mu? (dosyaya yazmadan)
func _kayit_testi() -> void:
	var k := Kayit.new()
	if k.kilitli_idler().size() != Kayit.KILIT_SIRASI.size():
		push_error("TEST HATASI: başta her şey kilitli olmalı")
	var s := k.kosu_bitti(false, 0, 3, false)
	if s["yeni_kademe"] != -1 or not s["acilanlar"].is_empty():
		push_error("TEST HATASI: kaybedilen 3 savaşlık koşu bir şey açmamalı")
	s = k.kosu_bitti(true, 0, 6, false)
	if s["yeni_kademe"] != 1 or s["acilanlar"].size() != 2 or k.deger("acik_kademe") != 1:
		push_error("TEST HATASI: zafer kademe 1'i ve 2 kilidi açmalıydı: %s" % str(s))
	var kosu := Kosu.new(KartHavuzu.yukle("res://kartlar/veriler"), -1, 0, k.kilitli_idler())
	for i in 30:
		for kart in kosu.odul_secenekleri(CardData.Sinif.HASARCI):
			if k.kilitli_idler().has(String(kart.id)):
				push_error("TEST HATASI: kilitli kart ödül olarak çıktı: " + kart.kart_adi)
		for t in kosu.tilsim_secenekleri():
			if k.kilitli_idler().has(t):
				push_error("TEST HATASI: kilitli tılsım çıktı: " + t)
	print("TEST: kayıt ve kilit testi bitti (%d kilit açık)" % k.deger("acilan"))
