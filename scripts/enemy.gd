class_name Enemy
extends Entity

const LEASH := 520.0

var type_id := ""
var home := Vector2.ZERO
var atk := 5.0
var speed := 60.0
var aggro_range := 0.0
var xp_reward := 10
var gold_reward := 2
var is_boss := false
var target: Entity = null
var wander_to := Vector2.ZERO
var wander_wait := 0.0
var attack_cd := 0.0
var death_time := 0.0


func setup(id: String, lvl: int, home_pos: Vector2) -> void:
	var d: Dictionary = GameData.ENEMY_TYPES[id]
	type_id = id
	level = lvl
	var steps := float(lvl - int(d["lvl_min"]))
	display_name = d["name"]
	body_color = d["color"]
	max_hp = float(d["hp"]) * (1.0 + 0.18 * steps)
	hp = max_hp
	atk = float(d["atk"]) * (1.0 + 0.12 * steps)
	speed = float(d["speed"])
	radius = float(d["radius"])
	aggro_range = float(d["aggro"])
	xp_reward = int(float(d["xp"]) * (1.0 + 0.2 * steps))
	gold_reward = int(d["gold"]) + int(steps)
	is_boss = id == "boss"
	home = home_pos
	position = home_pos
	wander_to = home_pos
	name_color = Color(1.0, 0.55, 0.5) if aggro_range > 0.0 else Color(0.85, 0.95, 0.85)
	if is_boss:
		name_color = Color(1.0, 0.3, 0.9)


func get_defense() -> float:
	return level * 0.5


func on_hurt(source: Entity) -> void:
	if source != null and not source.dead:
		if target == null or not is_instance_valid(target) or target.dead:
			target = source


func on_death(source: Entity) -> void:
	target = null
	world.on_enemy_killed(self, source)


func _target_ok() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target.dead or GameData.is_safe(target.position):
		return false
	return position.distance_to(home) < LEASH


func _process(delta: float) -> void:
	tick_anim(delta)
	if dead:
		death_time += delta
		modulate.a = maxf(0.0, 1.0 - death_time / 0.6)
		if death_time >= 0.6:
			queue_free()
		return
	attack_cd -= delta
	moving = false
	if target != null and not _target_ok():
		target = null
		wander_to = home
	if target == null and aggro_range > 0.0 and position.distance_to(home) < LEASH * 0.7:
		target = world.find_hostile_target(position, aggro_range)

	if target != null:
		var to := target.position - position
		var reach := radius + target.radius + 10.0
		if to.length() > reach:
			_move_to(target.position, speed * 1.15, delta)
		else:
			facing = to.normalized()
			if attack_cd <= 0.0:
				attack_cd = 1.6 if is_boss else 1.3
				attack_anim = 0.2
				if is_boss:
					world.spawn_effect("ring", position + Vector2(0, -radius), Vector2.ZERO, Color(1, 0.2, 0.4), 70.0)
				target.take_damage(atk * randf_range(0.85, 1.15), self)
	else:
		heal(max_hp * 0.06 * delta)
		if position.distance_to(wander_to) < 8.0:
			wander_wait -= delta
			if wander_wait <= 0.0:
				wander_to = home + Vector2(randf_range(-130, 130), randf_range(-130, 130))
				wander_wait = randf_range(1.5, 4.5)
		else:
			_move_to(wander_to, speed * 0.5, delta)
	queue_redraw()


func _move_to(p: Vector2, spd: float, delta: float) -> void:
	var dir := (p - position).normalized()
	facing = dir
	var wanted := position + dir * spd * delta
	var new_pos: Vector2 = world.resolve_position(wanted, radius)
	# los monstruos no entran al pueblo
	var from_town := new_pos - GameData.TOWN_CENTER
	var min_d := GameData.TOWN_RADIUS + radius + 10.0
	if from_town.length() < min_d:
		new_pos = GameData.TOWN_CENTER + from_town.normalized() * min_d
	# atascado contra un obstáculo: elegir otro destino
	if new_pos.distance_to(position) < spd * delta * 0.3:
		wander_to = new_pos
	position = new_pos
	moving = true


func _draw() -> void:
	draw_shadow()
	if world.player != null and world.player.target == self:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, radius + 8.0, 0, TAU, 32, Color(1, 0.25, 0.2, 0.9), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var c := body_center()
	var col := current_color(body_color)
	match type_id:
		"slime":
			var squish := 1.0 + sin(Time.get_ticks_msec() * 0.006 + home.x) * 0.08
			draw_set_transform(Vector2(0, -radius * 0.8), 0.0, Vector2(1.15 * squish, 0.85 / squish))
			draw_circle(Vector2.ZERO, radius, col.darkened(0.3))
			draw_circle(Vector2(0, -1), radius - 2.0, col)
			draw_circle(Vector2(-radius * 0.35, -radius * 0.4), radius * 0.25, Color(1, 1, 1, 0.5))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_eyes(Vector2(0, -radius * 0.8))
		"wolf":
			draw_circle(c, radius, col.darkened(0.35))
			draw_circle(c, radius - 2.0, col)
			var side := Vector2(-facing.y, facing.x)
			for s: float in [-1.0, 1.0]:
				var base := c + side * radius * 0.5 * s + Vector2(0, -radius * 0.6)
				draw_colored_polygon(PackedVector2Array([base - side * 5.0, base + side * 5.0, base + Vector2(0, -12)]), col.darkened(0.2))
			draw_circle(c + facing * radius * 0.7, radius * 0.45, col.lightened(0.15))
			draw_eyes(c)
		"skeleton":
			draw_circle(c, radius, Color(0.3, 0.28, 0.25))
			draw_circle(c, radius - 2.0, col)
			draw_circle(c + Vector2(-5, -2), 4.0, Color(0.1, 0.05, 0.05))
			draw_circle(c + Vector2(5, -2), 4.0, Color(0.1, 0.05, 0.05))
			draw_line(c + Vector2(-5, 7), c + Vector2(5, 7), Color(0.2, 0.2, 0.2), 2.0)
			draw_weapon("sword")
		"demon", "boss":
			draw_circle(c, radius, col.darkened(0.45))
			draw_circle(c, radius - 2.0, col)
			for s: float in [-1.0, 1.0]:
				var hb := c + Vector2(radius * 0.55 * s, -radius * 0.6)
				draw_colored_polygon(PackedVector2Array([hb + Vector2(-4, 0), hb + Vector2(4, 0), hb + Vector2(6.0 * s, -radius * 0.7)]), Color(0.15, 0.1, 0.1))
			draw_circle(c + Vector2(-radius * 0.3, -2), radius * 0.15, Color(1, 0.9, 0.2))
			draw_circle(c + Vector2(radius * 0.3, -2), radius * 0.15, Color(1, 0.9, 0.2))
			if is_boss:
				var crown := c + Vector2(0, -radius - 2)
				draw_colored_polygon(PackedVector2Array([
					crown + Vector2(-14, 0), crown + Vector2(-14, -12), crown + Vector2(-7, -5),
					crown + Vector2(0, -14), crown + Vector2(7, -5), crown + Vector2(14, -12), crown + Vector2(14, 0)]),
					Color(1.0, 0.8, 0.2))
	draw_overhead(true)
