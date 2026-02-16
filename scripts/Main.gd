extends Node2D

# ====================================================
# Main.gd - Episode 2
# ====================================================
# เพิ่มจาก EP01:
# - ทุ่นเหวี่ยงด้วย Tween พร้อม arc โค้ง
# - สายเบ็ดลากตามทุ่นทุก frame
# - ทุ่นเด้งขึ้นลงตอนรอปลา
# - ทุ่นดำดิ่ง + label สั่นตอนปลากิน
# - สีแฟลชตอนจับได้หรือพลาด
# ====================================================


# --------------------------------------------------
# State Machine (เหมือนเดิม)
# --------------------------------------------------

enum FishingState {
	CASTING,
	WAITING,
	BITING,
	MINIGAME,
	RESULT
}

var current_state: FishingState = FishingState.CASTING


# --------------------------------------------------
# ข้อมูลเกม
# --------------------------------------------------

var money: int = 0
var current_fish: Dictionary = {}

const MIN_WAIT_TIME: float = 3.0
const MAX_WAIT_TIME: float = 8.0
var wait_timer: float = 0.0

const BITE_WINDOW: float = 2.0
var bite_timer: float = 0.0


# --------------------------------------------------
# ตำแหน่งสำคัญในเกม
# --------------------------------------------------
# กำหนดเป็น const ทำให้ปรับค่าได้จากที่เดียว
# ถ้าต้องการย้ายตัวละคร แก้แค่ตรงนี้จุดเดียว

const CHARACTER_POS     := Vector2(350, 430)
const ROD_TIP_POS       := Vector2(390, 390)
const BOBBER_IDLE_POS   := Vector2(800, 510)
const BOBBER_BITE_POS   := Vector2(800, 535)
const BOBBER_RESET_POS  := Vector2(390, 395)


# --------------------------------------------------
# ตัวแปรสำหรับ animation
# --------------------------------------------------

var bobber_bob_tween: Tween
var bite_shake_tween: Tween
var bob_timer: float = 0.0


# --------------------------------------------------
# References ไปยัง Node ลูก
# --------------------------------------------------

@onready var money_label: Label      = $UI/MoneyLabel
@onready var notify_label: Label     = $UI/NotifyLabel
@onready var casting_label: Label    = $UI/CastingLabel
@onready var bobber: Sprite2D        = $FishingRod/Line/Bobber
@onready var fishing_line: Line2D    = $FishingRod/Line
@onready var minigame_container: Control = $MinigameContainer

var minigame_scene = preload("res://scenes/FishingMinigame.tscn")


# --------------------------------------------------
# _ready()
# --------------------------------------------------

func _ready() -> void:
	setup_placeholder_character()
	setup_placeholder_rod()
	update_money_display()
	change_state(FishingState.CASTING)


# --------------------------------------------------
# setup_placeholder_character()
# --------------------------------------------------

func setup_placeholder_character() -> void:
	$Character.position = CHARACTER_POS

	# ตัว (สี่เหลี่ยมสีผิว)
	var img = Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.9, 0.75, 0.6))
	var tex = ImageTexture.create_from_image(img)
	var char_sprite = Sprite2D.new()
	char_sprite.texture = tex
	char_sprite.position = Vector2(0, -32)
	$Character.add_child(char_sprite)

	# หัว (วงกลม 16 จุด)
	var head = Polygon2D.new()
	var head_points: PackedVector2Array = []
	for i in range(16):
		var angle = (i / 16.0) * TAU
		head_points.append(Vector2(cos(angle) * 14, sin(angle) * 14 - 72))
	head.polygon = head_points
	head.color = Color(0.9, 0.75, 0.6)
	$Character.add_child(head)


# --------------------------------------------------
# setup_placeholder_rod()
# --------------------------------------------------

