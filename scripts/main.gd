extends Node2D

@onready var bg: TextureRect = $CanvasLayer/Background
@onready var slime: AnimatedSprite2D = $CanvasLayer/Slime
@onready var ui = $CanvasLayer
@onready var feedback = $FeedbackManager

@export var backgrounds: Array[Texture2D]

# --- GDD v2 CORE GAME STATE ---
var level = 1
var coins = 0
var total_clicks = 0
var base_y = 0.0 
var is_jumping = false 

# --- COMBO & BOOST STATE ---
const MAX_COMBO: int = 10
const BOOST_DURATION: float = 7.0
const COMBO_DECAY_TIME: float = 2.8

var combo_count: int = 0
var combo_timer: float = 0.0
var is_boost_active: bool = false
var boost_timer: float = 0.0

# 5 Places & Slime Colors from GDD v2
var places = [
	{
		"name": "Padang Rumput",
		"bg": "res://assets/backgrounds/Phase 1 (#1).jpeg",
		"color": Color("#5CD65C"), # Hijau
		"min_lvl": 1,
		"max_lvl": 30
	},
	{
		"name": "Hutan Pepohonan",
		"bg": "res://assets/backgrounds/Phase 1 (#2).jpeg",
		"color": Color("#4DA6FF"), # Biru
		"min_lvl": 31,
		"max_lvl": 60
	},
	{
		"name": "Depan Mulut Gua",
		"bg": "res://assets/backgrounds/Phase 1 (#3).jpeg",
		"color": Color("#FF9F43"), # Oranye
		"min_lvl": 61,
		"max_lvl": 90
	},
	{
		"name": "Di Dalam Gua",
		"bg": "res://assets/backgrounds/Phase 1 (#4).jpeg",
		"color": Color("#9B59F5"), # Ungu
		"min_lvl": 91,
		"max_lvl": 120
	},
	{
		"name": "Gua Penuh Kristal",
		"bg": "res://assets/backgrounds/Phase 1 (#5).jpeg",
		"color": Color("#5CF2F2"), # Cyan berkilau
		"min_lvl": 121,
		"max_lvl": 150
	}
]

# --- SHOP ITEMS (Makanan = Boost Koin, Minuman = Kurangi Cooldown) ---
# Konsep: Setiap beli ada cooldown (timer). Selama cooldown, efek aktif dan tidak bisa dibeli lagi.
var shop_items = [
	{
		"id": "strawberry",
		"name": "Stroberi",
		"type": "food",
		"boost": 0.25,      # +25% koin
		"cost": 2500,         # 2500 koin
		"duration": 20.0,   # 20 detik aktif & cooldown
		"timer": 0.0,
		"active": false
	},
	{
		"id": "diet_coke",
		"name": "Diet Coke",
		"type": "drink",
		"boost": 0.15,      # -15% cooldown loncat
		"cost": 3500,
		"duration": 15.0,
		"timer": 0.0,
		"active": false
	},
	{
		"id": "orange",
		"name": "Jeruk",
		"type": "food",
		"boost": 0.50,      # +50% koin
		"cost": 7500,
		"duration": 25.0,
		"timer": 0.0,
		"active": false
	},
	{
		"id": "mtn_dew",
		"name": "Mtn Dew",
		"type": "drink",
		"boost": 0.25,      # -25% cooldown loncat
		"cost": 10500,
		"duration": 15.0,
		"timer": 0.0,
		"active": false
	},
	{
		"id": "pineapple",
		"name": "Nanas",
		"type": "food",
		"boost": 0.75,     # +75% koin
		"cost": 17500,
		"duration": 25.0,
		"timer": 0.0,
		"active": false
	},
	{
		"id": "monster",
		"name": "Monster",
		"type": "drink",
		"boost": 0.35,      # -35% cooldown loncat
		"cost": 24500,
		"duration": 10.0,
		"timer": 0.0,
		"active": false
	}
]

