class_name GameData
extends RefCounted

const MAP_SIZE := Vector2(4000, 4000)
const TOWN_CENTER := Vector2(2000, 2000)
const TOWN_RADIUS := 380.0
const SAVE_PATH := "user://save.cfg"
const POTION_COST := 15
const ART_SCALE := 3.0

const CHARS := preload("res://assets/sprites/characters.png")
const TILES := preload("res://assets/sprites/tiles.png")
const ICONS := preload("res://assets/sprites/icons.png")
const FONT := preload("res://assets/fonts/MedievalSharp.ttf")

# fila de cada personaje en characters.png (2 cuadros de 16x16 por fila)
const CHAR_ROW := {
	"knight": 0, "warrior": 1, "mage": 2, "archer": 3, "merchant": 4, "captain": 5,
	"slime": 6, "wolf": 7, "skeleton": 8, "demon": 9, "boss": 10,
	"villager": 11, "villager2": 12, "guard": 13,
}
const ICON := {"sword": 0, "potion": 1, "swirl": 2, "bubble": 3, "scroll": 4, "bag": 5, "book": 6, "coin": 7, "heart": 8}
const TILE := {
	"grass": [0, 1, 2, 3], "flowers": [4, 5], "forest": [6, 7, 8], "road": [9, 10],
	"plaza": [11, 12], "ruins": [13, 14], "cursed": [15, 16], "lava": [17],
}

# decoración: textura, radio de colisión (0 = sin colisión) y desplazamiento del círculo
const DECOR := {
	"oak": {"tex": preload("res://assets/sprites/decor/oak.png"), "r": 16.0, "off": Vector2(0, -6)},
	"oak2": {"tex": preload("res://assets/sprites/decor/oak2.png"), "r": 16.0, "off": Vector2(0, -6)},
	"oak_autumn": {"tex": preload("res://assets/sprites/decor/oak_autumn.png"), "r": 16.0, "off": Vector2(0, -6)},
	"pine": {"tex": preload("res://assets/sprites/decor/pine.png"), "r": 14.0, "off": Vector2(0, -6)},
	"pine2": {"tex": preload("res://assets/sprites/decor/pine2.png"), "r": 14.0, "off": Vector2(0, -6)},
	"deadtree": {"tex": preload("res://assets/sprites/decor/deadtree.png"), "r": 10.0, "off": Vector2(0, -4)},
	"rock": {"tex": preload("res://assets/sprites/decor/rock.png"), "r": 22.0, "off": Vector2(0, -14)},
	"rock_big": {"tex": preload("res://assets/sprites/decor/rock_big.png"), "r": 30.0, "off": Vector2(0, -18)},
	"pillar": {"tex": preload("res://assets/sprites/decor/pillar.png"), "r": 18.0, "off": Vector2(0, -6)},
	"pillar_broken": {"tex": preload("res://assets/sprites/decor/pillar_broken.png"), "r": 18.0, "off": Vector2(0, -6)},
	"tomb": {"tex": preload("res://assets/sprites/decor/tomb.png"), "r": 14.0, "off": Vector2(0, -8)},
	"house": {"tex": preload("res://assets/sprites/decor/house.png"), "r": 62.0, "off": Vector2(0, -38)},
	"house_thatch": {"tex": preload("res://assets/sprites/decor/house_thatch.png"), "r": 62.0, "off": Vector2(0, -38)},
	"well": {"tex": preload("res://assets/sprites/decor/well.png"), "r": 36.0, "off": Vector2(0, -18)},
	"stall": {"tex": preload("res://assets/sprites/decor/stall.png"), "r": 48.0, "off": Vector2(0, -24)},
	"board": {"tex": preload("res://assets/sprites/decor/board.png"), "r": 24.0, "off": Vector2(0, -8)},
	"banner_red": {"tex": preload("res://assets/sprites/decor/banner_red.png"), "r": 6.0, "off": Vector2.ZERO},
	"banner_blue": {"tex": preload("res://assets/sprites/decor/banner_blue.png"), "r": 6.0, "off": Vector2.ZERO},
	"tower": {"tex": preload("res://assets/sprites/decor/tower.png"), "r": 42.0, "off": Vector2(0, -28)},
	"barrel": {"tex": preload("res://assets/sprites/decor/barrel.png"), "r": 14.0, "off": Vector2(0, -10)},
	"crate": {"tex": preload("res://assets/sprites/decor/crate.png"), "r": 14.0, "off": Vector2(0, -10)},
	"hay": {"tex": preload("res://assets/sprites/decor/hay.png"), "r": 16.0, "off": Vector2(0, -8)},
}

