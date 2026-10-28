class_name GameData
extends RefCounted

const MAP_SIZE := Vector2(4000, 4000)
const TOWN_CENTER := Vector2(2000, 2000)
const TOWN_RADIUS := 380.0
const SAVE_PATH := "user://save.cfg"
const POTION_COST := 15

const ZONES := [
	{"name": "Pueblo de Gotex", "max_d": 380.0, "color": Color(0.42, 0.62, 0.34), "levels": "Zona segura"},
	{"name": "Pradera Verde", "max_d": 1000.0, "color": Color(0.38, 0.66, 0.32), "levels": "Nv 1-3"},
	{"name": "Bosque Oscuro", "max_d": 1500.0, "color": Color(0.2, 0.42, 0.22), "levels": "Nv 4-7"},
	{"name": "Ruinas Antiguas", "max_d": 2000.0, "color": Color(0.5, 0.47, 0.38), "levels": "Nv 8-12"},
	{"name": "Tierras Malditas", "max_d": 99999.0, "color": Color(0.36, 0.2, 0.28), "levels": "Nv 13+"},
]

const ENEMY_TYPES := {
	"slime": {"name": "Slime", "plural": "Slimes", "color": Color(0.35, 0.85, 0.55), "hp": 28.0, "atk": 6.0,
		"lvl_min": 1, "lvl_max": 3, "speed": 55.0, "radius": 13.0, "xp": 10, "gold": 2, "aggro": 0.0, "zone": 1},
	"wolf": {"name": "Lobo", "plural": "Lobos", "color": Color(0.55, 0.55, 0.6), "hp": 70.0, "atk": 13.0,
		"lvl_min": 4, "lvl_max": 7, "speed": 95.0, "radius": 15.0, "xp": 28, "gold": 6, "aggro": 150.0, "zone": 2},
	"skeleton": {"name": "Esqueleto", "plural": "Esqueletos", "color": Color(0.92, 0.9, 0.82), "hp": 140.0, "atk": 22.0,
		"lvl_min": 8, "lvl_max": 12, "speed": 75.0, "radius": 15.0, "xp": 60, "gold": 12, "aggro": 170.0, "zone": 3},
	"demon": {"name": "Demonio", "plural": "Demonios", "color": Color(0.85, 0.2, 0.2), "hp": 260.0, "atk": 38.0,
		"lvl_min": 13, "lvl_max": 18, "speed": 85.0, "radius": 18.0, "xp": 130, "gold": 25, "aggro": 190.0, "zone": 4},
	"boss": {"name": "Rey Demonio", "plural": "Rey Demonio", "color": Color(0.55, 0.05, 0.15), "hp": 2600.0, "atk": 60.0,
		"lvl_min": 20, "lvl_max": 20, "speed": 70.0, "radius": 32.0, "xp": 2500, "gold": 400, "aggro": 220.0, "zone": 4},
}

const ENEMY_COUNTS := {"slime": 28, "wolf": 24, "skeleton": 20, "demon": 14}
const BOSS_HOME := Vector2(3650, 3650)

const BOT_NAMES := [
	"xXDarkLordXx", "Lunita", "ElPepe99", "Kirito_mx", "NoobMaster", "Valkiria", "Toto",
	"SrPatata", "ZeldaFan", "Ragnar", "MagoSupremo", "Flechita", "Juanchi", "LaReinaRoja",
	"Pixel", "Tanquecito",
]
const BOT_CLASSES := ["Guerrero", "Mago", "Arquero"]

const CHAT_LINES := [
	"alguien para party?", "vendo espada +3, barato", "donde estan los esqueletos?", "lag...",
	"jajaja", "quien va al Rey Demonio?", "busco clan activo", "los lobos pegan fuerte",
	"necesito pociones :(", "alguien me regala oro? xd", "subiendo nivel en la pradera",
	"que buen dia para farmear", "cuidado con los demonios en las esquinas", "brb",
	"hola a todos!", "este server es el mejor", "quien quiere duelo?", "ya casi nivel 10!",
	"el comerciante subio los precios otra vez -_-", "el Rey Demonio esta en la esquina sureste",
]
const GREET_REPLIES := ["hola!", "holaa", "que tal!", "hey :)", "saludos aventurero", "o/", "buenas!"]
const CONGRATS := ["gg!", "felicidades!", "bien ahi!", "grande!", "gz", "a seguir subiendo!"]
const PLAYER_GREETS := ["Hola a todos!", "Saludos!", "Que tal, gente?", "Alguien para party?"]


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
