class_name UIManager
extends CanvasLayer

signal click_requested
signal upgrade_requested
signal boost_requested
signal item_buy_requested(item_id: String)

# UI Node References
@onready var hud_card: PanelContainer = $HUDCard
@onready var shop_bar: HBoxContainer = $ShopBar
@onready var level_title_label: Label = $HUDCard/VBox/HeaderHBox/LevelTitle
@onready var place_badge_label: Label = $HUDCard/VBox/HeaderHBox/PlaceBadge/PlaceLabel
@onready var coin_amount_label: Label = $HUDCard/VBox/CoinsHBox/CoinAmount
@onready var coin_rate_label: Label = $HUDCard/VBox/CoinsHBox/CoinRate
@onready var speed_info_label: Label = $HUDCard/VBox/InfoHBox/SpeedLabel
@onready var click_count_label: Label = $HUDCard/VBox/InfoHBox/ClickCountLabel

@onready var upgrade_btn: Button = $UpgradeButton

@onready var bottom_click_area: VBoxContainer = $BottomClickArea
@onready var boost_btn: Button = $BottomClickArea/BoostButton
@onready var combo_bar: ProgressBar = $BottomClickArea/ComboBar
@onready var combo_label: Label = $BottomClickArea/ComboLabel
@onready var cooldown_bar: ProgressBar = $BottomClickArea/CooldownBar
@onready var click_btn: Button = $BottomClickArea/ClickButton

@onready var celebration_label: Label = $CelebrationLabel

var coin_bounce_tween: Tween
var cooldown_tween: Tween
var denied_tween: Tween
var boost_pulse_tween: Tween

func _ready():
	click_btn.pressed.connect(func(): click_requested.emit())
	upgrade_btn.pressed.connect(func(): upgrade_requested.emit())
	boost_btn.pressed.connect(func(): boost_requested.emit())
	
	# Connect shop item buttons
	var shop_ids = ["strawberry", "diet_coke", "orange", "mtn_dew", "pineapple", "monster"]
	for id in shop_ids:
		var btn = shop_bar.get_node_or_null("Item_" + id)
		if btn:
			btn.pressed.connect(func():
				animate_button_punch(btn)
				item_buy_requested.emit(id)
			)
	
	cooldown_bar.max_value = 1.0
	cooldown_bar.value = 1.0
	
	combo_bar.max_value = 10.0
	combo_bar.value = 0.0
	boost_btn.visible = false

func update_shop_items(items: Array, current_coins: int):
	if shop_bar == null:
		shop_bar = get_node_or_null("ShopBar")
	if shop_bar == null: return
	
	for item in items:
		var btn = shop_bar.get_node_or_null("Item_" + item["id"])
		if not btn: continue
		var price_label = btn.get_node_or_null("VBox/PriceLabel")
		if not price_label: continue
		
		if item["timer"] > 0.0:
			price_label.text = "%ds" % int(ceil(item["timer"]))
			price_label.add_theme_color_override("font_color", Color("#FF9F43"))
			btn.disabled = true
		else:
			price_label.text = format_number(item["cost"])
			btn.disabled = false
			if current_coins >= item["cost"]:
				price_label.add_theme_color_override("font_color", Color("#FFD700"))
			else:
				price_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 0.75))

func update_shop_timers(items: Array):
	if shop_bar == null:
		shop_bar = get_node_or_null("ShopBar")
	if shop_bar == null: return
	
	for item in items:
		if item["timer"] > 0.0:
			var btn = shop_bar.get_node_or_null("Item_" + item["id"])
			if btn:
				var price_label = btn.get_node_or_null("VBox/PriceLabel")
				if price_label:
					price_label.text = "%ds" % int(ceil(item["timer"]))

func update_hud(level: int, place_name: String, coins: int, coin_reward: int, jump_speed: float, total_clicks: int, is_boost_active: bool):
	level_title_label.text = "LEVEL %d / 150" % level
	place_badge_label.text = place_name.to_upper()
	
	coin_amount_label.text = format_number(coins)
	if is_boost_active:
		coin_rate_label.text = " (+%s/klik) [2X BOOST]" % format_number(coin_reward)
		coin_rate_label.add_theme_color_override("font_color", Color("#FF8C00"))
	else:
		coin_rate_label.text = " (+%s/klik)" % format_number(coin_reward)
		coin_rate_label.add_theme_color_override("font_color", Color("#FFF59D"))
		
	speed_info_label.text = "Loncat: %.2fs" % jump_speed
	click_count_label.text = "Klik: %s" % format_number(total_clicks)

