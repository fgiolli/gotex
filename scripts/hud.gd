class_name Hud
extends Control
## Interfaz táctil: joystick, tocar-para-caminar, botones, barras, minimapa, chat, ventanas y guía.

const JOY_R := 85.0
const MAX_MESSAGES := 6
const TAP_MAX_MS := 350
const TAP_MAX_MOVE := 22.0

const GOLD := Color(0.88, 0.7, 0.32)
const WOOD := Color(0.2, 0.12, 0.06, 0.82)
const INK := Color(0.28, 0.17, 0.08)

var world  # main.gd
var font: Font
var small_font: Font
var joy_index := -1
var joy_center := Vector2.ZERO
var joy_vec := Vector2.ZERO
var touch_buttons := {}  # índice de dedo -> nombre de botón
var held := {}  # nombre de botón -> bool
var taps := {}  # índice de dedo -> [posición inicial, tiempo]
var touch_count := 0
var messages: Array = []  # [texto, color]
var banner_text := ""
var banner_color := Color.WHITE
var banner_time := 0.0
var panel: PanelContainer = null
var card_box: StyleBoxFlat


func _ready() -> void:
	font = GameData.FONT
	small_font = ThemeDB.fallback_font
	if font.fallbacks.is_empty():
		font.fallbacks = [ThemeDB.fallback_font]
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_box = StyleBoxFlat.new()
	card_box.bg_color = WOOD
	card_box.border_color = Color(GOLD, 0.8)
	card_box.set_border_width_all(2)
	card_box.set_corner_radius_all(8)
	theme = _make_theme()


func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 22
	var parchment := StyleBoxFlat.new()
	parchment.bg_color = Color(0.93, 0.86, 0.68)
	parchment.border_color = Color(0.42, 0.27, 0.14)
	parchment.set_border_width_all(5)
	parchment.set_corner_radius_all(10)
	parchment.set_content_margin_all(26)
	parchment.shadow_color = Color(0, 0, 0, 0.5)
	parchment.shadow_size = 10
	th.set_stylebox("panel", "PanelContainer", parchment)
	th.set_color("font_color", "Label", INK)
	var states := {"normal": Color(0.45, 0.28, 0.13), "hover": Color(0.55, 0.36, 0.18), "pressed": Color(0.32, 0.19, 0.08)}
	for st in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[st]
		sb.border_color = GOLD
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(8)
		sb.set_content_margin_all(8)
		th.set_stylebox(st, "Button", sb)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", Color(1.0, 0.94, 0.78))
	th.set_color("font_hover_color", "Button", Color(1.0, 0.97, 0.88))
	th.set_color("font_pressed_color", "Button", Color(1.0, 0.85, 0.5))
	th.set_font_size("font_size", "Button", 24)
	return th


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
	position = Vector2.ZERO
	size = get_viewport_rect().size
	banner_time = maxf(0.0, banner_time - delta)
	if panel != null:
		panel.position = ((size - panel.size) / 2.0).round()
	queue_redraw()


# --- entrada ---------------------------------------------------------------------

func _minimap_rect() -> Rect2:
	return Rect2(size.x - 186.0, 12.0, 172.0, 172.0)


func _buttons() -> Dictionary:
	var s := size
	var b := {
		"attack": [Vector2(s.x - 128, s.y - 128), 72.0],
		"skill": [Vector2(s.x - 285, s.y - 78), 48.0],
		"potion": [Vector2(s.x - 272, s.y - 212), 44.0],
		"emote": [Vector2(s.x - 58, 232), 32.0],
		"guide": [Vector2(s.x - 142, 232), 32.0],
	}
	if world != null and world.near_npc() != null:
		b["interact"] = [Vector2(s.x - 126, s.y - 296), 48.0]
	return b


func _button_at(p: Vector2) -> String:
	var bs := _buttons()
	for k in bs:
		var c: Vector2 = bs[k][0]
		var r: float = bs[k][1]
		if p.distance_to(c) <= r + 12.0:
			return k
	return ""


