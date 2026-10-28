extends Node2D
## Suelo del mapa con tiles de pixel-art (zonas, caminos y plaza de la villa).

const ATLAS_COLS := 8
const TILE_COUNT := 18

var layer: TileMapLayer


func _ready() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var src := TileSetAtlasSource.new()
	src.texture = GameData.TILES
	src.texture_region_size = Vector2i(16, 16)
	ts.add_source(src, 0)
	for i in TILE_COUNT:
		src.create_tile(Vector2i(i % ATLAS_COLS, i / ATLAS_COLS))

	layer = TileMapLayer.new()
	layer.tile_set = ts
	layer.scale = Vector2(GameData.ART_SCALE, GameData.ART_SCALE)
	add_child(layer)

	var cell := 16.0 * GameData.ART_SCALE
	var n := int(ceil(GameData.MAP_SIZE.x / cell))
	for y in n:
		for x in n:
			var idx := _tile_for(Vector2((x + 0.5) * cell, (y + 0.5) * cell), x, y)
			layer.set_cell(Vector2i(x, y), 0, Vector2i(idx % ATLAS_COLS, idx / ATLAS_COLS))


func _hash(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)


func _pick(group: String, h: float) -> int:
	var list: Array = GameData.TILE[group]
	return int(list[int(h * 997.0) % list.size()])


func _tile_for(c: Vector2, x: int, y: int) -> int:
	var h := _hash(x, y)
	var tc := GameData.TOWN_CENTER
	if c.distance_to(tc) < GameData.TOWN_RADIUS:
		return _pick("plaza", h)
	if absf(c.x - tc.x) < 40.0 or absf(c.y - tc.y) < 40.0:
		return _pick("road", h)
	match GameData.zone_index(c):
		1:
			return _pick("flowers", h) if h < 0.1 else _pick("grass", h)
		2:
			return _pick("grass", h) if h < 0.08 else _pick("forest", h)
		3:
			return _pick("grass", h) if h < 0.3 else _pick("ruins", h)
		4:
			return _pick("lava", h) if h < 0.05 else _pick("cursed", h)
	return _pick("grass", h)