func setup_placeholder_rod() -> void:
	$FishingRod.position = CHARACTER_POS

	# คันเบ็ดเป็นเส้น Line2D สีน้ำตาล
	var rod_line = Line2D.new()
	rod_line.add_point(Vector2(0, -60))
	rod_line.add_point(Vector2(40, -40))
	rod_line.width = 4.0
	rod_line.default_color = Color(0.45, 0.3, 0.15)
	$FishingRod.add_child(rod_line)

	# ทุ่นเริ่มต้นที่ปลายคัน
	bobber.position = BOBBER_RESET_POS

	# ตั้งค่าสายเบ็ด
	fishing_line.width = 1.5
	fishing_line.default_color = Color(0.85, 0.75, 0.6, 0.8)

	# สร้าง placeholder ทุ่น (วงกลมสีแดง)
	var bobber_img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var dx = x - 8.0
			var dy = y - 8.0
			if dx * dx + dy * dy <= 64:
				bobber_img.set_pixel(x, y, Color(0.9, 0.15, 0.15))
			else:
				bobber_img.set_pixel(x, y, Color(0, 0, 0, 0))
	bobber.texture = ImageTexture.create_from_image(bobber_img)


# --------------------------------------------------
# _process(delta)
# --------------------------------------------------

func _process(delta: float) -> void:
	match current_state:
		FishingState.CASTING:
			process_casting(delta)
		FishingState.WAITING:
			process_waiting(delta)
			process_bobber_bob(delta)
		FishingState.BITING:
			process_biting(delta)
		FishingState.MINIGAME:
			pass
		FishingState.RESULT:
			pass

	if current_state != FishingState.CASTING:
		update_fishing_line()


# --------------------------------------------------
# process_bobber_bob() - ทุ่นเด้งด้วย sin wave
# --------------------------------------------------
# sin(เวลา * ความเร็ว) ให้ค่า -1 ถึง 1 วนซ้ำ
# คูณ amplitude = ระยะเด้ง

func process_bobber_bob(delta: float) -> void:
	bob_timer += delta
	var amplitude = 4.0
	var speed = 2.0
	var new_y = BOBBER_IDLE_POS.y + sin(bob_timer * speed) * amplitude
	bobber.position = Vector2(BOBBER_IDLE_POS.x, new_y)


# --------------------------------------------------
# update_fishing_line() - ลากสายเบ็ดทุก frame
# --------------------------------------------------

func update_fishing_line() -> void:
	fishing_line.points = PackedVector2Array([
		ROD_TIP_POS,
		bobber.position
	])


# --------------------------------------------------
# State Functions
# --------------------------------------------------

func process_casting(delta: float) -> void:
	wait_timer -= delta
	if wait_timer <= 0:
		change_state(FishingState.WAITING)


func process_waiting(delta: float) -> void:
	wait_timer -= delta
	if wait_timer <= 0:
		current_fish = FishData.get_random_fish()
		change_state(FishingState.BITING)


func process_biting(delta: float) -> void:
	bite_timer -= delta
	if bite_timer <= 0:
		on_bite_missed()


# --------------------------------------------------
# _input()
# --------------------------------------------------

func _input(event: InputEvent) -> void:
	if current_state == FishingState.BITING:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				on_player_clicked()


# --------------------------------------------------
# Game Logic
# --------------------------------------------------

func on_player_clicked() -> void:
	change_state(FishingState.MINIGAME)


func on_bite_missed() -> void:
	if bite_shake_tween:
		bite_shake_tween.kill()
	notify_label.position.x = 500
	notify_label.modulate = Color.WHITE
	show_notification("ปลาหนีไปแล้ว...")
	change_state(FishingState.CASTING)


func on_minigame_success(fish_data: Dictionary) -> void:
	money += fish_data["price"]
	update_money_display()
	show_notification("จับได้! " + fish_data["name"] + " +" + str(fish_data["price"]) + " G")
	show_result_flash(true)
	change_state(FishingState.RESULT)


func on_minigame_failed() -> void:
	show_notification("พลาด! ปลาหนีไป")
	show_result_flash(false)
	change_state(FishingState.RESULT)


# --------------------------------------------------
# change_state()
# --------------------------------------------------

