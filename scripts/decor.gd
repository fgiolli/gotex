extends Node2D
## Árboles, rocas, pilares, casas y la fuente del pueblo.

var kind := "tree"
var variant := 0.0


func _draw() -> void:
	_shadow(26.0 if kind != "house" else 70.0)
	match kind:
		"tree":
			draw_rect(Rect2(-5, -26, 10, 26), Color(0.45, 0.3, 0.15))
			var g := Color(0.2, 0.5 + variant * 0.15, 0.2)
			draw_circle(Vector2(0, -48), 28, g.darkened(0.3))
			draw_circle(Vector2(-12, -46), 18, g)
			draw_circle(Vector2(11, -52), 18, g.lightened(0.08))
			draw_circle(Vector2(0, -62), 14, g.lightened(0.18))
		"pine":
			draw_rect(Rect2(-4, -18, 8, 18), Color(0.35, 0.22, 0.12))
			var g := Color(0.08, 0.28 + variant * 0.1, 0.14)
			draw_colored_polygon(PackedVector2Array([Vector2(-26, -14), Vector2(26, -14), Vector2(0, -56)]), g)
			draw_colored_polygon(PackedVector2Array([Vector2(-20, -38), Vector2(20, -38), Vector2(0, -76)]), g.lightened(0.08))
			draw_colored_polygon(PackedVector2Array([Vector2(-13, -60), Vector2(13, -60), Vector2(0, -92)]), g.lightened(0.16))
		"rock":
			var pts := PackedVector2Array()
			for i in 8:
				var ang: float = TAU * i / 8.0
				var r: float = 18.0 + sin(i * 2.7 + variant * 10.0) * 4.0
				pts.append(Vector2(cos(ang) * r, sin(ang) * r * 0.75 - 12.0))
			draw_colored_polygon(pts, Color(0.45, 0.44, 0.46))
			draw_circle(Vector2(-5, -18), 6, Color(0.6, 0.6, 0.62))
		"pillar":
			var h := 60.0 if variant > 0.4 else 34.0
			draw_rect(Rect2(-13, -h, 26, h), Color(0.68, 0.65, 0.58))
			draw_rect(Rect2(-13, -h, 6, h), Color(0.58, 0.55, 0.48))
			draw_rect(Rect2(-17, -h - 8, 34, 8), Color(0.78, 0.75, 0.68))
			draw_line(Vector2(4, -h + 10), Vector2(-2, -h + 26), Color(0.4, 0.38, 0.33), 2.0)
		"deadtree":
			var c := Color(0.25, 0.17, 0.14)
			draw_line(Vector2.ZERO, Vector2(0, -50), c, 7.0)
			draw_line(Vector2(0, -30), Vector2(-20, -50), c, 4.0)
			draw_line(Vector2(0, -40), Vector2(18, -62), c, 4.0)
			draw_line(Vector2(-20, -50), Vector2(-26, -62), c, 3.0)
		"house":
			var wall := Color(0.86, 0.78, 0.62).lerp(Color(0.75, 0.82, 0.86), variant)
			draw_rect(Rect2(-60, -70, 120, 70), wall)
			draw_rect(Rect2(-60, -70, 120, 70), wall.darkened(0.35), false, 3.0)
			var roof := Color(0.7, 0.25, 0.2).lerp(Color(0.25, 0.35, 0.6), variant)
			draw_colored_polygon(PackedVector2Array([Vector2(-74, -66), Vector2(74, -66), Vector2(0, -124)]), roof)
			draw_rect(Rect2(-12, -38, 24, 38), Color(0.45, 0.28, 0.15))
			draw_rect(Rect2(-46, -54, 20, 18), Color(0.55, 0.8, 1.0))
			draw_rect(Rect2(26, -54, 20, 18), Color(0.55, 0.8, 1.0))
		"fountain":
			draw_set_transform(Vector2(0, -10), 0.0, Vector2(1.0, 0.55))
			draw_circle(Vector2.ZERO, 46, Color(0.55, 0.55, 0.6))
			draw_circle(Vector2.ZERO, 38, Color(0.3, 0.55, 0.9))
			draw_circle(Vector2(-10, -8), 10, Color(0.6, 0.8, 1.0, 0.6))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_rect(Rect2(-6, -46, 12, 36), Color(0.65, 0.65, 0.7))
			draw_circle(Vector2(0, -50), 8, Color(0.6, 0.85, 1.0))


func _shadow(r: float) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