func screen_to_world(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * p


func _input(event: InputEvent) -> void:
	var st := event as InputEventScreenTouch
	if st != null:
		if st.pressed:
			touch_count += 1
			if is_modal():
				return
			var btn := _button_at(st.position)
			if btn != "":
				touch_buttons[st.index] = btn
				_press(btn)
				get_viewport().set_input_as_handled()
				return
			if _minimap_rect().has_point(st.position):
				open_menu()
				get_viewport().set_input_as_handled()
				return
			taps[st.index] = [st.position, Time.get_ticks_msec()]
			if st.position.x < size.x * 0.5 and joy_index == -1:
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
			if taps.has(st.index):
				var t: Array = taps[st.index]
				taps.erase(st.index)
				var start: Vector2 = t[0]
				if not is_modal() and Time.get_ticks_msec() - int(t[1]) < TAP_MAX_MS and start.distance_to(st.position) < TAP_MAX_MOVE:
					world.player_tap(screen_to_world(st.position))
		return
	var sd := event as InputEventScreenDrag
	if sd != null:
		if taps.has(sd.index):
			var start: Vector2 = taps[sd.index][0]
			if start.distance_to(sd.position) >= TAP_MAX_MOVE:
				taps.erase(sd.index)
		if sd.index == joy_index:
			var d := sd.position - joy_center
			if d.length() > JOY_R:
				# el joystick sigue al dedo
				joy_center += d - d.normalized() * JOY_R
				d = sd.position - joy_center
			joy_vec = d / JOY_R if d.length() > 10.0 else Vector2.ZERO


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
		KEY_G:
			open_guide(0)
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
		"guide":
			held[btn] = false
			open_guide(0)
		"interact":
			held[btn] = false
			var n = world.near_npc()
			if n != null:
				open_npc(n)


# --- ventanas --------------------------------------------------------------------

func open_npc(n) -> void:
	if n.role == "shop":
		open_shop()
	elif n.role == "quest":
		open_quest()


func open_panel(title: String, body: String, options: Array, icon: String = "") -> void:
	close_panel()
	joy_index = -1
	joy_vec = Vector2.ZERO
	held.clear()
	touch_buttons.clear()
	taps.clear()
	panel = PanelContainer.new()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	if icon != "":
		var tr := TextureRect.new()
		tr.texture = GameData.icon_texture(icon)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(0, 56)
		vb.add_child(tr)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_color", Color(0.45, 0.12, 0.08))
	vb.add_child(t)
	if body != "":
		var l := Label.new()
		l.text = body
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(600, 0)
		l.add_theme_font_size_override("font_size", 23)
		vb.add_child(l)
	for o in options:
		var b := Button.new()
		b.text = o[0]
		b.custom_minimum_size = Vector2(600, 56)
		b.pressed.connect(o[1])
		vb.add_child(b)
	add_child(panel)
	panel.reset_size()
	panel.position = ((size - panel.size) / 2.0).round()


func close_panel() -> void:
	if panel != null:
		panel.queue_free()
		panel = null


func open_guide(page: int) -> void:
	var pages: Array = GameData.GUIDE
	page = clampi(page, 0, pages.size() - 1)
	var pg: Dictionary = pages[page]
	var opts := []
	var go_prev := func() -> void:
		open_guide(page - 1)
	var go_next := func() -> void:
		open_guide(page + 1)
	if page < pages.size() - 1:
		opts.append(["Siguiente  >", go_next])
	else:
		opts.append(["¡A la aventura!", close_panel])
	if page > 0:
		opts.append(["<  Anterior", go_prev])
	if page < pages.size() - 1:
		opts.append(["Cerrar guía", close_panel])
	open_panel("%s  (%d/%d)" % [pg["title"], page + 1, pages.size()], pg["text"], opts, pg["icon"])
	world.guide_seen = true


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
	open_panel("Tienda de Mara", "¡Bienvenido, caballero! Tienes %d monedas de oro y %d pociones." % [p.gold, p.potions], [
		["Poción de vida  -  %d oro" % GameData.POTION_COST, buy_potion],
		["Forjar espada +%d  -  %d oro" % [p.weapon_lvl + 1, wc], buy_weapon],
		["Reforzar armadura +%d  -  %d oro" % [p.armor_lvl + 1, ac], buy_armor],
		["Cerrar", close_panel],
	], "bag")


func open_quest() -> void:
	var p = world.player
	if p.quest_type == "":
		var q: Dictionary = world.offer_quest()
		var tname: String = GameData.ENEMY_TYPES[q["type"]]["plural"]
		var text := "Los %s acechan los caminos del reino. Derrota %d y el rey te recompensará." % [tname, int(q["needed"])]
		if q["type"] == "boss":
			text = "Ha llegado la hora, héroe. Derrota al Rey Demonio en la esquina sureste de las Tierras Malditas."
		var accept := func() -> void:
			world.accept_quest(q)
			close_panel()
		open_panel("Capitán Rolo", text, [
			["Aceptar misión", accept],
			["Ahora no", close_panel],
		], "scroll")
	elif p.quest_count >= p.quest_needed:
		var r: Vector2i = world.quest_reward()
		var deliver := func() -> void:
			world.complete_quest()
			close_panel()
		open_panel("Capitán Rolo", "¡Excelente trabajo! Tu recompensa: %d XP, %d de oro y 2 pociones." % [r.x, r.y], [
			["Entregar misión", deliver],
		], "scroll")
	else:
		var abandon := func() -> void:
			p.quest_type = ""
			p.quest_needed = 0
			p.quest_count = 0
			close_panel()
		open_panel("Capitán Rolo", "Sigue así, caballero. Llevas %d de %d %s." % [p.quest_count, p.quest_needed, world.quest_target_name()], [
			["Seguir cazando", close_panel],
			["Abandonar misión", abandon],
		], "scroll")


func open_menu() -> void:
	var p = world.player
	var text := "Nivel %d   (XP %d / %d)\nAtaque %d   Defensa %d\nEspada +%d   Armadura +%d\nMonstruos derrotados: %d\n\nToques detectados: %d" % [
		p.level, p.xp, p.xp_to_next(), int(p.get_attack()), int(p.get_defense()), p.weapon_lvl, p.armor_lvl, p.kills, touch_count]
	var guide := func() -> void:
		open_guide(0)
	var confirm_reset := func() -> void:
		open_panel("¿Borrar partida?", "Perderás todo tu progreso.", [
			["Sí, empezar de cero", Callable(world, "reset_game")],
			["Cancelar", close_panel],
		])
	open_panel("Tu caballero", text, [
		["Continuar", close_panel],
		["Guía del juego", guide],
		["Borrar partida", confirm_reset],
	], "heart")


# --- dibujo ------------------------------------------------------------------------

func _text(pos: Vector2, s: String, fs: int, col: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0, f: Font = null) -> void:
	if f == null:
		f = font
	draw_string_outline(f, pos, s, align, width, fs, 5, Color(0.08, 0.04, 0.02, 0.9))
	draw_string(f, pos, s, align, width, fs, col)


func _icon(icon_name: String, rect: Rect2, mod: Color = Color.WHITE) -> void:
	draw_texture_rect_region(GameData.ICONS, rect, GameData.icon_region(icon_name), mod)


func _bar(r: Rect2, ratio: float, col: Color, label: String) -> void:
	draw_rect(r.grow(2), Color(0.1, 0.05, 0.02, 0.9))
	draw_rect(r, Color(0.25, 0.16, 0.1))
	var fill := Rect2(r.position, Vector2(r.size.x * clampf(ratio, 0.0, 1.0), r.size.y))
	draw_rect(fill, col)
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, maxf(2.0, r.size.y * 0.3))), Color(col.lightened(0.35), 0.8))
	if label != "":
		_text(Vector2(r.position.x, r.position.y + r.size.y - 3), label, int(r.size.y * 0.8), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, small_font)


