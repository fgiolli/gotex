class_name Player
extends Entity

const ATTACK_CD := 0.55
const ATTACK_REACH := 34.0
const SKILL_CD := 4.0
const SKILL_COST := 20.0
const SKILL_RADIUS := 130.0
const POTION_CD := 1.0

var xp := 0
var gold := 20
var potions := 3
var weapon_lvl := 0
var armor_lvl := 0
var mp := 50.0
var max_mp := 50.0
var speed := 175.0
var attack_cd := 0.0
var skill_cd := 0.0
var potion_cd := 0.0
var combat_time := 0.0
var respawn_time := 0.0
var target: Enemy = null
var move_target := Vector2.ZERO
var has_move_target := false
var pending_npc: Npc = null
var god_mode := false
var quest_type := ""
var quest_needed := 0
var quest_count := 0
var kills := 0


func _ready() -> void:
	radius = 15.0
	sprite_row = int(GameData.CHAR_ROW["knight"])
	name_color = Color(1.0, 0.92, 0.45)
	display_name = "Tú"
	recalc_stats()


func recalc_stats() -> void:
	max_hp = 100.0 + 22.0 * (level - 1) + 15.0 * armor_lvl
	max_mp = 50.0 + 5.0 * (level - 1)
	hp = minf(hp, max_hp)
	mp = minf(mp, max_mp)


func get_attack() -> float:
	return 10.0 + 3.5 * (level - 1) + 6.0 * weapon_lvl


func get_defense() -> float:
	return 0.6 * (level - 1) + 3.0 * armor_lvl


func xp_to_next() -> int:
	return GameData.xp_for_level(level)


func damage_color(_crit: bool) -> Color:
	return Color(1.0, 0.35, 0.35)


func take_damage(amount: float, source: Entity, crit: bool = false) -> void:
	if god_mode:
		amount = 0.0
	super.take_damage(amount, source, crit)


func on_hurt(_source: Entity) -> void:
	combat_time = 4.0


func on_death(source: Entity) -> void:
	respawn_time = 5.0
	target = null
	has_move_target = false
	world.on_player_died(source)


func respawn() -> void:
	dead = false
	hp = max_hp
	mp = max_mp
	target = null
	has_move_target = false
	position = GameData.TOWN_CENTER + Vector2(0, 90)
	world.hud.add_message("Has vuelto a la villa.", Color(0.7, 0.9, 1.0))


## Orden de "tocar el suelo": caminar a un punto.
func walk_to(p: Vector2) -> void:
	move_target = p
	has_move_target = true
	target = null
	pending_npc = null


func attack_target(e: Enemy) -> void:
	target = e
	has_move_target = false
	pending_npc = null


func _process(delta: float) -> void:
	tick_anim(delta)
	if dead:
		respawn_time -= delta
		if respawn_time <= 0.0:
			respawn()
		queue_redraw()
		return
	attack_cd -= delta
	skill_cd -= delta
	potion_cd -= delta
	combat_time -= delta

	var hud = world.hud
	var move: Vector2 = hud.joy_vec
	var kb := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		kb.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		kb.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		kb.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		kb.y += 1.0
	if kb != Vector2.ZERO:
		move = kb.normalized()
	var modal: bool = hud.is_modal()
	if modal:
		move = Vector2.ZERO

	var wants_attack: bool = (hud.is_held("attack") or Input.is_physical_key_pressed(KEY_SPACE)) and not modal
	if not _target_ok():
		target = null
	if wants_attack and target == null:
		target = world.nearest_enemy(position, 320.0)
		if target != null:
			has_move_target = false

	moving = false
	if move.length() > 0.1:
		# el joystick siempre manda
		position += move.limit_length(1.0) * speed * delta
		set_facing(move)
		moving = true
		has_move_target = false
		pending_npc = null
	elif target != null:
		var to := target.position - position
		var reach := radius + target.radius + ATTACK_REACH
		if to.length() > reach - 6.0:
			position += to.normalized() * speed * delta
			moving = true
		set_facing(to)
	elif has_move_target:
		var to := move_target - position
		if to.length() < 6.0:
			has_move_target = false
		else:
			var old := position
			position += to.normalized() * minf(speed * delta, to.length())
			set_facing(to)
			moving = true
			if world.resolve_position(position, radius).distance_to(old) < speed * delta * 0.2:
				has_move_target = false  # bloqueado por un obstáculo

	if target != null and attack_cd <= 0.0:
		if position.distance_to(target.position) <= radius + target.radius + ATTACK_REACH:
			_attack(target)

	position = world.resolve_position(position, radius)

	if pending_npc != null and position.distance_to(pending_npc.position) < 100.0:
		var n := pending_npc
		pending_npc = null
		has_move_target = false
		hud.open_npc(n)

	# regeneración
	if GameData.is_safe(position):
		heal(max_hp * 0.12 * delta)
		mp = minf(max_mp, mp + 12.0 * delta)
	else:
		if combat_time <= 0.0:
			heal(max_hp * 0.015 * delta)
		mp = minf(max_mp, mp + 4.0 * delta)
	queue_redraw()