const ZONES := [
	{"name": "Villa de Gotex", "max_d": 380.0, "color": Color(0.64, 0.6, 0.54), "levels": "Zona segura"},
	{"name": "Prados del Rey", "max_d": 1000.0, "color": Color(0.38, 0.64, 0.26), "levels": "Nv 1-3"},
	{"name": "Bosque Sombrío", "max_d": 1500.0, "color": Color(0.2, 0.42, 0.22), "levels": "Nv 4-7"},
	{"name": "Ruinas del Viejo Castillo", "max_d": 2000.0, "color": Color(0.55, 0.52, 0.44), "levels": "Nv 8-12"},
	{"name": "Tierras Malditas", "max_d": 99999.0, "color": Color(0.3, 0.16, 0.22), "levels": "Nv 13+"},
]

const ENEMY_TYPES := {
	"slime": {"name": "Limo", "plural": "Limos", "color": Color(0.35, 0.85, 0.55), "hp": 28.0, "atk": 6.0,
		"lvl_min": 1, "lvl_max": 3, "speed": 55.0, "radius": 16.0, "xp": 10, "gold": 2, "aggro": 0.0, "zone": 1, "scale": 3.0},
	"wolf": {"name": "Lobo", "plural": "Lobos", "color": Color(0.55, 0.55, 0.6), "hp": 70.0, "atk": 13.0,
		"lvl_min": 4, "lvl_max": 7, "speed": 95.0, "radius": 18.0, "xp": 28, "gold": 6, "aggro": 150.0, "zone": 2, "scale": 3.0},
	"skeleton": {"name": "Esqueleto", "plural": "Esqueletos", "color": Color(0.92, 0.9, 0.82), "hp": 140.0, "atk": 22.0,
		"lvl_min": 8, "lvl_max": 12, "speed": 75.0, "radius": 16.0, "xp": 60, "gold": 12, "aggro": 170.0, "zone": 3, "scale": 3.0},
	"demon": {"name": "Demonio", "plural": "Demonios", "color": Color(0.85, 0.2, 0.2), "hp": 260.0, "atk": 38.0,
		"lvl_min": 13, "lvl_max": 18, "speed": 85.0, "radius": 18.0, "xp": 130, "gold": 25, "aggro": 190.0, "zone": 4, "scale": 3.4},
	"boss": {"name": "Rey Demonio", "plural": "Rey Demonio", "color": Color(0.55, 0.05, 0.15), "hp": 2600.0, "atk": 60.0,
		"lvl_min": 20, "lvl_max": 20, "speed": 70.0, "radius": 34.0, "xp": 2500, "gold": 400, "aggro": 220.0, "zone": 4, "scale": 6.0},
}

const ENEMY_COUNTS := {"slime": 28, "wolf": 24, "skeleton": 20, "demon": 14}
const BOSS_HOME := Vector2(3650, 3650)

const BOT_NAMES := [
	"SirPatata", "Lady_Luna", "ElPepe99", "Ragnar", "MagoSupremo", "Flechita", "DonQuijote_mx",
	"Valkiria", "Kirito_mx", "Juanchi", "LaReinaRoja", "Tanquecito", "Morgana", "Arturito",
	"xXDarkLordXx", "Robin_Hood",
]
const BOT_CLASSES := ["Guerrero", "Mago", "Arquero"]

