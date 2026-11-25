class_name Dusmanlar
extends RefCounted
## Bütün düşmanların tanımları. Yeni düşman eklemek = buraya bir sözlük eklemek.
##
## can: oyuncu başına can (4 oyuncuda x4)
## guc_artisi: her 2 turda bir kazandığı kalıcı güç
## hamleler: tur = tekil | cift | alan | guc | kalkan | iyiles
##   hasar (saldırılar) veya miktar (diğerleri), agirlik = seçilme şansı
##   ilk_tur_yok: true ise ilk tur seçilmez
## gorunum: sekil (golem, goblin, trol, cadi, ork, ejder), renk, goz, yaricap

const NORMAL: Array[String] = ["tas_golem", "goblin_cetesi", "magara_trolu"]
const ELIT: Array[String] = ["bataklik_cadisi", "ork_savas_beyi"]
const BOSS := "kizil_ejder"


static func tanim(id: String) -> Dictionary:
	match id:
		"tas_golem":
			return {"id": id, "ad": "Taş Golem", "tip": "normal", "can": 36, "guc_artisi": 1,
				"hamleler": [
					{"tur": "tekil", "ad": "Kaya Yumruğu", "hasar": 29, "agirlik": 50},
					{"tur": "alan", "ad": "Deprem", "hasar": 14, "agirlik": 30},
					{"tur": "kalkan", "ad": "Taş Kabuk", "miktar": 16, "agirlik": 20},
				],
				"gorunum": {"sekil": "golem", "renk": "#55545c", "goz": "#6fd0ff", "yaricap": 74.0}}
		"goblin_cetesi":
			return {"id": id, "ad": "Goblin Çetesi", "tip": "normal", "can": 38, "guc_artisi": 1,
				"hamleler": [
					{"tur": "tekil", "ad": "Paslı Hançer", "hasar": 28, "agirlik": 40},
					{"tur": "cift", "ad": "Goblin Akını", "hasar": 20, "agirlik": 40},
					{"tur": "guc", "ad": "Savaş Davulu", "miktar": 3, "agirlik": 20},
				],
				"gorunum": {"sekil": "goblin", "renk": "#56762e", "goz": "#ffd84a", "yaricap": 66.0}}
		"magara_trolu":
			return {"id": id, "ad": "Mağara Trolü", "tip": "normal", "can": 33, "guc_artisi": 1,
				"hamleler": [
					{"tur": "tekil", "ad": "Sopa Darbesi", "hasar": 33, "agirlik": 45},
					{"tur": "alan", "ad": "Yer Sarsıntısı", "hasar": 16, "agirlik": 35},
					{"tur": "iyiles", "ad": "Yaraları Kapanıyor", "miktar": 16, "agirlik": 20},
				],
				"gorunum": {"sekil": "trol", "renk": "#56664c", "goz": "#ffb050", "yaricap": 74.0}}
		"bataklik_cadisi":
			return {"id": id, "ad": "Bataklık Cadısı", "tip": "elit", "can": 58, "guc_artisi": 2,
				"hamleler": [
					{"tur": "alan", "ad": "Zehirli Bulut", "hasar": 18, "agirlik": 35},
					{"tur": "tekil", "ad": "Lanet", "hasar": 38, "agirlik": 30},
					{"tur": "iyiles", "ad": "Kara İksir", "miktar": 32, "agirlik": 15},
					{"tur": "guc", "ad": "Kara Ayin", "miktar": 4, "agirlik": 20},
				],
				"gorunum": {"sekil": "cadi", "renk": "#33234a", "goz": "#9dff6a", "yaricap": 80.0}}
		"ork_savas_beyi":
			return {"id": id, "ad": "Ork Savaş Beyi", "tip": "elit", "can": 62, "guc_artisi": 2,
				"hamleler": [
					{"tur": "kalkan", "ad": "Demir Kalkan", "miktar": 30, "agirlik": 25},
					{"tur": "tekil", "ad": "Balta Darbesi", "hasar": 45, "agirlik": 30, "ilk_tur_yok": true},
					{"tur": "alan", "ad": "Savaş Narası", "hasar": 17, "agirlik": 30},
					{"tur": "cift", "ad": "Çifte Balta", "hasar": 23, "agirlik": 15},
				],
				"gorunum": {"sekil": "ork", "renk": "#4e5e2a", "goz": "#ff4a3a", "yaricap": 82.0}}
		_:
			return {"id": BOSS, "ad": "Kızıl Ejder", "tip": "boss", "can": 85, "guc_artisi": 3,
				"hamleler": [
					{"tur": "tekil", "ad": "Pençe", "hasar": 27, "agirlik": 45},
					{"tur": "tekil", "ad": "Ölümcül Isırık", "hasar": 40, "agirlik": 20, "ilk_tur_yok": true},
					{"tur": "alan", "ad": "Ejder Nefesi", "hasar": 15, "agirlik": 25},
					{"tur": "guc", "ad": "Öfkeleniyor", "miktar": 3, "agirlik": 10},
				],
				"gorunum": {"sekil": "ejder", "renk": "#7a1c14", "goz": "#ffd040", "yaricap": 92.0}}
