extends Node2D
## Número / texto flotante (daño, XP, curación).

var text := ""
var color := Color.WHITE
var font_size := 18
var t := 0.0
var life := 0.9


func _process(delta: float) -> void:
	t += delta
	position.y -= 45.0 * delta
	if t >= life:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var font: Font = GameData.FONT
	var alpha := 1.0 - maxf(0.0, (t - life * 0.5) / (life * 0.5))
	draw_string_outline(font, Vector2(-80, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 160, font_size, 5, Color(0, 0, 0, alpha))
	draw_string(font, Vector2(-80, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 160, font_size, Color(color, alpha))