func _target_ok() -> bool:
	if not is_instance_valid(target):
		return false
	if target.dead:
		return false
	return position.distance_to(target.position) < 520.0


func _attack(t: Enemy) -> void:
	attack_cd = ATTACK_CD
	attack_anim = 0.2
	combat_time = 4.0
	var dmg := get_attack() * randf_range(0.85, 1.15)
	var crit := randf() < 0.12
	if crit:
		dmg *= 1.8
	world.spawn_effect("slash", position + body_center() + facing * 22.0, facing, Color(1, 1, 0.85), 28.0)
	t.take_damage(dmg, self, crit)


func use_skill() -> void:
	if dead or skill_cd > 0.0:
		return
	if mp < SKILL_COST:
		world.hud.add_message("No tienes suficiente maná.", Color(0.6, 0.7, 1.0))
		return
	mp -= SKILL_COST
	skill_cd = SKILL_CD
	attack_anim = 0.2
	combat_time = 4.0
	world.spawn_effect("ring", position + Vector2(0, -6), Vector2.ZERO, Color(1.0, 0.85, 0.3), SKILL_RADIUS)
	for e in world.enemies.duplicate():
		if not e.dead and position.distance_to(e.position) <= SKILL_RADIUS + e.radius:
			e.take_damage(get_attack() * 1.7 * randf_range(0.9, 1.1), self)


func use_potion() -> void:
	if dead or potion_cd > 0.0:
		return
	if potions <= 0:
		world.hud.add_message("No te quedan pociones. Cómpralas a Mara.", Color(1.0, 0.6, 0.6))
		return
	if hp >= max_hp:
		return
	potions -= 1
	potion_cd = POTION_CD
	var amount := max_hp * 0.5
	heal(amount)
	world.spawn_text(position + Vector2(0, top_y() - 8.0), "+%d" % int(amount), Color(0.4, 1.0, 0.4))


func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		recalc_stats()
		hp = max_hp
		mp = max_mp
		world.on_player_level_up()


func _draw() -> void:
	if dead:
		var font: Font = GameData.FONT
		draw_texture_rect_region(GameData.CHARS, Rect2(-24, -40, 48, 48), Rect2(0, int(GameData.CHAR_ROW["knight"]) * 16, 16, 16), Color(1, 1, 1, 0.35))
		draw_string_outline(font, Vector2(-60, -50), "Caído", HORIZONTAL_ALIGNMENT_CENTER, 120, 22, 5, Color.BLACK)
		draw_string(font, Vector2(-60, -50), "Caído", HORIZONTAL_ALIGNMENT_CENTER, 120, 22, Color(0.85, 0.85, 0.85))
		return
	draw_shadow()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_arc(Vector2.ZERO, 19.0, 0, TAU, 32, Color(1.0, 0.85, 0.3, 0.8), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if has_move_target:
		var m := move_target - position
		draw_set_transform(m, 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, 12.0 + sin(Time.get_ticks_msec() * 0.01) * 2.0, 0, TAU, 20, Color(1, 0.9, 0.4, 0.8), 2.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_sprite()
	draw_overhead(true)
