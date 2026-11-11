"""Cult Sanctum: the chest, and the mimic that looks like it. Everything else comes from the frozen v4."""
from sets.sanctum_v3 import *  # noqa: F401,F403
from sets.sanctum_palette import P, PALETTE  # noqa: F401
from core import shadow, stamp

_WOOD = {"W": P["wood"], "D": P["wood_dark"], "I": P["iron"], "Y": P["gold"]}
# ; is only ever a sparkle in the air: it gets no ink, but turns to ink where it touches colour
_CHEST_L = {**_WOOD, "L": P["gold_pale"], ";": P["gold_pale"]}
_MIMIC_L = {**_WOOD, "T": P["ember"]}

# The box is 14 wide: a domed lid (top face, then its front), the seam with the hasp, the body.
_LID = [
    "..oooooooooo..",
    ".oWWIWWWWIWWo.",
    "oWWWIWWWWIWWWo",
    "oDDDIDDDDIDDDo",
]
_SEAM = "ooooooYYoooooo"
_BODY = [
    "oWWWIoYYoIWWWo",
    "oDDDIoYYoIDDDo",
    "oDDDIDDDDIDDDo",
    ".oooooooooooo.",
]
_GROUND = shadow(14, 12, [14, 14, 10])


def _box(top, body=_BODY, x=1, bx=None, by=9):
    """Body with its top row at by; everything above it (lid, seam, mouth) stacked up from there."""
    g = stamp(_GROUND, body, x if bx is None else bx, by)
    return stamp(g, top, x, by - len(top))


def _glint(g, x, y, c="Y"):
    return stamp(g, [c], x, y)


# ---------- chest: shut, candlelight catching one iron strap, then the other ----------
_SHUT = _box(_LID + [_SEAM])
CHEST = ([_SHUT, _glint(_SHUT, 5, 5), _SHUT, _glint(_SHUT, 10, 6), _SHUT], _CHEST_L)

# ---------- chest opening: the key turns, light leaks, the lid swings up on a hoard ----------
# swung right back, the lid shows its plain planks inside, lit gold along the bottom by the hoard
_LID_UP = [
    "..oooooooooo..",
    ".oDDoDDDDoDDo.",
    "oDDDoDDDDoDDDo",
    "oYYYoYYYYoYYYo",
    "oooooooooooooo",
]
_HOARD = [
    "oooooYLYoooooo",
    "ooooYYYYLYoooo",
    "oYLYYYoYYYYLYo",
    "oooooooooooooo",
]
# mid-swing: the lid's strapped front faces up, its underside catches the light that floods out
_LID_SWING = [
    "..oooooooooo..",
    ".oDDIDDDDIDDo.",
    "oDDDIDDDDIDDDo",
    "oYYYYYYYYYYYYo",
]
_FLOOD = ["oYLLLLLLLLLLYo", "oYYLLLLLLLLYYo", "oYYYYLLLLYYYYo", "oooooooooooooo"]
_OPEN = _box(_LID_UP + _HOARD)
CHEST_OPEN = ([
    _glint(_SHUT, 8, 10, "L"),
    _box(_LID + [_SEAM, "oYLLLLLLLLLLYo"]),
    stamp(_box(_LID_SWING + _FLOOD), [";..............;", "", ".;............;"], 0, 2),
    stamp(_OPEN, [".;............;.", "", ";..............;"], 0, 0),
    stamp(_glint(_OPEN, 7, 5, "L"), ["..............;.", "", ";..............."], 0, 0),
    _glint(_OPEN, 12, 6, "L"),
], _CHEST_L)

# ---------- mimic: the same box, but the hasp is a fang, and it licks its lips ----------
# at rest the hasp tapers to a point where the real lock is square
_FANG_BODY = [_BODY[0], "oDDDIoYooIDDDo"] + _BODY[2:]
_REST = _box(_LID + [_SEAM], _FANG_BODY)
# the lid cracks one row: the fang hangs in the gap, the tongue slips out of the right corner...
_LICK_OUT = ["ooooooYooooTTT", "oWWWIoYYoIWWWT"]
# ...and runs back along the lower lip, over the fang, before it slides in again
_LICK_RUN = ["ooTTTTTToooooo", "oWWWIoYYoIWWWo"]


def _lick(mouth, lift=1):
    top = _LID + [_SEAM] + ["oooooooooooooo"] * (lift - 1) + mouth[:1]
    return _box(top, mouth[1:] + _FANG_BODY[1:])


MIMIC = ([_REST, _glint(_REST, 5, 5), _REST, _REST, _lick(_LICK_OUT), _lick(_LICK_RUN)], _MIMIC_L)

_UPPER = ["wwowwowwowwoww", "owoowoowoowoow"]
_LOWER = "owoowoowoowoow"
# the tongue lolls out over the lower jaw and down the front
_LOLL = ["oTTTo", "oTTTo", "oTTo.", ".oo.."]
# fed, it takes its time: the lid up two rows, teeth showing, a slow lick from corner to corner
_SATED = ["owoowoowoowoow", "oooTTTTTTTTTTT", "oWWWIoYYoIWWWT"]
MIMIC_BITE = ([
    _box([_LID[0], _LID[1], _LID[3], _SEAM], _FANG_BODY, x=0),
    _box(_LID + ["owwowwowwowwoo", "oYooYooooooTTo", _LOWER], x=1),
    stamp(_box(_LID + _UPPER + ["oYooYooooooooo", "ooooooooooTTTo", _LOWER], x=2, bx=1), _LOLL, 11, 8),
    stamp(_box(_LID[1:] + ["owowowowowowow"], x=2, bx=2, by=10), ["oTo", ".o."], 11, 10),
    _box(_LID + [_SEAM] + _SATED[:2], _SATED[2:] + _FANG_BODY[1:]),
    _lick(_LICK_RUN),
], _MIMIC_L)
