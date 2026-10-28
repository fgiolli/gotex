extends Node2D
## Elemento del escenario dibujado con su sprite (árboles, casas, torres...).

var kind := "oak"


func _draw() -> void:
	var info: Dictionary = GameData.DECOR[kind]
	var tex: Texture2D = info["tex"]
	var size := tex.get_size() * GameData.ART_SCALE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, size.x * 0.36, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-size.x / 2.0, -size.y, size.x, size.y), false)
