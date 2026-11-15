class_name FeedbackManager
extends Node

@export var canvas_layer: CanvasLayer
@export var flash_rect: ColorRect
@export var feedback_container: Control

# SFX AudioStreamPlayers
@onready var sfx_click: AudioStreamPlayer = $SfxClick
@onready var sfx_jump: AudioStreamPlayer = $SfxJump
@onready var sfx_upgrade: AudioStreamPlayer = $SfxUpgrade
@onready var sfx_level_up: AudioStreamPlayer = $SfxLevelUp
@onready var sfx_phase_change: AudioStreamPlayer = $SfxPhaseChange
@onready var sfx_boost: AudioStreamPlayer = $SfxBoost

var font_melon: Font
var flash_tween: Tween
var shake_tween: Tween

func _ready():
	font_melon = load("res://assets/fonts/Melon Squishy.otf")

func play_click_fx(mouse_pos: Vector2, coins_earned: int):
	trigger_screen_flash(Color(0.85, 0.98, 1.0, 0.28), 0.12)
	trigger_screen_shake(2.5, 0.08)
	spawn_floating_text("+%s Koin" % format_number(coins_earned), mouse_pos, Color("#FFD700"))
	spawn_click_particles(mouse_pos)
	play_sfx(sfx_click, 0.08)

func play_denied_fx():
	play_sfx(sfx_click, 0.04)

func play_jump_fx():
	play_sfx(sfx_jump, 0.05)

func play_landing_fx(slime_pos: Vector2):
	spawn_landing_dust(slime_pos + Vector2(0, 30))

func play_upgrade_fx():
	play_sfx(sfx_upgrade)

func play_level_up_fx():
	play_sfx(sfx_level_up)
	trigger_screen_flash(Color(1.0, 0.9, 0.3, 0.45), 0.35)
	trigger_screen_shake(6.0, 0.22)

func play_phase_change_fx():
	play_sfx(sfx_phase_change)
	trigger_screen_flash(Color(0.3, 0.9, 1.0, 0.5), 0.4)
	trigger_screen_shake(8.0, 0.25)

func play_boost_fx(slime_pos: Vector2):
	play_sfx(sfx_boost)
	trigger_screen_flash(Color(1.0, 0.7, 0.2, 0.55), 0.4)
	trigger_screen_shake(9.0, 0.3)
	spawn_floating_text("FRENZY BOOST 2X!", slime_pos + Vector2(0, -60), Color("#FF9F43"), 34)
	spawn_boost_burst(slime_pos)

func trigger_screen_flash(color: Color, duration: float = 0.12):
	if flash_rect == null: return
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	flash_rect.color = color
	flash_rect.modulate.a = color.a
	flash_tween = create_tween()
	flash_tween.tween_property(flash_rect, "modulate:a", 0.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func trigger_screen_shake(amount: float, duration: float = 0.08):
	if canvas_layer == null: return
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
	var shake_offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
	canvas_layer.offset = shake_offset
	shake_tween = create_tween()
	shake_tween.tween_property(canvas_layer, "offset", Vector2.ZERO, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func spawn_floating_text(text: String, spawn_pos: Vector2, text_color: Color = Color("#FFD700"), font_size: int = 26):
	if feedback_container == null: return
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", font_melon)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.16, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 50
	
	var jitter = Vector2(randf_range(-20, 20), randf_range(-10, 10))
	label.position = spawn_pos + jitter - Vector2(40, 20)
	label.pivot_offset = Vector2(40, 15)
	
	feedback_container.add_child(label)
	
	label.scale = Vector2(0.5, 0.5)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(label, "scale", Vector2(1.2, 1.2), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "position:y", label.position.y - 70.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var tw_seq = create_tween()
	tw_seq.tween_interval(0.2)
	tw_seq.tween_property(label, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	tw_seq.tween_callback(label.queue_free)

func spawn_click_particles(pos: Vector2):
	if feedback_container == null: return
	var particles = CPUParticles2D.new()
	particles.position = pos
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 12
	particles.lifetime = 0.35
	particles.spread = 180.0
	particles.gravity = Vector2(0, 300)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = Color("#5CF2F2")
	particles.z_index = 45
	
	feedback_container.add_child(particles)
	particles.emitting = true
	get_tree().create_timer(0.4).timeout.connect(particles.queue_free)

func spawn_landing_dust(pos: Vector2):
	if feedback_container == null: return
	var dust = CPUParticles2D.new()
	dust.position = pos
	dust.emitting = false
	dust.one_shot = true
	dust.explosiveness = 0.95
	dust.amount = 8
	dust.lifetime = 0.25
	dust.spread = 160.0
	dust.gravity = Vector2(0, 50)
	dust.initial_velocity_min = 40.0
	dust.initial_velocity_max = 90.0
	dust.scale_amount_min = 2.0
	dust.scale_amount_max = 4.5
	dust.color = Color(1.0, 1.0, 1.0, 0.6)
	dust.z_index = 15
	
	feedback_container.add_child(dust)
	dust.emitting = true
	get_tree().create_timer(0.3).timeout.connect(dust.queue_free)

func spawn_boost_burst(pos: Vector2):
	if feedback_container == null: return
	var burst = CPUParticles2D.new()
	burst.position = pos
	burst.emitting = false
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 24
	burst.lifetime = 0.6
	burst.spread = 180.0
	burst.gravity = Vector2(0, -60)
	burst.initial_velocity_min = 140.0
	burst.initial_velocity_max = 260.0
	burst.scale_amount_min = 4.0
	burst.scale_amount_max = 8.0
	burst.color = Color("#FF9F43")
	burst.z_index = 45
	
	feedback_container.add_child(burst)
	burst.emitting = true
	get_tree().create_timer(0.7).timeout.connect(burst.queue_free)

func play_sfx(player: AudioStreamPlayer, pitch_variance: float = 0.0):
	if player == null or player.stream == null: return
	if pitch_variance > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	else:
		player.pitch_scale = 1.0
	player.play()

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
