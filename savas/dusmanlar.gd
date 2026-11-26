class_name Dusmanlar
extends RefCounted
## Bütün düşmanların tanımları. Yeni düşman eklemek = buraya bir sözlük eklemek.
##
## can: oyuncu başına can (4 oyuncuda x4)
## guc_artisi: her 2 turda bir kazandığı kalıcı güç
## hamleler: tur = tekil | cift | alan | guc | kalkan | iyiles | emme (vurduğu kadar iyileşir)
##   hasar (saldırılar) veya miktar (diğerleri), agirlik = seçilme şansı
##   ilk_tur_yok: true ise ilk tur seçilmez
## gorunum: sekil (golem, goblin, trol, cadi, ork, ejder), renk, goz, yaricap

const NORMAL: Array[String] = ["tas_golem", "goblin_cetesi", "magara_trolu"]
const ELIT: Array[String] = ["bataklik_cadisi", "ork_savas_beyi"]
const BOSS := "kizil_ejder"
## 2. bölüm: Lich'in Mezarı
const NORMAL_2: Array[String] = ["iskelet_lejyonu", "hayalet", "mumya"]
const ELIT_2: Array[String] = ["kara_sovalye", "kemik_ejderi"]
const BOSS_2 := "lich_kral"


static func normal_listesi(bolum: int) -> Array[String]:
	return NORMAL_2 if bolum >= 2 else NORMAL


static func elit_listesi(bolum: int) -> Array[String]:
	return ELIT_2 if bolum >= 2 else ELIT


