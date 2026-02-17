extends Control

# ====================================================
# FishingMinigame.gd - Episode 3
# ====================================================
# เพิ่มจาก EP01:
# - green zone size เปลี่ยนตาม difficulty จริง
# - ปลาส่ายซ้ายขวา (wiggle) ด้วย sin wave
# - progress bar สั่นเมื่อ critical (< 15%)
# - border รอบ bar
# - แสดง % ความคืบหน้าด้านบน bar
# ====================================================


# --------------------------------------------------
# Signals
# --------------------------------------------------

signal fish_caught(fish_data: Dictionary)
signal fish_escaped


# --------------------------------------------------
# ข้อมูลปลาที่รับจาก Main.gd
# --------------------------------------------------

var fish_data: Dictionary = {}


# --------------------------------------------------
# ขนาด Bar
# --------------------------------------------------

const BAR_WIDTH: float  = 80.0
const BAR_HEIGHT: float = 400.0
var bar_position: Vector2


# --------------------------------------------------
# Green Zone - ส่วนที่ผู้เล่นบังคับ
# --------------------------------------------------
# ความสูงของ green zone ขึ้นอยู่กับ difficulty ของปลา
# ยิ่งยาก zone ยิ่งเล็ก

var green_zone_height: float = 100.0  # จะคำนวณใหม่ใน _ready()
var green_zone_y: float = 0.0
var green_zone_velocity: float = 0.0

const GRAVITY: float      = 500.0
const LIFT_FORCE: float   = -900.0
const MAX_VELOCITY: float = 600.0


# --------------------------------------------------
# Fish - ตัวปลา
# --------------------------------------------------

var fish_y: float = 0.0
var fish_target_y: float = 0.0
var fish_direction_timer: float = 0.0

# wiggle คือการส่ายซ้ายขวาของปลา
# ใช้ sin wave เหมือน bobber ใน Main.gd
var fish_wiggle_timer: float = 0.0

const FISH_BASE_SPEED: float = 200.0


# --------------------------------------------------
# Progress
# --------------------------------------------------

var progress: float = 0.3
const PROGRESS_FILL_RATE: float  = 0.5
const PROGRESS_DRAIN_RATE: float = 0.4

# shake timer สำหรับตอน critical
var progress_shake_timer: float = 0.0
const SHAKE_SPEED: float = 20.0   # ความเร็วสั่น (radians/วินาที)
const SHAKE_AMOUNT: float = 5.0   # ระยะสั่น (pixels)


# --------------------------------------------------
# Nodes ที่สร้างใน code
# --------------------------------------------------

var bar_background: ColorRect
var bar_border: ColorRect         # EP3 ใหม่: border รอบ bar
var green_zone_rect: ColorRect
var fish_icon: ColorRect
var progress_bar_bg: ColorRect
var progress_bar_fill: ColorRect
var fish_name_label: Label
var progress_label: Label         # EP3 ใหม่: แสดง %
var hint_label: Label


# --------------------------------------------------
# _ready()
# --------------------------------------------------

func _ready() -> void:
	bar_position = get_viewport_rect().size / 2

	# --- คำนวณ green zone size จาก difficulty ---
	# lerp(a, b, t): t=0 คือ a, t=1 คือ b
	# difficulty 0.0 = zone ใหญ่สุด (130px) = ง่าย
	# difficulty 1.0 = zone เล็กสุด (55px)  = ยาก
	var difficulty = fish_data.get("difficulty", 0.5)
	green_zone_height = lerp(130.0, 55.0, difficulty)

	# ตำแหน่งเริ่มต้นของ green zone = กลาง bar
	green_zone_y = (BAR_HEIGHT - green_zone_height) / 2

	# ตำแหน่งเริ่มต้นของปลา = สุ่ม
	fish_y = randf_range(0, BAR_HEIGHT - 30)
	fish_target_y = randf_range(0, BAR_HEIGHT - 30)

	build_ui()


# --------------------------------------------------
# build_ui() - สร้าง Node ทั้งหมด
# --------------------------------------------------

