extends Control

@onready var fish_list: VBoxContainer = $Panel/VBox/FishList
@onready var total_label: Label       = $Panel/VBox/TotalLabel
@onready var stats_label: Label       = $Panel/VBox/StatsLabel

func _ready() -> void:
	hide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_TAB and event.pressed:
			toggle()

func toggle() -> void:
	if visible:
		hide()
	else:
		refresh()
		show()

func refresh() -> void:
	# ลบ row เก่า (dynamic ต้องทำใน code)
	for child in fish_list.get_children():
		child.queue_free()

	var inventory = FishData.get_inventory_list()

	if inventory.is_empty():
		var empty = Label.new()
		empty.text = "ยังไม่เคยจับปลาเลย..."
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		fish_list.add_child(empty)
	else:
		for entry in inventory:
			add_fish_row(entry)   # แค่ row เท่านั้นที่ทำใน code

	# อัปเดต label ที่มีอยู่ใน editor แล้ว
	total_label.text = "มูลค่ารวม: " + str(FishData.get_total_value()) + " G"
	stats_label.text = (
		"จับได้: " + str(FishData.total_caught) +
		"  |  หนีไป: " + str(FishData.total_escaped)
	)

func add_fish_row(entry: Dictionary) -> void:
	# row นี้ dynamic เพราะไม่รู้จำนวนล่วงหน้า ทำใน code ถูกต้อง
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	fish_list.add_child(row)

	var color_dot = ColorRect.new()
	color_dot.custom_minimum_size = Vector2(14, 14)
	color_dot.color = entry["color"]
	row.add_child(color_dot)

	var name_lbl = Label.new()
	name_lbl.text = entry["name_th"]
	name_lbl.custom_minimum_size.x = 130
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(name_lbl)

	var count_lbl = Label.new()
	count_lbl.text = "x" + str(entry["count"])
	count_lbl.custom_minimum_size.x = 36
	count_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	row.add_child(count_lbl)

	var price_lbl = Label.new()
	price_lbl.text = str(entry["price_each"]) + " G / ตัว"
	price_lbl.custom_minimum_size.x = 90
	price_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	row.add_child(price_lbl)

	var total_lbl = Label.new()
	total_lbl.text = "= " + str(entry["total_price"]) + " G"
	total_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	row.add_child(total_lbl)
