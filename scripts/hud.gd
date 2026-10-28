class_name Hud
extends Control
## Interfaz táctil: joystick, botones de acción, barras, minimapa, chat y ventanas.

const JOY_R := 80.0
const MAX_MESSAGES := 6

var world  # main.gd
var font: Font
var joy_index := -1
var joy_center := Vector2.ZERO
var joy_vec := Vector2.ZERO
var touch_buttons := {}  # índice de dedo -> nombre de botón
var held := {}  # nombre de botón -> bool
var messages: Array = []  # [texto, color]
var banner_text := ""
var banner_color := Color.WHITE
var banner_time := 0.0
var panel: PanelContainer = null
var card_box: StyleBoxFlat
var panel_box: StyleBoxFlat


func _ready() -> void:
	font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	card_box = StyleBoxFlat.new()
	card_box.bg_color = Color(0.04, 0.05, 0.09, 0.6)
	card_box.set_corner_radius_all(10)
	panel_box = StyleBoxFlat.new()
	panel_box.bg_color = Color(0.09, 0.09, 0.15, 0.97)
	panel_box.border_color = Color(0.95, 0.8, 0.35)
	panel_box.set_border_width_all(3)
	panel_box.set_corner_radius_all(16)
	panel_box.set_content_margin_all(24)


func is_modal() -> bool:
	return panel != null


func is_held(btn: String) -> bool:
	return bool(held.get(btn, false))


func add_message(text: String, color: Color) -> void:
	messages.append([text, color])
	while messages.size() > MAX_MESSAGES:
		messages.pop_front()


func show_banner(text: String, color: Color) -> void:
	banner_text = text
	banner_color = color
	banner_time = 3.0


func _process(delta: float) -> void:
	banner_time = maxf(0.0, banner_time - delta)
	if panel != null:
		panel.position = ((size - panel.size) / 2.0).round()
	queue_redraw()


# --- entrada ---------------------------------------------------------------------

func _minimap_rect() -> Rect2:
	return Rect2(size.x - 180.0, 10.0, 170.0, 170.0)


func _buttons() -> Dictionary:
	var s := size
	var b := {
		"attack": [Vector2(s.x - 130, s.y - 130), 70.0],
		"skill": [Vector2(s.x - 282, s.y - 80), 46.0],
		"potion": [Vector2(s.x - 270, s.y - 210), 42.0],
		"emote": [Vector2(s.x - 95, 228), 30.0],
	}
	if world != null and world.near_npc() != null:
		b["interact"] = [Vector2(s.x - 128, s.y - 292), 46.0]
	return b


func _button_at(p: Vector2) -> String:
	var bs := _buttons()
	for k in bs:
		var c: Vector2 = bs[k][0]
		var r: float = bs[k][1]
		if p.distance_to(c) <= r + 12.0:
			return k
	return ""


func _input(event: InputEvent) -> void:
	var st := event as InputEventScreenTouch
	if st != null:
		if st.pressed:
			if is_modal():
				return
			var btn := _button_at(st.position)
			if btn != "":
				touch_buttons[st.index] = btn
				_press(btn)
				get_viewport().set_input_as_handled()
			elif _minimap_rect().has_point(st.position):
				open_menu()
				get_viewport().set_input_as_handled()
			elif st.position.x < size.x * 0.5 and joy_index == -1:
				joy_index = st.index
				joy_center = st.position
				joy_vec = Vector2.ZERO
		else:
			if st.index == joy_index:
				joy_index = -1
				joy_vec = Vector2.ZERO
			if touch_buttons.has(st.index):
				held[touch_buttons[st.index]] = false
				touch_buttons.erase(st.index)
		return
	var sd := event as InputEventScreenDrag
	if sd != null and sd.index == joy_index:
		var d := sd.position - joy_center
		if d.length() > JOY_R:
			# el joystick sigue al dedo
			joy_center += d - d.normalized() * JOY_R
			d = sd.position - joy_center
		joy_vec = d / JOY_R


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.physical_keycode == KEY_ESCAPE or k.physical_keycode == KEY_M:
		if is_modal():
			close_panel()
		else:
			open_menu()
		return
	if is_modal():
		return
	match k.physical_keycode:
		KEY_Q:
			world.player.use_skill()
		KEY_E:
			world.player.use_potion()
		KEY_T:
			world.player_emote()
		KEY_F:
			_press("interact")
			held["interact"] = false


