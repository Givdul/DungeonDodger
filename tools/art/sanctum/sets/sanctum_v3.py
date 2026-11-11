"""Cult Sanctum: a forbidden temple under the dungeon, mid-ritual."""
from core import stamp, shadow
import kit

NAME = "Cult Sanctum"
PITCH = ("Charcoal-plum temple mid-ritual: the runaway sacrifice, an imp familiar, a candle-bearing cultist, "
         "a fireball whooshing between the walls, a fire-spitting gargoyle, a hungry mimic and spell-circle traps.")
OUTLINE = "#1b1520"
SHADOW = "#352c39"


def _g(rows):
    """Pads a drawing to 16x16."""
    return [r.ljust(16, ".") for r in rows] + ["." * 16] * (16 - len(rows))


# ---------- hero: the sacrifice who got away, bare feet, rope belt, rope still round one wrist ----------
_HERO_L = {"H": "#5e3431", "h": "#45272a", "S": "#c6966f", "s": "#9d7059", "W": "#9f937f", "V": "#73695b",
           "B": "#8c2d35", "R": "#a47c4b", "r": "#79593a"}


def _hero(rows):
    return stamp(shadow(8, 13, [8, 6]), _g(rows))


_IDLE_A = [
    "................",
    ".....oooooo.....",
    "....oHHHhHHo....",
    "...oHhHHHHHHo...",
    "...oHHhHHHhHo...",
    "...ohHSSSSHho...",
    "....oSoSSoSo....",
    ".....osSSso.....",
    "....ooWWWWoo....",
    "...oSoVWBWoSo...",
    "...osoVWWBoso...",
    "....ooRrRRoro...",
    "....oVWooWVor...",
    "....oSo..oSo....",
    "....ooo..ooo....",
]

_IDLE_B = [
    "................",
    "................",
    ".....oooooo.....",
    "....oHHHhHHo....",
    "...oHhHHHHHHo...",
    "...oHHhHHHhHo...",
    "...ohHSSSSHho...",
    "....oSoSSoSo....",
    "....oosSSsoo....",
    "...oSoVWBWoSo...",
    "...osoVWWBosro..",
    "....ooRrRRoor...",
    "....oVWooWVo....",
    "....oSo..oSo....",
    "....ooo..ooo....",
]

_RUN_A = [
    "................",
    "......ooooo.....",
    ".....oHHHHHo....",
    "....oHhHHHHHo...",
    "...ohHHHHhHHo...",
    "...ohHhHSSSSo...",
    "...oho.hSoSo....",
    "....o.oosSSo....",
    "....oSoWWWVoo...",
    "....osoVWBWoSo..",
    ".....ooRrRRooo..",
    "....oVWoWWVo....",
    "...oSoo..oSo....",
    "...ooo...ooo....",
]

_RUN_B = [
    "................",
    "................",
    "......ooooo.....",
    ".....oHHHHHo....",
    "....oHhHHHHHo...",
    "...ohHHHHhHHo...",
    "...ohoHhSSSSo...",
    "....o.ohSoSo....",
    ".....oooSSSo....",
    ".....oVWWWoSo...",
    "....oSoWBWoso...",
    ".....ooRrRRoo...",
    ".....oVWWVo.....",
    ".....ooSSoo.....",
    "......oooo......",
]

_RUN_C = [
    "................",
    "......ooooo.....",
    ".....oHHHHHo....",
    "....oHhHHHHHo...",
    "...ohHHHHhHHo...",
    "...ohHhHSSSSo...",
    "...oho.hSoSo....",
    "....o.oosSSo....",
    ".....oVWWWoSo...",
    "....oVWWBWoso...",
    "...oSoRrRRoo....",
    "...osoVWoVWo....",
    "....oo.oSooSo...",
    ".......ooo.ooo..",
]