static func boss_id(bolum: int) -> String:
	return BOSS_2 if bolum >= 2 else BOSS


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
		# --- 2. bölüm ---
		"iskelet_lejyonu":
			return {"id": id, "ad": "İskelet Lejyonu", "tip": "normal", "can": 48, "guc_artisi": 1,
				"hamleler": [
					{"tur": "cift", "ad": "Kılıç Yağmuru", "hasar": 26, "agirlik": 40},
					{"tur": "alan", "ad": "Kemik Fırtınası", "hasar": 15, "agirlik": 35},
					{"tur": "kalkan", "ad": "Kalkan Duvarı", "miktar": 20, "agirlik": 25},
				],
				"gorunum": {"sekil": "iskelet", "renk": "#cfc6aa", "goz": "#7affd0", "yaricap": 80.0,
					"model": {"dosya": "res://varliklar/modeller/kaykit/Skeleton_Warrior.glb",
						"saldiri": "1H_Melee_Attack_Slice_Diagonal"}}}
		"hayalet":
			return {"id": id, "ad": "Feryatçı Hayalet", "tip": "normal", "can": 40, "guc_artisi": 1,
				"hamleler": [
					{"tur": "tekil", "ad": "Buz Gibi Dokunuş", "hasar": 36, "agirlik": 40},
					{"tur": "emme", "ad": "Can Emme", "hasar": 24, "agirlik": 40},
					{"tur": "guc", "ad": "Fısıltılar", "miktar": 3, "agirlik": 20},
				],
				"gorunum": {"sekil": "hayalet", "renk": "#8aa4cc", "goz": "#d0f4ff", "yaricap": 74.0,
					"model": {"dosya": "res://varliklar/modeller/kaykit/Skeleton_Rogue.glb",
						"renk": "#6fa8ff", "saydam": 0.4, "saldiri": "Spellcast_Shoot"}}}
		"mumya":
			return {"id": id, "ad": "Kadim Mumya", "tip": "normal", "can": 52, "guc_artisi": 1,
				"hamleler": [
					{"tur": "tekil", "ad": "Sargı Darbesi", "hasar": 38, "agirlik": 45},
					{"tur": "alan", "ad": "Lanetli Toz", "hasar": 16, "agirlik": 35},
					{"tur": "iyiles", "ad": "Kadim Büyü", "miktar": 20, "agirlik": 20},
				],
				"gorunum": {"sekil": "mumya", "renk": "#b39c6c", "goz": "#ff6a3a", "yaricap": 76.0,
					"model": {"dosya": "res://varliklar/modeller/kaykit/Skeleton_Minion.glb",
						"renk": "#e2cc9c", "saldiri": "Unarmed_Melee_Attack_Punch_A"}}}
		"kara_sovalye":
			return {"id": id, "ad": "Kara Şövalye", "tip": "elit", "can": 75, "guc_artisi": 2,
				"hamleler": [
					{"tur": "kalkan", "ad": "Kara Kalkan", "miktar": 35, "agirlik": 25},
					{"tur": "tekil", "ad": "Ölüm Kılıcı", "hasar": 55, "agirlik": 30, "ilk_tur_yok": true},
					{"tur": "cift", "ad": "Çifte Darbe", "hasar": 30, "agirlik": 30},
					{"tur": "guc", "ad": "Karanlık Yemin", "miktar": 4, "agirlik": 15},
				],
				"gorunum": {"sekil": "kara_sovalye", "renk": "#5a5a6e", "goz": "#ff3a3a", "yaricap": 84.0,
					"model": {"dosya": "res://varliklar/modeller/kaykit/Skeleton_Warrior.glb",
						"renk": "#6a6478", "olcek": 1.12, "saldiri": "2H_Melee_Attack_Chop"}}}
		"kemik_ejderi":
			return {"id": id, "ad": "Kemik Ejderi", "tip": "elit", "can": 66, "guc_artisi": 2,
				"hamleler": [
					{"tur": "alan", "ad": "Çürük Nefes", "hasar": 17, "agirlik": 35},
					{"tur": "tekil", "ad": "Kemik Pençe", "hasar": 40, "agirlik": 35},
					{"tur": "emme", "ad": "Ruh Isırığı", "hasar": 25, "agirlik": 30},
				],
				"gorunum": {"sekil": "kemik_ejder", "renk": "#d8d0b8", "goz": "#9dff6a", "yaricap": 86.0}}
		"lich_kral":
			return {"id": id, "ad": "Lich Kral", "tip": "boss", "can": 110, "guc_artisi": 3,
				"hamleler": [
					{"tur": "tekil", "ad": "Ölüm Parmağı", "hasar": 34, "agirlik": 30},
					{"tur": "emme", "ad": "Ruh Hasadı", "hasar": 28, "agirlik": 25},
					{"tur": "alan", "ad": "Kara Dalga", "hasar": 19, "agirlik": 25},
					{"tur": "kalkan", "ad": "Kemik Muhafızlar", "miktar": 30, "agirlik": 10},
					{"tur": "guc", "ad": "Karanlık Ayin", "miktar": 4, "agirlik": 10},
				],
				"gorunum": {"sekil": "lich", "renk": "#4a3a6a", "goz": "#7affb0", "yaricap": 94.0,
					"model": {"dosya": "res://varliklar/modeller/kaykit/Skeleton_Mage.glb",
						"renk": "#7a68b0", "olcek": 1.15, "saldiri": "Spellcast_Shoot", "bekleme": "Idle_Combat"}}}
		_:
			return {"id": BOSS, "ad": "Kızıl Ejder", "tip": "boss", "can": 85, "guc_artisi": 3,
				"hamleler": [
					{"tur": "tekil", "ad": "Pençe", "hasar": 27, "agirlik": 45},
					{"tur": "tekil", "ad": "Ölümcül Isırık", "hasar": 40, "agirlik": 20, "ilk_tur_yok": true},
					{"tur": "alan", "ad": "Ejder Nefesi", "hasar": 15, "agirlik": 25},
					{"tur": "guc", "ad": "Öfkeleniyor", "miktar": 3, "agirlik": 10},
				],
				"gorunum": {"sekil": "ejder", "renk": "#7a1c14", "goz": "#ffd040", "yaricap": 92.0}}
