extends Control

# ====================================================
# FishingMinigame.gd - Mini-game ตกปลาแบบ Stardew Valley
# ====================================================
# Scene นี้จะถูกสร้างขึ้นตอนปลากิน และลบทิ้งตอนจบ
# ====================================================


# --------------------------------------------------
# Signals - การส่งข่าวออกไปให้ Main.gd รู้
# --------------------------------------------------
# signal คือ "กระดิ่ง" ที่เราส่งออกไป
# Main.gd จะรับ signal นี้และจัดการต่อ

signal fish_caught(fish_data: Dictionary)  # จับปลาสำเร็จ
signal fish_escaped                         # ปลาหนีไป


# --------------------------------------------------
# ตัวแปรรับค่าจากภายนอก
# --------------------------------------------------
# Main.gd จะส่ง fish_data มาก่อน add_child()
var fish_data: Dictionary = {}


# --------------------------------------------------
# ขนาดของ Mini-game Bar
# --------------------------------------------------
const BAR_WIDTH: float = 80.0
const BAR_HEIGHT: float = 400.0

# ตำแหน่งตรงกลางจอ
var bar_position: Vector2


# --------------------------------------------------
# Green Zone (ส่วนที่ผู้เล่นควบคุม)
# --------------------------------------------------
# Green zone เลื่อนขึ้นเมื่อค้างเมาส์ ตกลงเมื่อปล่อย

const GREEN_ZONE_HEIGHT: float = 100.0   # ความสูงของ green zone (ปรับตามความยากของปลา)
var green_zone_y: float = 0.0            # ตำแหน่ง Y ของ green zone (0 = บนสุดของ bar)
var green_zone_velocity: float = 0.0     # ความเร็วปัจจุบัน

const GRAVITY: float = 500.0            # แรงโน้มถ่วงที่ดึง green zone ลง
const LIFT_FORCE: float = -900.0        # แรงที่ใช้ยก green zone ขึ้น (ค้างเมาส์)
const MAX_VELOCITY: float = 600.0       # จำกัดความเร็วสูงสุด


# --------------------------------------------------
# Fish Icon (ตัวปลาที่เด้งขึ้นลง)
# --------------------------------------------------
var fish_y: float = 0.0                  # ตำแหน่ง Y ของปลา
var fish_velocity: float = 0.0           # ความเร็วของปลา
var fish_target_y: float = 0.0           # จุดหมายที่ปลากำลังเคลื่อนไป

const FISH_SPEED: float = 200.0          # ความเร็วของปลา (ปรับตาม difficulty)
var fish_direction_timer: float = 0.0    # นับเวลาก่อนเปลี่ยนทิศทาง


# --------------------------------------------------
# Progress Bar
# --------------------------------------------------
# progress เพิ่มขึ้นเมื่อปลาอยู่ใน green zone
# progress ลดลงเมื่อปลาออกจาก green zone

var progress: float = 0.3               # เริ่มที่ 30%
const PROGRESS_FILL_RATE: float = 0.5   # เพิ่ม 50% ต่อวินาที
const PROGRESS_DRAIN_RATE: float = 0.4  # ลด 40% ต่อวินาที


# --------------------------------------------------
# Drawing Nodes (จะสร้างใน _ready)
# --------------------------------------------------
var bar_background: ColorRect
var green_zone_rect: ColorRect
var fish_icon: ColorRect       # EP5 จะเปลี่ยนเป็น Sprite2D
var progress_bar_bg: ColorRect
var progress_bar_fill: ColorRect
var fish_name_label: Label


# --------------------------------------------------
# _ready() - ตั้งค่าเริ่มต้น
# --------------------------------------------------

func _ready() -> void:
	# คำนวณตำแหน่งกลางจอ
	bar_position = get_viewport_rect().size / 2

	# ปรับความสูง green zone ตามความยากของปลา
	# ปลายาก = green zone เล็ก = จับยากขึ้น
	var difficulty = fish_data.get("difficulty", 0.5)
	# difficulty 1.0 = green zone เล็กสุด (60px), difficulty 0.0 = ใหญ่สุด (140px)
	var zone_size = lerp(140.0, 60.0, difficulty)
	# แต่ใน EP01 ใช้ค่าคงที่ก่อน
	# zone_size = GREEN_ZONE_HEIGHT

	# ตำแหน่งเริ่มต้นของ green zone = กลาง bar
	green_zone_y = (BAR_HEIGHT - GREEN_ZONE_HEIGHT) / 2

	# ตำแหน่งเริ่มต้นของปลา = สุ่ม
	fish_y = randf_range(0, BAR_HEIGHT - 30)
	fish_target_y = randf_range(0, BAR_HEIGHT - 30)

	# สร้าง UI elements ทั้งหมด
	build_ui()