_UP_A = [
    "................",
    ".....oooooo.....",
    "....oHHHHHHo....",
    "...oHhHHHHhHo...",
    "...oHHHhHHHHo...",
    "...ohHHHHHHho...",
    "....ohHHHHho....",
    "...ooooHhoooo...",
    "..oSoVWWWWoSo...",
    "..osoWWBWVooo...",
    "...ooRRrRRoSo...",
    "....oVWoWVoso...",
    "....oSo.ooooo...",
    "....oso.........",
    "....ooo.........",
]

_UP_B = [
    "................",
    "................",
    ".....oooooo.....",
    "....oHHHHHHo....",
    "...oHhHHHHhHo...",
    "...oHHHhHHHHo...",
    "...ohHHHHHHho...",
    "...ooohHHhooo...",
    "..oSoVWWWWoSo...",
    "..osoWWBWVoso...",
    "...ooRRrRRoo....",
    "....oVWooWVo....",
    "....oSo..oSo....",
    "....ooo..ooo....",
]

_UP_C = [
    "................",
    ".....oooooo.....",
    "....oHHHHHHo....",
    "...oHhHHHHhHo...",
    "...oHHHhHHHHo...",
    "...ohHHHHHHho...",
    "....ohHHHHho....",
    "...ooooHhoooo...",
    "...oSoWWWWVoSo..",
    "...oooVWBWWoso..",
    "...oSoRRrRRoo...",
    "...osoVWoWVo....",
    "...ooooo.oSo....",
    ".........oso....",
    ".........ooo....",
]


HERO = {
    "legend": _HERO_L,
    "idle": [_hero(_IDLE_A)] * 3 + [_hero(_IDLE_B)] * 3,
    "run": [_hero(f) for f in (_RUN_A, _RUN_B, _RUN_C) * 2],
    "run_up": [_hero(f) for f in (_UP_A, _UP_B, _UP_C, _UP_B, _UP_A, _UP_B)],
}

# ---------- flyer: an imp familiar, one bat wing, leaning in to pounce ----------
_IMP_L = {"S": "#b08550", "s": "#7f5b38", "M": "#7a5a80", "m": "#5a4262", "W": "#bdb09a", "Y": "#e1b553"}
_IMP_HEAD = [
    "......oo..oo....",
    "......oWo.oWo...",
    ".......oWooWSo..",
    "......oSSSSSSo..",
    "......osSSSoYSo.",
    ".......osSooooo.",
    "........oowoo...",
]
_IMP_BODY = [
    ".......oSSSo....",
    "......oSSsoSo...",
    ".....oSSSSooSo..",
    "..oooosSSso.oo..",
    ".oSSooosSoSo....",
    "..oo...oo.oo....",
]
_IMP_WINGS = {
    "up": [   # raised
        ".oo.....",
        "oMMo....",
        "oMmMo...",
        "oMoMMo..",
        "oMooMMo.",
        ".o.oMmMo",
        "...oomMo",
        ".....ooo",
    ],
    "mid": [   # level
        "........",
        "........",
        "........",
        "........",
        "........",
        "ooooo...",
        "oMMMMoo.",
        ".oMoMMMo",
        "..ooMmMo",
        "....ooo.",
    ],
    "down": [   # swept back
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "oooooo..",
        "oMMMMMoo",
        ".oMoMoMo",
        "..o.o.o.",
    ],
}


def _imp(wing, top):
    g = stamp(stamp(stamp(["." * 16] * 16, _IMP_HEAD, 0, 2), _IMP_BODY, 0, 9), _IMP_WINGS[wing], 0, 1)
    return stamp(shadow(8, 14, [6, 4]), g, 0, top)


FLYER = ([_imp("up", -1), _imp("mid", -2), _imp("down", -2), _imp("mid", -1)], _IMP_L)