func _press(btn: String) -> void:
	held[btn] = true
	match btn:
		"skill":
			world.player.use_skill()
		"potion":
			world.player.use_potion()
		"emote":
			world.player_emote()
		"interact":
			var n = world.near_npc()
			if n != null:
				if n.role == "shop":
					open_shop()
				else:
					open_quest()


# --- ventanas --------------------------------------------------------------------

func open_panel(title: String, body: String, options: Array) -> void:
	close_panel()
	joy_index = -1
	joy_vec = Vector2.ZERO
	held.clear()
	touch_buttons.clear()
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 32)
	t.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vb.add_child(t)
	if body != "":
		var l := Label.new()
		l.text = body
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(580, 0)
		l.add_theme_font_size_override("font_size", 22)
		vb.add_child(l)
	for o in options:
		var b := Button.new()
		b.text = o[0]
		b.custom_minimum_size = Vector2(580, 62)
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(o[1])
		vb.add_child(b)
	add_child(panel)
	panel.reset_size()
	panel.position = ((size - panel.size) / 2.0).round()


func close_panel() -> void:
	if panel != null:
		panel.queue_free()
		panel = null


func open_shop() -> void:
	var p = world.player
	var wc := GameData.upgrade_cost(p.weapon_lvl)
	var ac := GameData.upgrade_cost(p.armor_lvl)
	var buy_potion := func() -> void:
		world.buy("potion")
		open_shop()
	var buy_weapon := func() -> void:
		world.buy("weapon")
		open_shop()
	var buy_armor := func() -> void:
		world.buy("armor")
		open_shop()
	open_panel("Tienda de Mara", "¡Bienvenido, aventurero! Tienes %d de oro y %d pociones." % [p.gold, p.potions], [
		["Poción de vida  —  %d oro" % GameData.POTION_COST, buy_potion],
		["Mejorar espada a +%d  —  %d oro" % [p.weapon_lvl + 1, wc], buy_weapon],
		["Mejorar armadura a +%d  —  %d oro" % [p.armor_lvl + 1, ac], buy_armor],
		["Cerrar", close_panel],
	])


func open_quest() -> void:
	var p = world.player
	if p.quest_type == "":
		var q: Dictionary = world.offer_quest()
		var tname: String = GameData.ENEMY_TYPES[q["type"]]["plural"]
		var text := "Los %s están causando problemas cerca del pueblo. Derrota %d y te daré una buena recompensa." % [tname, int(q["needed"])]
		if q["type"] == "boss":
			text = "Ha llegado la hora, héroe. Derrota al Rey Demonio en la esquina sureste de las Tierras Malditas."
		var accept := func() -> void:
			world.accept_quest(q)
			close_panel()
		open_panel("Capitán Rolo", text, [
			["Aceptar misión", accept],
			["Ahora no", close_panel],
		])
	elif p.quest_count >= p.quest_needed:
		var r: Vector2i = world.quest_reward()
		var deliver := func() -> void:
			world.complete_quest()
			close_panel()
		open_panel("Capitán Rolo", "¡Excelente trabajo! Aquí tienes tu recompensa: %d XP, %d oro y 2 pociones." % [r.x, r.y], [
			["Entregar misión", deliver],
		])
	else:
		var abandon := func() -> void:
			p.quest_type = ""
			p.quest_needed = 0
			p.quest_count = 0
			close_panel()
		open_panel("Capitán Rolo", "Sigue así. Llevas %d de %d %s." % [p.quest_count, p.quest_needed, world.quest_target_name()], [
			["Seguir cazando", close_panel],
			["Abandonar misión", abandon],
		])


