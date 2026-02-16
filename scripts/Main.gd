extends Node2D

# ====================================================
# Main.gd - Script หลักของเกมตกปลา
# ====================================================
# Script นี้ควบคุม "loop" หลักของเกมทั้งหมด
# ทุกอย่างเริ่มและจบที่นี่
# ====================================================


# --------------------------------------------------
# State Machine
# --------------------------------------------------
# enum คือการสร้างชื่อให้กับตัวเลข
# แทนที่จะใช้ current_state = 0, 1, 2...
# เราใช้ current_state = FishingState.CASTING
# ทำให้โค้ดอ่านง่ายขึ้นมาก

enum FishingState {
	CASTING,    # 0 - กำลังเหวี่ยงเบ็ด
	WAITING,    # 1 - รอปลากิน
	BITING,     # 2 - ปลากินเบ็ดแล้ว รอผู้เล่นคลิก
	MINIGAME,   # 3 - อยู่ใน mini-game
	RESULT      # 4 - แสดงผลว่าจับได้หรือพลาด
}

# ตัวแปรเก็บสถานะปัจจุบัน
var current_state: FishingState = FishingState.CASTING


# --------------------------------------------------
# ข้อมูลเกม
# --------------------------------------------------

var money: int = 0                  # เงินของผู้เล่น
var current_fish: Dictionary = {}   # ปลาที่กำลังจะจับ (เลือกตอน WAITING)

# เวลาสุ่มสำหรับรอปลากิน (วินาที)
const MIN_WAIT_TIME: float = 3.0
const MAX_WAIT_TIME: float = 8.0
var wait_timer: float = 0.0         # นับถอยหลัง

# เวลาที่ผู้เล่นมีโอกาสคลิกตอนปลากิน (วินาที)
const BITE_WINDOW: float = 2.0
var bite_timer: float = 0.0         # นับถอยหลัง


# --------------------------------------------------
# References ไปยัง Node ลูก
# --------------------------------------------------
# @onready หมายความว่า "ให้หา Node นี้ตอนที่ scene โหลดเสร็จแล้ว"
# ถ้าเราไม่ใช้ @onready แล้วหา Node ใน _init() จะ error
# เพราะ Node ยังไม่ถูกสร้างขึ้นมา

@onready var money_label: Label = $UI/MoneyLabel
@onready var notify_label: Label = $UI/NotifyLabel
@onready var casting_label: Label = $UI/CastingLabel
@onready var bobber: Sprite2D = $FishingRod/Bobber
@onready var fishing_line: Line2D = $FishingRod/Line
@onready var animation_player: AnimationPlayer = $Character/AnimationPlayer
@onready var minigame_container: Control = $MinigameContainer

# Preload คือการโหลด scene ไว้ล่วงหน้าในหน่วยความจำ
# ทำให้ตอน instantiate ไม่มีอาการกระตุก
@onready var minigame_scene = preload("res://FishingMinigame.tscn")


# --------------------------------------------------
# _ready() - ทำงานครั้งแรกที่ Scene โหลดเสร็จ
# --------------------------------------------------
# _ready() คือ "constructor" ของ Godot
# เขียนทุกอย่างที่ต้องทำแค่ครั้งเดียวตอนเริ่มเกมตรงนี้

func _ready() -> void:
	update_money_display()
	change_state(FishingState.CASTING)


# --------------------------------------------------
# _process(delta) - ทำงานทุก frame
# --------------------------------------------------
# delta คือเวลาที่ผ่านไปนับจาก frame ก่อนหน้า (หน่วย: วินาที)
# ปกติจะอยู่ที่ประมาณ 0.016 วินาที ถ้าเกมรัน 60 fps
#
# ทำไมต้องใช้ delta?
# ถ้าเราทำ wait_timer -= 1 ทุก frame
# บนเครื่องเร็ว (120fps) จะนับถอยหลังเร็วกว่าเครื่องช้า (30fps)
# แต่ถ้าเราทำ wait_timer -= delta
# 1 วินาทีจะเท่ากันทุกเครื่องเสมอ

func _process(delta: float) -> void:
	# ตรวจสอบว่าตอนนี้อยู่ใน state ไหน แล้วจัดการตาม state นั้น
	match current_state:
		FishingState.CASTING:
			process_casting(delta)
		FishingState.WAITING:
			process_waiting(delta)
		FishingState.BITING:
			process_biting(delta)
		FishingState.MINIGAME:
			pass  # mini-game จัดการตัวเองผ่าน signal
		FishingState.RESULT:
			pass  # รอ animation จบ


# --------------------------------------------------
# Input - รับการกดของผู้เล่น
# --------------------------------------------------
# _input() ทำงานทุกครั้งที่มี input event เกิดขึ้น
# ต่างจาก _process() ที่ทำงานทุก frame
# ใช้ _input() สำหรับการตรวจ "การกด" เพื่อไม่ให้พลาด

func _input(event: InputEvent) -> void:
	# ตอน BITING เท่านั้นที่ผู้เล่นต้องคลิก
	if current_state == FishingState.BITING:
		# ตรวจว่า event นี้คือการกดเมาส์ซ้ายหรือไม่
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				on_player_clicked()


# --------------------------------------------------
# State Functions - ฟังก์ชันที่ทำงานใน state ต่างๆ
# --------------------------------------------------

func process_casting(delta: float) -> void:
	# ตอนนี้แค่เล่น animation แล้วเปลี่ยน state
	# animation_player จะส่ง signal "animation_finished" เมื่อเสร็จ
	# แต่ EP01 นี้ยังไม่มี animation จริง เลยกำหนดเวลาตรงๆ ไปก่อน
	wait_timer -= delta
	if wait_timer <= 0:
		change_state(FishingState.WAITING)