func update_upgrade_button(level: int, cost: int, next_coin: int, coins: int, is_place_transition: bool, next_place: String):
	if level >= 150:
		upgrade_btn.text = "MAX LEVEL (TAMAT!)\nSelamat! Perjalanan Slime Selesai!"
		upgrade_btn.disabled = true
	elif is_place_transition:
		upgrade_btn.text = "PINDAH TEMPAT: %s\nBiaya: %s Koin  (Naik ke Lv. %d)" % [next_place, format_number(cost), level + 1]
		upgrade_btn.disabled = (coins < cost)
	else:
		upgrade_btn.text = "UPGRADE LEVEL (%d -> %d)\nBiaya: %s Koin • +Koin (%s/klik) & Loncat Makin Cepat" % [level, level + 1, format_number(cost), format_number(next_coin)]
		upgrade_btn.disabled = (coins < cost)

func update_combo(combo_count: int, max_combo: int, is_boost_ready: bool, is_boost_active: bool, boost_time_left: float):
	combo_bar.max_value = max_combo
	
	if is_boost_active:
		combo_bar.value = boost_time_left
		combo_bar.max_value = 7.0
		combo_label.text = "BOOST AKTIF: %.1fs (2X KOIN!)" % boost_time_left
		combo_label.add_theme_color_override("font_color", Color("#FFD700"))
		boost_btn.visible = false
	elif is_boost_ready:
		combo_bar.value = max_combo
		combo_label.text = "COMBO MAKSIMAL! TEKAN BOOST!"
		combo_label.add_theme_color_override("font_color", Color("#FF9F43"))
		if not boost_btn.visible:
			boost_btn.visible = true
			animate_boost_button_pulse()
	else:
		combo_bar.value = combo_count
		if combo_count > 0:
			combo_label.text = "COMBO: %d / %d" % [combo_count, max_combo]
		else:
			combo_label.text = "KLIK UNTUK COMBO"
		combo_label.add_theme_color_override("font_color", Color("#81D4FA"))
		boost_btn.visible = false

func start_cooldown(duration: float):
	click_btn.disabled = true
	click_btn.text = "WAIT..."
	
	cooldown_bar.max_value = duration
	cooldown_bar.value = 0.0
	
	if cooldown_tween and cooldown_tween.is_valid():
		cooldown_tween.kill()
	cooldown_tween = create_tween()
	cooldown_tween.tween_property(cooldown_bar, "value", duration, duration)

func finish_cooldown():
	click_btn.disabled = false
	click_btn.text = "CLICK"
	cooldown_bar.value = cooldown_bar.max_value
	
	# Subtle ready flash on the cooldown bar
	var tw = create_tween()
	tw.tween_property(cooldown_bar, "modulate", Color(1.6, 1.6, 1.6, 1.0), 0.06)
	tw.tween_property(cooldown_bar, "modulate", Color.WHITE, 0.12)
	
	animate_button_punch(click_btn)

func animate_cooldown_denied():
	if denied_tween and denied_tween.is_valid():
		denied_tween.kill()
		
	var orig_x = bottom_click_area.position.x
	denied_tween = create_tween()
	denied_tween.tween_property(bottom_click_area, "position:x", orig_x - 4.0, 0.03)
	denied_tween.tween_property(bottom_click_area, "position:x", orig_x + 4.0, 0.03)
	denied_tween.tween_property(bottom_click_area, "position:x", orig_x, 0.03)
	
	var bar_tw = create_tween()
	bar_tw.tween_property(cooldown_bar, "modulate", Color(1.6, 0.4, 0.4, 1.0), 0.04)
	bar_tw.tween_property(cooldown_bar, "modulate", Color.WHITE, 0.1)

func animate_coin_bounce():
	if coin_bounce_tween and coin_bounce_tween.is_valid():
		coin_bounce_tween.kill()
	coin_amount_label.pivot_offset = coin_amount_label.size / 2.0
	coin_bounce_tween = create_tween()
	coin_bounce_tween.tween_property(coin_amount_label, "scale", Vector2(1.2, 1.2), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	coin_bounce_tween.tween_property(coin_amount_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func animate_button_punch(btn: Button):
	if btn == null: return
	btn.pivot_offset = btn.size / 2.0
	var tw = create_tween()
	tw.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func animate_boost_button_pulse():
	if boost_pulse_tween and boost_pulse_tween.is_valid():
		boost_pulse_tween.kill()
	boost_btn.pivot_offset = boost_btn.size / 2.0
	boost_pulse_tween = create_tween().set_loops()
	boost_pulse_tween.tween_property(boost_btn, "scale", Vector2(1.05, 1.05), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	boost_pulse_tween.tween_property(boost_btn, "scale", Vector2(0.96, 0.96), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func show_celebration(text: String):
	celebration_label.text = text
	celebration_label.visible = true
	celebration_label.modulate.a = 1.0
	celebration_label.pivot_offset = celebration_label.size / 2.0
	celebration_label.scale = Vector2(0.3, 0.3)
	
	var tw = create_tween()
	tw.tween_property(celebration_label, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(celebration_label, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(0.7)
	tw.tween_property(celebration_label, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func(): celebration_label.visible = false)

func format_number(val: int) -> String:
	var s = str(val)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res
