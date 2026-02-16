extends Node

# ====================================================
# FishData.gd - ข้อมูลปลาทุกชนิดในเกม
# ====================================================
# ทำเป็น Autoload (Singleton) เพื่อให้ทุก Scene เรียกใช้ได้
# วิธีตั้ง Autoload: Project > Project Settings > Autoload
# กด + แล้วเลือกไฟล์นี้ ตั้งชื่อ "FishData"
# จากนั้น script ไหนก็ตามเรียก FishData.FISH_LIST ได้เลย
# ====================================================


# --------------------------------------------------
# ข้อมูลปลาทุกชนิด
# --------------------------------------------------
# Dictionary คือการเก็บข้อมูลแบบ key-value
# เหมือน JSON ที่คุ้นเคยกัน
#
# price    = ราคาขาย (Gold)
# difficulty = ความยาก mini-game (0.0 ง่าย ถึง 1.0 ยาก)
# color    = สีของ fish icon ใน mini-game (ก่อน EP5 มี sprite จริง)
# min_time = เวลารอน้อยสุดก่อนปลากิน (วินาที)
# max_time = เวลารอมากสุดก่อนปลากิน (วินาที)
# weight   = โอกาสที่ปลาชนิดนี้จะขึ้นมา (สูง = ขึ้นบ่อย)
# desc     = คำอธิบายปลาภาษาไทย

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
# get_random_fish() - สุ่มปลาโดยใช้ระบบ weight
# --------------------------------------------------
# ระบบ weight คือการสุ่มที่ไม่เท่ากัน
# เช่น Anchovy weight 30, Salmon weight 15
# Anchovy มีโอกาสออกมาเป็น 2 เท่าของ Salmon
#
# วิธีคิด: สุ่มเลขจาก 0 ถึง weight_total
# แล้วลบ weight ของแต่ละปลาออกทีละตัว
# ปลาที่ทำให้ผลรวมติดลบ = ปลาที่ถูกเลือก

static func get_random_fish() -> Dictionary:
	# คำนวณ weight รวมทั้งหมด
	var total_weight = 0
	for fish in FISH_LIST:
		total_weight += fish["weight"]

	# สุ่มเลขในช่วง 0 ถึง total_weight
	var roll = randi_range(0, total_weight - 1)

	# ไล่ทีละตัว ลบ weight ออกเรื่อยๆ
	for fish in FISH_LIST:
		roll -= fish["weight"]
		if roll < 0:
			return fish

	# ถ้าเกิด error (ไม่ควรเกิด) ส่งค่าสุดท้ายกลับไป
	return FISH_LIST[-1]


# --------------------------------------------------
# get_fish_by_id() - หาปลาจาก id
# --------------------------------------------------
static func get_fish_by_id(id: String) -> Dictionary:
	for fish in FISH_LIST:
		if fish["id"] == id:
			return fish
	return {}
