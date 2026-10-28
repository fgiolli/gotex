#!/usr/bin/env python3
"""Genera todo el pixel-art del juego en assets/sprites/.

Uso:  python3 tools/make_art.py
Requiere Pillow. El arte es original y se genera por código (personajes en ASCII,
árboles/casas/suelo de forma procedural), así que no hay problemas de licencia.
"""
import math
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites")
OUTLINE = (30, 20, 26, 255)


def C(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))


def ascii_img(rows, pal):
    w = len(rows[0])
    for i, r in enumerate(rows):
        assert len(r) == w, f"fila {i} mide {len(r)}: {r!r}"
    img = Image.new("RGBA", (w, len(rows)), (0, 0, 0, 0))
    px = img.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == ".":
                continue
            if ch not in pal:
                raise KeyError(f"color '{ch}' sin definir")
            if pal[ch] is None:
                continue
            px[x, y] = C(pal[ch])
    return img


def outline(img, col=OUTLINE):
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                    dst[x, y] = col
                    break
    return out


# ---------------------------------------------------------------------------
# Personajes 16x16 (miran a la derecha; el juego los voltea)
# ---------------------------------------------------------------------------

SKIN = {"S": "#f2c08a", "s": "#c98e5a", "V": "#1b1720"}

KNIGHT = [
    "................",
    ".......Pp.......",
    "......PPp....W..",
    ".....LLLLM...W..",
    "....LLLLLLM..W..",
    "....LLLVVVV..W..",
    "....LLLLLLM..W..",
    ".....MMMMM...W..",
    ".KYK.BBYBBM.YYY.",
    ".KYK.BYYYBMMMR..",
    ".KKK.BBYBB..MR..",
    "..K..RRYRR......",
    ".....BBBBB......",
    ".....MM.MM......",
    ".....rr.rr......",
    "................",
]
KNIGHT_LEGS = ["....MM...MM.....", "....rr...rr....."]

KNIGHT_BASE = {
    "L": "#e3e7ef", "M": "#a3abbd", "D": "#5f677a", "V": "#1b1720", "Y": "#f2c94c",
    "R": "#7a4a2a", "r": "#4a2c19", "W": "#f4f6fa",
}

MAGE = [
    "........HH......",
    ".......HHh......",
    "......HHHh......",
    ".....HHHHHh.....",
    "...hhhhhhhhhh...",
    ".....SSSSSs.....",
    ".....SSSVSs.....",
    ".....EEEEEE.O...",
    "....UUEEEEUUO...",
    "...UUUUEEUUSQ...",
    "...UU.UUYUU.Q...",
    "....UUUUUUU.Q...",
    "....UUUUUUU.Q...",
    "....uUUUUUu.Q...",
    ".....rr.rr..Q...",
    "................",
]
MAGE_LEGS = ["....uUUUUUu.Q...", "....rr...rr.Q..."]

ARCHER = [
    "................",
    "......GGG.......",
    ".....GGGGg......",
    "....GGGGGGg.....",
    "....GGSSSSg..R..",
    "....GSSSVSg...R.",
    "....gSSSSSg...R.",
    ".....gSSSg....R.",
    "...GGGGGGGG...R.",
    "..GGgFFFFgGSSSR.",
    "..GG.FFRFF...R..",
    "..q..FFFFF..R...",
    ".....FFFFF......",
    ".....nn.nn......",
    ".....rr.rr......",
    "................",
]
ARCHER_LEGS = ["....nn...nn.....", "....rr...rr....."]

MERCHANT = [
    "................",
    "................",
    ".....CCCCC......",
    "....CCCCCCC.....",
    "....ccccccccc...",
    ".....SSSVSS.....",
    ".....SSSSSSs....",
    ".....SKKKKS.....",
    "....TTSSSSTT....",
    "...TTAAAAAATT...",
    "...SSAAAAAASS...",
    "....TAAAAAAT....",
    "....TTTTTTTT....",
    ".....nn..nn.....",
    ".....rr..rr.....",
    "................",
]
MERCHANT_LEGS = ["....nn....nn....", "....rr....rr...."]

VILLAGER = [
    "................",
    "................",
    ".....HHHHH......",
    "....HHHHHHH.....",
    "....HSSSSSH.....",
    "....HSSSVSH.....",
    ".....SSSSS......",
    "......SSS.......",
    "....DDWWWDD.....",
    "...SDDDDDDDS....",
    "....DDDDDDD.....",
    "....DDaaaDD.....",
    "...DDDDDDDDD....",
    "....ddddddd.....",
    ".....rr.rr......",
    "................",
]
VILLAGER_LEGS = ["....ddddddd.....", "....rr...rr....."]

