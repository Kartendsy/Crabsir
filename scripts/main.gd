extends Control
## Crabsir — kasir Android modern (portrait, touch-friendly).
## Tema: "Sunset Orange" — kartu putih rounded + shadow di atas bg oranye lembut.

var cart: Dictionary = {}  # product_id(int) -> qty(int)

var _pages: Array = []
var _nav_buttons: Array = []
var _nav_icons: Array = []
var _clock_label: Label
var _time_accum: float = 0.0

# Kasir
var _search: LineEdit
var _product_grid: GridContainer
var _cart_list: VBoxContainer
var _total_label: Label
var _bayar_input: LineEdit
var _kembali_label: Label
var _cart_badge: Label

# Produk
var _produk_list: VBoxContainer

# Riwayat
var _riwayat_list: VBoxContainer
var _riwayat_info: Label
var _riwayat_search: LineEdit

# Laporan
var _lap_hari: Label
var _lap_hero_sub: Label
var _lap_total: Label
var _lap_count: Label
var _lap_best: Label
var _lap_chart: HBoxContainer

# Popup custom (overlay) — pengganti AcceptDialog native
var _pop_form: Control
var _pop_form_card: PanelContainer
var _pop_form_title: Label
var _fld_nama: LineEdit
var _fld_harga: LineEdit
var _fld_stok: LineEdit
var _editing_id: int = -1

var _pop_struk: Control
var _pop_struk_card: PanelContainer
var _pop_struk_title: Label
var _struk_meta: Label
var _struk_items: VBoxContainer
var _struk_total: Label
var _struk_bayar_v: Label
var _struk_kembali_v: Label
var _struk_barcode: HBoxContainer

var _pop_confirm: Control
var _pop_confirm_card: PanelContainer
var _confirm_title: Label
var _confirm_msg: Label
var _confirm_ok: Button
var _confirm_action: Callable

var _toast_layer: Control
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_time_left: float = 0.0

# ---------- Palet modern ----------
const C_BG := Color("fff7ed")        # latar aplikasi (oranye sangat muda)
const C_CARD := Color.WHITE
const C_INK := Color("0f172a")       # teks utama
const C_MUTED := Color("64748b")     # teks sekunder
const C_LINE := Color("e2e8f0")      # garis pembatas
const C_PRIMARY := Color("ea580c")   # oranye
const C_PRIMARY_D := Color("c2410c") # oranye tua
const C_PRIMARY_SOFT := Color("ffedd5")
const C_SUCCESS := Color("059669")
const C_SUCCESS_SOFT := Color("d1fae5")
const C_DANGER := Color("dc2626")
const C_DANGER_SOFT := Color("fee2e2")
const C_WARN := Color("d97706")
const C_WARN_SOFT := Color("fef3c7")
const C_HEADER_A := Color("7c2d12")  # header gradasi (atas)
const C_HEADER_B := Color("ea580c")  # header gradasi (bawah)


func _ready() -> void:
	_build_ui()
	DataStore.products_changed.connect(_refresh_all)
	DataStore.transactions_changed.connect(_refresh_all)
	_refresh_all()
	_update_clock()


func _process(delta: float) -> void:
	_time_accum += delta
	if _time_accum >= 1.0:
		_time_accum = 0.0
		_update_clock()
	if _toast_time_left > 0.0:
		_toast_time_left -= delta
		if _toast_time_left <= 0.0 and is_instance_valid(_toast_layer):
			_popup_hide(_toast_layer)


func _update_clock() -> void:
	if _clock_label:
		_clock_label.text = "●  " + Time.get_datetime_string_from_system().replace("T", "  •  ")


# ================= DESIGN SYSTEM =================

func _card_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_CARD
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.border_color = C_LINE
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0.28, 0.3, 0.55, 0.14)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	return sb


func _input_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.border_color = C_LINE
	sb.set_border_width_all(2)
	sb.shadow_color = Color(0.28, 0.3, 0.55, 0.08)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 2)
	return sb


func _pill(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(999)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.border_color = border
	sb.set_border_width_all(1)
	return sb


func _popup_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(28)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	sb.border_color = C_LINE
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0.1, 0.1, 0.25, 0.35)
	sb.shadow_size = 24
	sb.shadow_offset = Vector2(0, 8)
	return sb


# ---- Sistem popup custom: dim full-screen + kartu + fade ----
# Tidak memakai AcceptDialog/ConfirmationDialog sama sekali,
# jadi tidak ada bingkai/title-bar native yang tersisa.

func _dim_overlay() -> Control:
	var ov := Control.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.visible = false
	add_child(ov)
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.08, 0.18, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(dim)
	return ov


func _popup_card(ov: Control, min_w: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(min_w, 0)
	card.add_theme_stylebox_override("panel", _popup_style())
	center.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)
	return vb


func _popup_show(ov: Control) -> void:
	ov.visible = true
	ov.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(ov, "modulate:a", 1.0, 0.16)


func _popup_hide(ov: Control) -> void:
	var tw := create_tween()
	tw.tween_property(ov, "modulate:a", 0.0, 0.14)
	tw.tween_callback(func() -> void: ov.visible = false)


func _dlg_caption(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 23)
	l.add_theme_color_override("font_color", C_MUTED)
	return l


func _style_button(b: Button, bg: Color, fg: Color, border: Color, radius: int = 16, fsize: int = 30) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = bg
	n.set_corner_radius_all(radius)
	n.content_margin_left = 14
	n.content_margin_right = 14
	n.content_margin_top = 10
	n.content_margin_bottom = 10
	n.border_color = border
	n.set_border_width_all(1 if border != bg else 0)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = bg.darkened(0.07)
	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = bg.darkened(0.14)
	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Color("e2e8f0")
	var f := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("disabled", d)
	b.add_theme_stylebox_override("focus", f)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", Color("94a3b8"))
	b.add_theme_font_size_override("font_size", fsize)


func _style_input(f: LineEdit, fsize: int = 30) -> void:
	f.add_theme_stylebox_override("normal", _input_style())
	f.add_theme_stylebox_override("focus", _input_style())
	f.add_theme_stylebox_override("read_only", _input_style())
	f.add_theme_color_override("font_color", C_INK)
	f.add_theme_color_override("font_placeholder_color", Color("94a3b8"))
	f.add_theme_color_override("caret_color", C_PRIMARY)
	f.add_theme_font_size_override("font_size", fsize)


