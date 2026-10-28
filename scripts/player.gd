class_name Player
extends Entity

const ATTACK_CD := 0.55
const ATTACK_REACH := 34.0
const SKILL_CD := 4.0
const SKILL_COST := 20.0
const SKILL_RADIUS := 120.0
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
var quest_type := ""
var quest_needed := 0
var quest_count := 0
var kills := 0


func _ready() -> void:
	radius = 15.0
	body_color = Color(1.0, 0.72, 0.2)
	name_color = Color(1.0, 0.95, 0.4)
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


func on_hurt(_source: Entity) -> void:
	combat_time = 4.0


func on_death(source: Entity) -> void:
	respawn_time = 5.0
	target = null
	world.on_player_died(source)


func respawn() -> void:
	dead = false
	hp = max_hp
	mp = max_mp
	target = null
	position = GameData.TOWN_CENTER + Vector2(0, 90)
	world.hud.add_message("Has reaparecido en el pueblo.", Color(0.7, 0.9, 1.0))


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

	moving = false
	if move.length() > 0.1:
		position += move.limit_length(1.0) * speed * delta
		facing = move.normalized()
		moving = true
	elif target != null:
		var to := target.position - position
		var reach := radius + target.radius + ATTACK_REACH
		if to.length() > reach - 6.0:
			position += to.normalized() * speed * delta
			moving = true
		facing = to.normalized()

	if target != null and attack_cd <= 0.0:
		if position.distance_to(target.position) <= radius + target.radius + ATTACK_REACH:
			_attack(target)

	position = world.resolve_position(position, radius)

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
	world.spawn_effect("slash", position + Vector2(0, -radius) + facing * 18.0, facing, Color(1, 1, 0.85), 26.0)
	t.take_damage(dmg, self, crit)


func use_skill() -> void:
	if dead or skill_cd > 0.0:
		return
	if mp < SKILL_COST:
		world.hud.add_message("No tienes suficiente mana.", Color(0.6, 0.7, 1.0))
		return
	mp -= SKILL_COST
	skill_cd = SKILL_CD
	attack_anim = 0.2
	combat_time = 4.0
	world.spawn_effect("ring", position + Vector2(0, -radius), Vector2.ZERO, Color(1.0, 0.85, 0.3), SKILL_RADIUS)
	for e in world.enemies.duplicate():
		if not e.dead and position.distance_to(e.position) <= SKILL_RADIUS + e.radius:
			e.take_damage(get_attack() * 1.7 * randf_range(0.9, 1.1), self)


func use_potion() -> void:
	if dead or potion_cd > 0.0:
		return
	if potions <= 0:
		world.hud.add_message("No te quedan pociones. Compra en la tienda.", Color(1.0, 0.6, 0.6))
		return
	if hp >= max_hp:
		return
	potions -= 1
	potion_cd = POTION_CD
	var amount := max_hp * 0.5
	heal(amount)
	world.spawn_text(position + Vector2(0, -radius * 2.0 - 16.0), "+%d" % int(amount), Color(0.4, 1.0, 0.4))


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
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(-60, -20), "RIP", HORIZONTAL_ALIGNMENT_CENTER, 120, 22, 5, Color.BLACK)
		draw_string(font, Vector2(-60, -20), "RIP", HORIZONTAL_ALIGNMENT_CENTER, 120, 22, Color(0.8, 0.8, 0.8))
		return
	draw_shadow()
	draw_arc(Vector2.ZERO, radius + 4.0, 0, TAU, 24, Color(1.0, 0.9, 0.3, 0.6), 2.0)
	draw_humanoid(Color(0.55, 0.3, 0.12))
	draw_weapon("sword")
	draw_overhead(true)
