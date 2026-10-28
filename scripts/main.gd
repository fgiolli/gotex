extends Node2D
## Mundo del juego: genera el mapa, monstruos, jugadores simulados, NPCs y guarda la partida.

const GroundScript := preload("res://scripts/ground.gd")
const DecorScript := preload("res://scripts/decor.gd")
const EffectScript := preload("res://scripts/effect.gd")
const FloatingTextScript := preload("res://scripts/floating_text.gd")

var ground: Node2D
var entities: Node2D
var effects: Node2D
var camera: Camera2D
var hud: Hud
var player: Player
var enemies: Array[Enemy] = []
var bots: Array[Bot] = []
var npcs: Array[Npc] = []
var obstacles: Array[Vector3] = []  # x, y, radio
var respawns: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var chat_timer := 4.0
var save_timer := 15.0
var current_zone := -1
var guide_seen := false


func _ready() -> void:
	rng.randomize()
	ground = GroundScript.new()
	add_child(ground)
	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)
	effects = Node2D.new()
	effects.z_index = 10
	add_child(effects)

	_build_town()
	_build_obstacles()

	player = Player.new()
	player.world = self
	player.position = GameData.TOWN_CENTER + Vector2(0, 90)
	entities.add_child(player)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(GameData.MAP_SIZE.x)
	camera.limit_bottom = int(GameData.MAP_SIZE.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	camera.make_current()

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.world = self
	layer.add_child(hud)

	for type_id in GameData.ENEMY_COUNTS:
		var d: Dictionary = GameData.ENEMY_TYPES[type_id]
		for i in int(GameData.ENEMY_COUNTS[type_id]):
			spawn_enemy(type_id, random_point_in_zone(int(d["zone"])))
	spawn_enemy("boss", GameData.BOSS_HOME)

	var names := GameData.BOT_NAMES.duplicate()
	names.shuffle()
	for i in 14:
		var b := Bot.new()
		b.world = self
		var lvl := rng.randi_range(1, 17)
		b.setup(names[i], GameData.BOT_CLASSES[rng.randi() % GameData.BOT_CLASSES.size()], lvl)
		if rng.randf() < 0.3:
			b.position = random_town_point()
			b.state = "town"
			b.dest = random_town_point()
		else:
			b.position = random_point_in_zone(GameData.zone_for_level(lvl))
			b.dest = b.position
		entities.add_child(b)
		bots.append(b)

	print("Gotex listo: %d enemigos, %d jugadores, %d obstaculos" % [enemies.size(), bots.size(), obstacles.size()])
	if load_game():
		hud.add_message("Partida cargada. ¡Bienvenido de vuelta, caballero!", Color(0.7, 1.0, 0.7))
	else:
		hud.show_banner("Bienvenido a Gotex Online", Color(1.0, 0.9, 0.4))
		hud.add_message("Habla con el Capitán Rolo para tu primera misión.", Color(1.0, 0.9, 0.4))
	if not guide_seen:
		hud.open_guide.call_deferred(0)

	var args := OS.get_cmdline_user_args()
	if "--autotest" in args:
		_run_autotest.call_deferred(args)


func _build_town() -> void:
	var tc := GameData.TOWN_CENTER
	_add_decor("well", tc)
	_add_decor("house", tc + Vector2(-220, -150))
	_add_decor("house_thatch", tc + Vector2(220, -150))
	_add_decor("house_thatch", tc + Vector2(-230, 230))
	_add_decor("house", tc + Vector2(230, 230))
	_add_decor("stall", tc + Vector2(-125, 30))
	_add_decor("board", tc + Vector2(125, 20))
	for v: Vector2 in [Vector2(-300, -40), Vector2(300, -40), Vector2(-110, -260), Vector2(110, -260)]:
		_add_decor("banner_red" if v.x < 0 else "banner_blue", tc + v)
	for v: Vector2 in [Vector2(-150, -120), Vector2(-135, -100), Vector2(150, 260), Vector2(-320, 130), Vector2(320, 120)]:
		_add_decor(["barrel", "crate", "hay"][rng.randi() % 3], tc + v)
	# torres en las cuatro puertas de la villa
	var r := GameData.TOWN_RADIUS + 30.0
	for dir: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var side := dir.orthogonal()
		_add_decor("tower", tc + dir * r + side * 95.0)
		_add_decor("tower", tc + dir * r - side * 95.0)
		_add_npc("Guardia", "guard", "guard", tc + dir * (r - 40.0) + side * 60.0)

	_add_npc("Mara la Comerciante", "shop", "merchant", tc + Vector2(-125, 70))
	_add_npc("Capitán Rolo", "quest", "captain", tc + Vector2(125, 70))
	_add_npc("Aldeana", "villager", "villager", tc + Vector2(-60, 160))
	_add_npc("Aldeano", "villager", "villager2", tc + Vector2(80, -120))
	_add_npc("Aldeana", "villager", "villager2", tc + Vector2(-90, -170))


func _add_npc(n: String, role: String, row_name: String, pos: Vector2) -> void:
	var npc := Npc.new()
	npc.world = self
	npc.setup(n, role, row_name)
	npc.position = pos
	entities.add_child(npc)
	npcs.append(npc)


func _build_obstacles() -> void:
	var gen := RandomNumberGenerator.new()
	gen.seed = 98765
	var density := [0.0, 0.3, 1.0, 0.55, 0.5]
	for i in 900:
		var p := Vector2(gen.randf_range(40, GameData.MAP_SIZE.x - 40), gen.randf_range(40, GameData.MAP_SIZE.y - 40))
		var zi := GameData.zone_index(p)
		if zi == 0 or p.distance_to(GameData.TOWN_CENTER) < GameData.TOWN_RADIUS + 130.0:
			continue
		if gen.randf() > float(density[zi]):
			continue
		# dejar libres los caminos y la guarida del jefe
		if absf(p.x - GameData.TOWN_CENTER.x) < 70.0 or absf(p.y - GameData.TOWN_CENTER.y) < 70.0:
			continue
		if p.distance_to(GameData.BOSS_HOME) < 240.0:
			continue
		if _blocked(p, 70.0):
			continue
		var roll := gen.randf()
		match zi:
			1:
				_add_decor("oak" if roll < 0.45 else ("oak2" if roll < 0.85 else "rock"), p)
			2:
				_add_decor("pine" if roll < 0.4 else ("pine2" if roll < 0.7 else ("oak_autumn" if roll < 0.9 else "oak2")), p)
			3:
				_add_decor("pillar" if roll < 0.3 else ("pillar_broken" if roll < 0.6 else ("rock_big" if roll < 0.8 else "oak2")), p)
			_:
				_add_decor("deadtree" if roll < 0.45 else ("tomb" if roll < 0.75 else "rock"), p)


func _add_decor(kind: String, pos: Vector2) -> void:
	var info: Dictionary = GameData.DECOR[kind]
	var d = DecorScript.new()
	d.kind = kind
	d.position = pos
	entities.add_child(d)
	var off: Vector2 = info["off"]
	obstacles.append(Vector3(pos.x + off.x, pos.y + off.y, float(info["r"])))


func _blocked(p: Vector2, extra: float) -> bool:
	for o in obstacles:
		if p.distance_to(Vector2(o.x, o.y)) < o.z + extra:
			return true
	return false


func resolve_position(p: Vector2, r: float) -> Vector2:
	for o in obstacles:
		var c := Vector2(o.x, o.y)
		var d := p - c
		var min_d := o.z + r
		if absf(d.x) < min_d and absf(d.y) < min_d:
			var l := d.length()
			if l < min_d:
				if l < 0.01:
					d = Vector2.RIGHT
					l = 1.0
				p = c + d / l * min_d
	p.x = clampf(p.x, r, GameData.MAP_SIZE.x - r)
	p.y = clampf(p.y, r, GameData.MAP_SIZE.y - r)
	return p


func random_point_in_zone(zi: int) -> Vector2:
	for i in 300:
		var p := Vector2(rng.randf_range(80, GameData.MAP_SIZE.x - 80), rng.randf_range(80, GameData.MAP_SIZE.y - 80))
		if GameData.zone_index(p) != zi:
			continue
		if zi > 0 and p.distance_to(GameData.TOWN_CENTER) < GameData.TOWN_RADIUS + 80.0:
			continue
		if _blocked(p, 30.0):
			continue
		return p
	return GameData.TOWN_CENTER + Vector2(0, GameData.TOWN_RADIUS + 200.0)


func random_town_point() -> Vector2:
	for i in 50:
		var p := GameData.TOWN_CENTER + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(70.0, GameData.TOWN_RADIUS - 40.0)
		if not _blocked(p, 20.0):
			return p
	return GameData.TOWN_CENTER + Vector2(0, 120)


func spawn_enemy(type_id: String, home: Vector2) -> void:
	var d: Dictionary = GameData.ENEMY_TYPES[type_id]
	var e := Enemy.new()
	e.world = self
	e.setup(type_id, rng.randi_range(int(d["lvl_min"]), int(d["lvl_max"])), home)
	entities.add_child(e)
	enemies.append(e)


func spawn_effect(kind: String, a: Vector2, b: Vector2, color: Color, size: float) -> void:
	var fx = EffectScript.new()
	fx.kind = kind
	fx.a = a
	fx.b = b
	fx.color = color
	fx.size = size
	if kind == "bolt":
		fx.life = 0.3
	elif kind == "levelup":
		fx.life = 0.9
	elif kind == "marker":
		fx.life = 0.5
	effects.add_child(fx)


func spawn_text(pos: Vector2, text: String, color: Color, font_size: int = 18) -> void:
	# no gastar recursos en textos lejos de la cámara
	if player != null and pos.distance_to(player.position) > 900.0:
		return
	var t = FloatingTextScript.new()
	t.text = text
	t.color = color
	t.font_size = font_size
	t.position = pos + Vector2(rng.randf_range(-8, 8), 0)
	effects.add_child(t)


# --- consultas usadas por la IA -------------------------------------------

func nearest_enemy(pos: Vector2, max_range: float) -> Enemy:
	var best: Enemy = null
	var best_d := max_range
	for e in enemies:
		if e.dead:
			continue
		var d := pos.distance_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	return best


func find_hostile_target(pos: Vector2, max_range: float) -> Entity:
	var best: Entity = null
	var best_d := max_range
	if not player.dead and not GameData.is_safe(player.position):
		var d := pos.distance_to(player.position)
		if d < best_d:
			best_d = d
			best = player
	for b in bots:
		if b.dead or GameData.is_safe(b.position):
			continue
		var d := pos.distance_to(b.position)
		if d < best_d:
			best_d = d
			best = b
	return best


func find_enemy_for_bot(bot: Bot) -> Enemy:
	var best: Enemy = null
	var best_d := 650.0
	for e in enemies:
		if e.dead or e.level > bot.level + 1 or e.level < bot.level - 6:
			continue
		if e.is_boss and bot.level < 18:
			continue
		var d := bot.position.distance_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	return best


func near_npc() -> Npc:
	if player == null or player.dead:
		return null
	for n in npcs:
		if n.is_interactive() and player.position.distance_to(n.position) < 110.0:
			return n
	return null


## Toque en el mundo: atacar al monstruo tocado, hablar con un NPC o caminar hasta ahí.
func player_tap(wp: Vector2) -> void:
	if player.dead:
		return
	var best: Enemy = null
	var best_d := 70.0
	for e in enemies:
		if e.dead:
			continue
		var d := wp.distance_to(e.position + e.body_center())
		if d < best_d + e.radius:
			best_d = d
			best = e
	if best != null:
		player.attack_target(best)
		return
	for n in npcs:
		if n.is_interactive() and wp.distance_to(n.position + n.body_center()) < 60.0:
			player.walk_to(n.position + Vector2(0, 40))
			player.pending_npc = n
			return
	player.walk_to(wp)
	spawn_effect("marker", wp, Vector2.ZERO, Color(1.0, 0.9, 0.4), 22.0)


# --- pruebas automáticas y capturas (solo con --autotest) ----------------------

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = pos
	ev.pressed = pressed
	get_tree().root.push_input(ev)


func _drag(index: int, pos: Vector2, rel: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	ev.relative = rel
	get_tree().root.push_input(ev)


func _shot(dir: String, file: String) -> void:
	if dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		DirAccess.make_dir_recursive_absolute(dir)
		img.save_png(dir.path_join(file))
		print("AUTOTEST captura ", file)


func _teleport(p: Vector2) -> void:
	player.position = p
	player.target = null
	player.has_move_target = false
	camera.reset_smoothing()


func _run_autotest(args: PackedStringArray) -> void:
	var shots := ""
	for a in args:
		if a.begins_with("--shots="):
			shots = a.substr(8)
	player.god_mode = true
	await _frames(10)
	hud.close_panel()
	await _frames(5)
	var win := Vector2(get_tree().root.size)
	print("AUTOTEST ventana ", win, " viewport ", get_viewport().get_visible_rect().size)
	var ok := true

	# 1) joystick: arrastrar en la mitad izquierda
	_teleport(GameData.TOWN_CENTER + Vector2(0, 90))
	var start := player.position
	var p0 := win * Vector2(0.15, 0.7)
	_touch(0, p0, true)
	for i in 15:
		_drag(0, p0 + Vector2(6.0 * (i + 1), 0), Vector2(6, 0))
		await get_tree().process_frame
	await _frames(40)
	var moved := player.position.x - start.x
	_touch(0, p0 + Vector2(90, 0), false)
	print("AUTOTEST joystick se movio %.1f px" % moved)
	if moved < 40.0:
		ok = false
		print("AUTOTEST FALLO joystick")

	# 2) tocar el suelo para caminar
	await _frames(5)
	start = player.position
	var tap := win * Vector2(0.62, 0.62)
	_touch(1, tap, true)
	await _frames(2)
	_touch(1, tap, false)
	await _frames(70)
	moved = player.position.distance_to(start)
	print("AUTOTEST tocar-para-caminar se movio %.1f px" % moved)
	if moved < 40.0:
		ok = false
		print("AUTOTEST FALLO tocar-para-caminar")

	# 3) botón de ataque (abajo a la derecha) contra un monstruo cercano
	var slime: Enemy = null
	for e in enemies:
		if e.type_id == "slime" and not e.dead:
			slime = e
			break
	if slime != null:
		_teleport(slime.position + Vector2(-60, 10))
		await _frames(3)
		var hp0 := slime.hp
		var btn: Vector2 = hud._buttons()["attack"][0]
		var win_btn := btn * win / hud.size
		_touch(2, win_btn, true)
		await _frames(60)
		_touch(2, win_btn, false)
		print("AUTOTEST ataque: vida del limo %.0f -> %.0f" % [hp0, slime.hp])
		if slime.hp >= hp0 and not slime.dead:
			ok = false
			print("AUTOTEST FALLO ataque")

	# 4) capturas de pantalla
	if shots != "":
		_teleport(GameData.TOWN_CENTER + Vector2(-40, 140))
		for b in bots.slice(0, 4):
			b.position = random_town_point()
			b.state = "town"
		await _frames(90)
		bot_chat(bots[0], "¡por el rey!")
		await _frames(20)
		await _shot(shots, "01_villa.png")

		_teleport(GameData.TOWN_CENTER + Vector2(0, -560))
		await _frames(5)
		var near := nearest_enemy(player.position, 2000.0)
		if near != null:
			_teleport(near.position + Vector2(-70, 20))
			player.attack_target(near)
		await _frames(50)
		player.use_skill()
		await _frames(6)
		await _shot(shots, "02_combate.png")

		_teleport(GameData.TOWN_CENTER + Vector2(1150, 300))
		await _frames(60)
		await _shot(shots, "03_bosque.png")

		_teleport(GameData.TOWN_CENTER + Vector2(-1500, -1050))
		await _frames(60)
		await _shot(shots, "04_ruinas.png")

		_teleport(GameData.BOSS_HOME + Vector2(-260, -120))
		await _frames(60)
		await _shot(shots, "05_rey_demonio.png")

		_teleport(GameData.TOWN_CENTER + Vector2(-125, 120))
		await _frames(30)
		hud.open_shop()
		await _frames(10)
		await _shot(shots, "06_tienda.png")
		hud.open_guide(1)
		await _frames(10)
		await _shot(shots, "07_guia.png")
		hud.close_panel()

	print("AUTOTEST PASS" if ok else "AUTOTEST FAIL")
	get_tree().quit(0 if ok else 1)


# --- eventos de juego ---------------------------------------------------------

func on_enemy_killed(e: Enemy, killer: Entity) -> void:
	enemies.erase(e)
	var zone := int(GameData.ENEMY_TYPES[e.type_id]["zone"])
	respawns.append({"t": 120.0 if e.is_boss else rng.randf_range(8.0, 14.0), "type": e.type_id, "zone": zone})
	if killer is Player:
		var p := killer as Player
		var gold := e.gold_reward + rng.randi_range(0, e.gold_reward)
		p.gold += gold
		p.kills += 1
		spawn_text(e.position + Vector2(0, e.top_y() - 34.0), "+%d XP  +%d oro" % [e.xp_reward, gold], Color(1.0, 0.9, 0.3), 16)
		if rng.randf() < 0.08:
			p.potions += 1
			hud.add_message("¡Encontraste una poción!", Color(0.5, 1.0, 0.5))
		if p.quest_type == e.type_id and p.quest_count < p.quest_needed:
			p.quest_count += 1
			if p.quest_count >= p.quest_needed:
				hud.add_message("¡Misión completada! Vuelve con el Capitán Rolo.", Color(1.0, 0.9, 0.3))
				hud.show_banner("Misión completada", Color(1.0, 0.9, 0.3))
		if e.is_boss:
			hud.add_message("[Sistema] Has derrotado al Rey Demonio!!", Color(1.0, 0.4, 1.0))
			hud.show_banner("REY DEMONIO DERROTADO", Color(1.0, 0.4, 1.0))
			_bots_react(GameData.CONGRATS, 9999.0, 0.7)
		p.gain_xp(e.xp_reward)
	elif killer is Bot:
		var b := killer as Bot
		b.add_xp(e.xp_reward)
		if e.is_boss:
			hud.add_message("[Sistema] %s ha derrotado al Rey Demonio!" % b.display_name, Color(1.0, 0.4, 1.0))


func on_player_died(_killer: Entity) -> void:
	var lost := int(player.gold * 0.1)
	player.gold -= lost
	hud.add_message("Has muerto. Perdiste %d de oro." % lost, Color(1.0, 0.4, 0.4))
	if rng.randf() < 0.5:
		var b := _random_nearby_bot(600.0)
		if b != null:
			bot_chat(b, ["F", "rip :(", "noo", "cuidado!"][rng.randi() % 4])


func on_bot_died(b: Bot) -> void:
	if b.position.distance_to(player.position) < 600.0 and rng.randf() < 0.5:
		hud.add_message("%s ha caído en combate." % b.display_name, Color(0.8, 0.8, 0.8))


func on_player_level_up() -> void:
	hud.show_banner("NIVEL %d!" % player.level, Color(1.0, 0.85, 0.2))
	hud.add_message("Has subido a nivel %d!" % player.level, Color(1.0, 0.85, 0.2))
	spawn_effect("levelup", player.position + Vector2(0, -15), Vector2.ZERO, Color(1.0, 0.9, 0.3), 70.0)
	_bots_react(GameData.CONGRATS, 700.0, 0.6)
	save_game()


func player_emote() -> void:
	if player.dead:
		return
	player.say(GameData.PLAYER_GREETS[rng.randi() % GameData.PLAYER_GREETS.size()])
	hud.add_message("[Tú]: " + player.say_text, Color(1.0, 0.95, 0.5))
	_bots_react(GameData.GREET_REPLIES, 700.0, 0.7)


func _bots_react(lines: Array, max_d: float, chance: float) -> void:
	for b in bots:
		if b.dead or b.position.distance_to(player.position) > max_d or rng.randf() > chance:
			continue
		var line: String = lines[rng.randi() % lines.size()]
		var bot := b
		var reply := func() -> void:
			if is_instance_valid(bot) and not bot.dead:
				bot_chat(bot, line)
		get_tree().create_timer(rng.randf_range(0.6, 2.5)).timeout.connect(reply)


func _random_nearby_bot(max_d: float) -> Bot:
	var near: Array[Bot] = []
	for b in bots:
		if not b.dead and b.position.distance_to(player.position) < max_d:
			near.append(b)
	if near.is_empty():
		return null
	return near[rng.randi() % near.size()]


func bot_chat(b: Bot, text: String) -> void:
	b.say(text)
	hud.add_message("[%s]: %s" % [b.display_name, text], Color(0.75, 0.88, 1.0))


# --- tienda y misiones -------------------------------------------------------------

func buy(item: String) -> void:
	match item:
		"potion":
			if player.gold >= GameData.POTION_COST:
				player.gold -= GameData.POTION_COST
				player.potions += 1
				hud.add_message("Compraste una poción.", Color(0.5, 1.0, 0.5))
			else:
				hud.add_message("No tienes suficiente oro.", Color(1.0, 0.5, 0.5))
		"weapon":
			var cost := GameData.upgrade_cost(player.weapon_lvl)
			if player.gold >= cost:
				player.gold -= cost
				player.weapon_lvl += 1
				hud.add_message("Tu espada ahora es +%d!" % player.weapon_lvl, Color(0.5, 1.0, 0.5))
			else:
				hud.add_message("No tienes suficiente oro.", Color(1.0, 0.5, 0.5))
		"armor":
			var cost := GameData.upgrade_cost(player.armor_lvl)
			if player.gold >= cost:
				player.gold -= cost
				player.armor_lvl += 1
				player.recalc_stats()
				hud.add_message("Tu armadura ahora es +%d!" % player.armor_lvl, Color(0.5, 1.0, 0.5))
			else:
				hud.add_message("No tienes suficiente oro.", Color(1.0, 0.5, 0.5))
	save_game()


func offer_quest() -> Dictionary:
	var type_id := GameData.enemy_for_level(player.level)
	var needed := 8
	if player.level >= 16 and rng.randf() < 0.35:
		type_id = "boss"
		needed = 1
	elif type_id == "demon":
		needed = 6
	return {"type": type_id, "needed": needed}


func accept_quest(q: Dictionary) -> void:
	player.quest_type = q["type"]
	player.quest_needed = int(q["needed"])
	player.quest_count = 0
	hud.add_message("Nueva misión: derrota %d %s." % [player.quest_needed, quest_target_name()], Color(1.0, 0.9, 0.4))
	save_game()


func quest_target_name() -> String:
	if player.quest_type == "":
		return ""
	return GameData.ENEMY_TYPES[player.quest_type]["plural"]


func quest_reward() -> Vector2i:
	var d: Dictionary = GameData.ENEMY_TYPES[player.quest_type]
	var xp := int(player.xp_to_next() * 0.4) + int(d["xp"]) * player.quest_needed
	var gold := int(d["gold"]) * player.quest_needed * 3 + 20
	return Vector2i(xp, gold)


func complete_quest() -> void:
	var r := quest_reward()
	player.quest_type = ""
	player.quest_needed = 0
	player.quest_count = 0
	player.gold += r.y
	player.potions += 2
	hud.add_message("Recompensa: %d XP, %d oro y 2 pociones." % [r.x, r.y], Color(1.0, 0.9, 0.3))
	player.gain_xp(r.x)
	save_game()


# --- bucle principal ----------------------------------------------------------------

func _process(delta: float) -> void:
	for i in range(respawns.size() - 1, -1, -1):
		var r: Dictionary = respawns[i]
		r["t"] = float(r["t"]) - delta
		if float(r["t"]) <= 0.0:
			var type_id: String = r["type"]
			var home := GameData.BOSS_HOME if type_id == "boss" else random_point_in_zone(int(r["zone"]))
			if home.distance_to(player.position) > 350.0 or type_id == "boss":
				spawn_enemy(type_id, home)
				respawns.remove_at(i)

	chat_timer -= delta
	if chat_timer <= 0.0:
		chat_timer = rng.randf_range(7.0, 16.0)
		var alive: Array[Bot] = []
		for b in bots:
			if not b.dead:
				alive.append(b)
		if not alive.is_empty():
			bot_chat(alive[rng.randi() % alive.size()], GameData.CHAT_LINES[rng.randi() % GameData.CHAT_LINES.size()])

	save_timer -= delta
	if save_timer <= 0.0:
		save_timer = 15.0
		save_game()

	var zi := GameData.zone_index(player.position)
	if zi != current_zone:
		if current_zone != -1:
			var z: Dictionary = GameData.ZONES[zi]
			hud.show_banner("%s  (%s)" % [z["name"], z["levels"]], Color(0.85, 0.95, 1.0))
		current_zone = zi


# --- guardado ------------------------------------------------------------------------

func save_game() -> void:
	if player == null:
		return
	var cf := ConfigFile.new()
	cf.set_value("player", "level", player.level)
	cf.set_value("player", "xp", player.xp)
	cf.set_value("player", "gold", player.gold)
	cf.set_value("player", "potions", player.potions)
	cf.set_value("player", "weapon", player.weapon_lvl)
	cf.set_value("player", "armor", player.armor_lvl)
	cf.set_value("player", "kills", player.kills)
	cf.set_value("player", "quest_type", player.quest_type)
	cf.set_value("player", "quest_needed", player.quest_needed)
	cf.set_value("player", "quest_count", player.quest_count)
	var pos := player.position if not player.dead else GameData.TOWN_CENTER + Vector2(0, 90)
	cf.set_value("player", "pos", pos)
	cf.set_value("player", "guide_v2", guide_seen)
	cf.save(GameData.SAVE_PATH)


func load_game() -> bool:
	var cf := ConfigFile.new()
	if cf.load(GameData.SAVE_PATH) != OK:
		return false
	player.level = int(cf.get_value("player", "level", 1))
	player.xp = int(cf.get_value("player", "xp", 0))
	player.gold = int(cf.get_value("player", "gold", 20))
	player.potions = int(cf.get_value("player", "potions", 3))
	player.weapon_lvl = int(cf.get_value("player", "weapon", 0))
	player.armor_lvl = int(cf.get_value("player", "armor", 0))
	player.kills = int(cf.get_value("player", "kills", 0))
	player.quest_type = str(cf.get_value("player", "quest_type", ""))
	player.quest_needed = int(cf.get_value("player", "quest_needed", 0))
	player.quest_count = int(cf.get_value("player", "quest_count", 0))
	guide_seen = bool(cf.get_value("player", "guide_v2", false))
	var pos: Vector2 = cf.get_value("player", "pos", GameData.TOWN_CENTER + Vector2(0, 90))
	player.position = resolve_position(pos, player.radius)
	player.hp = 99999.0
	player.mp = 99999.0
	player.recalc_stats()
	return true


func reset_game() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameData.SAVE_PATH))
	get_tree().reload_current_scene()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			save_game()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if hud != null and hud.is_modal():
				hud.close_panel()
			else:
				save_game()
				get_tree().quit()