func _chip(parent: Control, text: String, bg: Color, fg: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", fg)
	l.add_theme_stylebox_override("normal", _pill(bg, bg))
	# Label tidak punya "normal" — bungkus agar terlihat seperti chip:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", _pill(bg, bg))
	var inner := Label.new()
	inner.text = text
	inner.add_theme_font_size_override("font_size", 22)
	inner.add_theme_color_override("font_color", fg)
	wrap.add_child(inner)
	parent.add_child(wrap)
	l.queue_free()
	return inner


# ================= UI UTAMA =================

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	root.add_child(_make_header())

	var content := Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.clip_contents = true
	root.add_child(content)

	var kasir := _make_kasir_page()
	var produk := _make_produk_page()
	var riwayat := _make_riwayat_page()
	var laporan := _make_laporan_page()
	for p in [kasir, produk, riwayat, laporan]:
		p.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.add_child(p)
		_pages.append(p)

	root.add_child(_make_bottom_nav())
	_show_page(0)
	_make_popups()


func _make_header() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 112)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.border_color = C_LINE
	sb.border_width_bottom = 2
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	bar.add_theme_stylebox_override("panel", sb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.alignment = BoxContainer.ALIGNMENT_BEGIN
	bar.add_child(hb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)

	var title := Label.new()
	title.text = "Crabsir"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", C_INK)
	vb.add_child(title)

	_clock_label = Label.new()
	_clock_label.add_theme_font_size_override("font_size", 23)
	_clock_label.add_theme_color_override("font_color", C_MUTED)
	vb.add_child(_clock_label)

	# Badge keranjang di header
	_cart_badge = Label.new()
	_cart_badge.text = "0"
	_cart_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cart_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cart_badge.custom_minimum_size = Vector2(68, 68)
	_cart_badge.add_theme_font_size_override("font_size", 28)
	_cart_badge.add_theme_color_override("font_color", C_PRIMARY_D)
	var badge_bg := StyleBoxFlat.new()
	badge_bg.bg_color = C_PRIMARY_SOFT
	badge_bg.set_corner_radius_all(999)
	_cart_badge.add_theme_stylebox_override("normal", badge_bg)
	hb.add_child(_cart_badge)
	return bar


func _make_bottom_nav() -> Control:
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override("margin_left", 16)
	wrap.add_theme_constant_override("margin_right", 16)
	wrap.add_theme_constant_override("margin_top", 8)
	wrap.add_theme_constant_override("margin_bottom", 14)

	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 128)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(26)
	sb.border_color = C_LINE
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0.28, 0.3, 0.55, 0.16)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, -3)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	bar.add_theme_stylebox_override("panel", sb)
	wrap.add_child(bar)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(hb)

	var names := ["Kasir", "Produk", "Riwayat", "Laporan"]
	var icons := [
		preload("res://icons/shopping-cart-fill.svg"),
		preload("res://icons/inbox-unarchive-fill.svg"),
		preload("res://icons/booklet-fill.svg"),
		preload("res://icons/line-chart-line.svg"),
	]
	for i in names.size():
		var b := Button.new()
		b.text = ""
		b.tooltip_text = names[i]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 100)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_show_page.bind(i))
		var pad := MarginContainer.new()
		pad.set_anchors_preset(Control.PRESET_FULL_RECT)
		pad.add_theme_constant_override("margin_left", 26)
		pad.add_theme_constant_override("margin_right", 26)
		pad.add_theme_constant_override("margin_top", 20)
		pad.add_theme_constant_override("margin_bottom", 20)
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pad)
		var tr := TextureRect.new()
		tr.texture = icons[i]
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pad.add_child(tr)
		hb.add_child(b)
		_nav_buttons.append(b)
		_nav_icons.append(tr)
	_refresh_nav_styles(0)
	return wrap


func _refresh_nav_styles(active: int) -> void:
	for i in _nav_buttons.size():
		var b: Button = _nav_buttons[i]
		var tr: TextureRect = _nav_icons[i]
		if i == active:
			_style_button(b, C_PRIMARY, Color.WHITE, C_PRIMARY, 20, 27)
			tr.modulate = Color.WHITE
		else:
			_style_button(b, C_PRIMARY_SOFT, C_PRIMARY, C_PRIMARY_SOFT, 20, 27)
			tr.modulate = Color("fb923c")


func _show_page(idx: int) -> void:
	for i in _pages.size():
		_pages[i].visible = (i == idx)
	_refresh_nav_styles(idx)
	if idx == 2:
		_refresh_riwayat()
	if idx == 3:
		_refresh_laporan()


# ================= HALAMAN KASIR =================

