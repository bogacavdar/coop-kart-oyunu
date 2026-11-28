class_name YardakciGorunumu
extends Control
## Bossun yanındaki küçük düşman: 3D model, can çubuğu ve adı.

const BOYUT := Vector2(160, 190)

var no: int
var ad: String
var hasar := 0
var model: Model3D
var _bar: ProgressBar
var _yazi: Label
var _on_isareti: Label


func _init(p_no: int, p_ad: String, can: int, max_can: int, gorunum: Dictionary, p_hasar: int) -> void:
	no = p_no
	ad = p_ad
	hasar = p_hasar
	size = BOYUT
	pivot_offset = BOYUT / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	if gorunum.has("dosya"):
		var ayar := gorunum.duplicate()
		ayar["uzaklik"] = 5.2
		model = Model3D.new(ayar, Vector2(BOYUT.x, 150))
		model.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(model)

	_on_isareti = Label.new()
	_on_isareti.text = "SİPER"
	_on_isareti.position = Vector2(0, 0)
	_on_isareti.size = Vector2(BOYUT.x, 18)
	_on_isareti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_on_isareti.add_theme_font_size_override("font_size", 12)
	_on_isareti.add_theme_color_override("font_color", Color("#ffb347"))
	_on_isareti.add_theme_color_override("font_outline_color", Color.BLACK)
	_on_isareti.add_theme_constant_override("outline_size", 4)
	_on_isareti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_on_isareti.visible = false
	add_child(_on_isareti)

	_yazi = Label.new()
	_yazi.position = Vector2(0, 146)
	_yazi.size = Vector2(BOYUT.x, 20)
	_yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_yazi.add_theme_font_size_override("font_size", 13)
	_yazi.add_theme_color_override("font_color", Color("#f0d9a8"))
	_yazi.add_theme_color_override("font_outline_color", Color.BLACK)
	_yazi.add_theme_constant_override("outline_size", 4)
	_yazi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_yazi)

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.position = Vector2(25, 170)
	_bar.size = Vector2(BOYUT.x - 50, 10)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dolu := StyleBoxFlat.new()
	dolu.bg_color = Color("#c0392b")
	dolu.set_corner_radius_all(3)
	var zemin := StyleBoxFlat.new()
	zemin.bg_color = Color(0, 0, 0, 0.65)
	zemin.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("fill", dolu)
	_bar.add_theme_stylebox_override("background", zemin)
	add_child(_bar)
	guncelle(can, max_can)
	Ipucu.baglan(self, ipucu_metni)


func ipucu_metni() -> String:
	return ("[b]%s[/b]  ·  Yardakçı  ·  Can %d/%d\n" % [ad, int(_bar.value), int(_bar.max_value)]) \
		+ "Yaşadığı sürece bossun önünde siper olur: tek hedefli vuruşlar önce en öndeki yardakçıya gider, fazlası boşa gider. " \
		+ "Bütün düşmanlara vuran (alan) kartlar hepsine birden işler.\n" \
		+ "Her tur rastgele birine %d hasar vurur (Meydan Okuma onu da üstüne çeker)." % hasar


func merkeze_yerlestir(merkez: Vector2) -> void:
	position = merkez - BOYUT / 2.0


func merkez() -> Vector2:
	return position + Vector2(BOYUT.x / 2.0, 80)


func on_mu(acik: bool) -> void:
	_on_isareti.visible = acik


func guncelle(can: int, max_can: int) -> void:
	_bar.max_value = max_can
	_bar.value = can
	_yazi.text = "%s  %d/%d" % [ad, can, max_can]


func belir() -> void:
	scale = Vector2(0.3, 0.3)
	modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)


func vur() -> void:
	if model:
		model.vurul()
	modulate = Color(2.0, 1.3, 1.3)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.25)


func saldir() -> void:
	if model:
		model.saldir()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.12)
	tw.tween_property(self, "scale", Vector2.ONE, 0.18)


func ol() -> void:
	if model:
		model.ol()
	_on_isareti.visible = false
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