SLIME = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "......LLLL......",
    "....LLggggLL....",
    "...LgWggggggg...",
    "..Lggggggggggg..",
    "..gggggVggVggg..",
    "..gggggVggVggg..",
    ".gggggggggggggg.",
    ".dggggggggggggd.",
    "..dddddddddddd..",
    "................",
]
SLIME_B = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    ".....LLLLLL.....",
    "...LLgWggggLL...",
    ".Lggggggggggggg.",
    ".ggggggVggVgggg.",
    ".ggggggVggVgggg.",
    ".gggggggggggggg.",
    ".dggggggggggggd.",
    "..dddddddddddd..",
    "................",
]

WOLF = [
    "................",
    "................",
    "................",
    "................",
    "...........a.a..",
    "..........aAaA..",
    "..........AAAAA.",
    "a.........AVAAAk",
    ".a.aaaaaaaAAAAs.",
    "..aAAAAAAAAAAs..",
    "..AAAAAAAAAAA...",
    "..AAWWWWWWAAA...",
    "...A.A....A.A...",
    "...A.A....A.A...",
    "...d.d....d.d...",
    "................",
]
WOLF_LEGS = ["..A.A....A.A....", ".A...A..A...A...", ".d...d..d...d..."]

SKELETON = [
    "................",
    "................",
    ".....BBBBB......",
    "....BBBBBBB.....",
    "....BBBBVVB.....",
    "....BBBBVVB.....",
    ".....BBBBBb..M..",
    ".....bBbBb...M..",
    "......BBB....M..",
    "....BbBbBbB..M..",
    "...B.BbBbB.Byyy.",
    "...B..BBB...BR..",
    ".....BbbbB......",
    ".....B...B......",
    ".....BB..BB.....",
    "................",
]
SKELETON_LEGS = ["....B.....B.....", "...BB.....BB...."]

DEMON = [
    "................",
    "...h.......h....",
    "...hh.....hh....",
    "....hRRRRRh.....",
    "....RRRRRRR.....",
    "....RRRRYRY.....",
    "....RRRRRRR.....",
    "....rRkkkRr.....",
    ".ww..RRRRR..ww..",
    "www.RRRRRRR.www.",
    "ww..RRrRRrR..ww.",
    "w...RRRRRRR...w.",
    ".....RRRRR......",
    ".....RR.RR......",
    ".....kk.kk......",
    "................",
]
DEMON_LEGS = ["....RR...RR.....", "....kk...kk....."]
DEMON_KING_TOP = [
    "....Y.Y.Y.......",
    "...hYYYYYh......",
    "...hYrYrYh......",
]


def legs_frame(rows, legs, start=13):
    f = list(rows)
    for i, r in enumerate(legs):
        f[start + i] = r
    return f


def char_frames(rows, legs, pal, start=13):
    return [ascii_img(rows, pal), ascii_img(legs_frame(rows, legs, start), pal)]