func _make_kasir_page() -> Control:
	var page := MarginContainer.new()
	page.add_theme_constant_override("margin_left", 16)
	page.add_theme_constant_override("margin_right", 16)
	page.add_theme_constant_override("margin_top", 14)
	page.add_theme_constant_override("margin_bottom", 6)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	page.add_child(vb)

	_search = LineEdit.new()
	_search.placeholder_text = "🔍  Cari produk..."
	_search.clear_button_enabled = true
	_search.custom_minimum_size = Vector2(0, 92)
	_style_input(_search, 29)
	_search.text_changed.connect(func(_t: String) -> void: _refresh_product_grid())
	vb.add_child(_search)

	vb.add_child(_section_label("PRODUK  •  ketuk + untuk masuk keranjang"))

	var scroll_prod := ScrollContainer.new()
	scroll_prod.custom_minimum_size = Vector2(0, 330)
	scroll_prod.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_prod.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll_prod)

	_product_grid = GridContainer.new()
	_product_grid.columns = 2
	_product_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_product_grid.add_theme_constant_override("h_separation", 12)
	_product_grid.add_theme_constant_override("v_separation", 12)
	scroll_prod.add_child(_product_grid)

	# Kartu keranjang
	var cart_card := PanelContainer.new()
	cart_card.add_theme_stylebox_override("panel", _card_style())
	vb.add_child(cart_card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	cart_card.add_child(cv)

	var cart_head := HBoxContainer.new()
	cv.add_child(cart_head)
	var cl := Label.new()
	cl.text = "🛒 Keranjang"
	cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cl.add_theme_font_size_override("font_size", 30)
	cl.add_theme_color_override("font_color", C_INK)
	cart_head.add_child(cl)
	var b_clear_top := Button.new()
	b_clear_top.text = "Bersihkan"
	_style_button(b_clear_top, C_DANGER_SOFT, C_DANGER, C_DANGER_SOFT, 999, 24)
	b_clear_top.custom_minimum_size = Vector2(170, 64)
	b_clear_top.pressed.connect(_clear_cart)
	cart_head.add_child(b_clear_top)

	var scroll_cart := ScrollContainer.new()
	scroll_cart.custom_minimum_size = Vector2(0, 190)
	scroll_cart.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cv.add_child(scroll_cart)

	_cart_list = VBoxContainer.new()
	_cart_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cart_list.add_theme_constant_override("separation", 8)
	scroll_cart.add_child(_cart_list)

	# Total bar (gelap, modern)
	var total_panel := PanelContainer.new()
	var ts := StyleBoxFlat.new()
	ts.bg_color = C_INK
	ts.set_corner_radius_all(16)
	ts.content_margin_left = 20
	ts.content_margin_right = 20
	ts.content_margin_top = 12
	ts.content_margin_bottom = 12
	total_panel.add_theme_stylebox_override("panel", ts)
	cv.add_child(total_panel)
	var th := HBoxContainer.new()
	total_panel.add_child(th)
	_total_label = Label.new()
	_total_label.text = "Total  Rp0"
	_total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_total_label.add_theme_font_size_override("font_size", 36)
	_total_label.add_theme_color_override("font_color", Color.WHITE)
	th.add_child(_total_label)
	_kembali_label = Label.new()
	_kembali_label.text = "Kembali Rp0"
	_kembali_label.add_theme_font_size_override("font_size", 26)
	_kembali_label.add_theme_color_override("font_color", Color("fed7aa"))
	th.add_child(_kembali_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	cv.add_child(row)

	_bayar_input = LineEdit.new()
	_bayar_input.placeholder_text = "Nominal bayar (Rp)"
	_bayar_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_bayar_input.custom_minimum_size = Vector2(0, 92)
	_bayar_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_input(_bayar_input, 29)
	_bayar_input.text_changed.connect(func(_t: String) -> void: _refresh_kembali())
	row.add_child(_bayar_input)

	var b_bayar := Button.new()
	b_bayar.text = "BAYAR →"
	b_bayar.custom_minimum_size = Vector2(260, 92)
	_style_button(b_bayar, C_SUCCESS, Color.WHITE, C_SUCCESS, 16, 32)
	b_bayar.pressed.connect(_checkout)
	row.add_child(b_bayar)

	return page


func _section_label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", C_MUTED)
	return l


func _refresh_product_grid() -> void:
	_clear_children(_product_grid)
	var kw := _search.text if _search else ""
	var items := DataStore.search_products(kw)
	for p in items:
		_product_grid.add_child(_make_product_card(p))
	if _product_grid.get_child_count() == 0:
		var l := Label.new()
		l.text = "Produk tidak ditemukan."
		l.add_theme_font_size_override("font_size", 28)
		l.add_theme_color_override("font_color", C_MUTED)
		_product_grid.add_child(l)


func _make_product_card(p: Dictionary) -> Control:
	var stok := int(p["stock"])
	var pid := int(p["id"])

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	var name := Label.new()
	name.text = String(p["name"])
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size = Vector2(0, 66)
	name.add_theme_font_size_override("font_size", 29)
	name.add_theme_color_override("font_color", C_INK)
	vb.add_child(name)

	var price := Label.new()
	price.text = DataStore.rupiah(int(p["price"]))
	price.add_theme_font_size_override("font_size", 32)
	price.add_theme_color_override("font_color", C_PRIMARY_D)
	vb.add_child(price)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)

	var stock_lbl := Label.new()
	stock_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if stok <= 0:
		stock_lbl.text = "Habis"
		stock_lbl.add_theme_color_override("font_color", C_DANGER)
	elif stok <= 5:
		stock_lbl.text = "Sisa %d" % stok
		stock_lbl.add_theme_color_override("font_color", C_WARN)
	else:
		stock_lbl.text = "Stok %d" % stok
		stock_lbl.add_theme_color_override("font_color", C_SUCCESS)
	stock_lbl.add_theme_font_size_override("font_size", 24)
	row.add_child(stock_lbl)

	var b := Button.new()
	b.text = "+ Tambah" if stok > 0 else "Habis"
	b.disabled = stok <= 0
	b.custom_minimum_size = Vector2(170, 72)
	_style_button(b, C_PRIMARY if stok > 0 else Color("e2e8f0"), Color.WHITE if stok > 0 else C_MUTED, C_PRIMARY if stok > 0 else Color("e2e8f0"), 999, 25)
	b.pressed.connect(_add_to_cart.bind(pid))
	row.add_child(b)
	return card


func _add_to_cart(pid: int) -> void:
	var p := DataStore.get_product(pid)
	if p.is_empty():
		return
	var cur: int = int(cart.get(pid, 0))
	if cur + 1 > int(p["stock"]):
		_toast("Stok %s tidak cukup." % String(p["name"]))
		return
	cart[pid] = cur + 1
	_refresh_cart()


func _cart_total() -> int:
	var sum := 0
	for pid in cart.keys():
		var p := DataStore.get_product(int(pid))
		if not p.is_empty():
			sum += int(p["price"]) * int(cart[pid])
	return sum


func _cart_count() -> int:
	var n := 0
	for pid in cart.keys():
		n += int(cart[pid])
	return n


func _refresh_cart() -> void:
	_clear_children(_cart_list)
	for pid in cart.keys():
		var p := DataStore.get_product(int(pid))
		if p.is_empty():
			continue
		var qty: int = int(cart[pid])
		var sub: int = int(p["price"]) * qty
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_cart_list.add_child(row)

		var info := Label.new()
		info.text = "%s  ×%d\n%s" % [String(p["name"]), qty, DataStore.rupiah(sub)]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 27)
		info.add_theme_color_override("font_color", C_INK)
		row.add_child(info)

		var b_min := Button.new()
		b_min.text = "−"
		b_min.custom_minimum_size = Vector2(76, 76)
		_style_button(b_min, Color("f1f5f9"), C_INK, Color("f1f5f9"), 999, 30)
		b_min.pressed.connect(_cart_dec.bind(int(pid)))
		row.add_child(b_min)

		var q := Label.new()
		q.text = str(qty)
		q.custom_minimum_size = Vector2(52, 76)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.add_theme_font_size_override("font_size", 28)
		q.add_theme_color_override("font_color", C_INK)
		row.add_child(q)

		var b_plus := Button.new()
		b_plus.text = "+"
		b_plus.custom_minimum_size = Vector2(76, 76)
		_style_button(b_plus, C_PRIMARY_SOFT, C_PRIMARY_D, C_PRIMARY_SOFT, 999, 30)
		b_plus.pressed.connect(_cart_inc.bind(int(pid)))
		row.add_child(b_plus)

	if cart.is_empty():
		var l := Label.new()
		l.text = "Keranjang kosong — pilih produk di atas."
		l.add_theme_font_size_override("font_size", 26)
		l.add_theme_color_override("font_color", C_MUTED)
		_cart_list.add_child(l)

	_total_label.text = "Total  " + DataStore.rupiah(_cart_total())
	if _cart_badge:
		_cart_badge.text = str(_cart_count())
	_refresh_kembali()