func _ready():
	base_y = slime.position.y 
	
	# Connect UI Signals (Only ClickButton triggers clicks, no fullscreen area!)
	ui.click_requested.connect(_on_click_button_pressed)
	ui.upgrade_requested.connect(_on_upgrade_button_pressed)
	ui.boost_requested.connect(_on_boost_button_pressed)
	ui.item_buy_requested.connect(_on_item_buy_requested)
	
	update_game()

func _process(delta: float):
	# Handle Boost active duration
	if is_boost_active:
		boost_timer -= delta
		if boost_timer <= 0.0:
			is_boost_active = false
			boost_timer = 0.0
			combo_count = 0
			update_ui()
		else:
			ui.update_combo(combo_count, MAX_COMBO, false, true, boost_timer)
	else:
		# Combo decay if player stops clicking
		if combo_count > 0 and combo_count < MAX_COMBO:
			combo_timer -= delta
			if combo_timer <= 0.0:
				combo_count = max(0, combo_count - 1)
				combo_timer = 1.0 # Decay gradually
				ui.update_combo(combo_count, MAX_COMBO, false, false, 0.0)

	# Handle Shop Item Cooldowns & Buff Timers
	var shop_status_changed = false
	for item in shop_items:
		if item["timer"] > 0.0:
			item["timer"] -= delta
			if item["timer"] <= 0.0:
				item["timer"] = 0.0
				item["active"] = false
				shop_status_changed = true
	
	if shop_status_changed:
		update_game()
	else:
		ui.update_shop_timers(shop_items)

# --- GDD v2 FORMULAS ---

func get_base_coin_reward() -> int:
	return int(max(level, round(pow(1.10, level - 1))))

func get_food_coin_multiplier() -> float:
	var mult = 1.0
	for item in shop_items:
		if item["type"] == "food" and item["active"]:
			mult += item["boost"]
	return mult

func get_drink_cooldown_factor() -> float:
	var factor = 1.0
	for item in shop_items:
		if item["type"] == "drink" and item["active"]:
			factor -= item["boost"]
	return max(0.35, factor) # Batas maksimal percepatan dari minuman

func get_coin_reward() -> int:
	var base = get_base_coin_reward()
	var with_food = int(round(base * get_food_coin_multiplier()))
	if is_boost_active:
		return with_food * 2 # 2x Coin Frenzy Boost!
	return with_food

func get_upgrade_cost() -> int:
	return int(round(10.0 * pow(1.12, level - 1)))

func get_jump_duration() -> float:
	var dur = max(0.3, pow(0.97, level - 1))
	dur *= get_drink_cooldown_factor()
	if is_boost_active:
		dur = max(0.15, dur * 0.75) # 25% faster jumps during boost
	return max(0.15, dur)

func get_place_index() -> int:
	return clampi((level - 1) / 30, 0, 4)

func is_place_transition_level() -> bool:
	return level in [30, 60, 90, 120]

# --- CLICK & JUMP LOGIC ---

func _on_click_button_pressed():
	# GDD: "Klik saat Slime masih di udara tidak dihitung."
	if is_jumping:
		ui.animate_cooldown_denied()
		return
		
	is_jumping = true
	total_clicks += 1
	
	# Add combo progress (if boost is not currently running)
	if not is_boost_active:
		if combo_count < MAX_COMBO:
			combo_count += 1
			combo_timer = COMBO_DECAY_TIME
			
	var earned_coins = get_coin_reward()
	coins += earned_coins
	
	# Visual & Audio Feedbacks
	var click_pos = ui.click_btn.global_position + (ui.click_btn.size / 2.0)
	feedback.play_click_fx(click_pos, earned_coins)
	ui.animate_coin_bounce()
	
	update_ui()
	
	# Jump animation
	var jump_duration = get_jump_duration()
	var half_time = jump_duration / 2.0
	
	var phase = get_place_index()
	slime.stop()
	slime.frame = 0
	if slime.sprite_frames.has_animation("jump_" + str(phase)):
		slime.play("jump_" + str(phase))
	else:
		slime.play("jump_0")
	slime.speed_scale = 0.7 / jump_duration
	
	feedback.play_jump_fx()
	ui.start_cooldown(jump_duration)
	
	var jump_height = 80.0
		
	var tween = create_tween()
	tween.tween_property(slime, "position:y", base_y - jump_height, half_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(slime, "position:y", base_y, half_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): _on_slime_landed())

