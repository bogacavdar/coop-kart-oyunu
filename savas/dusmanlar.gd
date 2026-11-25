class_name Dusmanlar
extends RefCounted
## Bütün düşmanların tanımları. Yeni düşman eklemek = buraya bir sözlük eklemek.
##
## can: oyuncu başına can (4 oyuncuda x4)
## guc_artisi: her 2 turda bir kazandığı kalıcı güç
## hamleler: tur = tekil | cift | alan | guc | kalkan | iyiles
##   hasar (saldırılar) veya miktar (diğerleri), agirlik = seçilme şansı
##   ilk_tur_yok: true ise ilk tur seçilmez
## gorunum: renk, goz, halka, yaricap

const NORMAL: Array[String] = ["kuyruklu_yavru", "golge_akrep", "nebula_kurdu"]
const ELIT: Array[String] = ["ay_cadisi", "gunes_muhafizi"]
const BOSS := "saturn_golgesi"


static func tanim(id: String) -> Dictionary:
	match id:
		"kuyruklu_yavru":
			return {"id": id, "ad": "Kuyruklu Yıldız Yavrusu", "tip": "normal", "can": 36, "guc_artisi": 1,
				"hamleler": [
					{"tur": "tekil", "ad": "Kuyruk Darbesi", "hasar": 29, "agirlik": 50},
					{"tur": "alan", "ad": "Toz Bulutu", "hasar": 14, "agirlik": 30},
					{"tur": "kalkan", "ad": "Buz Kabuğu", "miktar": 16, "agirlik": 20},
				],
				"gorunum": {"renk": "#1d3a5c", "goz": "#7fd6ff", "halka": false, "yaricap": 64.0}}
		"golge_akrep":
			return {"id": id, "ad": "Gölge Akrep", "tip": "normal", "can": 38, "guc_artisi": 1,
				"hamleler": [
					{"tur": "tekil", "ad": "Zehirli İğne", "hasar": 28, "agirlik": 40},
					{"tur": "cift", "ad": "Çifte Kıskaç", "hasar": 20, "agirlik": 40},
					{"tur": "guc", "ad": "Zehir Biriktiriyor", "miktar": 3, "agirlik": 20},
				],
				"gorunum": {"renk": "#3a2416", "goz": "#ffcf4a", "halka": false, "yaricap": 66.0}}
		"nebula_kurdu":
			return {"id": id, "ad": "Nebula Kurdu", "tip": "normal", "can": 33, "guc_artisi": 1,
				"hamleler": [
					{"tur": "tekil", "ad": "Isırık", "hasar": 33, "agirlik": 45},
					{"tur": "alan", "ad": "Uluma", "hasar": 16, "agirlik": 35},
					{"tur": "iyiles", "ad": "Yaralarını Yalıyor", "miktar": 16, "agirlik": 20},
				],
				"gorunum": {"renk": "#2c2650", "goz": "#c38bff", "halka": false, "yaricap": 62.0}}
		"ay_cadisi":
			return {"id": id, "ad": "Ay Cadısı", "tip": "elit", "can": 58, "guc_artisi": 2,
				"hamleler": [
					{"tur": "alan", "ad": "Ay Tutulması", "hasar": 18, "agirlik": 35},
					{"tur": "tekil", "ad": "Lanet", "hasar": 38, "agirlik": 30},
					{"tur": "iyiles", "ad": "Ay Işığı İksiri", "miktar": 32, "agirlik": 15},
					{"tur": "guc", "ad": "Dolunay", "miktar": 4, "agirlik": 20},
				],
				"gorunum": {"renk": "#1f3a38", "goz": "#b8ffe8", "halka": true, "yaricap": 78.0}}
		"gunes_muhafizi":
			return {"id": id, "ad": "Güneş Muhafızı", "tip": "elit", "can": 62, "guc_artisi": 2,
				"hamleler": [
					{"tur": "kalkan", "ad": "Güneş Kalkanı", "miktar": 30, "agirlik": 25},
					{"tur": "tekil", "ad": "Alev Kılıcı", "hasar": 45, "agirlik": 30, "ilk_tur_yok": true},
					{"tur": "alan", "ad": "Güneş Patlaması", "hasar": 17, "agirlik": 30},
					{"tur": "cift", "ad": "Çifte Işın", "hasar": 23, "agirlik": 15},
				],
				"gorunum": {"renk": "#5a3010", "goz": "#fff0a0", "halka": true, "yaricap": 80.0}}
		_:
			return {"id": BOSS, "ad": "Satürn'ün Gölgesi", "tip": "boss", "can": 85, "guc_artisi": 3,
				"hamleler": [
					{"tur": "tekil", "ad": "Kuyruklu Yıldız", "hasar": 27, "agirlik": 45},
					{"tur": "tekil", "ad": "Kara Delik", "hasar": 40, "agirlik": 20, "ilk_tur_yok": true},
					{"tur": "alan", "ad": "Satürn Halkası", "hasar": 15, "agirlik": 25},
					{"tur": "guc", "ad": "Güç Topluyor", "miktar": 3, "agirlik": 10},
				],
				"gorunum": {"renk": "#2e1533", "goz": "#ffa040", "halka": true, "yaricap": 92.0}}