func _cart_inc(pid: int) -> void:
	_add_to_cart(pid)


func _cart_dec(pid: int) -> void:
	var q: int = int(cart.get(pid, 0)) - 1
	if q <= 0:
		cart.erase(pid)
	else:
		cart[pid] = q
	_refresh_cart()


func _clear_cart() -> void:
	cart.clear()
	if _bayar_input:
		_bayar_input.text = ""
	_refresh_cart()


func _refresh_kembali() -> void:
	if _kembali_label == null or _bayar_input == null:
		return
	var raw := _bayar_input.text.strip_edges()
	if raw == "":
		_kembali_label.text = "Kembali Rp0"
		return
	var bayar := raw.to_int()
	var kembali := bayar - _cart_total()
	if kembali < 0:
		_kembali_label.text = "Kurang " + DataStore.rupiah(-kembali)
		_kembali_label.add_theme_color_override("font_color", Color("fca5a5"))
	else:
		_kembali_label.text = "Kembali " + DataStore.rupiah(kembali)
		_kembali_label.add_theme_color_override("font_color", Color("fed7aa"))


func _checkout() -> void:
	if cart.is_empty():
		_toast("Keranjang masih kosong.")
		return
	var total := _cart_total()
	var bayar := _bayar_input.text.strip_edges().to_int()
	if _bayar_input.text.strip_edges() == "":
		_toast("Masukkan nominal bayar dulu.")
		return
	if bayar < total:
		_toast("Uang kurang " + DataStore.rupiah(total - bayar))
		return
	var items: Array = []
	for pid in cart.keys():
		var p := DataStore.get_product(int(pid))
		if p.is_empty():
			continue
		var qty: int = int(cart[pid])
		items.append({
			"id": int(pid),
			"name": String(p["name"]),
			"price": int(p["price"]),
			"qty": qty,
			"subtotal": int(p["price"]) * qty,
		})
	var t := DataStore.add_transaction(items, total, bayar)
	cart.clear()
	_bayar_input.text = ""
	_refresh_cart()
	_show_struk(t)


func _toast(msg: String, dur: float = 2.0) -> void:
	if _toast_layer == null:
		return
	_toast_label.text = msg
	_toast_time_left = dur
	_popup_show(_toast_layer)


# ================= HALAMAN PRODUK =================

func _make_produk_page() -> Control:
	var page := MarginContainer.new()
	page.add_theme_constant_override("margin_left", 16)
	page.add_theme_constant_override("margin_right", 16)
	page.add_theme_constant_override("margin_top", 14)
	page.add_theme_constant_override("margin_bottom", 6)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	page.add_child(vb)

	var b_add := Button.new()
	b_add.text = "+  Tambah Produk"
	b_add.custom_minimum_size = Vector2(0, 104)
	_style_button(b_add, C_PRIMARY, Color.WHITE, C_PRIMARY, 18, 30)
	b_add.pressed.connect(_open_add_product)
	vb.add_child(b_add)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	_produk_list = VBoxContainer.new()
	_produk_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_produk_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_produk_list)
	return page


func _refresh_produk_list() -> void:
	if _produk_list == null:
		return
	_clear_children(_produk_list)
	for p in DataStore.products:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_style())
		_produk_list.add_child(card)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		card.add_child(hb)

		var info := Label.new()
		info.text = "%s\n%s • Stok %d" % [String(p["name"]), DataStore.rupiah(int(p["price"])), int(p["stock"])]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 28)
		info.add_theme_color_override("font_color", C_INK)
		hb.add_child(info)

		var pid := int(p["id"])
		var b_edit := Button.new()
		b_edit.text = "Edit"
		b_edit.custom_minimum_size = Vector2(124, 80)
		_style_button(b_edit, C_PRIMARY_SOFT, C_PRIMARY_D, C_PRIMARY_SOFT, 14, 26)
		b_edit.pressed.connect(_open_edit_product.bind(pid))
		hb.add_child(b_edit)

		var b_del := Button.new()
		b_del.text = "Hapus"
		b_del.custom_minimum_size = Vector2(124, 80)
		_style_button(b_del, C_DANGER_SOFT, C_DANGER, C_DANGER_SOFT, 14, 26)
		b_del.pressed.connect(_delete_product.bind(pid))
		hb.add_child(b_del)


func _open_add_product() -> void:
	_editing_id = -1
	_fld_nama.text = ""
	_fld_harga.text = ""
	_fld_stok.text = ""
	_pop_form_title.text = "＋ Tambah Produk"
	_popup_show(_pop_form)


func _open_edit_product(pid: int) -> void:
	var p := DataStore.get_product(pid)
	if p.is_empty():
		return
	_editing_id = pid
	_fld_nama.text = String(p["name"])
	_fld_harga.text = str(int(p["price"]))
	_fld_stok.text = str(int(p["stock"]))
	_pop_form_title.text = "✏️ Edit Produk"
	_popup_show(_pop_form)


func _delete_product(pid: int) -> void:
	var p := DataStore.get_product(pid)
	if p.is_empty():
		return
	_ask_confirm("Hapus Produk?", "Hapus \"%s\" dari daftar produk?" % String(p["name"]), "Ya, hapus", _do_delete_product.bind(pid))


func _do_delete_product(pid: int) -> void:
	DataStore.delete_product(pid)
	_toast("Produk dihapus.")


func _ask_confirm(title: String, msg: String, ok_text: String, action: Callable) -> void:
	_confirm_title.text = title
	_confirm_msg.text = msg
	_confirm_ok.text = ok_text
	_confirm_action = action
	_popup_show(_pop_confirm)