func _on_slime_landed():
	is_jumping = false
	
	feedback.play_landing_fx(slime.position)
	
	# Landing squash & stretch
	var sq = create_tween()
	sq.tween_property(slime, "scale", Vector2(0.22, 0.18), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sq.tween_property(slime, "scale", Vector2(0.2, 0.2), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	ui.finish_cooldown()

# --- BOOST LOGIC ---

func _on_boost_button_pressed():
	if combo_count < MAX_COMBO or is_boost_active: return
	
	is_boost_active = true
	boost_timer = BOOST_DURATION
	combo_count = 0
	
	feedback.play_boost_fx(slime.position)
	update_ui()

# --- SHOP ITEM BUY LOGIC ---

func _on_item_buy_requested(item_id: String):
	for item in shop_items:
		if item["id"] == item_id:
			# Jika sedang cooldown, tidak bisa dibeli langsung
			if item["timer"] > 0.0:
				if feedback: feedback.play_denied_fx()
				if ui: ui.animate_cooldown_denied()
				return
				
			if coins >= item["cost"]:
				coins -= item["cost"]
				item["timer"] = item["duration"]
				item["active"] = true
				if feedback: feedback.play_upgrade_fx()
				if ui: ui.show_celebration(item["name"].to_upper() + " AKTIF!")
				update_game()
			else:
				if feedback: feedback.play_denied_fx()
				if ui: ui.animate_cooldown_denied()
			break

# --- UPGRADE & PROGRESSION LOGIC ---

func _on_upgrade_button_pressed():
	if level >= 150: return
	
	var cost = get_upgrade_cost()
	if coins >= cost:
		coins -= cost
		var old_phase = get_place_index()
		level += 1
		var new_phase = get_place_index()
		
		ui.animate_button_punch(ui.upgrade_btn)
		feedback.play_upgrade_fx()
		
		# Check if location changed (30->31, 60->61, etc.)
		if new_phase > old_phase:
			var place_name = places[new_phase]["name"]
			feedback.play_phase_change_fx()
			ui.show_celebration("PINDAH TEMPAT: %s!" % place_name.to_upper())
		else:
			feedback.play_level_up_fx()
			ui.show_celebration("LEVEL UP! Lv. %d" % level)
			
		update_game()

func update_game():
	var p_idx = get_place_index()
	var current_place = places[p_idx]
	
	# Background
	if backgrounds.size() > p_idx and backgrounds[p_idx] != null:
		bg.texture = backgrounds[p_idx]
	elif ResourceLoader.exists(current_place["bg"]):
		var tex = load(current_place["bg"])
		if tex:
			bg.texture = tex
			
	# Slime animation & appearance
	var anim_name = "jump_" + str(p_idx)
	if slime.sprite_frames.has_animation(anim_name):
		slime.animation = anim_name
		slime.frame = 0
		slime.modulate = Color.WHITE
	else:
		slime.animation = "jump_0"
		slime.frame = 0
		slime.modulate = current_place["color"]
	
	update_ui()

func update_ui():
	var p_idx = get_place_index()
	var current_place = places[p_idx]
	
	ui.update_hud(level, current_place["name"], coins, get_coin_reward(), get_jump_duration(), total_clicks, is_boost_active)
	
	var cost = get_upgrade_cost()
	var next_coin = int(max(level + 1, round(pow(1.10, level))))
	var next_place = places[min(p_idx + 1, 4)]["name"]
	ui.update_upgrade_button(level, cost, next_coin, coins, is_place_transition_level(), next_place)
	
	var is_boost_ready = (combo_count >= MAX_COMBO and not is_boost_active)
	ui.update_combo(combo_count, MAX_COMBO, is_boost_ready, is_boost_active, boost_timer)
	ui.update_shop_items(shop_items, coins)
