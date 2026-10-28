extends Node2D
## Dibuja el suelo del mapa una sola vez (zonas, caminos, plaza del pueblo).

const TILE := 80.0


func _hash(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)


func _draw() -> void:
	var cols := int(GameData.MAP_SIZE.x / TILE)
	var rows := int(GameData.MAP_SIZE.y / TILE)
	for y in rows:
		for x in cols:
			var center := Vector2((x + 0.5) * TILE, (y + 0.5) * TILE)
			var base: Color = GameData.ZONES[GameData.zone_index(center)]["color"]
			var f := 0.93 + _hash(x, y) * 0.12
			draw_rect(Rect2(x * TILE, y * TILE, TILE + 1.0, TILE + 1.0), Color(base.r * f, base.g * f, base.b * f))

	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	# detalles del suelo
	for i in 2600:
		var p := Vector2(rng.randf_range(0, GameData.MAP_SIZE.x), rng.randf_range(0, GameData.MAP_SIZE.y))
		match GameData.zone_index(p):
			0, 1:
				var flower := [Color(1, 0.9, 0.3), Color(1, 0.5, 0.6), Color(0.9, 0.9, 1.0), Color(0.7, 0.5, 1.0)]
				if rng.randf() < 0.5:
					draw_circle(p, 3.0, flower[rng.randi() % flower.size()])
				else:
					_tuft(p, Color(0.28, 0.5, 0.22))
			2:
				if rng.randf() < 0.15:
					draw_circle(p, 5.0, Color(0.8, 0.25, 0.2))
					draw_circle(p + Vector2(-1.5, -1.5), 1.5, Color(1, 1, 1))
				else:
					_tuft(p, Color(0.13, 0.3, 0.15))
			3:
				draw_line(p, p + Vector2(rng.randf_range(-14, 14), rng.randf_range(-8, 8)), Color(0.35, 0.32, 0.26), 2.0)
			4:
				if rng.randf() < 0.12:
					draw_set_transform(p, 0.0, Vector2(1.0, 0.5))
					draw_circle(Vector2.ZERO, rng.randf_range(14, 30), Color(0.95, 0.35, 0.1))
					draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.75, 0.2))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					draw_circle(p, 2.0, Color(0.85, 0.82, 0.75))

	# caminos que salen del pueblo
	var road := Color(0.62, 0.5, 0.34)
	var tc := GameData.TOWN_CENTER
	draw_rect(Rect2(0, tc.y - 30, GameData.MAP_SIZE.x, 60), road)
	draw_rect(Rect2(tc.x - 30, 0, 60, GameData.MAP_SIZE.y), road)
	for i in 400:
		var p := Vector2(rng.randf_range(0, GameData.MAP_SIZE.x), tc.y + rng.randf_range(-26, 26))
		if rng.randf() < 0.5:
			p = Vector2(tc.x + rng.randf_range(-26, 26), rng.randf_range(0, GameData.MAP_SIZE.y))
		draw_circle(p, rng.randf_range(1.5, 3.5), road.darkened(0.2))

	# plaza
	draw_circle(tc, GameData.TOWN_RADIUS, Color(0.5, 0.48, 0.44))
	draw_circle(tc, GameData.TOWN_RADIUS - 8.0, Color(0.66, 0.63, 0.57))
	for ring in [110.0, 200.0, 290.0]:
		draw_arc(tc, ring, 0, TAU, 64, Color(0.58, 0.55, 0.5), 3.0)
	for i in 16:
		var ang: float = TAU * i / 16.0
		draw_line(tc + Vector2.from_angle(ang) * 60.0, tc + Vector2.from_angle(ang) * (GameData.TOWN_RADIUS - 8.0), Color(0.58, 0.55, 0.5), 2.0)

	# borde del mundo
	draw_rect(Rect2(Vector2.ZERO, GameData.MAP_SIZE), Color(0.05, 0.05, 0.05), false, 8.0)


func _tuft(p: Vector2, c: Color) -> void:
	draw_line(p, p + Vector2(-3, -6), c, 2.0)
	draw_line(p, p + Vector2(0, -8), c, 2.0)
	draw_line(p, p + Vector2(3, -6), c, 2.0)