func _save_product_dialog() -> void:
	var nama := _fld_nama.text.strip_edges()
	var harga := _fld_harga.text.strip_edges().to_int()
	var stok := _fld_stok.text.strip_edges().to_int()
	if nama == "":
		_toast("Nama produk wajib diisi.")
		return
	if _editing_id < 0:
		DataStore.add_product(nama, harga, stok)
		_toast("Produk ditambahkan.")
	else:
		DataStore.update_product(_editing_id, nama, harga, stok)
		_toast("Produk diperbarui.")
	_popup_hide(_pop_form)


# ================= HALAMAN RIWAYAT =================

func _make_riwayat_page() -> Control:
	var page := MarginContainer.new()
	page.add_theme_constant_override("margin_left", 16)
	page.add_theme_constant_override("margin_right", 16)
	page.add_theme_constant_override("margin_top", 14)
	page.add_theme_constant_override("margin_bottom", 6)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	page.add_child(vb)

	# Kartu ringkasan
	var sum := PanelContainer.new()
	sum.add_theme_stylebox_override("panel", _card_style())
	vb.add_child(sum)
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 14)
	sum.add_child(sh)
	var sic := Label.new()
	sic.text = "🧾"
	sic.add_theme_font_size_override("font_size", 52)
	sh.add_child(sic)
	var stx := VBoxContainer.new()
	stx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stx.add_theme_constant_override("separation", 0)
	sh.add_child(stx)
	_riwayat_info = Label.new()
	_riwayat_info.add_theme_font_size_override("font_size", 30)
	_riwayat_info.add_theme_color_override("font_color", C_INK)
	stx.add_child(_riwayat_info)
	var ssub := Label.new()
	ssub.text = "Ketuk tombol Struk untuk lihat nota"
	ssub.add_theme_font_size_override("font_size", 23)
	ssub.add_theme_color_override("font_color", C_MUTED)
	stx.add_child(ssub)

	_riwayat_search = LineEdit.new()
	_riwayat_search.placeholder_text = "🔍  Cari ID / nama produk..."
	_riwayat_search.clear_button_enabled = true
	_riwayat_search.custom_minimum_size = Vector2(0, 92)
	_style_input(_riwayat_search, 29)
	_riwayat_search.text_changed.connect(func(_t: String) -> void: _refresh_riwayat())
	vb.add_child(_riwayat_search)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	_riwayat_list = VBoxContainer.new()
	_riwayat_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_riwayat_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_riwayat_list)
	return page


func _refresh_riwayat() -> void:
	if _riwayat_list == null:
		return
	_clear_children(_riwayat_list)
	var trx: Array = DataStore.transactions
	_riwayat_info.text = "%d transaksi • %s" % [trx.size(), DataStore.rupiah(DataStore.omzet_total())]
	var kw := ""
	if _riwayat_search:
		kw = _riwayat_search.text.strip_edges().to_lower()
	var shown := 0
	for i in range(trx.size() - 1, -1, -1):
		var t: Dictionary = trx[i]
		if kw != "" and not _trx_match(t, kw):
			continue
		_riwayat_list.add_child(_make_trx_card(t, i))
		shown += 1
	if trx.is_empty():
		_riwayat_list.add_child(_empty_note("Belum ada transaksi."))
	elif shown == 0:
		_riwayat_list.add_child(_empty_note("Tidak cocok dengan pencarian."))


func _trx_match(t: Dictionary, kw: String) -> bool:
	if String(t["id"]).to_lower().contains(kw):
		return true
	for it in (t["items"] as Array):
		if String(it["name"]).to_lower().contains(kw):
			return true
	return false


func _empty_note(msg: String) -> Label:
	var l := Label.new()
	l.text = msg
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 27)
	l.add_theme_color_override("font_color", C_MUTED)
	return l


func _make_trx_card(t: Dictionary, idx: int) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	vb.add_child(top)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 0)
	top.add_child(left)
	var lid := Label.new()
	lid.text = String(t["id"])
	lid.add_theme_font_size_override("font_size", 27)
	lid.add_theme_color_override("font_color", C_INK)
	left.add_child(lid)
	var ltime := Label.new()
	ltime.text = DataStore.format_time(int(t["time"]))
	ltime.add_theme_font_size_override("font_size", 23)
	ltime.add_theme_color_override("font_color", C_MUTED)
	left.add_child(ltime)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 0)
	top.add_child(right)
	var ltotal := Label.new()
	ltotal.text = DataStore.rupiah(int(t["total"]))
	ltotal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ltotal.add_theme_font_size_override("font_size", 31)
	ltotal.add_theme_color_override("font_color", C_PRIMARY_D)
	right.add_child(ltotal)
	var lcount := Label.new()
	lcount.text = "%d item" % (t["items"] as Array).size()
	lcount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lcount.add_theme_font_size_override("font_size", 23)
	lcount.add_theme_color_override("font_color", C_MUTED)
	right.add_child(lcount)

	var bot := HBoxContainer.new()
	bot.add_theme_constant_override("separation", 8)
	vb.add_child(bot)
	var items: Array = t["items"]
	var preview := Label.new()
	var names: Array = []
	for k in mini(items.size(), 2):
		names.append(String(items[k]["name"]))
	preview.text = " • ".join(names)
	if items.size() > 2:
		preview.text += "  +%d lainnya" % (items.size() - 2)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.clip_text = true
	preview.add_theme_font_size_override("font_size", 24)
	preview.add_theme_color_override("font_color", C_MUTED)
	bot.add_child(preview)

	var tt: Dictionary = t
	var b := Button.new()
	b.text = "Struk →"
	b.custom_minimum_size = Vector2(168, 76)
	_style_button(b, C_PRIMARY_SOFT, C_PRIMARY_D, C_PRIMARY_SOFT, 999, 25)
	b.pressed.connect(_show_struk.bind(tt, idx))
	bot.add_child(b)
	return card


# ================= HALAMAN LAPORAN =================