func build_ui() -> void:
	var bar_x = bar_position.x - BAR_WIDTH / 2
	var bar_y = bar_position.y - BAR_HEIGHT / 2

	# --- Border (สร้างก่อน background เพื่อให้อยู่ข้างหลัง) ---
	# วิธีทำ border ง่ายๆ: วางสี่เหลี่ยมใหญ่กว่า 4px ไว้ข้างหลัง
	bar_border = ColorRect.new()
	bar_border.position = Vector2(bar_x - 4, bar_y - 4)
	bar_border.size = Vector2(BAR_WIDTH + 8, BAR_HEIGHT + 8)
	bar_border.color = Color(0.6, 0.5, 0.3)   # สีทองอ่อน
	add_child(bar_border)

	# --- Background ---
	bar_background = ColorRect.new()
	bar_background.position = Vector2(bar_x, bar_y)
	bar_background.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar_background.color = Color(0.08, 0.08, 0.12, 0.95)
	add_child(bar_background)

	# --- Green Zone ---
	green_zone_rect = ColorRect.new()
	green_zone_rect.size = Vector2(BAR_WIDTH, green_zone_height)
	green_zone_rect.color = Color(0.2, 0.8, 0.3, 0.6)
	bar_background.add_child(green_zone_rect)

	# --- Fish Icon ---
	fish_icon = ColorRect.new()
	fish_icon.size = Vector2(BAR_WIDTH - 10, 20)
	fish_icon.position.x = 5
	fish_icon.color = fish_data.get("color", Color.YELLOW)
	bar_background.add_child(fish_icon)

	# --- Progress Bar พื้นหลัง ---
	progress_bar_bg = ColorRect.new()
	progress_bar_bg.position = Vector2(bar_x - 24, bar_y)
	progress_bar_bg.size = Vector2(14, BAR_HEIGHT)
	progress_bar_bg.color = Color(0.2, 0.2, 0.2)
	add_child(progress_bar_bg)

	# --- Progress Bar Fill ---
	progress_bar_fill = ColorRect.new()
	progress_bar_fill.color = Color(0.2, 0.9, 0.4)
	progress_bar_bg.add_child(progress_bar_fill)

	# --- ชื่อปลา ---
	fish_name_label = Label.new()
	fish_name_label.text = fish_data.get("name", "ปลาไม่รู้จัก")
	fish_name_label.position = Vector2(bar_x - 20, bar_y - 50)
	fish_name_label.add_theme_color_override("font_color", Color.WHITE)
	fish_name_label.add_theme_font_size_override("font_size", 18)
	add_child(fish_name_label)

	# --- Progress % Label (EP3 ใหม่) ---
	progress_label = Label.new()
	progress_label.text = "30%"
	progress_label.position = Vector2(bar_x - 30, bar_y - 28)
	progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	progress_label.add_theme_font_size_override("font_size", 14)
	add_child(progress_label)

	# --- Hint Label ---
	hint_label = Label.new()
	hint_label.text = "ค้างเมาส์ = ยกกรอบขึ้น"
	hint_label.position = Vector2(bar_x - 40, bar_y + BAR_HEIGHT + 14)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint_label.add_theme_font_size_override("font_size", 13)
	add_child(hint_label)


# --------------------------------------------------
# _process(delta)
# --------------------------------------------------

func _process(delta: float) -> void:
	update_green_zone(delta)
	update_fish(delta)
	update_progress(delta)
	update_visuals(delta)
	check_end_conditions()


# --------------------------------------------------
# update_green_zone() - Physics ของ green zone
# --------------------------------------------------

func update_green_zone(delta: float) -> void:
	var is_holding = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if is_holding:
		green_zone_velocity += LIFT_FORCE * delta
	else:
		green_zone_velocity += GRAVITY * delta

	# clamp = จำกัดค่าให้อยู่ระหว่าง min ถึง max
	green_zone_velocity = clamp(green_zone_velocity, -MAX_VELOCITY, MAX_VELOCITY)
	green_zone_y += green_zone_velocity * delta
	green_zone_y = clamp(green_zone_y, 0, BAR_HEIGHT - green_zone_height)

	# ชนขอบ = หยุด velocity ทันที
	if green_zone_y <= 0 or green_zone_y >= BAR_HEIGHT - green_zone_height:
		green_zone_velocity = 0


# --------------------------------------------------
# update_fish() - AI ปลา
# --------------------------------------------------

func update_fish(delta: float) -> void:
	fish_wiggle_timer += delta

	# เปลี่ยน target ตาม timer
	fish_direction_timer -= delta
	if fish_direction_timer <= 0:
		fish_target_y = randf_range(20, BAR_HEIGHT - 50)

		# ปลายากเปลี่ยนทิศบ่อยกว่า
		# difficulty สูง = timer สั้น = เปลี่ยนบ่อย = จับยาก
		var difficulty = fish_data.get("difficulty", 0.5)
		fish_direction_timer = randf_range(
			lerp(1.5, 0.4, difficulty),   # min time
			lerp(3.0, 0.8, difficulty)    # max time
		)

	# เคลื่อนที่ไปหา target
	var speed = FISH_BASE_SPEED * fish_data.get("difficulty", 0.5)
	fish_y = move_toward(fish_y, fish_target_y, speed * delta)
	fish_y = clamp(fish_y, 0, BAR_HEIGHT - 20)


