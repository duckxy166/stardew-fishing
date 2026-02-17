extends Node

# ====================================================
# FishData.gd - Episode 4
# ====================================================
# เพิ่มจาก EP01:
# - static var inventory เก็บสถิติการจับ
# - add_catch() บันทึกการจับแต่ละครั้ง
# - get_total_value() คำนวณมูลค่ารวม
# - get_catch_count() ดูจำนวนที่จับได้
# ====================================================


# --------------------------------------------------
# ข้อมูลปลาทุกชนิด (เหมือนเดิม)
# --------------------------------------------------
# weight = โอกาสที่ปลาชนิดนี้จะขึ้น
# ยิ่งสูง ยิ่งออกบ่อย
# Anchovy 30 vs Salmon 15 = Anchovy ออกบ่อยกว่า 2 เท่า

const FISH_LIST: Array = [
	{
		"id": "salmon",
		"name": "Salmon",
		"name_th": "ปลาแซลมอน",
		"price": 75,
		"difficulty": 0.7,
		"color": Color(0.9, 0.3, 0.3),
		"min_time": 3.0,
		"max_time": 6.0,
		"weight": 15,
		"desc": "ปลาน้ำเย็น ว่องไว จับยาก แต่ราคาดี"
	},
	{
		"id": "sea_cucumber",
		"name": "Sea Cucumber",
		"name_th": "ปลิงทะเล",
		"price": 75,
		"difficulty": 0.35,
		"color": Color(0.4, 0.7, 0.4),
		"min_time": 2.0,
		"max_time": 5.0,
		"weight": 20,
		"desc": "เคลื่อนที่ช้า จับง่าย แต่ราคาดีเกินคาด"
	},
	{
		"id": "shad",
		"name": "Shad",
		"name_th": "ปลาแชด",
		"price": 60,
		"difficulty": 0.5,
		"color": Color(0.6, 0.8, 1.0),
		"min_time": 3.0,
		"max_time": 7.0,
		"weight": 25,
		"desc": "ปลาขนาดกลาง จับได้ไม่ยากนัก"
	},
	{
		"id": "herring",
		"name": "Herring",
		"name_th": "ปลาเฮอร์ริ่ง",
		"price": 30,
		"difficulty": 0.3,
		"color": Color(0.7, 0.7, 1.0),
		"min_time": 2.0,
		"max_time": 5.0,
		"weight": 25,
		"desc": "ปลาพบได้ทั่วไป จับง่าย ราคาต่ำ"
	},
	{
		"id": "anchovy",
		"name": "Anchovy",
		"name_th": "ปลาแอนโชวี",
		"price": 30,
		"difficulty": 0.3,
		"color": Color(0.9, 0.9, 0.4),
		"min_time": 2.0,
		"max_time": 4.0,
		"weight": 30,
		"desc": "ปลาตัวเล็ก ขึ้นบ่อยที่สุด เหมาะสำหรับมือใหม่"
	},
]


# --------------------------------------------------
# Inventory - สถิติการจับปลา (EP4 ใหม่)
# --------------------------------------------------
# ไม่ใช่ const เพราะต้องการแก้ค่าได้ระหว่างเกม
# Dictionary: key = fish id, value = จำนวนที่จับได้
#
# ทำไมใช้ static var?
# static var คือตัวแปรที่ใช้ร่วมกันทุก instance ของ class
# เนื่องจาก FishData เป็น Autoload (มี instance เดียว)
# จึงไม่ต่างกัน แต่ static ทำให้เรียกจาก get_fish_by_id() ได้โดยตรง

var inventory: Dictionary = {}
var total_earned: int = 0          # เงินรวมที่หาได้ตลอดเกม
var total_caught: int = 0          # จำนวนปลารวมที่จับได้
var total_escaped: int = 0         # จำนวนครั้งที่ปลาหนี


# --------------------------------------------------
# get_random_fish() - สุ่มปลาด้วย Weighted Random
# --------------------------------------------------
# อธิบาย algorithm:
# 1. รวม weight ทั้งหมด
# 2. สุ่มเลข 0 ถึง total-1
# 3. ลบ weight ทีละตัว ปลาไหนทำให้ roll ติดลบ = ปลานั้น

func get_random_fish() -> Dictionary:
	var total_weight = 0
	for fish in FISH_LIST:
		total_weight += fish["weight"]

	var roll = randi_range(0, total_weight - 1)

	for fish in FISH_LIST:
		roll -= fish["weight"]
		if roll < 0:
			return fish

	return FISH_LIST[-1]


# --------------------------------------------------
# add_catch() - บันทึกการจับปลา (EP4 ใหม่)
# --------------------------------------------------
# เรียกจาก Main.gd ตอน on_minigame_success()
# fish_data = Dictionary ที่ได้จาก signal fish_caught

func add_catch(fish_data: Dictionary) -> void:
	var id = fish_data.get("id", "unknown")

	# ถ้ายังไม่เคยจับปลาชนิดนี้ ตั้งค่าเริ่มต้นเป็น 0
	if not inventory.has(id):
		inventory[id] = 0

	# เพิ่มจำนวน
	inventory[id] += 1
	total_caught += 1
	total_earned += fish_data.get("price", 0)


# --------------------------------------------------
# add_escape() - บันทึกปลาที่หนีไป (EP4 ใหม่)
# --------------------------------------------------

func add_escape() -> void:
	total_escaped += 1


# --------------------------------------------------
# get_catch_count() - ดูจำนวนปลาชนิดที่จับได้ (EP4 ใหม่)
# --------------------------------------------------

func get_catch_count(fish_id: String) -> int:
	return inventory.get(fish_id, 0)


# --------------------------------------------------
# get_total_value() - คำนวณมูลค่าปลาทั้งหมดใน inventory (EP4 ใหม่)
# --------------------------------------------------

func get_total_value() -> int:
	var total = 0
	for id in inventory:
		var fish = get_fish_by_id(id)
		if not fish.is_empty():
			total += fish["price"] * inventory[id]
	return total


# --------------------------------------------------
# get_inventory_list() - แปลง inventory เป็น Array สำหรับแสดงผล (EP4 ใหม่)
# --------------------------------------------------
# คืน Array ของ Dictionary แต่ละตัวมี: id, name, count, total_price

func get_inventory_list() -> Array:
	var result = []
	for id in inventory:
		var fish = get_fish_by_id(id)
		if not fish.is_empty():
			result.append({
				"id": id,
				"name": fish["name"],
				"name_th": fish.get("name_th", fish["name"]),
				"count": inventory[id],
				"price_each": fish["price"],
				"total_price": fish["price"] * inventory[id],
				"color": fish["color"]
			})

	# เรียงตาม total_price มากไปน้อย
	# Callable คือการส่งฟังก์ชันเป็น argument
	result.sort_custom(func(a, b): return a["total_price"] > b["total_price"])
	return result


# --------------------------------------------------
# get_fish_by_id() - หาปลาจาก id
# --------------------------------------------------

func get_fish_by_id(id: String) -> Dictionary:
	for fish in FISH_LIST:
		if fish["id"] == id:
			return fish
	return {}


# --------------------------------------------------
# reset_inventory() - รีเซ็ตสถิติทั้งหมด (EP4 ใหม่)
# --------------------------------------------------

func reset_inventory() -> void:
	inventory.clear()
	total_earned = 0
	total_caught = 0
	total_escaped = 0
