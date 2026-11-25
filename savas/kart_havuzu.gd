class_name KartHavuzu
extends RefCounted
## Klasördeki bütün kartları yükleyip sınıflara göre gruplar: { sinif: [CardData, ...] }


static func yukle(klasor: String) -> Dictionary:
	var havuz := {}
	var yol := klasor.trim_suffix("/") + "/"
	for dosya in DirAccess.get_files_at(yol):
		dosya = dosya.trim_suffix(".remap")  # dışa aktarılmış oyunda gerekli
		if not dosya.ends_with(".tres"):
			continue
		var kart := load(yol + dosya) as CardData
		if kart == null:
			continue
		if not havuz.has(kart.sinif):
			havuz[kart.sinif] = []
		havuz[kart.sinif].append(kart)
	return havuz
