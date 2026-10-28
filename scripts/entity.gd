class_name Entity
extends Node2D
## Base para todo lo que tiene vida: jugador, bots, enemigos y NPCs.

var world  # referencia a main.gd (sin tipo para evitar dependencias cíclicas)
var display_name := ""
var level := 1
var max_hp := 100.0
var hp := 100.0
var radius := 15.0
var sprite_row := 0
var sprite_scale := GameData.ART_SCALE
var sprite_top := 14.0  # filas de pixel-art visibles por encima de los pies
var name_color := Color.WHITE
var facing := Vector2.DOWN
var face_left := false
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
	world.spawn_text(position + Vector2(0, top_y() - 8.0), label, damage_color(crit))
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


func set_facing(dir: Vector2) -> void:
	if dir.length_squared() < 0.0001:
		return
	facing = dir.normalized()
	if absf(facing.x) > 0.15:
		face_left = facing.x < 0.0


func tick_anim(delta: float) -> void:
	attack_anim = maxf(0.0, attack_anim - delta)
	hurt_anim = maxf(0.0, hurt_anim - delta)
	say_time = maxf(0.0, say_time - delta)
	if moving:
		bob += delta * 12.0
	else:
		bob = 0.0


## Altura (negativa) de la parte de arriba del sprite.
func top_y() -> float:
	return -sprite_top * sprite_scale


## Centro del cuerpo, para efectos y proyectiles.
func body_center() -> Vector2:
	return Vector2(0, -sprite_top * 0.5 * sprite_scale)


func draw_shadow() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 5.5 * sprite_scale, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func anim_frame() -> int:
	if moving and int(bob / 3.0) % 2 == 1:
		return 1
	return 0


func draw_sprite(frame: int = -1) -> void:
	if frame < 0:
		frame = anim_frame()
	var w := 16.0 * sprite_scale
	var lunge := 0.0
	if attack_anim > 0.0:
		lunge = sin(attack_anim / 0.2 * PI) * 2.0 * sprite_scale
	var col := Color(1.0, 0.45, 0.45) if hurt_anim > 0.0 else Color.WHITE
	if face_left:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect_region(GameData.CHARS, Rect2(-w / 2.0 + lunge, -15.0 * sprite_scale, w, w),
		Rect2(frame * 16, sprite_row * 16, 16, 16), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_overhead(show_bar: bool) -> void:
	var font: Font = GameData.FONT
	var top := top_y() - 4.0
	if show_bar:
		var w := maxf(40.0, radius * 2.4)
		draw_rect(Rect2(-w / 2.0 - 1, top - 1, w + 2, 7), Color(0.1, 0.05, 0.02, 0.85))
		var ratio := clampf(hp / max_hp, 0.0, 1.0)
		var bar_col := Color(0.35, 0.85, 0.3) if ratio > 0.5 else (Color(0.95, 0.75, 0.2) if ratio > 0.25 else Color(0.9, 0.2, 0.15))
		draw_rect(Rect2(-w / 2.0, top, w * ratio, 5), bar_col)
		top -= 4.0
	var label := display_name if level >= 99 else "%s  Nv %d" % [display_name, level]
	draw_string_outline(font, Vector2(-110, top - 3), label, HORIZONTAL_ALIGNMENT_CENTER, 220, 16, 5, Color(0.08, 0.04, 0.02, 0.9))
	draw_string(font, Vector2(-110, top - 3), label, HORIZONTAL_ALIGNMENT_CENTER, 220, 16, name_color)
	if say_time > 0.0:
		var size := font.get_string_size(say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		var r := Rect2(-size.x / 2.0 - 10, top - 52, size.x + 20, 28)
		draw_rect(r, Color(0.96, 0.92, 0.8, 0.95))
		draw_rect(r, Color(0.42, 0.27, 0.14), false, 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-6, r.end.y), Vector2(6, r.end.y), Vector2(0, r.end.y + 8)]), Color(0.96, 0.92, 0.8, 0.95))
		draw_string(font, Vector2(r.position.x + 10, r.position.y + 20), say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.25, 0.15, 0.08))
