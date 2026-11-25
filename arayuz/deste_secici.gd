class_name DesteSecici
extends ColorRect
## Desteyi ızgara halinde gösteren üst katman.
## secilebilir geçerli bir Callable ise (kart -> bool) kart seçtirir, değilse sadece gösterir.

signal secildi(indeks: int)
signal kapandi

var _deste: Array
var _secilebilir: Callable
var _baslik: String


func _init(baslik: String, deste: Array, secilebilir: Callable = Callable()) -> void:
	_baslik = baslik
	_deste = deste
	_secilebilir = secilebilir
	color = Color(0.02, 0.01, 0.06, 0.92)
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 400


func _ready() -> void:
	var b := Arayuz.etiket(self, 30, _baslik, Arayuz.ALTIN)
	b.position = Vector2(0, 22)
	b.size = Vector2(1280, 40)

	var kaydirma := ScrollContainer.new()
	kaydirma.position = Vector2(60, 80)
	kaydirma.size = Vector2(1160, 545)
	kaydirma.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(kaydirma)

	var izgara := GridContainer.new()
	izgara.columns = 7
	izgara.add_theme_constant_override("h_separation", 12)
	izgara.add_theme_constant_override("v_separation", 12)
	kaydirma.add_child(izgara)

	for i in _deste.size():
		var kart: CardData = _deste[i]
		var kutu := Control.new()
		kutu.custom_minimum_size = Vector2(152, 226)
		kutu.mouse_filter = Control.MOUSE_FILTER_PASS
		izgara.add_child(kutu)
		var v := CardView.new()
		v.setup(kart)
		kutu.add_child(v)
		v.yerlestir(Vector2(76, 113), 0.72)
		if _secilebilir.is_valid():
			if _secilebilir.call(kart):
				v.card_clicked.connect(func(_v): _sec(i))
			else:
				v.modulate = Color(0.45, 0.45, 0.5)
				v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			v.mouse_filter = Control.MOUSE_FILTER_PASS

	var kapat := Arayuz.buton("Vazgeç" if _secilebilir.is_valid() else "Kapat", Vector2(200, 52))
	kapat.position = Vector2(540, 645)
	kapat.pressed.connect(func():
		kapandi.emit()
		queue_free()
	)
	add_child(kapat)


func _sec(i: int) -> void:
	secildi.emit(i)
	queue_free()


## Arayüz testi için: seçilebilen ilk kartı seçer
func otomatik_adim() -> void:
	for i in _deste.size():
		if not _secilebilir.is_valid() or _secilebilir.call(_deste[i]):
			_sec(i)
			return
	kapandi.emit()
	queue_free()
