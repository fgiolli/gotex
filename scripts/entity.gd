class_name Entity
extends Node2D
## Base para todo lo que tiene vida: jugador, bots, enemigos y NPCs.

var world  # referencia a main.gd (sin tipo para evitar dependencias cíclicas)
var display_name := ""
var level := 1
var max_hp := 100.0
var hp := 100.0
var radius := 15.0
var body_color := Color.WHITE
var name_color := Color.WHITE
var facing := Vector2.DOWN
var attack_anim := 0.0
var hurt_anim := 0.0
var dead := false
var bob := 0.0
var moving := false
var say_text := ""
var say_time := 0.0


func get_defense() -> float:
	return 0.0


func take_damage(amount: float, source: Entity, crit: bool = false) -> void:
	if dead:
		return
	var dmg := maxf(1.0, amount - get_defense())
	hp -= dmg
	hurt_anim = 0.15
	var label := str(int(round(dmg)))
	if crit:
		label += "!"
	world.spawn_text(position + Vector2(0, -radius * 2.0 - 16.0), label, damage_color(crit))
	on_hurt(source)
	if hp <= 0.0:
		hp = 0.0
		dead = true
		on_death(source)


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


func on_hurt(_source: Entity) -> void:
	pass


func on_death(_source: Entity) -> void:
	pass


func damage_color(crit: bool) -> Color:
	return Color(1.0, 0.85, 0.2) if crit else Color.WHITE


func say(text: String) -> void:
	say_text = text
	say_time = 4.0


func tick_anim(delta: float) -> void:
	attack_anim = maxf(0.0, attack_anim - delta)
	hurt_anim = maxf(0.0, hurt_anim - delta)
	say_time = maxf(0.0, say_time - delta)
	if moving:
		bob += delta * 12.0
	else:
		bob = 0.0


func body_center() -> Vector2:
	return Vector2(0, -radius - absf(sin(bob)) * 3.0)


func draw_shadow() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, radius * 1.05, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func current_color(base: Color) -> Color:
	return Color(1.0, 0.45, 0.45) if hurt_anim > 0.0 else base


func draw_eyes(c: Vector2) -> void:
	var f := facing.normalized()
	if f.y < -0.6:
		return
	var side := Vector2(-f.y, f.x)
	var eye := c + Vector2(f.x * radius * 0.45, -radius * 0.15 + f.y * radius * 0.25)
	draw_circle(eye + side * radius * 0.28, maxf(2.0, radius * 0.15), Color(0.05, 0.05, 0.08))
	draw_circle(eye - side * radius * 0.28, maxf(2.0, radius * 0.15), Color(0.05, 0.05, 0.08))


func draw_humanoid(hat_color: Color) -> void:
	var c := body_center()
	var col := current_color(body_color)
	draw_circle(c, radius, col.darkened(0.4))
	draw_circle(c, radius - 2.0, col)
	# cara
	draw_circle(c + Vector2(0, -2), radius * 0.62, Color(1.0, 0.86, 0.72))
	draw_eyes(c + Vector2(0, -2))
	# sombrero / pelo
	draw_arc(c + Vector2(0, -2), radius * 0.66, PI * 1.05, PI * 1.95, 12, hat_color, radius * 0.4)


func draw_weapon(kind: String) -> void:
	var c := body_center()
	var f := facing.normalized()
	var swing := attack_anim / 0.2
	var dir := f.rotated(-1.2 + 2.4 * (1.0 - swing)) if attack_anim > 0.0 else f.rotated(0.6)
	var hand := c + dir * radius * 0.9
	match kind:
		"sword":
			draw_line(hand, hand + dir * 22.0, Color(0.85, 0.87, 0.92), 4.0)
			draw_line(hand - dir.orthogonal() * 6.0, hand + dir.orthogonal() * 6.0, Color(0.55, 0.4, 0.2), 3.0)
		"staff":
			draw_line(hand - dir * 6.0, hand + dir * 22.0, Color(0.5, 0.33, 0.18), 3.0)
			draw_circle(hand + dir * 24.0, 5.0, Color(0.5, 0.75, 1.0))
		"bow":
			draw_arc(hand, 12.0, dir.angle() - 1.2, dir.angle() + 1.2, 10, Color(0.55, 0.38, 0.2), 3.0)


func draw_overhead(show_bar: bool) -> void:
	var font := ThemeDB.fallback_font
	var top := -radius * 2.0 - 10.0
	if show_bar:
		var w := maxf(36.0, radius * 2.4)
		draw_rect(Rect2(-w / 2.0 - 1, top - 1, w + 2, 7), Color(0, 0, 0, 0.7))
		var ratio := clampf(hp / max_hp, 0.0, 1.0)
		var bar_col := Color(0.3, 0.9, 0.3) if ratio > 0.5 else (Color(0.95, 0.75, 0.2) if ratio > 0.25 else Color(0.95, 0.25, 0.2))
		draw_rect(Rect2(-w / 2.0, top, w * ratio, 5), bar_col)
	var label := display_name if level >= 99 else "%s  Nv%d" % [display_name, level]
	draw_string_outline(font, Vector2(-100, top - 5), label, HORIZONTAL_ALIGNMENT_CENTER, 200, 13, 4, Color(0, 0, 0, 0.85))
	draw_string(font, Vector2(-100, top - 5), label, HORIZONTAL_ALIGNMENT_CENTER, 200, 13, name_color)
	if say_time > 0.0:
		var size := font.get_string_size(say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		var r := Rect2(-size.x / 2.0 - 8, top - 48, size.x + 16, 26)
		draw_rect(r, Color(1, 1, 1, 0.92))
		draw_colored_polygon(PackedVector2Array([Vector2(-6, r.end.y), Vector2(6, r.end.y), Vector2(0, r.end.y + 7)]), Color(1, 1, 1, 0.92))
		draw_string(font, Vector2(r.position.x + 8, r.position.y + 18), say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.1, 0.1, 0.15))
