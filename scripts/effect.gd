extends Node2D
## Efecto visual de corta duración (tajo, proyectil, onda).

var kind := "slash"
var a := Vector2.ZERO
var b := Vector2.ZERO
var color := Color.WHITE
var size := 30.0
var t := 0.0
var life := 0.25


func _process(delta: float) -> void:
	t += delta
	if t >= life:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var k := t / life
	match kind:
		"slash":
			var ang := b.angle()
			draw_arc(a, size, ang - 1.1, ang + 1.1, 14, Color(color, 1.0 - k), 5.0)
		"bolt":
			var head := a.lerp(b, minf(1.0, k * 2.0))
			draw_line(a.lerp(b, maxf(0.0, k * 2.0 - 0.6)), head, Color(color, 0.9), size * 0.6)
			draw_circle(head, size, Color(color, 1.0 - k * 0.5))
		"ring":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
			var p := Vector2(a.x, a.y / 0.6)
			draw_arc(p, size * (0.3 + 0.7 * k), 0, TAU, 48, Color(color, 1.0 - k), 8.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"levelup":
			for i in 3:
				var r: float = size * (k + i * 0.25)
				draw_arc(a, r, 0, TAU, 40, Color(color, maxf(0.0, 1.0 - k - i * 0.2)), 4.0)