# --------------------------------------------------
# build_ui() - สร้าง Node ของ mini-game ใน code
# --------------------------------------------------
# เราสร้าง Node ใน code แทนการวาดใน editor เพราะ
# mini-game จะถูกสร้างและลบทิ้งแบบ dynamic
# และขนาดบาง element ต้องคำนวณตาม difficulty ของปลา

func build_ui() -> void:
	var bar_x = bar_position.x - BAR_WIDTH / 2
	var bar_y = bar_position.y - BAR_HEIGHT / 2

	# พื้นหลังทึบของ bar ทั้งหมด
	bar_background = ColorRect.new()
	bar_background.position = Vector2(bar_x, bar_y)
	bar_background.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar_background.color = Color(0.1, 0.1, 0.15, 0.9)
	add_child(bar_background)

	# Green Zone - ส่วนที่ผู้เล่นบังคับ
	green_zone_rect = ColorRect.new()
	green_zone_rect.size = Vector2(BAR_WIDTH, GREEN_ZONE_HEIGHT)
	green_zone_rect.color = Color(0.2, 0.8, 0.3, 0.6)
	bar_background.add_child(green_zone_rect)

	# Fish Icon - ตัวปลา (สี่เหลี่ยมสีเหลืองก่อน EP5 จะเปลี่ยนเป็น sprite)
	fish_icon = ColorRect.new()
	fish_icon.size = Vector2(BAR_WIDTH - 10, 20)
	fish_icon.position.x = 5
	fish_icon.color = fish_data.get("color", Color.YELLOW)
	bar_background.add_child(fish_icon)

	# Progress bar พื้นหลัง (สีเทา)
	progress_bar_bg = ColorRect.new()
	progress_bar_bg.position = Vector2(bar_x - 20, bar_y)
	progress_bar_bg.size = Vector2(12, BAR_HEIGHT)
	progress_bar_bg.color = Color(0.3, 0.3, 0.3)
	add_child(progress_bar_bg)

	# Progress bar การเติม (สีเขียว จะสูงขึ้นเมื่อ progress เพิ่ม)
	progress_bar_fill = ColorRect.new()
	progress_bar_fill.color = Color(0.2, 0.9, 0.4)
	progress_bar_bg.add_child(progress_bar_fill)

	# ชื่อปลา
	fish_name_label = Label.new()
	fish_name_label.text = fish_data.get("name", "ปลาไม่รู้จัก")
	fish_name_label.position = Vector2(bar_x - 50, bar_y - 40)
	fish_name_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(fish_name_label)

	# คำแนะนำ
	var hint_label = Label.new()
	hint_label.text = "ค้างเมาส์เพื่อยกกรอบสีเขียว"
	hint_label.position = Vector2(bar_x - 60, bar_y + BAR_HEIGHT + 10)
	hint_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(hint_label)


# --------------------------------------------------
# _process(delta) - Logic หลักของ mini-game
# --------------------------------------------------

func _process(delta: float) -> void:
	update_green_zone(delta)
	update_fish(delta)
	update_progress(delta)
	update_visuals()
	check_end_conditions()


# --------------------------------------------------
# update_green_zone() - Physics ของ green zone
# --------------------------------------------------

func update_green_zone(delta: float) -> void:
	# ตรวจว่าค้างเมาส์ซ้ายอยู่ไหม
	var is_holding = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	# ใช้ velocity-based movement เหมือน physics จริง
	# velocity จะสะสมแรงขึ้นหรือลงตาม input
	if is_holding:
		# ดึงขึ้น (แรงต้านทาน + แรงยก)
		green_zone_velocity += LIFT_FORCE * delta
	else:
		# ปล่อยมือ: แรงโน้มถ่วงดึงลง
		green_zone_velocity += GRAVITY * delta

	# จำกัดความเร็วสูงสุด ป้องกัน green zone วิ่งเร็วเกินไป
	green_zone_velocity = clamp(green_zone_velocity, -MAX_VELOCITY, MAX_VELOCITY)

	# ขยับตำแหน่ง
	green_zone_y += green_zone_velocity * delta

	# ป้องกัน green zone ออกนอก bar
	# clamp(value, min, max) คือการจำกัดค่าให้อยู่ในช่วง min ถึง max
	green_zone_y = clamp(green_zone_y, 0, BAR_HEIGHT - GREEN_ZONE_HEIGHT)

	# ถ้าชนขอบ ให้หยุด velocity
	if green_zone_y <= 0 or green_zone_y >= BAR_HEIGHT - GREEN_ZONE_HEIGHT:
		green_zone_velocity = 0