# ---------- drifter: a hooded cultist gliding with a candle held out ----------
_CULT_L = {"R": "#6b2a36", "r": "#4e1f2b", "E": "#d0a048", "W": "#bdb09a", "Y": "#e1b553", "y": "#b5612f"}
_CULT = [
    [
        "....oo..........",
        "....oRo.........",
        ".....oRo....oy..",
        ".....oRRoo..oYo.",
        "....oRRRRRo..o..",
        "....oRRoooooowo.",
        "...oRRRoEooEowo.",
        "...oRrRoooooowo.",
        "..oRRrRRooRRRoo.",
        "..oRrRRRRoorrRo.",
        ".orRRrRRRRRoooo.",
        "orRo.orRRrRo....",
        "oo...ooRoooo....",
    ],
    [
        "...oo...........",
        "...oRo..........",
        "....oRo.....oy..",
        ".....oRRoo..oYo.",
        "....oRRRRRo..o..",
        "....oRRoooooowo.",
        "...oRRRoEooEowo.",
        "...oRrRoooooowo.",
        "..oRRrRRooRRRoo.",
        "..oRrRRRRoorrRo.",
        ".orRRrRRRRRoooo.",
        "..orRoorRRrRo...",
        "...oo..ooRooo...",
    ],
]


def _cult(i, lift):
    return stamp(shadow(8, 13, [6, 8, 6]), _CULT[i], 0, 1 + lift)


DRIFTER = ([_cult(0, 0), _cult(0, -1), _cult(1, -1), _cult(1, 0)], _CULT_L)

# ---------- spinner: a fireball whooshing across the corridor, core leading, flame trailing ----------
_FIRE_L = {"L": "#f3d98a", "Y": "#e1b553", "y": "#c8742f", "E": "#d4513a", "R": "#8c2d35", ";": "#e1b553",
           ",": "#d4513a"}
_FIRE = [
    [
        "..........ooo...",
        ".....oooooYYyo..",
        "...ooyEEoyYLYyo.",
        ";.oEEyoooYLwLYyo",
        "oRREEEyyYLwwLYyo",
        ".ooooEEyYYLLYYyo",
        "..,oRREooyYYYyo.",
        "....ooo..ooyyo..",
        "..........ooo...",
    ],
    [
        ".....oo...ooo...",
        "..ooRRoooooYYyo.",
        ".oRREEyyoyYLYyo.",
        "..oooooyYYLwLYyo",
        "..oRREEyYLwwLYyo",
        ",..ooooEYYLLYYyo",
        ".....oEEoyYYYyo.",
        ".....,oooooyyo..",
        "..........ooo...",
    ],
    [
        "..........ooo...",
        "....;..oooYYyo..",
        "..oooooEEyYLYyo.",
        ".oRREEEyoYLwLYyo",
        "..ooooyyYLwwLYyo",
        "oRREEEEyYYLLYYyo",
        ".ooooooEoyYYYyo.",
        "...,...oooyyyo..",
        "..........ooo...",
    ],
    [
        "...,......ooo...",
        "......oooooYYyo.",
        "..oooREEoyYLYyo.",
        ".oRREEyyyYLwLYyo",
        "..ooooooYLwwLYyo",
        "...oRREEyYLLYYyo",
        "..oRREooyyYYYyo.",
        "...ooo...ooyyo..",
        "..........ooo...",
    ],
]
SPINNER_DRIFT = 80
SPINNER = ([stamp(shadow(6, 13, [6, 4]), f, 0, 3) for f in _FIRE], _FIRE_L)

# ---------- bomber: a gargoyle on its plinth that spits burning skulls ----------
_GARG_L = {"G": "#81768a", "g": "#5e5569", "H": "#a2967f", "p": "#463d4c", "E": "#d4513a", "Y": "#e1b553",
           "y": "#b5612f"}