func change_state(new_state: FishingState) -> void:
	match current_state:
		FishingState.MINIGAME:
			for child in minigame_container.get_children():
				child.queue_free()
		FishingState.BITING:
			if bite_shake_tween:
				bite_shake_tween.kill()
			notify_label.position.x = 500
			notify_label.modulate = Color.WHITE

	current_state = new_state
	print("State: ", FishingState.keys()[new_state])

	match new_state:
		FishingState.CASTING:
			casting_label.text = "กำลังเหวี่ยงเบ็ด..."
			notify_label.text = ""
			bob_timer = 0.0
			wait_timer = 1.0
			cast_bobber()

		FishingState.WAITING:
			casting_label.text = "รอปลากิน..."
			wait_timer = randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME)

		FishingState.BITING:
			casting_label.text = ""
			notify_label.text = "คลิกเดี๋ยวนี้!"
			bite_timer = BITE_WINDOW
			show_bite_effect()

		FishingState.MINIGAME:
			notify_label.text = ""
			casting_label.text = ""
			start_minigame()

		FishingState.RESULT:
			await get_tree().create_timer(2.0).timeout
			change_state(FishingState.CASTING)


# --------------------------------------------------
# cast_bobber() - เหวี่ยงทุ่นด้วย Tween arc
# --------------------------------------------------
# ใช้ Tween 2 ตัวแยก X และ Y เพื่อทำเส้นโค้ง

func cast_bobber() -> void:
	if bobber_bob_tween:
		bobber_bob_tween.kill()

	bobber.position = BOBBER_RESET_POS

	var cast_duration = 0.8

	# X: เลื่อนขวาตรงๆ ชะลอก่อนถึง
	var tween_x = create_tween()
	tween_x.tween_property(bobber, "position:x",
		BOBBER_IDLE_POS.x, cast_duration)
	tween_x.set_ease(Tween.EASE_OUT)
	tween_x.set_trans(Tween.TRANS_QUAD)

	# Y: ขึ้นสูงก่อน 40% แล้วลงน้ำ 60%
	var tween_y = create_tween()
	tween_y.tween_property(bobber, "position:y",
		BOBBER_RESET_POS.y - 150, cast_duration * 0.4)
	tween_y.set_ease(Tween.EASE_OUT)
	tween_y.tween_property(bobber, "position:y",
		BOBBER_IDLE_POS.y, cast_duration * 0.6)
	tween_y.set_ease(Tween.EASE_IN)

	# รอ X tween เสร็จ แล้วเปลี่ยน state
	await tween_x.finished
	change_state(FishingState.WAITING)


# --------------------------------------------------
# show_bite_effect() - ทุ่นดำดิ่ง + label สั่น
# --------------------------------------------------

func show_bite_effect() -> void:
	# ทุ่นดำดิ่ง
	var dip_tween = create_tween()
	dip_tween.tween_property(bobber, "position:y",
		BOBBER_BITE_POS.y, 0.15)
	dip_tween.set_ease(Tween.EASE_IN)

	# Label สีแดง
	notify_label.modulate = Color(1.0, 0.2, 0.2)

	# Label สั่นวนซ้ำ
	bite_shake_tween = create_tween()
	bite_shake_tween.set_loops()
	var shake = 6.0
	var speed = 0.06
	bite_shake_tween.tween_property(notify_label, "position:x", 500.0 + shake, speed)
	bite_shake_tween.tween_property(notify_label, "position:x", 500.0 - shake, speed)
	bite_shake_tween.tween_property(notify_label, "position:x", 500.0, speed)


# --------------------------------------------------
# show_result_flash() - แฟลชสีบอกผล
# --------------------------------------------------

func show_result_flash(success: bool) -> void:
	var flash_color = Color(0.3, 1.0, 0.4) if success else Color(1.0, 0.3, 0.3)
	notify_label.modulate = flash_color
	var flash_tween = create_tween()
	flash_tween.tween_property(notify_label, "modulate", Color.WHITE, 1.5)
	flash_tween.set_ease(Tween.EASE_IN)


# --------------------------------------------------
# Mini-game
# --------------------------------------------------

func start_minigame() -> void:
	var minigame = minigame_scene.instantiate()
	minigame.fish_data = current_fish
	minigame_container.add_child(minigame)
	minigame.fish_caught.connect(on_minigame_success)
	minigame.fish_escaped.connect(on_minigame_failed)


# --------------------------------------------------
# UI
# --------------------------------------------------

func update_money_display() -> void:
	money_label.text = str(money) + " G"


func show_notification(text: String) -> void:
	notify_label.text = text
