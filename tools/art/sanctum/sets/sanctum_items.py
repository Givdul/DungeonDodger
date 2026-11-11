"""Cult Sanctum, big polish: items. Everything else comes from the frozen v3."""
from sets.sanctum_v3 import *  # noqa: F401,F403
from sets.sanctum_palette import P, PALETTE  # noqa: F401
from core import mirror, shadow, shift, stamp


# ---------- pickup: a cult coin in candle gold, stamped with the sanctum's sigil, spinning ----------
_COIN_L = {"L": P["gold_pale"], "Y": P["gold"], "y": P["gold_dark"], ";": P["gold_pale"]}
# flat gold, shade only on the lower right, the sigil stamped in the shade tone
_COIN_FACE = [
    "...ooo...",
    "..oLYYo..",
    ".oLYYYYo.",
    "oYyYYYyYo",
    "oYYyYyYYo",
    "oYYYyYYyo",
    ".oYYYYyo.",
    "..oyyyo..",
    "...ooo...",
]
_COIN_TURN = [
    "..ooo..",
    ".oLYYo.",
    "oLYYYYo",
    "oYyYyYo",
    "oYYyYYo",
    "oYYYYyo",
    "oYYYyyo",
    ".oyyyo.",
    "..ooo..",
]
_COIN_EDGE = [
    ".oo.",
    "oLYo",
    "oYYo",
    "oYyo",
    "oYyo",
    "oYyo",
    "oYyo",
    "oyyo",
    ".oo.",
]


def _coin(art, lift, glint=None, star=None):
    w = len(art[0])
    x = (16 - w + 1) // 2
    if glint:
        art = stamp(art, ["w"], *glint)
    g = stamp(shadow(8, 12, [4, 6, 4]), art, x, 2 + lift)
    return stamp(g, star, 9, lift) if star else g


_STAR = [".;.", ";;;", ".;."]
_TWINKLE = ["...", ".;.", "..."]
# a slow turn, then a twinkle off the rim while it rests
PICKUP = ([_coin(_COIN_FACE, 0, (2, 2)), _coin(_COIN_FACE, -1, (3, 1)), _coin(_COIN_TURN, -1),
           _coin(_COIN_EDGE, -1), _coin(mirror(_COIN_TURN), -1), _coin(_COIN_FACE, 0),
           _coin(_COIN_FACE, 0, star=_STAR), _coin(_COIN_FACE, 0, star=_TWINKLE)], _COIN_L)

# ---------- key: iron, with a horned bow ----------
_KEY_L = {"K": P["iron"], "H": P["bone"]}
# a bone ring for a bow, an iron shaft, two teeth; flat, the ink rounds the ring's corners
_KEY = [
    "..HH.........",
    ".HHHH........",
    "HHooHHKKKKKKK",
    "HHooHHKKKKKKK",
    ".HHHH...KK.K.",
    "..HH....KK.K.",
]
# a glint runs from the bow down the shaft to the tip, then the key rests
_KEY_GLINT = [(1, 1), (7, 2), (10, 2), (12, 2), None, None]


def _key(i):
    lift = (0, -1, -1, -1, 0, 0)[i]
    k = _KEY
    if _KEY_GLINT[i]:
        k = stamp(k, ["w"], *_KEY_GLINT[i])
    return stamp(shadow(10, 11, [8, 10, 8]), k, 1, 4 + lift)


KEY = ([_key(i) for i in range(6)], _KEY_L)

# ---------- chest: a mimic that licks its lips ----------
_MIMIC_L = {"W": "#6e4636", "D": "#523327", "I": "#7a7282", "i": "#5a5262", "T": "#a33a48",
            "t": "#7a2836", "Y": "#e1b553"}
_LID = [
    "..oooooooooooo..",
    ".oWWIWWWWWWIWWo.",
    ".oDDiDDDDDDiDDo.",
    ".oowowowowowowo.",
]
_BODY = [
    ".oiowowowowowio.",
    ".oWWIWWoIoWIWWo.",
    ".oDDiDDoioDiDDo.",
    ".oDDiDDDDDDiDDo.",
    "..oooooooooooo..",
]
# what shows between the jaws, top to bottom; the lid rises by one row per row here
_MOUTHS = {
    "shut": [],
    "peek": [".oooooYooYooooo."],
    "gape": [".ooooooooooTTTo.", ".ooooooooootTto."],
    "lick": [".ooooooooooTTTTT", ".oooooooooottTto"],
    "sweep": [".oooTTTTTTttooo.", ".ooTToooooooooo."],
    "slurp": [".oooooooooTTtoo."],
}


def _chest(mouth, glint=None):
    lid = stamp(_LID, ["w"], glint, 1) if glint else _LID
    g = lid + _MOUTHS[mouth] + _BODY
    if mouth == "lick":
        g = stamp(g, ["...............T"], 0, 3)
    # one column left of centre, so the tongue has room for its ink at the right edge
    return stamp(shift(shadow(14, 12, [14, 14, 10]), -1), g, -1, 13 - len(g))


# it breathes, eyes glinting in the crack, settles, peeks again, then gapes and licks its lips
CHEST = ([_chest("shut"), _chest("peek"), _chest("shut", 4), _chest("peek"),
          _chest("gape"), _chest("lick"), _chest("sweep"), _chest("slurp")], _MIMIC_L)

