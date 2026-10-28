class_name Npc
extends Entity
## Personajes de la villa: comerciante, capitán, guardias y aldeanos.

var role := "shop"
var home := Vector2.ZERO
var dest := Vector2.ZERO
var wait := 0.0
var talk_cd := 0.0


func setup(n: String, r: String, row_name: String) -> void:
	display_name = n
	role = r
	sprite_row = int(GameData.CHAR_ROW[row_name])
	name_color = Color(1.0, 0.85, 0.35) if is_interactive() else Color(0.9, 0.88, 0.8)
	level = 99
	radius = 16.0
	talk_cd = randf_range(5.0, 20.0)


func is_interactive() -> bool:
	return role == "shop" or role == "quest"


func _ready() -> void:
	home = position
	dest = position


func _process(delta: float) -> void:
	tick_anim(delta)
	talk_cd -= delta
	moving = false
	var p = world.player
	var near_player := false
	if p != null and not p.dead:
		var to: Vector2 = p.position - position
		near_player = to.length() < 220.0
		if near_player and role != "villager":
			set_facing(to)
	if role == "villager":
		if position.distance_to(dest) > 6.0:
			var dir := (dest - position).normalized()
			var old := position
			position = world.resolve_position(position + dir * 45.0 * delta, radius)
			set_facing(dir)
			moving = true
			if position.distance_to(old) < 45.0 * delta * 0.3:
				dest = position
		else:
			wait -= delta
			if wait <= 0.0:
				wait = randf_range(2.0, 6.0)
				dest = world.random_town_point()
	if talk_cd <= 0.0:
		talk_cd = randf_range(15.0, 35.0)
		if role == "villager":
			say(GameData.VILLAGER_LINES[randi() % GameData.VILLAGER_LINES.size()])
		elif role == "guard" and near_player:
			say(GameData.GUARD_LINES[randi() % GameData.GUARD_LINES.size()])
	queue_redraw()


func _draw() -> void:
	draw_shadow()
	draw_sprite()
	draw_overhead(false)
	if not is_interactive():
		return
	var tex: Texture2D = GameData.ICONS
	var icon := "bag" if role == "shop" else "scroll"
	if role == "quest" and world.player != null and world.player.quest_type != "":
		if world.player.quest_count < world.player.quest_needed:
			return
	var y := top_y() - 58.0 + sin(Time.get_ticks_msec() * 0.005) * 4.0
	draw_texture_rect_region(tex, Rect2(-18, y, 36, 36), GameData.icon_region(icon))