_GARG = {
    "idle": [
        ".o....oo........",
        "oGo....oHo......",
        "oGgo....oHo.....",
        "oGgGo..oGGHoooo.",
        "ogGgGooGGGGGGGGo",
        ".oggoGGGoEGGoooo",
        ".ooggoGGGGGooGwo",
        "...oooGGGGGoooo.",
        "...oGGgGgGGo....",
        "...ogGGooGGgo...",
        "...oogGoogGo....",
        "..oooooooooooo..",
        "..ogggggggggggo.",
        "..opgppgppgppo..",
        "..oooooooooooo..",
    ],
    "rear": [
        "......oo........",
        ".o.....oHo......",
        "oGo.....oHoooo..",
        "oGgo...oGGHGGGo.",
        "oGgGo.oGGGGGoEo.",
        "ogGgGoGGGGGGGGGo",
        ".oggoGGGGGGoooo.",
        ".ooggoGGGGGGo...",
        "...oGGgGgGGo....",
        "...ogGGooGGgo...",
        "...oogGoogGo....",
        "..oooooooooooo..",
        "..ogggggggggggo.",
        "..opgppgppgppo..",
        "..oooooooooooo..",
    ],
    "spit": [
        ".o....oo........",
        "oGo....oHo......",
        "oGgo....oHo...y.",
        "oGgGo..oGGHoooYy",
        "ogGgGooGGGGGGoYY",
        ".oggoGGGoEGGoyYy",
        ".ooggoGGGGGoEYYy",
        "...oooGGGGGoGoy.",
        "...oGGgGgGGoo...",
        "...ogGGooGGgo...",
        "...oogGoogGo....",
        "..oooooooooooo..",
        "..ogggggggggggo.",
        "..opgppgppgppo..",
        "..oooooooooooo..",
    ],
}


def _garg(pose):
    return stamp(shadow(14, 12, [12, 14, 12, 8]), _GARG[pose], 0, 1)


BOMBER = ([_garg("idle")] * 3 + [_garg("idle")], _GARG_L)
BOMBER_SPIT = ([_garg("idle"), _garg("rear"), _garg("rear"), _garg("spit"), _garg("spit"), _garg("idle")], _GARG_L)

# ---------- bomb: a skull burning on the floor ----------
_SKULL_L = {"B": "#b3a690", "b": "#857a6a", "Y": "#e1b553", "y": "#b5612f", "E": "#d4513a", "P": "#f3d98a"}
_SKULL = [
    "......oo........",
    ".....oYo..o.....",
    ".....oYyooyo....",
    "....oyYYyYyo....",
    "....ooooooooo...",
    "...obBBBoBBBo...",
    "..obBBBBBoBBbo..",
    "..oBooBBBooBbo..",
    "..oBoEBBBoEbbo..",
    "..obBBBoBBbbbo..",
    "...oobowowobo...",
    ".....ooooooo....",
]
_SKULL_B = stamp(stamp(_SKULL, ["....o..o....", "...oYoyYo...", "...oyYPYyo..", "...oYyYyYo.."], 1, 0),
                 ["", "", "", "", "", "", "", "", ".....Y....Y"])
BOMB = ([stamp(shadow(10, 12, [8, 10, 8]), s, 0, 2) for s in (_SKULL, _SKULL_B, _SKULL, _SKULL_B)],
        _SKULL_L)

# ---------- pickup: a blood-red gem ----------
_GEM_L = {"R": "#a8323b", "r": "#741f2c", "L": "#cf5a55"}
_GEM = [
    ".......oo.......",
    "......oLRo......",
    ".....oLwRro.....",
    ".....oLRRro.....",
    "......oRro......",
    ".......oo.......",
]
_GEM_T = [
    ".......oo.......",
    ".......oRo......",
    "......oLRro.....",
    "......oRrro.....",
    ".......oro......",
    ".......oo.......",
]
PICKUP = ([stamp(shadow(6, 12, [4, 6, 4]), g, 0, 4 + l)
           for g, l in ((_GEM, 0), (_GEM, -1), (_GEM_T, -1), (_GEM_T, 0))], _GEM_L)

