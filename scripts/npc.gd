class_name Npc
extends Entity

var role := "shop"
var hat_color := Color.WHITE


func setup(n: String, r: String, col: Color, hat: Color) -> void:
	display_name = n
	role = r
	body_color = col
	hat_color = hat
	name_color = Color(1.0, 0.85, 0.3)
	level = 99
	radius = 16.0


func _process(delta: float) -> void:
	tick_anim(delta)
	if world.player != null:
		var to: Vector2 = world.player.position - position
		if to.length() < 250.0:
			facing = to.normalized()
	queue_redraw()


func _draw() -> void:
	draw_shadow()
	draw_humanoid(hat_color)
	draw_overhead(false)
	var font := ThemeDB.fallback_font
	var icon := "$" if role == "shop" else "!"
	if role == "quest" and world.player != null and world.player.quest_type != "":
		icon = "?" if world.player.quest_count >= world.player.quest_needed else ""
	if icon != "":
		var y := -radius * 2.0 - 34.0 + sin(Time.get_ticks_msec() * 0.005) * 3.0
		draw_string_outline(font, Vector2(-20, y), icon, HORIZONTAL_ALIGNMENT_CENTER, 40, 26, 5, Color.BLACK)
		draw_string(font, Vector2(-20, y), icon, HORIZONTAL_ALIGNMENT_CENTER, 40, 26, Color(1.0, 0.85, 0.2))