# --------------------------------------------------
# update_fish() - การเคลื่อนที่ของปลา
# --------------------------------------------------

func update_fish(delta: float) -> void:
	# นับเวลาก่อนเปลี่ยนทิศทาง
	fish_direction_timer -= delta
	if fish_direction_timer <= 0:
		# เลือกจุดหมายใหม่แบบสุ่ม
		fish_target_y = randf_range(20, BAR_HEIGHT - 50)
		# รอสักพักก่อนเปลี่ยนทิศทางอีก
		fish_direction_timer = randf_range(0.5, 2.0)

	# ขยับปลาไปทางจุดหมาย
	# ความเร็วขึ้นอยู่กับ difficulty ของปลา
	var speed = FISH_SPEED * fish_data.get("difficulty", 0.5)
	fish_y = move_toward(fish_y, fish_target_y, speed * delta)
	# move_toward(current, target, step) คือการเคลื่อนที่เข้าหา target ทีละ step
	# โดยไม่ overshooting (ไม่เกิน target)

	# จำกัดไม่ให้ออกนอก bar
	fish_y = clamp(fish_y, 0, BAR_HEIGHT - 20)


# --------------------------------------------------
# update_progress() - คำนวณ progress
# --------------------------------------------------

func update_progress(delta: float) -> void:
	# ตรวจว่าปลาอยู่ใน green zone ไหม
	var fish_center = fish_y + 10  # จุดกลางของปลา (ปลาสูง 20px)
	var zone_top = green_zone_y
	var zone_bottom = green_zone_y + GREEN_ZONE_HEIGHT
	var is_fish_in_zone = fish_center >= zone_top and fish_center <= zone_bottom

	if is_fish_in_zone:
		progress += PROGRESS_FILL_RATE * delta
	else:
		progress -= PROGRESS_DRAIN_RATE * delta

	# จำกัด progress ไว้ที่ 0-1
	progress = clamp(progress, 0.0, 1.0)


# --------------------------------------------------
# update_visuals() - อัปเดตรูปร่างหน้าตาตาม state
# --------------------------------------------------

func update_visuals() -> void:
	# ขยับ green zone
	green_zone_rect.position.y = green_zone_y

	# ขยับปลา
	fish_icon.position.y = fish_y

	# อัปเดต progress bar (แสดงจากล่างขึ้นบน)
	var fill_height = BAR_HEIGHT * progress
	progress_bar_fill.size = Vector2(12, fill_height)
	progress_bar_fill.position.y = BAR_HEIGHT - fill_height

	# เปลี่ยนสีตาม progress
	if progress > 0.7:
		progress_bar_fill.color = Color(0.2, 0.9, 0.4)   # เขียว - ใกล้จับได้
	elif progress > 0.3:
		progress_bar_fill.color = Color(0.9, 0.8, 0.2)   # เหลือง - กลางๆ
	else:
		progress_bar_fill.color = Color(0.9, 0.3, 0.2)   # แดง - ใกล้พลาด

	# Green zone เปลี่ยนสีเมื่อปลาอยู่ข้างใน
	var fish_center = fish_y + 10
	var is_fish_in_zone = fish_center >= green_zone_y and fish_center <= green_zone_y + GREEN_ZONE_HEIGHT
	if is_fish_in_zone:
		green_zone_rect.color = Color(0.3, 1.0, 0.4, 0.7)  # สว่างขึ้น
	else:
		green_zone_rect.color = Color(0.2, 0.6, 0.3, 0.6)  # มืดลง


# --------------------------------------------------
# check_end_conditions() - ตรวจสอบว่า mini-game จบหรือยัง
# --------------------------------------------------

func check_end_conditions() -> void:
	if progress >= 1.0:
		# จับปลาสำเร็จ
		emit_signal("fish_caught", fish_data)
		queue_free()  # ลบตัวเองออกจาก scene tree

	elif progress <= 0.0:
		# ปลาหนีไป
		emit_signal("fish_escaped")
		queue_free()