# ---------- key: iron, with a horned bow ----------
_KEY_L = {"K": "#8e8697", "k": "#625a6b", "H": "#b9ae9c"}
_KEY = [
    "..o..o..........",
    ".oHooHo.........",
    ".oHKKHo.........",
    "oKoooKoooooooo..",
    "oKo.oKKKKKKKKKo.",
    "okoookkkkkokoko.",
    ".okkko.....o.o..",
    "..ooo...........",
]
KEY = ([stamp(shadow(10, 11, [8, 10, 8]), k, 1, 3 + l)
        for k, l in ((_KEY, 0), (_KEY, -1), (stamp(_KEY, ["......w"], 0, 4), -1), (_KEY, 0))], _KEY_L)

# ---------- chest: a mimic that licks its lips ----------
_MIMIC_L = {"W": "#6e4636", "D": "#523327", "I": "#7a7282", "i": "#5a5262", "T": "#a33a48",
            "t": "#7a2836"}
_CHEST_SHUT = [
    "..oooooooooooo..",
    ".oWWWWWWWWWWWWo.",
    ".oIDDDDDDDDDDIo.",
    ".oowowowowowowo.",
    ".oiowowowowowio.",
    ".oWWWWWoIoWWWWo.",
    ".oDDDDDoioDDDDo.",
    ".oIDDDDDDDDDDIo.",
    "..oooooooooooo..",
]
_CHEST_GAPE = [
    "..oooooooooooo..",
    ".oWWWWWWWWWWWWo.",
    ".oIDDDDDDDDDDIo.",
    ".oowowowowowowo.",
    ".oooooooooTTTTo.",
    ".oioowowowotTTto",
    ".oWWWWWoIoWWWWo.",
    ".oDDDDDoioDDDDo.",
    ".oIDDDDDDDDDDIo.",
    "..oooooooooooo..",
]
_CHEST_LICK = [
    "..oooooooooooo..",
    ".oWWWWWWWWWWWWo.",
    ".oIDDDDDDDDDDIo.",
    ".oowowowowowowoo",
    ".ooooooooooTTTTo",
    ".oioowowowottTo.",
    ".oWWWWWoIoWWWWo.",
    ".oDDDDDoioDDDDo.",
    ".oIDDDDDDDDDDIo.",
    "..oooooooooooo..",
]


def _chest(g, top):
    return stamp(shadow(14, 12, [14, 14, 10]), g, 0, top)


CHEST = ([_chest(_CHEST_SHUT, 4), _chest(_CHEST_SHUT, 4), _chest(_CHEST_SHUT, 4), _chest(_CHEST_GAPE, 3),
          _chest(_CHEST_LICK, 3), _chest(_CHEST_GAPE, 3), _chest(_CHEST_SHUT, 4), _chest(_CHEST_SHUT, 4)], _MIMIC_L)

# ---------- potion: a goblet of something red, brimming over ----------
_GOB_L = {"I": "#8e8697", "i": "#625a6b", "R": "#a8323b", "r": "#741f2c", "Y": "#d0a048"}
_GOBLET = [
    "....ooooooo.....",
    "...oRRrRRRYo....",
    "...RIRRRRrio....",
    "...RoIIIiio.....",
    "....ooIio.......",
    "......oo........",
    ".....oIio.......",
    "....oIiiio......",
    "....oooooo......",
]
_GOBLET_B = stamp(_GOBLET, ["....RRRrRw", "", "", "...R"], 0, 1)
POTION = ([stamp(shadow(8, 12, [6, 8, 6]), g, 2, 3 + l)
           for g, l in ((_GOBLET, 0), (_GOBLET, -1), (_GOBLET_B, -1), (_GOBLET_B, 0))], _GOB_L)