func _draw() -> void:
	if world == null or world.player == null:
		return
	var p = world.player
	var s := size

	# estado del jugador
	draw_style_box(card_box, Rect2(10, 10, 350, 140))
	draw_circle(Vector2(46, 50), 30, Color(0.1, 0.06, 0.03))
	draw_arc(Vector2(46, 50), 30, 0, TAU, 32, GOLD, 3.0)
	draw_texture_rect_region(GameData.CHARS, Rect2(22, 22, 48, 48), Rect2(0, 0, 16, 16))
	_text(Vector2(18, 108), "Nv %d" % p.level, 20, Color(1, 0.92, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 56)
	_text(Vector2(86, 36), "Caballero", 22, Color(1, 0.92, 0.6))
	_bar(Rect2(86, 46, 262, 22), p.hp / p.max_hp, Color(0.78, 0.15, 0.15), "%d / %d" % [int(p.hp), int(p.max_hp)])
	_bar(Rect2(86, 76, 262, 14), p.mp / p.max_mp, Color(0.22, 0.42, 0.9), "")
	_bar(Rect2(86, 98, 262, 10), float(p.xp) / float(p.xp_to_next()), Color(0.92, 0.75, 0.2), "")
	_icon("coin", Rect2(86, 116, 24, 24))
	_text(Vector2(114, 138), str(p.gold), 20, Color(1, 0.85, 0.3))
	_icon("potion", Rect2(190, 116, 24, 24))
	_text(Vector2(218, 138), str(p.potions), 20, Color(0.7, 1.0, 0.7))
	_text(Vector2(250, 138), "ATQ %d" % int(p.get_attack()), 16, Color(0.9, 0.85, 0.75), HORIZONTAL_ALIGNMENT_RIGHT, 98, small_font)

	# misión
	var y := 160.0
	if p.quest_type != "":
		draw_style_box(card_box, Rect2(10, y, 350, 38))
		_icon("scroll", Rect2(18, y + 5, 28, 28))
		var done: bool = p.quest_count >= p.quest_needed
		var qt := "%s: %d / %d" % [world.quest_target_name(), p.quest_count, p.quest_needed]
		if done:
			qt = "¡Lista! Vuelve con Rolo"
		_text(Vector2(54, y + 27), qt, 19, Color(0.6, 1.0, 0.6) if done else Color(1, 0.92, 0.6))
		y += 46.0

	# chat
	if not messages.is_empty():
		draw_style_box(card_box, Rect2(10, y, 450, messages.size() * 22 + 12))
		for i in messages.size():
			var m: Array = messages[i]
			_text(Vector2(20, y + 25 + i * 22), m[0], 15, m[1], HORIZONTAL_ALIGNMENT_LEFT, 430, small_font)

	# zona y jugadores en línea
	var zone: Dictionary = GameData.ZONES[GameData.zone_index(p.position)]
	_text(Vector2(0, 36), zone["name"], 28, Color(1.0, 0.93, 0.7), HORIZONTAL_ALIGNMENT_CENTER, s.x)
	_text(Vector2(0, 60), "%s   ·   %d en línea" % [zone["levels"], world.bots.size() + 1], 17, Color(0.75, 0.95, 0.7), HORIZONTAL_ALIGNMENT_CENTER, s.x)

	_draw_minimap()

	# joystick
	var jc := joy_center if joy_index != -1 else Vector2(175, s.y - 165)
	var ja := 1.0 if joy_index != -1 else 0.6
	draw_circle(jc, JOY_R, Color(0.1, 0.06, 0.03, 0.35 * ja))
	draw_arc(jc, JOY_R, 0, TAU, 48, Color(GOLD, 0.7 * ja), 4.0)
	draw_circle(jc + joy_vec * JOY_R, 36.0, Color(0.45, 0.28, 0.13, 0.85 * ja))
	draw_arc(jc + joy_vec * JOY_R, 36.0, 0, TAU, 32, Color(GOLD, ja), 3.0)
	if joy_index == -1:
		_text(Vector2(jc.x - 120, jc.y + JOY_R + 26), "Arrastra o toca el suelo", 15, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 240, small_font)

	# botones
	var bs := _buttons()
	for k in bs:
		var c: Vector2 = bs[k][0]
		var r: float = bs[k][1]
		var pressed := is_held(k)
		var icon := "sword"
		var label := ""
		var sub := ""
		var cd := 0.0
		match k:
			"attack":
				label = "Atacar"
			"skill":
				icon = "swirl"
				label = "Giro"
				sub = "%d MP" % int(Player.SKILL_COST)
				cd = p.skill_cd / Player.SKILL_CD
			"potion":
				icon = "potion"
				label = "Poción"
				sub = "x%d" % p.potions
				cd = p.potion_cd / Player.POTION_CD
			"emote":
				icon = "bubble"
				label = "Hola"
			"guide":
				icon = "book"
				label = "Guía"
			"interact":
				var n = world.near_npc()
				var shop: bool = n != null and n.role == "shop"
				icon = "bag" if shop else "scroll"
				label = "Tienda" if shop else "Misión"
		draw_circle(c, r + 3.0, Color(0.08, 0.04, 0.02, 0.75))
		draw_circle(c, r, Color(0.32, 0.19, 0.08, 0.95) if pressed else Color(0.2, 0.12, 0.06, 0.85))
		draw_arc(c, r, 0, TAU, 48, GOLD.lightened(0.2) if pressed else GOLD, 4.0)
		var isz := r * 1.1
		_icon(icon, Rect2(c.x - isz / 2.0, c.y - isz / 2.0 - (6.0 if r > 40.0 else 0.0), isz, isz))
		if cd > 0.0:
			draw_arc(c, r - 8.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(cd, 0.0, 1.0), 40, Color(0, 0, 0, 0.6), 14.0)
		if r > 40.0:
			_text(Vector2(c.x - r, c.y + r * 0.62), label, 17 if r > 60.0 else 15, Color(1, 0.92, 0.65), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0)
		else:
			_text(Vector2(c.x - r - 10, c.y + r + 18), label, 15, Color(1, 0.92, 0.65), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0 + 20)
		if sub != "":
			_text(Vector2(c.x - r, c.y - r - 6), sub, 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, small_font)

	# aviso grande
	if banner_time > 0.0:
		var a := minf(1.0, banner_time)
		draw_string_outline(font, Vector2(0, s.y * 0.3), banner_text, HORIZONTAL_ALIGNMENT_CENTER, s.x, 46, 10, Color(0.08, 0.04, 0.02, a * 0.9))
		draw_string(font, Vector2(0, s.y * 0.3), banner_text, HORIZONTAL_ALIGNMENT_CENTER, s.x, 46, Color(banner_color, a))

	if p.dead:
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.3, 0.0, 0.0, 0.35))
		_text(Vector2(0, s.y * 0.45), "Has caído en combate", 50, Color(1, 0.45, 0.4), HORIZONTAL_ALIGNMENT_CENTER, s.x)
		_text(Vector2(0, s.y * 0.45 + 46), "Despiertas en la villa en %d..." % int(ceil(p.respawn_time)), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, s.x)