# --------------------------------------------------
# update_progress() - คำนวณ progress
# --------------------------------------------------

func update_progress(delta: float) -> void:
	var fish_center = fish_y + 10
	var zone_top    = green_zone_y
	var zone_bottom = green_zone_y + green_zone_height
	var is_in_zone  = fish_center >= zone_top and fish_center <= zone_bottom

	if is_in_zone:
		progress += PROGRESS_FILL_RATE * delta
	else:
		progress -= PROGRESS_DRAIN_RATE * delta

	progress = clamp(progress, 0.0, 1.0)


# --------------------------------------------------
# update_visuals() - อัปเดตรูปร่างหน้าตา
# --------------------------------------------------

func update_visuals(delta: float) -> void:
	# --- ขยับ green zone ---
	green_zone_rect.position.y = green_zone_y
	green_zone_rect.size.y = green_zone_height

	# --- ปลาส่ายซ้ายขวา (wiggle) ---
	# sin wave ด้วย timer แยกต่างหาก
	# ความเร็วส่าย = ขึ้นกับ difficulty (ปลายาก = ส่ายเร็ว)
	var wiggle_speed = lerp(4.0, 10.0, fish_data.get("difficulty", 0.5))
	var wiggle_x = sin(fish_wiggle_timer * wiggle_speed) * 3.0
	fish_icon.position = Vector2(5 + wiggle_x, fish_y)

	# --- Progress Bar ---
	var fill_height = BAR_HEIGHT * progress
	progress_bar_fill.size = Vector2(14, fill_height)
	progress_bar_fill.position.y = BAR_HEIGHT - fill_height

	# สีของ progress bar เปลี่ยนตาม progress
	if progress > 0.7:
		progress_bar_fill.color = Color(0.2, 0.9, 0.4)    # เขียว
		bar_border.color = Color(0.6, 0.5, 0.3)            # ทองปกติ
	elif progress > 0.3:
		progress_bar_fill.color = Color(0.9, 0.8, 0.2)    # เหลือง
		bar_border.color = Color(0.6, 0.5, 0.3)
	else:
		progress_bar_fill.color = Color(0.9, 0.3, 0.2)    # แดง
		# Border กระพริบสีแดงตอน critical
		var blink = abs(sin(fish_wiggle_timer * 5.0))
		bar_border.color = Color(0.9, 0.2 + blink * 0.3, 0.2)

	# --- progress bar สั่นตอน critical ---
	# เมื่อ progress < 15% progress bar จะสั่น
	if progress < 0.15:
		progress_shake_timer += delta
		var shake_x = sin(progress_shake_timer * SHAKE_SPEED) * SHAKE_AMOUNT
		progress_bar_bg.position.x = progress_bar_bg.position.x - (progress_bar_bg.position.x - \
			(bar_position.x - BAR_WIDTH / 2 - 24 + shake_x)) * 0.5
		# ลด font size hint เพื่อบอกผู้เล่นว่าใกล้พลาดแล้ว
		hint_label.text = "ระวัง! ปลาเกือบหนีแล้ว!"
		hint_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	else:
		progress_shake_timer = 0.0
		# reset position ของ progress bar
		var target_x = bar_position.x - BAR_WIDTH / 2 - 24
		progress_bar_bg.position.x = lerp(progress_bar_bg.position.x, target_x, 0.3)
		hint_label.text = "ค้างเมาส์ = ยกกรอบขึ้น"
		hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	# --- % Label ---
	progress_label.text = str(int(progress * 100)) + "%"

	# --- Green zone เปลี่ยนสีเมื่อปลาอยู่ข้างใน ---
	var fish_center = fish_y + 10
	var is_in_zone = fish_center >= green_zone_y and fish_center <= green_zone_y + green_zone_height
	if is_in_zone:
		green_zone_rect.color = Color(0.3, 1.0, 0.4, 0.7)
	else:
		green_zone_rect.color = Color(0.2, 0.6, 0.3, 0.5)


# --------------------------------------------------
# check_end_conditions()
# --------------------------------------------------

func check_end_conditions() -> void:
	if progress >= 1.0:
		emit_signal("fish_caught", fish_data)
		queue_free()
	elif progress <= 0.0:
		emit_signal("fish_escaped")
		queue_free()