# ---------- tiles ----------
_TILE_L = {
    "F": "#4a3f4e", "f": "#463b4a", "h": "#51455a", "g": "#3d3342", "u": "#55404f",   # floor, alt, lit edge, grout, worn rune
    "K": "#2a2230", "B": "#5a4e62", "b": "#4b4053", "e": "#211a26",                     # wall mortar, brick, brick shade, deep edge
    "Y": "#e1b553", "y": "#b5612f", "W": "#bdb09a",                                      # flame, ember, wax
    "v": "#150f16", "V": "#2c222f", "L": "#6a1e26", "l": "#3e151d", "E": "#b23a32",      # well depth, well wall, red glow
    "U": "#c4473a", "n": "#6b2c35",                                                      # rune lit, rune dull
    "I": "#6f6878", "i": "#4d4657", "H": "#b0a48e", "j": "#857a68",                      # iron, horn
    "P": "#f3d98a", ";": "#e1b553", ",": "#d4513a",                                      # flame core, sparks
}
_FLOOR = ["h" * 15 + "g"] + ["h" + "F" * 14 + "g"] * 14 + ["g" * 16]
_FLOOR_B = ["h" * 7 + "g" + "h" * 7 + "g"] + ["h" + "f" * 6 + "g" + "h" + "f" * 6 + "g"] * 14 + ["g" * 16]
_RUNE = [
    "................",
    "................",
    "................",
    "................",
    "......u...u.....",
    "......u..u......",
    "......uuu.......",
    "......u..u......",
    "......u...u.....",
    "......u.........",
]
_CRACK = [
    "................",
    "................",
    "..........g.....",
    "...........g....",
    "..........gg....",
    "............g...",
    "................",
]
_STAIN = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "...n............",
    "..nlnn..........",
    "...nn...........",
]