func process_waiting(delta: float) -> void:
	# นับถอยหลัง รอปลากิน
	wait_timer -= delta
	if wait_timer <= 0:
		# ถึงเวลาแล้ว ปลากิน!
		pick_random_fish()
		change_state(FishingState.BITING)


func process_biting(delta: float) -> void:
	# นับถอยหลัง ถ้าผู้เล่นไม่คลิกทัน = พลาด
	bite_timer -= delta
	if bite_timer <= 0:
		on_bite_missed()


# --------------------------------------------------
# Game Logic Functions
# --------------------------------------------------

func pick_random_fish() -> void:
	# สุ่มปลาจาก FishData
	# FishData.get_random_fish() จะถูกสร้างใน Episode 4
	# ตอนนี้ hardcode ไว้ก่อน
	var fish_list = [
		{"name": "Salmon",       "price": 75,  "difficulty": 0.7, "color": Color(1, 0.3, 0.3)},
		{"name": "Sea Cucumber", "price": 75,  "difficulty": 0.4, "color": Color(0.4, 0.6, 0.4)},
		{"name": "Shad",         "price": 60,  "difficulty": 0.5, "color": Color(0.6, 0.8, 1.0)},
		{"name": "Herring",      "price": 30,  "difficulty": 0.3, "color": Color(0.7, 0.7, 1.0)},
		{"name": "Anchovy",      "price": 30,  "difficulty": 0.3, "color": Color(0.9, 0.9, 0.5)},
	]
	# randi_range(0, size-1) คือการสุ่มเลขจำนวนเต็มในช่วงที่กำหนด
	current_fish = fish_list[randi_range(0, fish_list.size() - 1)]


func on_player_clicked() -> void:
	# ผู้เล่นคลิกทัน เข้า mini-game
	change_state(FishingState.MINIGAME)


func on_bite_missed() -> void:
	# ผู้เล่นช้าเกินไป ปลาหนีแล้ว
	show_notification("ปลาหนีไปแล้ว...")
	change_state(FishingState.CASTING)


func on_minigame_success(fish_data: Dictionary) -> void:
	# รับ signal จาก FishingMinigame เมื่อจับปลาสำเร็จ
	money += fish_data["price"]
	update_money_display()
	show_notification("จับได้! " + fish_data["name"] + " +" + str(fish_data["price"]) + " G")
	change_state(FishingState.RESULT)


func on_minigame_failed() -> void:
	# รับ signal จาก FishingMinigame เมื่อจับพลาด
	show_notification("พลาด! ปลาหนีไป")
	change_state(FishingState.RESULT)


# --------------------------------------------------
# change_state() - เปลี่ยน State พร้อมตั้งค่าใหม่
# --------------------------------------------------
# ฟังก์ชันนี้สำคัญมาก เพราะทุกการเปลี่ยน state ต้องผ่านที่นี่
# ทำให้เราควบคุมและ debug ได้ง่าย

func change_state(new_state: FishingState) -> void:
	# ออกจาก state เก่า - ทำสิ่งที่ต้องทำเมื่อออก
	match current_state:
		FishingState.MINIGAME:
			# ลบ mini-game scene ออกจากหน่วยความจำ
			for child in minigame_container.get_children():
				child.queue_free()

	# เปลี่ยน state
	current_state = new_state
	print("State เปลี่ยนเป็น: ", FishingState.keys()[new_state])

	# เข้าสู่ state ใหม่ - ตั้งค่าเริ่มต้น
	match new_state:
		FishingState.CASTING:
			casting_label.text = "กำลังเหวี่ยงเบ็ด..."
			notify_label.text = ""
			wait_timer = 1.5  # เวลา animation เหวี่ยง (EP5 จะใช้ animation จริง)

		FishingState.WAITING:
			casting_label.text = "รอปลากิน..."
			# สุ่มเวลารอระหว่าง MIN_WAIT_TIME ถึง MAX_WAIT_TIME
			wait_timer = randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME)

		FishingState.BITING:
			casting_label.text = ""
			notify_label.text = "คลิกเดี๋ยวนี้!"
			bite_timer = BITE_WINDOW
			# เล่นเสียงและ animation ตอนปลากิน (EP6)

		FishingState.MINIGAME:
			notify_label.text = ""
			casting_label.text = ""
			start_minigame()

		FishingState.RESULT:
			# รอสักครู่แล้วกลับไป CASTING
			await get_tree().create_timer(2.0).timeout
			change_state(FishingState.CASTING)


# --------------------------------------------------
# Mini-game Functions
# --------------------------------------------------

func start_minigame() -> void:
	# สร้าง instance ของ FishingMinigame scene
	# instance คือการสร้าง "ก็อปปี้" ของ scene ขึ้นมาใช้งาน
	var minigame = minigame_scene.instantiate()

	# ส่งข้อมูลปลาไปให้ mini-game รู้ว่ากำลังจับปลาอะไร
	minigame.fish_data = current_fish

	# ใส่ mini-game เข้าไปใน container
	minigame_container.add_child(minigame)

	# เชื่อม signal จาก mini-game มายัง Main
	# "fish_caught" คือ signal ที่ FishingMinigame จะส่งออกมา
	minigame.fish_caught.connect(on_minigame_success)
	minigame.fish_escaped.connect(on_minigame_failed)


# --------------------------------------------------
# UI Functions
# --------------------------------------------------

func update_money_display() -> void:
	money_label.text = str(money) + " G"


func show_notification(text: String) -> void:
	notify_label.text = text