const CHAT_LINES := [
	"¿alguien para party?", "vendo espada +3, barata", "¿dónde están los esqueletos?", "lag...",
	"jajaja", "¿quién va contra el Rey Demonio?", "busco gremio activo", "los lobos pegan fuerte",
	"necesito pociones :(", "alguien me presta oro? xd", "subiendo nivel en los prados",
	"¡por el rey!", "cuidado con los demonios de las esquinas", "brb, voy a la taberna",
	"saludos, viajeros!", "este reino es el mejor", "quien quiere duelo en la plaza?", "ya casi nivel 10!",
	"Mara subio los precios otra vez -_-", "el Rey Demonio esta en la esquina sureste",
	"busco escudero xd", "las ruinas dan buen oro",
]
const GREET_REPLIES := ["hola!", "holaa", "que tal!", "¡salud, caballero!", "saludos o/", "buenas!", "bienvenido!"]
const CONGRATS := ["gg!", "felicidades!", "bien ahi!", "grande!", "gz", "¡larga vida al héroe!"]
const PLAYER_GREETS := ["¡Hola a todos!", "¡Saludos, viajeros!", "¿Qué tal, gente?", "¿Alguien para party?"]
const VILLAGER_LINES := [
	"¡Larga vida al rey!", "Dicen que el Rey Demonio despertó...", "Hoy hay pan fresco.",
	"Cuidado con los lobos del bosque.", "Las ruinas están malditas.", "¡Qué buen día!",
]
const GUARD_LINES := ["Bienvenido a la villa.", "Aquí dentro estás a salvo.", "¡Alto! ...ah, eres tú."]

const GUIDE := [
	{"title": "Bienvenido, caballero", "icon": "book",
		"text": "Llegas a la Villa de Gotex, en un reino lleno de monstruos. Otros aventureros recorren estas tierras contigo.\n\nTu meta: subir de nivel, mejorar tu equipo y derrotar al Rey Demonio."},
	{"title": "Moverte", "icon": "bubble",
		"text": "Pon el dedo en la mitad IZQUIERDA de la pantalla y arrastra: aparece un joystick.\n\nO simplemente TOCA el suelo donde quieras ir y tu caballero caminará hasta allí."},
	{"title": "Combatir", "icon": "sword",
		"text": "Toca un monstruo para atacarlo, o pulsa el botón de la ESPADA para atacar al más cercano.\n\nGIRO golpea a todos a tu alrededor (gasta maná). La POCIÓN cura la mitad de tu vida."},
	{"title": "La villa", "icon": "bag",
		"text": "Dentro de la villa estás a salvo y te curas rápido.\n\nMara la Comerciante vende pociones y mejora tu espada y armadura. El Capitán Rolo, junto al tablón, te da misiones con buenas recompensas."},
	{"title": "El reino", "icon": "scroll",
		"text": "Prados del Rey (Nv 1-3): limos.\nBosque Sombrío (Nv 4-7): lobos.\nRuinas del Viejo Castillo (Nv 8-12): esqueletos.\nTierras Malditas (Nv 13+): demonios y el Rey Demonio, al sureste."},
	{"title": "Consejos", "icon": "coin",
		"text": "Si mueres, vuelves a la villa y pierdes el 10% de tu oro.\n\nLa partida se guarda sola. Toca el minimapa para ver tus estadísticas, y el libro para volver a esta guía."},
]


static func zone_index(pos: Vector2) -> int:
	var d := pos.distance_to(TOWN_CENTER)
	for i in ZONES.size():
		if d < float(ZONES[i]["max_d"]):
			return i
	return ZONES.size() - 1


static func is_safe(pos: Vector2) -> bool:
	return pos.distance_to(TOWN_CENTER) < TOWN_RADIUS


static func zone_for_level(lvl: int) -> int:
	if lvl <= 3:
		return 1
	if lvl <= 7:
		return 2
	if lvl <= 12:
		return 3
	return 4


static func enemy_for_level(lvl: int) -> String:
	match zone_for_level(lvl):
		1:
			return "slime"
		2:
			return "wolf"
		3:
			return "skeleton"
	return "demon"


static func upgrade_cost(current_lvl: int) -> int:
	return int(40.0 * pow(float(current_lvl + 1), 1.5))


static func xp_for_level(lvl: int) -> int:
	return int(40.0 * pow(float(lvl), 1.6))


static func icon_region(icon_name: String) -> Rect2:
	return Rect2(int(ICON[icon_name]) * 16, 0, 16, 16)


static func icon_texture(icon_name: String) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = ICONS
	at.region = icon_region(icon_name)
	return at