func _make_laporan_page() -> Control:
	var page := MarginContainer.new()
	page.add_theme_constant_override("margin_left", 16)
	page.add_theme_constant_override("margin_right", 16)
	page.add_theme_constant_override("margin_top", 14)
	page.add_theme_constant_override("margin_bottom", 6)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	scroll.add_child(vb)

	# Hero: omzet hari ini
	var hero := PanelContainer.new()
	var hs := StyleBoxFlat.new()
	hs.bg_color = C_PRIMARY_D
	hs.set_corner_radius_all(24)
	hs.content_margin_left = 24
	hs.content_margin_right = 24
	hs.content_margin_top = 20
	hs.content_margin_bottom = 20
	hs.shadow_color = Color(0.85, 0.42, 0.12, 0.35)
	hs.shadow_size = 12
	hs.shadow_offset = Vector2(0, 4)
	hero.add_theme_stylebox_override("panel", hs)
	vb.add_child(hero)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 2)
	hero.add_child(hv)
	var hey := Label.new()
	hey.text = "💰  OMZET HARI INI"
	hey.add_theme_font_size_override("font_size", 24)
	hey.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	hv.add_child(hey)
	_lap_hari = Label.new()
	_lap_hari.text = "Rp0"
	_lap_hari.add_theme_font_size_override("font_size", 56)
	_lap_hari.add_theme_color_override("font_color", Color.WHITE)
	hv.add_child(_lap_hari)
	_lap_hero_sub = Label.new()
	_lap_hero_sub.add_theme_font_size_override("font_size", 25)
	_lap_hero_sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	hv.add_child(_lap_hero_sub)

	# Dua kartu mini sejajar
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	_lap_total = _make_mini_card(row, "🏦  TOTAL OMZET")
	_lap_count = _make_mini_card(row, "🧾  TRANSAKSI")

	# Grafik 7 hari
	var chart_card := PanelContainer.new()
	chart_card.add_theme_stylebox_override("panel", _card_style())
	vb.add_child(chart_card)
	var chv := VBoxContainer.new()
	chv.add_theme_constant_override("separation", 8)
	chart_card.add_child(chv)
	var cht := Label.new()
	cht.text = "📈  7 HARI TERAKHIR"
	cht.add_theme_font_size_override("font_size", 24)
	cht.add_theme_color_override("font_color", C_MUTED)
	chv.add_child(cht)
	_lap_chart = HBoxContainer.new()
	_lap_chart.add_theme_constant_override("separation", 8)
	_lap_chart.custom_minimum_size = Vector2(0, 250)
	chv.add_child(_lap_chart)

	# Produk terlaris
	var best_card := PanelContainer.new()
	best_card.add_theme_stylebox_override("panel", _card_style())
	vb.add_child(best_card)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 10)
	best_card.add_child(bh)
	var bl := VBoxContainer.new()
	bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bl.add_theme_constant_override("separation", 2)
	bh.add_child(bl)
	var bt := Label.new()
	bt.text = "⭐  PRODUK TERLARIS"
	bt.add_theme_font_size_override("font_size", 24)
	bt.add_theme_color_override("font_color", C_MUTED)
	bl.add_child(bt)
	_lap_best = Label.new()
	_lap_best.text = "-"
	_lap_best.add_theme_font_size_override("font_size", 32)
	_lap_best.add_theme_color_override("font_color", C_INK)
	bl.add_child(_lap_best)
	var medal := Label.new()
	medal.text = "🥇"
	medal.add_theme_font_size_override("font_size", 52)
	bh.add_child(medal)

	var b_reset := Button.new()
	b_reset.text = "Hapus Semua Data"
	b_reset.custom_minimum_size = Vector2(0, 96)
	_style_button(b_reset, Color.WHITE, C_DANGER, C_DANGER, 18, 28)
	b_reset.pressed.connect(_on_reset_pressed)
	vb.add_child(b_reset)
	return page


func _make_mini_card(parent: Control, title: String) -> Label:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _card_style())
	parent.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	card.add_child(vb)
	var lt := Label.new()
	lt.text = title
	lt.add_theme_font_size_override("font_size", 22)
	lt.add_theme_color_override("font_color", C_MUTED)
	vb.add_child(lt)
	var lv := Label.new()
	lv.text = "-"
	lv.add_theme_font_size_override("font_size", 33)
	lv.add_theme_color_override("font_color", C_INK)
	vb.add_child(lv)
	return lv


func _make_stat_card(parent: Control, title: String, _accent: Color) -> Label:
	return _make_mini_card(parent, title)


func _refresh_laporan() -> void:
	if _lap_hari == null:
		return
	var today := DataStore.today_key()
	var count_today := 0
	for t in DataStore.transactions:
		if DataStore.date_key(int(t["time"])) == today:
			count_today += 1
	_lap_hari.text = DataStore.rupiah(DataStore.omzet_today())
	_lap_hero_sub.text = "%s  •  %d transaksi" % [_pretty_today(), count_today]
	_lap_total.text = DataStore.rupiah(DataStore.omzet_total())
	_lap_count.text = "%d transaksi" % DataStore.transactions.size()
	# Produk terlaris
	var qty_map: Dictionary = {}
	var name_map: Dictionary = {}
	for t in DataStore.transactions:
		for it in (t["items"] as Array):
			var pid := int(it["id"])
			qty_map[pid] = int(qty_map.get(pid, 0)) + int(it["qty"])
			name_map[pid] = String(it["name"])
	var best := "-"
	var best_q := 0
	for pid in qty_map.keys():
		if int(qty_map[pid]) > best_q:
			best_q = int(qty_map[pid])
			best = "%s (%d pcs)" % [String(name_map[pid]), best_q]
	_lap_best.text = best
	_refresh_chart()


func _pretty_today() -> String:
	var d := Time.get_date_dict_from_system()
	var months := ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"]
	var m: int = clampi(int(d["month"]) - 1, 0, 11)
	return "%02d %s %04d" % [int(d["day"]), months[m], int(d["year"])]


func _short_money(v: int) -> String:
	if v >= 1000000:
		var j := v / 1000000.0
		if j >= 10.0:
			return "%d jt" % int(round(j))
		return "%.1f jt" % j
	if v >= 1000:
		return "%d rb" % int(round(v / 1000.0))
	return str(v)