# ---------- potion: a gold goblet brimming with blood, a heart rising off it ----------
_GOB_L = {"Y": P["gold"], "y": P["gold_dark"], "R": P["blood"], ",": P["life"], ";": P["white"]}
_GOBLET = [
    ".ooooooo.",
    "oRwRRRRRo",
    "oYYYYYYyo",
    "oYYYRYYyo",
    ".oYYYYyo.",
    "..oYYyo..",
    "...oyo...",
    "..oYYyo..",
    "..ooooo..",
]
_HEART = [",,.,,", ",;,,,", ".,,,.", "..,.."]
_HEART_SMALL = [",.,", ".,."]
_HEART_FADE = [",.,", ".,."]
# a heart wells up off the blood and floats away; then a drop runs down the bowl
_POTION_FX = [
    (_HEART_SMALL, 7, 3, None), (_HEART, 6, 1, None), (_HEART, 6, 0, None), (_HEART_FADE, 7, 0, None),
    (None, 0, 0, (8, 1)), (None, 0, 0, (8, 2)), (None, 0, 0, (8, 3)), (None, 0, 0, (7, 4)),
]


def _potion(heart, hx, hy, drip):
    cup = stamp(_GOBLET, ["R"], *drip) if drip else _GOBLET
    g = stamp(shadow(8, 13, [6, 8, 6]), cup, 4, 5)
    return stamp(g, heart, hx, hy) if heart else g


POTION = ([_potion(*fx) for fx in _POTION_FX], _GOB_L)


# ---------- the coin collected: it hops, flashes, bursts into sparks and is gone ----------
_TAKEN_L = {**_COIN_L, ",": P["gold_pale"], ";": P["white"]}
_COIN_FLASH = [r.replace("o", ".").translate(str.maketrans("LYy", ";;;")) for r in _COIN_FACE]
_BURST = [
    "....;.....;....",
    "...............",
    ".....,...,.....",
    ";.............;",
    "...,.......,...",
    "...............",
    "...,.......,...",
    ";.............;",
    ".....,...,.....",
    "...............",
    "....;.....;....",
]
_BURST_WIDE = [
    "..;.........;..",
    "...............",
    "...............",
    "...............",
    ",.............,",
    "...............",
    "...............",
    "...............",
    "...............",
    "...............",
    "..,.........,..",
]


def _spark(art, top, shadow_rows):
    g = shadow(8, 12, shadow_rows) if shadow_rows else ["." * 16] * 16
    return stamp(g, art, (16 - len(art[0])) // 2, top)


PICKUP_TAKEN = ([_coin(_COIN_FACE, -2, (2, 2)), _spark(_COIN_FLASH, -1, [2, 4, 2]),
                 _spark(_BURST, 0, None), _spark(_BURST_WIDE, 0, None), ["." * 16] * 16], _TAKEN_L)

# ---------- the key collected: it lifts, flashes white, glints off both ends and is gone ----------
_KEY_TAKEN_L = {**_KEY_L, ";": P["white"]}
_KEY_FLASH = [r.replace("o", ".").translate(str.maketrans("HK", ";;")) for r in _KEY]
_GLINTS = [
    ".;...........;.",
    ";;;.........;;;",
    ".;...........;.",
]
_GLINTS_WIDE = [
    "...............;",
    "................",
    "................",
    ";...............",
    "................",
    "................",
    "................",
    "................",
    ";..............;",
]


def _key_up(art, lift, shadow_rows, glint=None):
    if glint:
        art = stamp(art, ["w"], *glint)
    g = shadow(10, 11, shadow_rows) if shadow_rows else ["." * 16] * 16
    return stamp(g, art, 1, 4 + lift)


KEY_TAKEN = ([_key_up(_KEY, -2, [8, 10, 8], (1, 1)), _key_up(_KEY, -3, [6, 8, 6], (12, 2)),
              _key_up(_KEY_FLASH, -4, [4, 6, 4]), stamp(["." * 16] * 16, _GLINTS, 1, 1),
              stamp(["." * 16] * 16, _GLINTS_WIDE, 0, 0), ["." * 16] * 16], _KEY_TAKEN_L)

# ---------- HUD: one life, the goblet's heart ----------
_LIFE_L = {"H": P["life"], "h": P["blood"]}
LIFE_ICON = ([[
    ".oo.oo..",
    "oHwoHHo.",
    "oHHHHHo.",
    "oHHHHho.",
    ".oHHho..",
    "..oho...",
    "...o....",
    "........",
]], _LIFE_L)

# ---------- HUD: the iron frame that holds the key ----------
# its outer 3px are the frame, because the game also draws it as a 9-slice button with 3px margins
_BOX_L = {"L": P["iron_lit"], "K": P["iron"], "k": P["iron_dark"], "D": P["deep"]}
_BOX = [
    ".oooooooooooooo.",
    "oKLLLLLLLLLLLLKo",
    "oLooooooooooooko",
    "oLoDDDDDDDDDDDko",
    "oLoDDDDDDDDDDDko",
    "oLoDDDDDDDDDDDko",
    "oLoDDDDDDDDDDDko",
    "oLoDDDDDDDDDDDko",
    "oLoDDDDDDDDDDDko",
    "oLoDDDDDDDDDDDko",
    "oLoDDDDDDDDDDDko",
    "oLoDDDDDDDDDDDko",
    "oLoDDDDDDDDDDDko",
    "oLoDDDDDDDDDDDko",
    "oKkkkkkkkkkkkkKo",
    ".oooooooooooooo.",
]
ITEM_BOX = ([_BOX], _BOX_L)
