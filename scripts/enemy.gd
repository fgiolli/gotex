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
	sprite_row = int(GameData.CHAR_ROW[id])
	sprite_scale = float(d["scale"])
	if id == "slime":
		sprite_top = 9.0
	elif id == "wolf":
		sprite_top = 11.0
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
			set_facing(to)
			if attack_cd <= 0.0:
				attack_cd = 1.6 if is_boss else 1.3
				attack_anim = 0.2
				if is_boss:
					world.spawn_effect("ring", position + Vector2(0, -6), Vector2.ZERO, Color(1, 0.2, 0.4), 80.0)
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
	set_facing(dir)
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
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, radius + 10.0, 0, TAU, 32, Color(1, 0.25, 0.2, 0.9), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var frame := anim_frame()
	if type_id == "slime":
		frame = int(Time.get_ticks_msec() / 350.0 + home.x) % 2
	draw_sprite(frame)
	draw_overhead(true)
