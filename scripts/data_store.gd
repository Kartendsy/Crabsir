extends Node
## DataStore: autoload untuk produk & transaksi, simpan JSON lokal.
## Cocok untuk Android (user://).

signal products_changed
signal transactions_changed

const SAVE_PATH := "user://kasiro_data.json"

var products: Array = []       # [{id:int, name:String, price:int, stock:int}]
var transactions: Array = []   # [{id:String, time:int, items:Array, total:int, bayar:int, kembali:int}]
var _next_product_id: int = 1


func _ready() -> void:
	load_data()
	if products.is_empty():
		_seed_sample_data()


func rupiah(n: int) -> String:
	# Format 15000 -> "Rp15.000"
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	out = s + out
	if n < 0:
		out = "-" + out
	return "Rp" + out


func today_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


func date_key(unix: int) -> String:
	var d := Time.get_date_dict_from_unix_time(unix)
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


func format_time(unix: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(unix)
	return "%04d-%02d-%02d %02d:%02d" % [d["year"], d["month"], d["day"], d["hour"], d["minute"]]


# ---------- Produk ----------

func add_product(p_name: String, price: int, stock: int) -> Dictionary:
	var p := {
		"id": _next_product_id,
		"name": p_name.strip_edges(),
		"price": maxi(0, price),
		"stock": maxi(0, stock),
	}
	_next_product_id += 1
	products.append(p)
	save_data()
	products_changed.emit()
	return p


func update_product(id: int, p_name: String, price: int, stock: int) -> bool:
	for p in products:
		if int(p["id"]) == id:
			p["name"] = p_name.strip_edges()
			p["price"] = maxi(0, price)
			p["stock"] = maxi(0, stock)
			save_data()
			products_changed.emit()
			return true
	return false


func delete_product(id: int) -> void:
	for i in range(products.size() - 1, -1, -1):
		if int(products[i]["id"]) == id:
			products.remove_at(i)
	save_data()
	products_changed.emit()


func get_product(id: int) -> Dictionary:
	for p in products:
		if int(p["id"]) == id:
			return p
	return {}


func search_products(keyword: String) -> Array:
	var kw := keyword.strip_edges().to_lower()
	if kw == "":
		return products.duplicate()
	var out: Array = []
	for p in products:
		if String(p["name"]).to_lower().contains(kw):
			out.append(p)
	return out


func decrease_stock(id: int, qty: int) -> void:
	for p in products:
		if int(p["id"]) == id:
			p["stock"] = maxi(0, int(p["stock"]) - qty)
	save_data()
	products_changed.emit()


# ---------- Transaksi ----------

func add_transaction(items: Array, total: int, bayar: int) -> Dictionary:
	var t := {
		"id": "TRX-%s-%d" % [Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", ""), transactions.size() + 1],
		"time": int(Time.get_unix_time_from_system()),
		"items": items.duplicate(true),
		"total": total,
		"bayar": bayar,
		"kembali": bayar - total,
	}
	# Kurangi stok
	for it in items:
		decrease_stock_no_save(int(it["id"]), int(it["qty"]))
	transactions.append(t)
	save_data()
	products_changed.emit()
	transactions_changed.emit()
	return t


func decrease_stock_no_save(id: int, qty: int) -> void:
	for p in products:
		if int(p["id"]) == id:
			p["stock"] = maxi(0, int(p["stock"]) - qty)


func delete_transaction(idx: int) -> void:
	if idx >= 0 and idx < transactions.size():
		transactions.remove_at(idx)
		save_data()
		transactions_changed.emit()


func clear_all_data() -> void:
	products.clear()
	transactions.clear()
	_next_product_id = 1
	save_data()
	products_changed.emit()
	transactions_changed.emit()


func omzet_today() -> int:
	var k := today_key()
	var sum := 0
	for t in transactions:
		if date_key(int(t["time"])) == k:
			sum += int(t["total"])
	return sum


func omzet_total() -> int:
	var sum := 0
	for t in transactions:
		sum += int(t["total"])
	return sum


# ---------- Simpan / Muat ----------

func save_data() -> void:
	var data := {
		"next_id": _next_product_id,
		"products": products,
		"transactions": transactions,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	products = parsed.get("products", [])
	transactions = parsed.get("transactions", [])
	_next_product_id = int(parsed.get("next_id", 1))
	# Jaga next_id tetap unik
	var mx := 0
	for p in products:
		mx = maxi(mx, int(p.get("id", 0)))
	_next_product_id = maxi(_next_product_id, mx + 1)


func _seed_sample_data() -> void:
	add_product("Kopi Tubruk", 8000, 50)
	add_product("Teh Manis", 5000, 50)
	add_product("Indomie Goreng", 12000, 30)
	add_product("Roti Bakar", 10000, 20)
	add_product("Air Mineral", 3000, 100)
