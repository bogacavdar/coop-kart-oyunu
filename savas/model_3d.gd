class_name Model3D
extends SubViewportContainer
## 2D ekranın içinde animasyonlu bir 3D model gösterir (kendi küçük 3D sahnesinde).
## ayar: {"dosya": "res://...glb", "olcek": 1.0, "donus": 0, "renk": "#rrggbb", "saydam": 1.0,
##        "saldiri": "anim adı", "vurulma": "Hit_A", "olum": "Death_A", "bekleme": "Idle",
##        "kamera_y": 1.3, "hedef_y": 1.0, "uzaklik": 4.6}

var ayar: Dictionary
var _vp: SubViewport
var _model: Node3D
var _ap: AnimationPlayer
var _bekleme := "Idle"
var _oldu := false


func _init(p_ayar: Dictionary, boyut: Vector2) -> void:
	ayar = p_ayar
	size = boyut
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_vp = SubViewport.new()
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.size = Vector2i(boyut)
	_vp.msaa_3d = Viewport.MSAA_2X
	add_child(_vp)

	var ortam := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.56, 0.7)
	env.ambient_light_energy = 0.75
	ortam.environment = env
	_vp.add_child(ortam)

	# Önden sıcak ana ışık, arkadan soğuk kenar ışığı
	var ana := DirectionalLight3D.new()
	ana.rotation_degrees = Vector3(-35, 28, 0)
	ana.light_energy = 1.5
	ana.light_color = Color(1.0, 0.9, 0.78)
	_vp.add_child(ana)
	var kenar := DirectionalLight3D.new()
	kenar.rotation_degrees = Vector3(-15, 200, 0)
	kenar.light_energy = 1.1
	kenar.light_color = Color(0.6, 0.75, 1.0)
	_vp.add_child(kenar)

	var kamera := Camera3D.new()
	kamera.fov = 32
	var konum := Vector3(0, float(ayar.get("kamera_y", 1.6)), float(ayar.get("uzaklik", 6.3)))
	var hedef := Vector3(0, float(ayar.get("hedef_y", 1.15)), 0)
	kamera.transform = Transform3D(Basis.looking_at(hedef - konum, Vector3.UP), konum)
	_vp.add_child(kamera)

	var sahne: PackedScene = load(ayar["dosya"])
	_model = sahne.instantiate()
	_model.scale = Vector3.ONE * float(ayar.get("olcek", 1.0))
	_model.rotation_degrees.y = float(ayar.get("donus", 0.0))
	_vp.add_child(_model)
	if ayar.has("renk"):
		_renklendir(_model, Color(str(ayar["renk"])), float(ayar.get("saydam", 1.0)))

	_ap = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_bekleme = str(ayar.get("bekleme", "Idle"))
	if _ap:
		var anim := _ap.get_animation(_bekleme)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		_oynat(_bekleme)


## Modelin bütün yüzeylerini verilen renkle çarpar (ve istenirse yarı saydam yapar)
func _renklendir(dugum: Node, renk: Color, saydam: float) -> void:
	if dugum is MeshInstance3D:
		var m := dugum as MeshInstance3D
		for i in m.mesh.get_surface_count():
			var asil := m.get_active_material(i)
			if asil is StandardMaterial3D:
				var kopya: StandardMaterial3D = asil.duplicate()
				if not String(asil.resource_name).to_lower().contains("glow"):
					kopya.albedo_color = renk
				if saydam < 1.0:
					kopya.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					kopya.albedo_color.a = saydam
				m.set_surface_override_material(i, kopya)
	for c in dugum.get_children():
		_renklendir(c, renk, saydam)


func _oynat(ad: String, sonra_bekle: bool = false) -> void:
	if _ap == null or not _ap.has_animation(ad):
		return
	_ap.play(ad, 0.15)
	if sonra_bekle:
		_ap.queue(_bekleme)


func saldir() -> void:
	if not _oldu:
		_oynat(str(ayar.get("saldiri", "1H_Melee_Attack_Chop")), true)


func vurul() -> void:
	if not _oldu:
		_oynat(str(ayar.get("vurulma", "Hit_A")), true)


func ol() -> void:
	_oldu = true
	_oynat(str(ayar.get("olum", "Death_A")))