func _refresh_chart() -> void:
	if _lap_chart == null:
		return
	_clear_children(_lap_chart)
	var day_names := ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"]
	var now := int(Time.get_unix_time_from_system())
	var days: Array = []
	for back in range(6, -1, -1):
		var dd := Time.get_datetime_dict_from_unix_time(float(now - back * 86400))
		days.append({
			"key": "%04d-%02d-%02d" % [int(dd["year"]), int(dd["month"]), int(dd["day"])],
			"wd": int(dd["weekday"]),
			"today": back == 0,
		})
	var sums: Dictionary = {}
	for dd in days:
		sums[String(dd["key"])] = 0
	for t in DataStore.transactions:
		var k := DataStore.date_key(int(t["time"]))
		if sums.has(k):
			sums[k] = int(sums[k]) + int(t["total"])
	var mx := 1
	for dd in days:
		mx = maxi(mx, int(sums[String(dd["key"])]))
	for dd in days:
		var v: int = int(sums[String(dd["key"])])
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		_lap_chart.add_child(col)
		var val := Label.new()
		val.text = _short_money(v) if v > 0 else ""
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val.custom_minimum_size = Vector2(0, 30)
		val.add_theme_font_size_override("font_size", 19)
		val.add_theme_color_override("font_color", C_MUTED)
		col.add_child(val)
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(spacer)
		var bar := PanelContainer.new()
		var h := 14 + int(140.0 * v / mx)
		bar.custom_minimum_size = Vector2(0, h)
		var bs := StyleBoxFlat.new()
		bs.set_corner_radius_all(8)
		if bool(dd["today"]):
			bs.bg_color = C_PRIMARY
		elif v > 0:
			bs.bg_color = Color("fdba74")
		else:
			bs.bg_color = Color("e2e8f0")
		bar.add_theme_stylebox_override("panel", bs)
		col.add_child(bar)
		var nm := Label.new()
		nm.text = day_names[clampi(int(dd["wd"]), 0, 6)]
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_size_override("font_size", 21)
		if bool(dd["today"]):
			nm.add_theme_color_override("font_color", C_PRIMARY_D)
		else:
			nm.add_theme_color_override("font_color", C_MUTED)
		col.add_child(nm)


func _on_reset_pressed() -> void:
	_ask_confirm("⚠️ Hapus Semua Data?", "Hapus SEMUA produk & transaksi? Tindakan ini tidak bisa dibatalkan.", "Ya, hapus", _do_reset_all)


func _do_reset_all() -> void:
	DataStore.clear_all_data()
	_clear_cart()
	_toast("Semua data dihapus.")


# ================= POPUP CUSTOM =================

func _make_popups() -> void:
	_make_form_popup()
	_make_struk_popup()
	_make_confirm_popup()
	_make_toast()


func _make_form_popup() -> void:
	_pop_form = _dim_overlay()
	var vb := _popup_card(_pop_form, 600.0)
	_pop_form_card = vb.get_parent() as PanelContainer

	_pop_form_title = Label.new()
	_pop_form_title.text = "＋ Tambah Produk"
	_pop_form_title.add_theme_font_size_override("font_size", 36)
	_pop_form_title.add_theme_color_override("font_color", C_INK)
	vb.add_child(_pop_form_title)
	var sub := Label.new()
	sub.text = "Lengkapi nama, harga, dan stok di bawah."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 25)
	sub.add_theme_color_override("font_color", C_MUTED)
	vb.add_child(sub)

	vb.add_child(_dlg_caption("NAMA PRODUK"))
	_fld_nama = _dlg_field(vb, "Cth: Kopi Susu Gula Aren")
	vb.add_child(_dlg_caption("HARGA JUAL (Rp)"))
	_fld_harga = _dlg_field(vb, "Cth: 10000")
	_fld_harga.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	vb.add_child(_dlg_caption("STOK"))
	_fld_stok = _dlg_field(vb, "Cth: 50")
	_fld_stok.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(row)
	var b_cancel := Button.new()
	b_cancel.text = "Batal"
	b_cancel.custom_minimum_size = Vector2(220, 92)
	_style_button(b_cancel, Color("f1f5f9"), C_MUTED, Color("f1f5f9"), 14, 28)
	b_cancel.pressed.connect(func() -> void: _popup_hide(_pop_form))
	row.add_child(b_cancel)
	var b_save := Button.new()
	b_save.text = "Simpan"
	b_save.custom_minimum_size = Vector2(220, 92)
	_style_button(b_save, C_PRIMARY, Color.WHITE, C_PRIMARY, 14, 28)
	b_save.pressed.connect(_save_product_dialog)
	row.add_child(b_save)


func _make_struk_popup() -> void:
	_pop_struk = _dim_overlay()
	var vb := _popup_card(_pop_struk, 600.0)
	_pop_struk_card = vb.get_parent() as PanelContainer

	# Kepala nota
	_pop_struk_title = Label.new()
	_pop_struk_title.text = "STRUK PEMBAYARAN"
	_pop_struk_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pop_struk_title.add_theme_font_size_override("font_size", 23)
	_pop_struk_title.add_theme_color_override("font_color", C_MUTED)
	vb.add_child(_pop_struk_title)

	var logo := Label.new()
	logo.text = "CRABSIR"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 52)
	logo.add_theme_color_override("font_color", C_PRIMARY_D)
	vb.add_child(logo)

	var addr := Label.new()
	addr.text = "Jl. Merdeka No. 45 • 0812-3456-7890"
	addr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	addr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	addr.add_theme_font_size_override("font_size", 23)
	addr.add_theme_color_override("font_color", C_MUTED)
	vb.add_child(addr)

	_dash_sep(vb)

	_struk_meta = Label.new()
	_struk_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_struk_meta.add_theme_font_size_override("font_size", 25)
	_struk_meta.add_theme_color_override("font_color", C_INK)
	vb.add_child(_struk_meta)

	_dash_sep(vb)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	_struk_items = VBoxContainer.new()
	_struk_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_struk_items.add_theme_constant_override("separation", 10)
	scroll.add_child(_struk_items)

	_dash_sep(vb)

	# Kotak total
	var total_box := PanelContainer.new()
	var ts := StyleBoxFlat.new()
	ts.bg_color = C_PRIMARY_D
	ts.set_corner_radius_all(16)
	ts.content_margin_left = 20
	ts.content_margin_right = 20
	ts.content_margin_top = 12
	ts.content_margin_bottom = 12
	total_box.add_theme_stylebox_override("panel", ts)
	vb.add_child(total_box)
	var th := HBoxContainer.new()
	total_box.add_child(th)
	var tl := Label.new()
	tl.text = "TOTAL"
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.add_theme_font_size_override("font_size", 30)
	tl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	th.add_child(tl)
	_struk_total = Label.new()
	_struk_total.add_theme_font_size_override("font_size", 38)
	_struk_total.add_theme_color_override("font_color", Color.WHITE)
	th.add_child(_struk_total)

	_struk_bayar_v = _receipt_kv(vb, "Bayar")
	_struk_kembali_v = _receipt_kv(vb, "Kembali")

	_dash_sep(vb)

	# Barcode mainan dari ID transaksi
	var bc_center := HBoxContainer.new()
	bc_center.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(bc_center)
	_struk_barcode = HBoxContainer.new()
	_struk_barcode.add_theme_constant_override("separation", 0)
	bc_center.add_child(_struk_barcode)

	var thanks := Label.new()
	thanks.text = "★ Terima kasih ★"
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks.add_theme_font_size_override("font_size", 30)
	thanks.add_theme_color_override("font_color", C_INK)
	vb.add_child(thanks)
	var bye := Label.new()
	bye.text = "Sampai jumpa kembali!"
	bye.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bye.add_theme_font_size_override("font_size", 24)
	bye.add_theme_color_override("font_color", C_MUTED)
	vb.add_child(bye)

	var b_close := Button.new()
	b_close.text = "Tutup"
	b_close.custom_minimum_size = Vector2(0, 96)
	_style_button(b_close, C_SUCCESS, Color.WHITE, C_SUCCESS, 14, 30)
	b_close.pressed.connect(func() -> void: _popup_hide(_pop_struk))
	vb.add_child(b_close)


