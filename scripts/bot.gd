class_name Bot
extends Entity
## "Otro jugador" simulado: caza monstruos, vuelve al pueblo y chatea.

var cls := "Guerrero"
var atk := 12.0
var speed := 160.0
var attack_range := 30.0
var attack_cd := 0.0
var target: Enemy = null
var state := "hunt"
var state_time := 0.0
var think := 0.0
var dest := Vector2.ZERO
var respawn_time := 0.0
var xp := 0
var potion_cd := 0.0


func setup(n: String, c: String, lvl: int) -> void:
	display_name = n
	cls = c
	level = lvl
	name_color = Color(0.6, 0.85, 1.0)
	match c:
		"Guerrero":
			sprite_row = int(GameData.CHAR_ROW["warrior"])
			attack_range = 30.0
		"Mago":
			sprite_row = int(GameData.CHAR_ROW["mage"])
			attack_range = 170.0
		_:
			sprite_row = int(GameData.CHAR_ROW["archer"])
			attack_range = 190.0
	speed = randf_range(150.0, 175.0)
	recalc()
	state_time = randf_range(20.0, 60.0)


func recalc() -> void:
	max_hp = 100.0 + 22.0 * (level - 1)
	if cls == "Guerrero":
		max_hp *= 1.3
	atk = 11.0 + 3.5 * (level - 1)
	hp = max_hp


func get_defense() -> float:
	return 0.8 * (level - 1) + (3.0 if cls == "Guerrero" else 0.0)


func damage_color(_crit: bool) -> Color:
	return Color(1.0, 0.6, 0.6)


func on_death(_source: Entity) -> void:
	respawn_time = randf_range(6.0, 12.0)
	target = null
	visible = false
	world.on_bot_died(self)


func add_xp(amount: int) -> void:
	xp += amount
	if level < 20 and xp >= GameData.xp_for_level(level) * 2:
		xp = 0
		level += 1
		recalc()
		world.bot_chat(self, "subi a nivel %d :D" % level)


func _process(delta: float) -> void:
	tick_anim(delta)
	if dead:
		respawn_time -= delta
		if respawn_time <= 0.0:
			dead = false
			visible = true
			hp = max_hp
			position = world.random_town_point()
			state = "town"
			state_time = randf_range(6.0, 15.0)
			dest = world.random_town_point()
		return
	attack_cd -= delta
	think -= delta
	state_time -= delta
	potion_cd -= delta
	if think <= 0.0:
		think = randf_range(0.4, 0.7)
		_think()

	moving = false
	if state == "hunt" and is_instance_valid(target) and not target.dead:
		var to := target.position - position
		var reach := attack_range + radius + target.radius
		if to.length() > reach - 4.0:
			_step(target.position, delta)
		else:
			set_facing(to)
			if attack_cd <= 0.0:
				_attack(target)
	elif position.distance_to(dest) > 12.0:
		_step(dest, delta)

	if hp < max_hp * 0.3 and potion_cd <= 0.0:
		potion_cd = 20.0
		heal(max_hp * 0.5)
	if target == null or GameData.is_safe(position):
		heal(max_hp * (0.1 if GameData.is_safe(position) else 0.02) * delta)
	queue_redraw()


func _step(p: Vector2, delta: float) -> void:
	var dir := (p - position).normalized()
	set_facing(dir)
	var old := position
	position = world.resolve_position(position + dir * speed * delta, radius)
	moving = true
	if position.distance_to(old) < speed * delta * 0.3:
		# atascado: rodear un poco
		position = world.resolve_position(position + dir.orthogonal() * speed * delta, radius)


func _think() -> void:
	if state == "hunt":
		if not is_instance_valid(target) or target.dead:
			target = world.find_enemy_for_bot(self)
			if target == null and position.distance_to(dest) < 30.0:
				dest = world.random_point_in_zone(GameData.zone_for_level(level))
		if state_time <= 0.0 or hp < max_hp * 0.15:
			state = "town"
			target = null
			dest = world.random_town_point()
			state_time = randf_range(10.0, 25.0)
	else:
		if position.distance_to(dest) < 20.0 and randf() < 0.08:
			dest = world.random_town_point()
		if state_time <= 0.0:
			state = "hunt"
			state_time = randf_range(40.0, 90.0)
			dest = world.random_point_in_zone(GameData.zone_for_level(level))


func _attack(t: Enemy) -> void:
	attack_cd = 0.9 if cls == "Guerrero" else 1.2
	attack_anim = 0.2
	var from := position + body_center()
	var to := t.position + t.body_center()
	match cls:
		"Mago":
			world.spawn_effect("bolt", from, to, Color(0.5, 0.7, 1.0), 6.0)
		"Arquero":
			world.spawn_effect("bolt", from, to, Color(0.85, 0.7, 0.4), 3.0)
		_:
			world.spawn_effect("slash", from + facing * 22.0, facing, Color(1, 0.9, 0.9), 24.0)
	t.take_damage(atk * randf_range(0.85, 1.15), self, randf() < 0.1)


func _draw() -> void:
	if dead:
		return
	draw_shadow()
	draw_sprite()
	draw_overhead(true)
