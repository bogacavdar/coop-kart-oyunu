class_name Ses
extends RefCounted
## Ses efektleri: Ses.cal(herhangi_bir_dugum, "vurus")
## Dosyalar varliklar/sesler/<ad>.wav. Aynı isimle yeni dosya koyarak değiştirilebilir.

static var _akislar := {}
static var acik := true


static func cal(dugum: Node, ad: String, ses_db: float = -4.0, perde: float = 1.0) -> void:
	if not acik or dugum == null or not dugum.is_inside_tree():
		return
	if not _akislar.has(ad):
		var yol := "res://varliklar/sesler/%s.wav" % ad
		_akislar[ad] = load(yol) if ResourceLoader.exists(yol) else null
	var akis: AudioStream = _akislar[ad]
	if akis == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = akis
	p.volume_db = ses_db
	p.pitch_scale = perde * randf_range(0.94, 1.06)
	dugum.get_tree().root.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