func _draw_minimap() -> void:
	var mr := _minimap_rect()
	draw_style_box(card_box, mr.grow(6))
	var sc := mr.size.x / GameData.MAP_SIZE.x
	draw_rect(mr, GameData.ZONES[4]["color"])
	var mc := mr.position + GameData.TOWN_CENTER * sc
	for i: int in [3, 2, 1, 0]:
		draw_circle(mc, float(GameData.ZONES[i]["max_d"]) * sc, GameData.ZONES[i]["color"])
	draw_line(Vector2(mr.position.x, mc.y), Vector2(mr.end.x, mc.y), Color(0.66, 0.52, 0.35), 2.0)
	draw_line(Vector2(mc.x, mr.position.y), Vector2(mc.x, mr.end.y), Color(0.66, 0.52, 0.35), 2.0)
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
		if n.is_interactive():
			draw_circle(mr.position + n.position * sc, 2.5, Color(1, 0.9, 0.2))
	var pp: Vector2 = mr.position + world.player.position * sc
	draw_circle(pp, 5.0, Color.BLACK)
	draw_circle(pp, 3.5, Color.WHITE)
	draw_rect(mr, Color(GOLD, 0.6), false, 2.0)
	_text(Vector2(mr.position.x, mr.end.y - 6), "Menú", 15, Color(1, 0.92, 0.65), HORIZONTAL_ALIGNMENT_RIGHT, mr.size.x - 6)