def build_characters():
    kn = lambda extra: {**KNIGHT_BASE, **extra}
    chars = {}
    chars["knight"] = char_frames(KNIGHT, KNIGHT_LEGS, kn({"P": "#d8343a", "p": "#9c2228", "K": "#2f5fc4", "B": "#2f5fc4"}))
    chars["warrior"] = char_frames(KNIGHT, KNIGHT_LEGS, kn({"P": None, "p": None, "K": "#8a5a2b", "B": "#b8332b"}))
    chars["mage"] = char_frames(MAGE, MAGE_LEGS, {
        **SKIN, "H": "#6a45b8", "h": "#46307e", "E": "#ececec", "U": "#3f5fbf", "u": "#2c4590",
        "Y": "#f2c94c", "O": "#8ff0ff", "Q": "#8a5a2b", "r": "#3a2a40"})
    chars["archer"] = char_frames(ARCHER, ARCHER_LEGS, {
        **SKIN, "G": "#3f8a3a", "g": "#2a5e28", "F": "#8a7442", "R": "#8a5a2b", "q": "#6b4320",
        "n": "#3b4a2a", "r": "#4a2c19"})
    chars["merchant"] = char_frames(MERCHANT, MERCHANT_LEGS, {
        **SKIN, "C": "#b83a3a", "c": "#7e2626", "T": "#4f7a3a", "A": "#efe6d2", "K": "#6b4320",
        "n": "#5a4636", "r": "#3b2a1e"})
    chars["captain"] = char_frames(KNIGHT, KNIGHT_LEGS, kn({"P": "#f2c94c", "p": "#b8892a", "K": "#6b3fa0", "B": "#6b3fa0"}))
    chars["slime"] = [ascii_img(SLIME, {"L": "#9cf09a", "g": "#4cc26a", "d": "#2e8a4a", "W": "#ffffff", "V": "#103018"}),
                      ascii_img(SLIME_B, {"L": "#9cf09a", "g": "#4cc26a", "d": "#2e8a4a", "W": "#ffffff", "V": "#103018"})]
    wolf_pal = {"a": "#5f616b", "A": "#8d8f99", "V": "#f2d24b", "k": "#1b1b1f", "s": "#c9cbd3", "W": "#c9cbd3", "d": "#3a3b42"}
    chars["wolf"] = char_frames(WOLF, WOLF_LEGS, wolf_pal, start=12)
    chars["skeleton"] = char_frames(SKELETON, SKELETON_LEGS, {
        "B": "#ebe5d0", "b": "#a69f86", "V": "#7a1010", "M": "#b9bec9", "y": "#9a7a3a", "R": "#5a3a22"})
    demon_pal = {"h": "#e8dcc0", "R": "#c62f2f", "r": "#8a1f1f", "Y": "#ffd84a", "k": "#2a1010", "w": "#5a1f3a"}
    chars["demon"] = char_frames(DEMON, DEMON_LEGS, demon_pal)
    king_rows = DEMON_KING_TOP + DEMON[3:]
    chars["demonking"] = char_frames(king_rows, DEMON_LEGS, {**demon_pal, "R": "#7a1030", "r": "#4a0820", "w": "#2a0f2f"})
    chars["villager"] = char_frames(VILLAGER, VILLAGER_LEGS, {
        **SKIN, "H": "#5a3a1a", "D": "#a0522d", "d": "#6e3a20", "W": "#efe6d2", "a": "#efe6d2", "r": "#3b2a1e"})
    chars["villager2"] = char_frames(VILLAGER, VILLAGER_LEGS, {
        **SKIN, "H": "#e0c060", "D": "#4a7ab0", "d": "#2f5580", "W": "#efe6d2", "a": "#efe6d2", "r": "#3b2a1e"})
    chars["guard"] = char_frames(KNIGHT, KNIGHT_LEGS, kn({"P": "#3a3a3a", "p": "#222222", "K": "#8a2b2b", "B": "#8a2b2b"}))
    return chars


CHAR_ORDER = ["knight", "warrior", "mage", "archer", "merchant", "captain", "slime", "wolf",
              "skeleton", "demon", "demonking", "villager", "villager2", "guard"]

# ---------------------------------------------------------------------------
# Suelo 16x16
# ---------------------------------------------------------------------------


def speckle(img, r, cols, n):
    px = img.load()
    for _ in range(n):
        px[r.randrange(16), r.randrange(16)] = C(r.choice(cols))


def tile_grass(seed, flowers=False):
    r = random.Random(seed)
    img = Image.new("RGBA", (16, 16), C("#5c9e3e"))
    speckle(img, r, ["#6aae48", "#4f8f36", "#67a944"], 46)
    px = img.load()
    for _ in range(3):
        x, y = r.randrange(1, 15), r.randrange(3, 15)
        px[x, y] = C("#3e7a2c")
        px[x, y - 1] = C("#3e7a2c")
        px[x - 1, y] = C("#4a8a34")
        px[x + 1, y - 2] = C("#7cc055")
    if flowers:
        for _ in range(3):
            x, y = r.randrange(1, 15), r.randrange(1, 15)
            col = C(r.choice(["#f4d84a", "#f07aa0", "#ffffff", "#b48af0"]))
            px[x, y] = col
            px[(x + 1) % 16, y] = col
            px[x, (y + 1) % 16] = col
            px[(x + 1) % 16, (y + 1) % 16] = C("#f4a83a")
    return img


def tile_forest(seed):
    r = random.Random(seed)
    img = Image.new("RGBA", (16, 16), C("#2f6634"))
    speckle(img, r, ["#3a763c", "#25552a", "#2a5e2e"], 60)
    px = img.load()
    for _ in range(4):
        x, y = r.randrange(16), r.randrange(16)
        px[x, y] = C(r.choice(["#8a6a2a", "#a0522d", "#6b8e23"]))
    return img


def tile_road(seed):
    r = random.Random(seed)
    img = Image.new("RGBA", (16, 16), C("#a8835a"))
    speckle(img, r, ["#b8936a", "#987350", "#9a7a52"], 60)
    px = img.load()
    for _ in range(3):
        x, y = r.randrange(15), r.randrange(15)
        px[x, y] = C("#c8b08a")
        px[x + 1, y] = C("#c8b08a")
        px[x, y + 1] = C("#7a5a3a")
        px[x + 1, y + 1] = C("#7a5a3a")
    return img