def _wall_base():
    """Coursed stone on the outer side, a cast shadow, then floor."""
    rows = []
    for y in range(16):
        course = y % 4
        if course == 3:
            face = "K" * 9
        else:
            seam = 3 if (y // 4) % 2 == 0 else 6
            tone = "h" if course == 0 else ("b" if course == 2 else "B")
            face = "".join("K" if x == seam else tone for x in range(9))
        rows.append("e" + face + "e" + "g" + _FLOOR[y][12:])
    return rows


_ALCOVE = [
    "..eee....",
    ".eeeee...",
    ".eeYee...",
    ".eyYye...",
    ".eeWee...",
    ".eeWee...",
    ".eWWWe...",
    "KKKKKKK..",
]
_WALL_B = stamp(_wall_base(), _ALCOVE, 2, 3)
_WALL_PLAIN = _wall_base()

# the shaft's stone lip, then black; far down, a summoning circle still smoulders
_PIT = stamp(["h" * 15 + "g", "V" * 16, "KVVVVKVVVVVVKVVV", "V" * 16, "lVVlVVVVlVVVlVVl", "vlvvvlvvvvlvvvlv"]
             + ["v" * 16] * 10, [
    "", "", "", "", "", "", "", "",
    ".......ll.......",
    ".....l....l.....",
    "....l......l....",
    ".....l....l.....",
    ".......ll.......",
])

# the trap: a summoning circle chalked in old blood; its sigil lights, it bursts into a pillar of flame
_CIRCLE = [
    "................",
    "................",
    ".....nnnnnn.....",
    "....n......n....",
    "...n...nn...n...",
    "..n...n..n...n..",
    "..n...n..n...n..",
    "..n..n....n..n..",
    "..n..n....n..n..",
    "..n.n......n.n..",
    "..n.nnnnnnnn.n..",
    "...n........n...",
    "....n......n....",
    ".....nnnnnn.....",
]


def _lit(sigil):
    """The circle in a brighter red, the sigil inside it in `sigil`."""
    return ["".join((sigil if 3 <= y <= 10 and 4 <= x <= 11 else "U") if c == "n" else c for x, c in enumerate(r))
            for y, r in enumerate(_CIRCLE)]


_GLOW = _lit("Y")
_COOLING = _lit("E")
_PILLAR = [
    [
        "......oo........",
        ".....oYo........",
        ".....oYyo.......",
        "..oo.oPYo..oo...",
        ".oyo.oYPYooYo...",
        ".oYyooPwPYoyYo..",
        ".oYYyoPwPYoYYo..",
        "..oYyPPwPPyYyo..",
        "..oyYPwwwPYYEo..",
        "..oEyYPPPYYyEo..",
        "...oEyyYYyyEo...",
        "....ooEEEEoo....",
    ],
    [
        "........oo......",
        "..o....oYo......",
        ".oYo...oyYo.....",
        ".oyo..oYPYo..o..",
        "..oYooYPPYo.oYo.",
        "..oyYoPwPYooyYo.",
        "..oYyPPwPYyoYo..",
        "..oyYPwwPPYyYo..",
        "..oyYPwwwPYYEo..",
        "..oEyYPPPYYyEo..",
        "...oEyyYYyyEo...",
        "....ooEEEEoo....",
    ],
]
_DYING = [
    "................",
    "................",
    "................",
    "................",
    "......;.........",
    "..........,.....",
    ".......o........",
    "..o...oYo...o...",
    ".oyo..oYyo.oyo..",
    ".oYyooyPYooYo...",
    "..oEyyYYyyEo....",
    "...ooooooooo....",
]


def _flame(pillar):
    return stamp(stamp(_FLOOR, _GLOW), pillar, 0, 1)


_TRAP = [stamp(_FLOOR, _CIRCLE), stamp(_FLOOR, _CIRCLE), stamp(_FLOOR, _GLOW),
         _flame(_PILLAR[0]), _flame(_PILLAR[1]), _flame(_PILLAR[0]), _flame(_DYING), stamp(_FLOOR, _COOLING)]

# the floor splits along its joints, the circle's red glow showing through, then drops away
_CRACKS = [
    [
        "................",
        "................",
        "................",
        ".....g..........",
        "......g.........",
        ".......g........",
        ".......gg.......",
        "........g.......",
        ".........g......",
        "................",
    ],
    [
        "........g.......",
        "........g.......",
        "........g.......",
        ".....g..g.......",
        "......g.g.......",
        ".......gl.......",
        ".......lg..g....",
        "gggggggllLggggg.",
        "........lggg....",
        "........g.......",
        ".......gg.......",
        "......g.g.......",
        "........g.......",
        "........g.......",
        "........g.......",
    ],
]

_GATE = [
    ".oo..........oo.",
    "oHo..........oHo",
    "oHjo........ojHo",
    ".oHjo......ojHo.",
    "..oHHoooooooHo..",
    "...oIIIIIIIIIo..",
    "..oIiooEoEooiIo.",
    "..oIIIIiiIIIIIo.",
    "..ooIooIoIooIoo.",
    "...oIooIoIooIo..",
    "...oIooIoIooIo..",
    "..oIIIIIIIIIIIo.",
    "..oiiiiiiiiiiio.",
    "...oIooIoIooIo..",
    "...oIooIoIooIo..",
    "...oIooIoIooIo..",
    "...oIooIoIooIo..",
    "...oiooioiooio..",
    "..ooooooooooooo.",
]

TILES = {
    "legend": _TILE_L,
    "floor": [_FLOOR, _FLOOR_B, stamp(_FLOOR, _RUNE), stamp(_FLOOR, _CRACK), stamp(_FLOOR, _STAIN)],
    "wall": [_WALL_PLAIN, _WALL_B],
    "pit": _PIT,
    "spikes": _TRAP,
    "crumble": kit.breaking(_FLOOR, _PIT, _CRACKS, "fgV"),
    "gate": kit.rising(stamp(_FLOOR + _FLOOR, ["o" * 16, "e" * 16], 0, 28), _GATE),
}