func open_menu() -> void:
	var p = world.player
	var text := "Nivel %d   (XP %d / %d)\nAtaque %d   Defensa %d\nEspada +%d   Armadura +%d\nMonstruos derrotados: %d\n\nJoystick a la izquierda. ATACAR fija el monstruo más cercano. En el pueblo te curas rápido. La partida se guarda sola." % [
		p.level, p.xp, p.xp_to_next(), int(p.get_attack()), int(p.get_defense()), p.weapon_lvl, p.armor_lvl, p.kills]
	var confirm_reset := func() -> void:
		open_panel("¿Borrar partida?", "Perderás todo tu progreso.", [
			["Sí, empezar de cero", Callable(world, "reset_game")],
			["Cancelar", close_panel],
		])
	open_panel("Aventurero", text, [
		["Continuar", close_panel],
		["Borrar partida", confirm_reset],
	])


# --- dibujo ------------------------------------------------------------------------

func _text(pos: Vector2, s: String, fs: int, col: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string_outline(font, pos, s, align, width, fs, 4, Color(0, 0, 0, 0.85))
	draw_string(font, pos, s, align, width, fs, col)


func _bar(r: Rect2, ratio: float, col: Color, label: String) -> void:
	draw_rect(r, Color(0, 0, 0, 0.6))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(ratio, 0.0, 1.0), r.size.y)), col)
	draw_rect(r, Color(1, 1, 1, 0.25), false, 1.0)
	if label != "":
		_text(Vector2(r.position.x, r.position.y + r.size.y - 4), label, int(r.size.y * 0.75), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _draw() -> void:
	if world == null or world.player == null:
		return
	var p = world.player
	var s := size

	# estado del jugador
	draw_style_box(card_box, Rect2(10, 10, 310, 136))
	_text(Vector2(24, 38), "Aventurero", 20, Color(1, 0.95, 0.5))
	_text(Vector2(24, 38), "Nv %d" % p.level, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 282)
	_bar(Rect2(24, 48, 282, 22), p.hp / p.max_hp, Color(0.85, 0.2, 0.22), "HP %d / %d" % [int(p.hp), int(p.max_hp)])
	_bar(Rect2(24, 76, 282, 16), p.mp / p.max_mp, Color(0.25, 0.45, 0.95), "MP %d / %d" % [int(p.mp), int(p.max_mp)])
	_bar(Rect2(24, 98, 282, 12), float(p.xp) / float(p.xp_to_next()), Color(0.95, 0.8, 0.2), "")
	_text(Vector2(24, 136), "Oro %d" % p.gold, 18, Color(1, 0.85, 0.3))
	_text(Vector2(24, 136), "ATQ %d  DEF %d" % [int(p.get_attack()), int(p.get_defense())], 16, Color(0.85, 0.85, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, 282)

	# misión
	var y := 156.0
	if p.quest_type != "":
		draw_style_box(card_box, Rect2(10, y, 310, 34))
		var done: bool = p.quest_count >= p.quest_needed
		var qt := "Misión: %s %d/%d" % [world.quest_target_name(), p.quest_count, p.quest_needed]
		if done:
			qt = "Misión lista: vuelve con Rolo"
		_text(Vector2(22, y + 24), qt, 17, Color(0.6, 1.0, 0.6) if done else Color(1, 0.92, 0.6))
		y += 42.0

	# chat
	if not messages.is_empty():
		draw_style_box(card_box, Rect2(10, y, 440, messages.size() * 21 + 12))
		for i in messages.size():
			var m: Array = messages[i]
			_text(Vector2(20, y + 24 + i * 21), m[0], 15, m[1])

	# zona y jugadores en línea
	var zi := GameData.zone_index(p.position)
	var zone: Dictionary = GameData.ZONES[zi]
	_text(Vector2(0, 32), "%s  ·  %s" % [zone["name"], zone["levels"]], 20, Color(0.9, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER, s.x)
	_text(Vector2(0, 54), "En línea: %d" % (world.bots.size() + 1), 15, Color(0.6, 1.0, 0.6), HORIZONTAL_ALIGNMENT_CENTER, s.x)

	_draw_minimap()

	# joystick
	var jc := joy_center if joy_index != -1 else Vector2(170, s.y - 170)
	draw_circle(jc, JOY_R, Color(1, 1, 1, 0.1))
	draw_arc(jc, JOY_R, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(jc + joy_vec * JOY_R, 34.0, Color(1, 1, 1, 0.4))

	# botones
	var bs := _buttons()
	for k in bs:
		var c: Vector2 = bs[k][0]
		var r: float = bs[k][1]
		var pressed := is_held(k)
		var accent := Color(1, 1, 1)
		var label := ""
		var sub := ""
		var cd := 0.0
		match k:
			"attack":
				accent = Color(1.0, 0.45, 0.35)
				label = "ATACAR"
			"skill":
				accent = Color(1.0, 0.85, 0.3)
				label = "GIRO"
				sub = "%d MP" % int(Player.SKILL_COST)
				cd = p.skill_cd / Player.SKILL_CD
			"potion":
				accent = Color(0.45, 1.0, 0.5)
				label = "POCIÓN"
				sub = "x%d" % p.potions
				cd = p.potion_cd / Player.POTION_CD
			"emote":
				accent = Color(0.6, 0.85, 1.0)
				label = "HOLA"
			"interact":
				accent = Color(1.0, 0.9, 0.3)
				var n = world.near_npc()
				label = "TIENDA" if n != null and n.role == "shop" else "MISIÓN"
		draw_circle(c, r, Color(0.06, 0.06, 0.1, 0.8 if pressed else 0.5))
		draw_arc(c, r, 0, TAU, 48, accent, 4.0 if pressed else 3.0)
		if cd > 0.0:
			draw_arc(c, r - 7.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(cd, 0.0, 1.0), 40, Color(0, 0, 0, 0.65), 12.0)
		var fs := 22 if r > 60.0 else (13 if r < 35.0 else 16)
		var ly := c.y + fs * 0.35 - (8.0 if sub != "" else 0.0)
		_text(Vector2(c.x - r, ly), label, fs, accent, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0)
		if sub != "":
			_text(Vector2(c.x - r, ly + 18), sub, 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0)

	# aviso grande
	if banner_time > 0.0:
		var a := minf(1.0, banner_time)
		draw_string_outline(font, Vector2(0, s.y * 0.3), banner_text, HORIZONTAL_ALIGNMENT_CENTER, s.x, 40, 8, Color(0, 0, 0, a * 0.9))
		draw_string(font, Vector2(0, s.y * 0.3), banner_text, HORIZONTAL_ALIGNMENT_CENTER, s.x, 40, Color(banner_color, a))

	if p.dead:
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.35, 0.0, 0.0, 0.35))
		_text(Vector2(0, s.y * 0.45), "Has muerto", 48, Color(1, 0.4, 0.4), HORIZONTAL_ALIGNMENT_CENTER, s.x)
		_text(Vector2(0, s.y * 0.45 + 44), "Reapareces en el pueblo en %d..." % int(ceil(p.respawn_time)), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, s.x)


func _draw_minimap() -> void:
	var mr := _minimap_rect()
	draw_style_box(card_box, mr.grow(5))
	var sc := mr.size.x / GameData.MAP_SIZE.x
	draw_rect(mr, GameData.ZONES[4]["color"])
	var mc := mr.position + GameData.TOWN_CENTER * sc
	for i: int in [3, 2, 1, 0]:
		draw_circle(mc, float(GameData.ZONES[i]["max_d"]) * sc, GameData.ZONES[i]["color"])
	draw_circle(mc, GameData.TOWN_RADIUS * sc, Color(0.66, 0.63, 0.57))
	for e in world.enemies:
		if e.dead:
			continue
		if e.is_boss:
			draw_circle(mr.position + e.position * sc, 4.0, Color(1, 0.2, 1))
		else:
			draw_rect(Rect2(mr.position + e.position * sc - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 0.3, 0.25))
	for b in world.bots:
		if not b.dead:
			draw_circle(mr.position + b.position * sc, 2.5, Color(0.4, 0.8, 1.0))
	for n in world.npcs:
		draw_circle(mr.position + n.position * sc, 2.5, Color(1, 0.9, 0.2))
	var pp: Vector2 = mr.position + world.player.position * sc
	draw_circle(pp, 5.0, Color.BLACK)
	draw_circle(pp, 3.5, Color.WHITE)
	draw_rect(mr, Color(1, 1, 1, 0.3), false, 1.0)
	_text(Vector2(mr.position.x, mr.end.y - 6), "MENÚ", 12, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_RIGHT, mr.size.x - 6)