def tile_stones(seed, base, mortar, size=(6, 4), moss=None, light=0.18):
    r = random.Random(seed)
    img = Image.new("RGBA", (16, 16), C(mortar))
    px = img.load()
    sw, sh = size
    rows = 16 // sh
    for row in range(rows):
        off = (row % 2) * (sw // 2)
        y0 = row * sh
        for col in range(-1, 16 // sw + 2):
            x0 = col * sw + off
            shade = r.uniform(-0.12, 0.12)
            bc = C(base)
            stone = mix(bc, (255, 255, 255, 255), shade) if shade > 0 else mix(bc, (0, 0, 0, 255), -shade)
            for yy in range(y0 + 1, y0 + sh):
                for xx in range(x0 + 1, x0 + sw):
                    c = stone
                    if yy == y0 + 1:
                        c = mix(stone, (255, 255, 255, 255), light)
                    elif yy == y0 + sh - 1:
                        c = mix(stone, (0, 0, 0, 255), 0.15)
                    px[xx % 16, yy % 16] = c
    if moss:
        speckle(img, r, moss, 10)
    return img


def tile_cursed(seed, lava=False):
    r = random.Random(seed)
    img = Image.new("RGBA", (16, 16), C("#3e2433"))
    speckle(img, r, ["#4d2d40", "#2e1a26", "#44283a"], 70)
    px = img.load()
    x, y = r.randrange(16), r.randrange(16)
    for _ in range(9 if lava else 5):
        px[x % 16, y % 16] = C("#d04a2a" if lava else "#7a2a2a")
        x += r.choice([-1, 0, 1])
        y += r.choice([0, 1])
    if lava:
        for _ in range(4):
            px[r.randrange(16), r.randrange(16)] = C("#ffb03a")
    else:
        px[r.randrange(16), r.randrange(16)] = C("#d8d0c0")
    return img


TILE_NAMES = []


def build_tiles():
    tiles = []
    for s in range(4):
        tiles.append(("grass", tile_grass(10 + s)))
    for s in range(2):
        tiles.append(("grass_flowers", tile_grass(20 + s, True)))
    for s in range(3):
        tiles.append(("forest", tile_forest(30 + s)))
    for s in range(2):
        tiles.append(("road", tile_road(40 + s)))
    for s in range(2):
        tiles.append(("plaza", tile_stones(50 + s, "#a49c90", "#5e574e")))
    for s in range(2):
        tiles.append(("ruins", tile_stones(60 + s, "#8e8670", "#57513f", (8, 8), ["#5a7a3a", "#4a6a30"], 0.1)))
    for s in range(2):
        tiles.append(("cursed", tile_cursed(70 + s)))
    tiles.append(("cursed_lava", tile_cursed(80, True)))
    return tiles


# ---------------------------------------------------------------------------
# Decoración procedural
# ---------------------------------------------------------------------------


def shade_pick(level, cols):
    level = max(0.0, min(0.999, level))
    return C(cols[int(level * len(cols))])


def make_oak(seed, greens):
    r = random.Random(seed)
    W, H = 32, 40
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    for y in range(26, 40):
        for x in range(13, 19):
            px[x, y] = C("#5a3a22" if x >= 17 else ("#8a5a32" if x == 13 else "#70482a"))
    for x in (11, 12, 19, 20):
        px[x, 39] = C("#5a3a22")
    blobs = [(16, 15, 11), (8, 19, 7), (24, 19, 7), (16, 7, 7), (10, 10, 6), (22, 10, 6), (16, 22, 7)]
    for y in range(H):
        for x in range(W):
            inside = any((x - bx) ** 2 + (y - by) ** 2 <= br * br for bx, by, br in blobs)
            if not inside:
                continue
            nx, ny = (x - 16) / 14.0, (y - 14) / 14.0
            light = 0.55 - (nx * 0.45 + ny * 0.6) * 0.6 + r.uniform(-0.12, 0.12)
            px[x, y] = shade_pick(light, greens)
    return outline(img)


def make_pine(seed):
    r = random.Random(seed)
    W, H = 24, 44
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    cols = ["#123d22", "#1a4f2b", "#236236", "#2e7a42"]
    for y in range(36, 44):
        for x in range(10, 14):
            px[x, y] = C("#4a2e1a" if x >= 12 else "#6b4320")
    for i in range(4):
        apex = 1 + i * 8
        base = apex + 14
        for y in range(apex, min(base, 40)):
            half = (y - apex) * (0.55 + i * 0.12)
            for x in range(int(12 - half), int(12 + half) + 1):
                if 0 <= x < W:
                    t = (x - (12 - half)) / (2 * half + 1)
                    light = 0.85 - t * 0.7 + r.uniform(-0.1, 0.1)
                    if y >= base - 2:
                        light -= 0.25
                    px[x, y] = shade_pick(light, cols)
    return outline(img)


def make_deadtree(seed):
    r = random.Random(seed)
    img = Image.new("RGBA", (24, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    col = C("#4a3326")
    d.line([(12, 35), (12, 8)], fill=col, width=3)
    d.line([(12, 20), (5, 12)], fill=col, width=2)
    d.line([(12, 16), (19, 8)], fill=col, width=2)
    d.line([(5, 12), (3, 5)], fill=col, width=1)
    d.line([(19, 8), (21, 3)], fill=col, width=1)
    d.line([(12, 9), (14, 2)], fill=col, width=1)
    d.line([(12, 26), (17, 22)], fill=col, width=1)
    px = img.load()
    for y in range(8, 36):
        if px[13, y][3]:
            px[13, y] = C("#2e1f17")
    return outline(img)


def make_rock(seed, big=False):
    r = random.Random(seed)
    W, H = (24, 18) if big else (18, 14)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    cx, cy = W / 2, H * 0.6
    rx, ry = W * 0.45, H * 0.45
    cols = ["#4a4850", "#5e5c66", "#76747e", "#908e98", "#a8a6b0"]
    for y in range(H):
        for x in range(W):
            ang = math.atan2(y - cy, x - cx)
            rr = 1 + 0.12 * math.sin(ang * 3 + seed)
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= rr:
                nx, ny = (x - cx) / rx, (y - cy) / ry
                light = 0.6 - (nx * 0.5 + ny * 0.7) * 0.5 + r.uniform(-0.08, 0.08)
                px[x, y] = shade_pick(light, cols)
    if r.random() < 0.6:
        for _ in range(5):
            x, y = r.randrange(W), r.randrange(int(H * 0.5))
            if px[x, y][3]:
                px[x, y] = C("#5a8a3a")
    return outline(img)


def make_pillar(seed, broken):
    r = random.Random(seed)
    W, H = 16, 36
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    top = r.randint(12, 18) if broken else 5
    for y in range(top, 32):
        for x in range(4, 12):
            c = "#bcb3a0" if x < 6 else ("#a39a86" if x < 10 else "#857c6a")
            if x in (6, 9):
                c = "#8e8572"
            px[x, y] = C(c)
    if broken:
        for x in range(4, 12):
            for y in range(top, top + r.randint(0, 3)):
                px[x, y] = (0, 0, 0, 0)
    else:
        for y in range(2, 5):
            for x in range(2, 14):
                px[x, y] = C("#c8bfac" if y == 2 else "#a39a86")
    for y in range(32, 36):
        for x in range(2, 14):
            px[x, y] = C("#a39a86" if y == 32 else "#857c6a")
    for _ in range(6):
        x, y = r.randrange(4, 12), r.randrange(top, 32)
        px[x, y] = C("#5a7a3a")
    return outline(img)


def make_tomb(seed):
    img = Image.new("RGBA", (12, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([1, 2, 10, 15], radius=4, fill=C("#8e8a92"))
    d.rectangle([7, 4, 10, 15], fill=C("#74707a"))
    d.line([(5, 5), (5, 11)], fill=C("#4a4650"))
    d.line([(3, 7), (7, 7)], fill=C("#4a4650"))
    return outline(img)


def make_house(seed, roof="tiles"):
    r = random.Random(seed)
    W, H = 48, 52
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    plaster = ["#d9c9a6", "#e8dcc0", "#f0e6d0"]
    beam = C("#5a3a22")
    # paredes
    for y in range(28, 51):
        for x in range(5, 43):
            c = C(plaster[1])
            if x > 36:
                c = C(plaster[0])
            if r.random() < 0.05:
                c = C(plaster[2])
            px[x, y] = c
    for x in range(5, 43):
        px[x, 28] = beam
        px[x, 38] = beam
        px[x, 50] = beam
    for x in (5, 6, 23, 24, 41, 42):
        for y in range(28, 51):
            px[x, y] = beam
    d = ImageDraw.Draw(img)
    d.line([(7, 29), (22, 37)], fill=beam)
    d.line([(25, 37), (40, 29)], fill=beam)
    # puerta
    d.rectangle([19, 40, 28, 50], fill=C("#6b4320"))
    d.rectangle([19, 40, 28, 41], fill=C("#4a2c19"))
    d.line([(23, 41), (23, 50)], fill=C("#4a2c19"))
    px[26, 45] = C("#f2c94c")
    # ventanas
    for wx in (9, 32):
        d.rectangle([wx, 41, wx + 6, 47], fill=C("#8ec8e8"))
        d.line([(wx + 3, 41), (wx + 3, 47)], fill=C("#4a2c19"))
        d.line([(wx, 44), (wx + 6, 44)], fill=C("#4a2c19"))
        d.rectangle([wx - 2, 41, wx - 1, 47], fill=C("#3f6a3a"))
        d.rectangle([wx + 7, 41, wx + 8, 47], fill=C("#3f6a3a"))
        px[wx + 1, 42] = C("#d8f0ff")
    # tejado
    if roof == "tiles":
        cols = ["#7e2e20", "#9a3a28", "#b8503a", "#cf6a4a"]
    else:
        cols = ["#8a6a2a", "#a8843a", "#c9a24a", "#e0c070"]
    for y in range(6, 30):
        t = (y - 6) / 23.0
        left = int(12 - t * 11)
        right = int(36 + t * 11)
        for x in range(left, right + 1):
            row = (y - 6) % 4
            c = cols[2]
            if row == 3:
                c = cols[0]
            elif row == 0:
                c = cols[3]
            if roof == "tiles" and row != 3 and (x + (y // 4) * 2) % 5 == 0:
                c = cols[1]
            if roof != "tiles" and r.random() < 0.15:
                c = cols[1]
            if x > right - 4:
                c = cols[max(0, cols.index(c) - 1)]
            px[x, y] = C(c)
    for x in range(12, 37):
        px[x, 6] = C(cols[0])
        px[x, 5] = C(cols[1])
    # chimenea
    for y in range(1, 12):
        for x in range(31, 36):
            px[x, y] = C("#8e8a92" if x < 34 else "#6e6a72")
    for x in range(30, 37):
        px[x, 1] = C("#5e5a62")
    return outline(img)


def make_well():
    W, H = 28, 32
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([2, 18, 25, 31], fill=C("#8e8a92"))
    d.ellipse([5, 20, 22, 27], fill=C("#22384a"))
    d.ellipse([7, 21, 14, 24], fill=C("#3a5a7a"))
    for x in range(2, 26, 4):
        d.line([(x, 27), (x, 30)], fill=C("#6e6a72"))
    d.rectangle([3, 6, 5, 23], fill=C("#6b4320"))
    d.rectangle([22, 6, 24, 23], fill=C("#6b4320"))
    d.polygon([(0, 8), (14, 0), (27, 8), (24, 10), (3, 10)], fill=C("#9a3a28"))
    d.line([(0, 8), (14, 0), (27, 8)], fill=C("#cf6a4a"))
    d.line([(6, 12), (21, 12)], fill=C("#4a2c19"))
    d.line([(14, 12), (14, 17)], fill=C("#d8d0c0"))
    d.rectangle([12, 17, 16, 20], fill=C("#8a5a32"))
    return outline(img)


def make_stall():
    W, H = 36, 34
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([3, 8, 4, 31], fill=C("#5a3a22"))
    d.rectangle([31, 8, 32, 31], fill=C("#5a3a22"))
    d.rectangle([2, 20, 33, 31], fill=C("#8a5a32"))
    for y in (23, 27):
        d.line([(2, y), (33, y)], fill=C("#6b4320"))
    d.rectangle([2, 19, 33, 20], fill=C("#a8743e"))
    for i, col in enumerate(["#d8343a", "#f2c94c", "#e07a2a", "#8a4ab0", "#d8343a", "#4a8a3a"]):
        x = 5 + i * 5
        d.ellipse([x, 15, x + 3, 18], fill=C(col))
    for x in range(1, 35):
        stripe = (x // 4) % 2 == 0
        for y in range(2, 11):
            img.putpixel((x, y), C("#c83a3a" if stripe else "#f0e6d0"))
        if (x % 4) in (1, 2):
            img.putpixel((x, 11), C("#c83a3a" if stripe else "#f0e6d0"))
    return outline(img)


def make_board():
    img = Image.new("RGBA", (24, 30), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([3, 14, 5, 29], fill=C("#5a3a22"))
    d.rectangle([18, 14, 20, 29], fill=C("#5a3a22"))
    d.rectangle([1, 3, 22, 18], fill=C("#8a5a32"))
    d.rectangle([1, 3, 22, 4], fill=C("#a8743e"))
    for x0, y0 in ((3, 6), (11, 7), (16, 6)):
        d.rectangle([x0, y0, x0 + 5, y0 + 7], fill=C("#f0e6d0"))
        d.line([(x0 + 1, y0 + 2), (x0 + 4, y0 + 2)], fill=C("#7a6a5a"))
        d.line([(x0 + 1, y0 + 4), (x0 + 4, y0 + 4)], fill=C("#7a6a5a"))
        img.putpixel((x0 + 2, y0), C("#d8343a"))
    return outline(img)


def make_banner(col):
    img = Image.new("RGBA", (14, 38), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([6, 3, 7, 37], fill=C("#5a3a22"))
    d.ellipse([5, 0, 8, 3], fill=C("#f2c94c"))
    d.line([(1, 5), (12, 5)], fill=C("#5a3a22"))
    d.polygon([(2, 6), (11, 6), (11, 22), (6, 18), (2, 22)], fill=C(col))
    d.rectangle([5, 9, 8, 14], fill=C("#f2c94c"))
    d.line([(4, 11), (9, 11)], fill=C("#f2c94c"))
    return outline(img)


def make_tower():
    W, H = 30, 58
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    r = random.Random(7)
    for y in range(10, 58):
        for x in range(3, 27):
            brick_row = (y - 10) // 4
            off = (brick_row % 2) * 3
            c = "#9a948a"
            if (y - 10) % 4 == 0 or (x + off) % 6 == 0:
                c = "#6e675e"
            elif x > 21:
                c = "#827c72"
            elif x < 6:
                c = "#b0aa9e"
            if r.random() < 0.04:
                c = "#5a7a3a"
            px[x, y] = C(c)
    for y in range(4, 10):
        for x in range(1, 29):
            if (x // 4) % 2 == 0 or y >= 8:
                px[x, y] = C("#b0aa9e" if y < 6 else "#9a948a")
    d = ImageDraw.Draw(img)
    d.rectangle([13, 22, 15, 30], fill=C("#1e1a20"))
    d.rectangle([13, 38, 15, 44], fill=C("#1e1a20"))
    return outline(img)


def make_small(kind):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if kind == "barrel":
        d.ellipse([3, 2, 12, 6], fill=C("#a8743e"))
        d.rectangle([3, 4, 12, 14], fill=C("#8a5a32"))
        d.ellipse([3, 12, 12, 15], fill=C("#8a5a32"))
        d.line([(3, 6), (12, 6)], fill=C("#5e5a62"))
        d.line([(3, 12), (12, 12)], fill=C("#5e5a62"))
        d.line([(10, 5), (10, 14)], fill=C("#6b4320"))
    elif kind == "crate":
        d.rectangle([2, 4, 13, 15], fill=C("#a8743e"))
        d.rectangle([2, 4, 13, 5], fill=C("#c08a4e"))
        d.line([(2, 4), (13, 15)], fill=C("#6b4320"))
        d.line([(13, 4), (2, 15)], fill=C("#6b4320"))
        d.rectangle([2, 4, 13, 15], outline=C("#6b4320"))
    elif kind == "hay":
        d.rounded_rectangle([1, 5, 14, 15], radius=3, fill=C("#d8b450"))
        for x in range(2, 14, 3):
            d.line([(x, 6), (x + 1, 14)], fill=C("#b8943a"))
        d.line([(1, 9), (14, 9)], fill=C("#8a6a2a"))
    return outline(img)


# ---------------------------------------------------------------------------
# Iconos 16x16 para los botones
# ---------------------------------------------------------------------------


def icon(kind):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if kind == "sword":
        d.line([(4, 11), (13, 2)], fill=C("#e8ecf2"), width=2)
        d.line([(5, 11), (13, 3)], fill=C("#a3abbd"))
        d.line([(2, 8), (7, 13)], fill=C("#f2c94c"), width=2)
        d.line([(3, 12), (1, 14)], fill=C("#7a4a2a"), width=2)
    elif kind == "potion":
        img = ascii_img([
            "................",
            "......kkkk......",
            "......kkkk......",
            ".......GG.......",
            ".......GG.......",
            ".....GGGGGG.....",
            "....GRRRRRRG....",
            "...GRRWRRRRRG...",
            "...GRWRRRRRRG...",
            "...GRRRRRRRRG...",
            "...GrRRRRRRrG...",
            "....GrrrrrrG....",
            ".....GGGGGG.....",
            "................",
            "................",
            "................",
        ], {"k": "#8a5a32", "G": "#cfe6f0", "R": "#e0303a", "r": "#a01e28", "W": "#ffffff"})
    elif kind == "swirl":
        pts = []
        for i in range(70):
            t = i / 69 * math.pi * 3.2
            rr = 0.6 + t * 0.62
            pts.append((7.5 + rr * math.cos(t), 7.5 + rr * math.sin(t)))
        d.line(pts, fill=C("#f2c94c"), width=2)
        d.line(pts[20:], fill=C("#fff0a0"), width=1)
    elif kind == "bubble":
        d.rounded_rectangle([1, 2, 14, 11], radius=4, fill=C("#f4f0e6"))
        d.polygon([(4, 10), (8, 10), (3, 14)], fill=C("#f4f0e6"))
        for x in (5, 8, 11):
            d.rectangle([x - 1, 6, x, 7], fill=C("#5a3a22"))
    elif kind == "scroll":
        d.rectangle([3, 3, 12, 12], fill=C("#f0e0b8"))
        d.rectangle([2, 1, 13, 3], fill=C("#c8a870"))
        d.rectangle([2, 12, 13, 14], fill=C("#c8a870"))
        for y in (5, 7, 9):
            d.line([(5, y), (10, y)], fill=C("#7a5a3a"))
        img.putpixel((10, 11), C("#d8343a"))
    elif kind == "bag":
        d.ellipse([2, 5, 13, 15], fill=C("#8a5a32"))
        d.polygon([(5, 2), (10, 2), (9, 6), (6, 6)], fill=C("#8a5a32"))
        d.line([(5, 6), (10, 6)], fill=C("#f2c94c"))
        d.ellipse([6, 9, 9, 12], fill=C("#f2c94c"))
    elif kind == "book":
        d.rectangle([3, 2, 12, 14], fill=C("#8a2b2b"))
        d.rectangle([11, 3, 13, 14], fill=C("#f0e6d0"))
        d.rectangle([5, 5, 9, 9], outline=C("#f2c94c"))
        d.line([(3, 2), (3, 14)], fill=C("#5a1a1a"))
    elif kind == "coin":
        d.ellipse([2, 2, 13, 13], fill=C("#b8892a"))
        d.ellipse([3, 3, 12, 12], fill=C("#f2c94c"))
        d.line([(7, 5), (7, 10)], fill=C("#b8892a"), width=2)
        img.putpixel((5, 4), C("#fff4b0"))
    elif kind == "heart":
        d.ellipse([1, 2, 8, 9], fill=C("#d8343a"))
        d.ellipse([7, 2, 14, 9], fill=C("#d8343a"))
        d.polygon([(1, 6), (14, 6), (7.5, 14)], fill=C("#d8343a"))
        img.putpixel((4, 4), C("#ff9aa0"))
    return outline(img)


ICON_ORDER = ["sword", "potion", "swirl", "bubble", "scroll", "bag", "book", "coin", "heart"]

# ---------------------------------------------------------------------------


def sheet(images, cols, cell):
    rows = (len(images) + cols - 1) // cols
    out = Image.new("RGBA", (cols * cell[0], rows * cell[1]), (0, 0, 0, 0))
    for i, im in enumerate(images):
        out.paste(im, ((i % cols) * cell[0], (i // cols) * cell[1]))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    chars = build_characters()
    char_imgs = []
    for name in CHAR_ORDER:
        f0, f1 = chars[name]
        char_imgs += [outline(f0), outline(f1)]
    sheet(char_imgs, 2, (16, 16)).save(os.path.join(OUT, "characters.png"))

    tiles = build_tiles()
    sheet([t for _, t in tiles], 8, (16, 16)).save(os.path.join(OUT, "tiles.png"))

    sheet([icon(k) for k in ICON_ORDER], len(ICON_ORDER), (16, 16)).save(os.path.join(OUT, "icons.png"))

    greens = ["#1f4a22", "#2c6430", "#3a7d3a", "#55a046", "#78c25a"]
    autumn = ["#5a3a12", "#8a5418", "#b8741e", "#d89a30", "#f0c050"]
    decor = {
        "oak": make_oak(1, greens),
        "oak2": make_oak(2, greens),
        "oak_autumn": make_oak(3, autumn),
        "pine": make_pine(4),
        "pine2": make_pine(5),
        "deadtree": make_deadtree(6),
        "rock": make_rock(7),
        "rock_big": make_rock(8, True),
        "pillar": make_pillar(9, False),
        "pillar_broken": make_pillar(10, True),
        "tomb": make_tomb(11),
        "house": make_house(12, "tiles"),
        "house_thatch": make_house(13, "thatch"),
        "well": make_well(),
        "stall": make_stall(),
        "board": make_board(),
        "banner_red": make_banner("#b8332b"),
        "banner_blue": make_banner("#2f5fc4"),
        "tower": make_tower(),
        "barrel": make_small("barrel"),
        "crate": make_small("crate"),
        "hay": make_small("hay"),
    }
    ddir = os.path.join(OUT, "decor")
    os.makedirs(ddir, exist_ok=True)
    for name, im in decor.items():
        im.save(os.path.join(ddir, name + ".png"))

    # vista previa (solo para revisar, no la usa el juego)
    prev = Image.new("RGBA", (420, 300), C("#3a5a2a"))
    x = 4
    for i, im in enumerate(char_imgs):
        prev.paste(im.resize((32, 32), Image.NEAREST), (4 + (i % 14) * 34, 4 + (i // 14) * 34), im.resize((32, 32), Image.NEAREST))
    x, y = 4, 80
    for name, im in decor.items():
        big = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
        if x + big.width > 420:
            x, y = 4, y + 110
        prev.paste(big, (x, y), big)
        x += big.width + 4
    prev.save(os.path.join(ROOT, "tools", "preview.png"))
    print("ok:", len(char_imgs), "frames de personajes,", len(tiles), "tiles,", len(decor), "decoraciones")


if __name__ == "__main__":
    main()