func _dash_sep(parent: Control) -> void:
	var d := Label.new()
	d.text = "- ".repeat(30)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.add_theme_font_size_override("font_size", 22)
	d.add_theme_color_override("font_color", Color("94a3b8"))
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(d)


func _receipt_kv(parent: Control, key: String) -> Label:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var k := Label.new()
	k.text = key
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.add_theme_font_size_override("font_size", 27)
	k.add_theme_color_override("font_color", C_MUTED)
	row.add_child(k)
	var v := Label.new()
	v.add_theme_font_size_override("font_size", 28)
	v.add_theme_color_override("font_color", C_INK)
	row.add_child(v)
	return v


func _build_barcode(box: HBoxContainer, seed_text: String) -> void:
	_clear_children(box)
	var x := absi(hash(seed_text)) + 7
	for i in 34:
		x = (x * 1103515245 + 12345) & 0x7fffffff
		var bar := ColorRect.new()
		if i % 2 == 0:
			bar.color = Color(0.06, 0.08, 0.18)
			bar.custom_minimum_size = Vector2(3 + x % 6, 88)
		else:
			bar.color = Color.WHITE
			bar.custom_minimum_size = Vector2(2 + x % 5, 88)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(bar)


func _make_confirm_popup() -> void:
	_pop_confirm = _dim_overlay()
	var vb := _popup_card(_pop_confirm, 560.0)
	_pop_confirm_card = vb.get_parent() as PanelContainer

	_confirm_title = Label.new()
	_confirm_title.text = "Hapus?"
	_confirm_title.add_theme_font_size_override("font_size", 34)
	_confirm_title.add_theme_color_override("font_color", C_INK)
	vb.add_child(_confirm_title)
	_confirm_msg = Label.new()
	_confirm_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_msg.add_theme_font_size_override("font_size", 28)
	_confirm_msg.add_theme_color_override("font_color", C_MUTED)
	vb.add_child(_confirm_msg)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(row)
	var b_cancel := Button.new()
	b_cancel.text = "Batal"
	b_cancel.custom_minimum_size = Vector2(220, 92)
	_style_button(b_cancel, Color("f1f5f9"), C_MUTED, Color("f1f5f9"), 14, 28)
	b_cancel.pressed.connect(func() -> void: _popup_hide(_pop_confirm))
	row.add_child(b_cancel)
	_confirm_ok = Button.new()
	_confirm_ok.text = "Ya"
	_confirm_ok.custom_minimum_size = Vector2(220, 92)
	_style_button(_confirm_ok, C_DANGER, Color.WHITE, C_DANGER, 14, 28)
	_confirm_ok.pressed.connect(_on_confirm_ok)
	row.add_child(_confirm_ok)


func _on_confirm_ok() -> void:
	_popup_hide(_pop_confirm)
	if _confirm_action.is_valid():
		_confirm_action.call()
	_confirm_action = Callable()


func _make_toast() -> void:
	_toast_layer = Control.new()
	_toast_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_layer.visible = false
	add_child(_toast_layer)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_bottom", 190)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_layer.add_child(margin)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_END
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vb)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(hb)
	_toast_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.18, 0.92)
	sb.set_corner_radius_all(999)
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	_toast_panel.add_theme_stylebox_override("panel", sb)
	hb.add_child(_toast_panel)
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 28)
	_toast_label.add_theme_color_override("font_color", Color.WHITE)
	_toast_panel.add_child(_toast_label)


func _dlg_field(parent: Control, placeholder: String) -> LineEdit:
	var f := LineEdit.new()
	f.placeholder_text = placeholder
	f.custom_minimum_size = Vector2(0, 92)
	_style_input(f, 29)
	parent.add_child(f)
	return f


func _show_struk(t: Dictionary, idx: int = -1) -> void:
	_struk_meta.text = "%s\n%s" % [String(t["id"]), DataStore.format_time(int(t["time"]))]
	_clear_children(_struk_items)
	for it in (t["items"] as Array):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_struk_items.add_child(row)
		var left := VBoxContainer.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left.add_theme_constant_override("separation", 0)
		row.add_child(left)
		var nm := Label.new()
		nm.text = String(it["name"])
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.add_theme_font_size_override("font_size", 28)
		nm.add_theme_color_override("font_color", C_INK)
		left.add_child(nm)
		var dt := Label.new()
		dt.text = "%d × %s" % [int(it["qty"]), DataStore.rupiah(int(it["price"]))]
		dt.add_theme_font_size_override("font_size", 24)
		dt.add_theme_color_override("font_color", C_MUTED)
		left.add_child(dt)
		var sub := Label.new()
		sub.text = DataStore.rupiah(int(it["subtotal"]))
		sub.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		sub.add_theme_font_size_override("font_size", 28)
		sub.add_theme_color_override("font_color", C_INK)
		row.add_child(sub)
	_struk_total.text = DataStore.rupiah(int(t["total"]))
	_struk_bayar_v.text = DataStore.rupiah(int(t["bayar"]))
	_struk_kembali_v.text = DataStore.rupiah(int(t["kembali"]))
	_build_barcode(_struk_barcode, String(t["id"]))
	_popup_show(_pop_struk)


# ================= REFRESH =================

func _refresh_all() -> void:
	_refresh_product_grid()
	_refresh_cart()
	_refresh_produk_list()
	_refresh_riwayat()
	if _pages.size() == 4 and _pages[3].visible:
		_refresh_laporan()


func _clear_children(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()
