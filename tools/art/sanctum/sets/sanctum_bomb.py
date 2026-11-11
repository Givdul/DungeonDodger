"""Cult Sanctum: the skull bomb, in flight, landing marker and blast."""
from sets.sanctum_v3 import *  # noqa: F401,F403
from core import stamp, shadow
from sets.sanctum_palette import P, PALETTE  # noqa: F401

# ---------- bomb: a skull burning on the floor, its fire and eyes building until it blows ----------
_SKULL_L = {"B": P["bone"], "Y": P["gold"], "E": P["ember"], "P": P["gold_pale"]}
_SKULL = [
    "....ooooooooo...",
    "...oBBBBoBBBo...",
    "..oBBBBBBoBBBo..",
    "..oBooBBBooBBo..",
    "..oBoEBBBoEBBo..",
    "..oBBBBoBBBBBo..",
    "...ooBoBoBoBo...",
    ".....ooooooo....",
]
# A teardrop of fire on the cracked crown that climbs and sways, licking off a loose tongue above it, while
# the eye sockets go from embers to white-hot through the loop. On the last frame the skull rattles.
_SKULL_FIRE_H = [2, 3, 3, 4, 4, 5]
_SKULL_SWAY = [0, 1, 1, 0, -1, -1]
_SKULL_EYES = ["E", "E", "E", "Y", "Y", "P"]


def _skull_fire(t):
    h, sway = _SKULL_FIRE_H[t], _SKULL_SWAY[t]
    g = ["." * 16] * 16
    for d in range(h):
        w = max(1, 5 - (d * 5) // h)
        x = 8 - w // 2 + (sway if d >= h // 2 else 0)
        if w >= 3:
            inner = ("P" if d == 0 and t >= 2 else "Y") * (w - 2)
            row = "E" + inner + "E"
        else:
            row = ("Y" if d < h - 1 else "E") * w
        g = stamp(g, [row], x - (w == 5), 5 - d)
    tip = max(1, 5 - h - 1)   # the loose tongue, split off by a gap of ink
    g = g if tip >= 5 - h else stamp(g, ["E"], 8 + sway + (1 if t % 2 else -1), tip)
    return g


def _bomb(t):
    g = stamp(["." * 16] * 16, _skull_fire(t))
    g = stamp(g, [r.replace("E", _SKULL_EYES[t]) for r in _SKULL], 0, 6)
    return stamp(shadow(10, 13, [8, 10, 8]), g, 1 if t == 5 else 0, 0)


BOMB = ([_bomb(t) for t in range(6)], _SKULL_L)


def _blank(w=16, h=16):
    return ["." * w] * h


def _turn(g, quarters):
    """Rotates a square grid clockwise by quarter turns."""
    for _ in range(quarters % 4):
        g = ["".join(g[len(g) - 1 - x][y] for x in range(len(g))) for y in range(len(g[0]))]
    return g


# ---------- in flight: the same skull tumbling end over end, its crown fuse spitting sparks ----------
# The skull is centred on the cell so it turns about its own middle. The fuse is a short flame on the
# crack in the crown that turns with it; loose sparks fall behind the flight (below on the way up,
# above on the way down). ';' and ',' are sparks without ink, like his.
_FLIGHT_L = {"B": P["bone"], "Y": P["gold"], "E": P["ember"], "P": P["gold_pale"], ";": P["gold_pale"],
             ",": P["ember"]}
_FUSE = [  # the flight flame at two flickers: tip leaning left, then right
    ["......E.........",
     "......EY........",
     ".....EYPE......."],
    ["........E.......",
     ".......YE.......",
     "......EPYE......"],
]


# The tumble's in-between frames, drawn by hand rather than turned: the skull tilted about 45 degrees with
# its crown and fuse leaning right, then left, so the sockets and teeth still read. Frames 0 and 2 are the
# upright and upside-down skull. The left tilt is the right one mirrored, with the sockets kept as the
# approved skull draws them (ember low on the right).
_TILT_RIGHT = [
    "............E...",
    "...........YE...",
    ".......ooooPYE..",
    "......oBBBBoE...",
    ".....oBBBBBo....",
    "....oBooBBBBo...",
    "...oBBoEBBBBBo..",
    "..oBBBBBBBBBBo..",
    "..ooBBoBBooBBo..",
    "...oBoBBBoEBo...",
    "....ooBoBBBBo...",
    ".....ooBoBBo....",
    "......ooBoo.....",
    ".......oo.......",
    "................",
    "................",
]
_TILT_LEFT = [
    "...E............",
    "...EY...........",
    "..EYPoooo.......",
    "...EoBBBBo......",
    "....oBBBBBo.....",
    "...oBBBBooBo....",
    "..oBBBBBoEBBo...",
    "..oBBBBBBBBBBo..",
    "..oBBooBBoBBoo..",
    "...oBEoBBBoBo...",
    "...oBBBBoBoo....",
    "....oBBoBoo.....",
    ".....ooBoo......",
    ".......oo.......",
    "................",
    "................",
]


def _tumbler(quarter, flicker):
    if quarter % 4 == 1:
        return _TILT_RIGHT
    if quarter % 4 == 3:
        return _TILT_LEFT
    g = stamp(_blank(), _FUSE[flicker], 0, 1)
    g = stamp(g, _SKULL, 0, 4)
    return _turn(g, quarter)


# Where the sparks are, per frame, for the way up. The way down mirrors them top to bottom.
_SPARKS_UP = [
    [(5, 14, ";"), (9, 15, ",")],
    [(3, 13, ","), (8, 14, ";"), (11, 15, ",")],
    [(4, 15, ";"), (10, 13, ";")],
    [(6, 13, ";"), (12, 14, ","), (2, 15, ",")],
]


def _flight(t, down):
    g = _tumbler(t, t % 2)
    for x, y, c in _SPARKS_UP[t]:
        y = 15 - y if down else y
        if g[y][x] == ".":
            g = stamp(g, [c], x, y)
    return g


BOMB_UP = ([_flight(t, False) for t in range(4)], _FLIGHT_L)
BOMB_DOWN = ([_flight(t, True) for t in range(4)], _FLIGHT_L)


# ---------- landing marker: a summoning ring scratched on the floor, its four runes lighting in turn ----------
_MARK_L = {"R": P["blood"], "E": P["ember"], "Y": P["gold"]}
# Full width and low in the cell, so its sides and runes still show round the skull once it lands.
_RING = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "....oooooooo....",
    "..ooRRRRRRRRoo..",
    ".oRRoo....ooRRo.",
    "oRoo........ooRo",
    "oRo....ER....oRo",
    "oRo....RE....oRo",
    "oRoo........ooRo",
    ".oRRoo....ooRRo.",
    "..ooRRRRRRRRoo..",
    "....oooooooo....",
]
_RUNES = [(7, 7), (14, 10), (7, 14), (1, 10)]   # top, right, bottom, left: the 2px mark at each


def _rune(g, i, c):
    x, y = _RUNES[i]
    return stamp(g, [c * 2] if i % 2 == 0 else [c, c], x, y)


_MARK_GLOW = ["R", "E", "E", "E"]   # the ring flares, then holds while the lit rune runs round


def _marker(t):
    g = [r.replace("R", _MARK_GLOW[t]) for r in _RING]
    for i in range(4):
        g = _rune(g, i, "Y" if i == t else "E")
    return g


BOMB_MARKER = ([_marker(t) for t in range(4)], _MARK_L)


# ---------- blast: the skull bursts in a ball of candle fire, throws its bones, and smokes away ----------
# Drawn like his: flat chunks split by ink, not a smooth ball. The fire is a cluster of lobes, each with its
# own ink edge, ember on the side facing out and gold toward the middle; one pale heart. The lobes turn to
# smoke where they were, and the smoke drifts out and thins to nothing.
_BLAST_L = {"E": P["ember"], "Y": P["gold"], "P": P["gold_pale"], "B": P["bone"], "S": P["iron"],
            ",": P["iron"]}
_MID = (16, 16)


def _disc(g, cx, cy, r, c):
    rows = [list(row) for row in g]
    for y in range(len(rows)):
        for x in range(len(rows[0])):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + r * 0.6:
                rows[y][x] = c
    return ["".join(row) for row in rows]


def _inward(cx, cy, d):
    """A point d pixels from (cx, cy) toward the middle of the blast."""
    dx, dy = _MID[0] - cx, _MID[1] - cy
    n = max(1, (dx * dx + dy * dy) ** 0.5)
    return cx + round(dx * d / n), cy + round(dy * d / n)


def _lobe(g, cx, cy, r):
    g = _disc(g, cx, cy, r + 1, "o")
    g = _disc(g, cx, cy, r, "E")
    if r <= 2:   # a small lick is ember with one gold pixel, not a gold cross
        return stamp(g, ["Y"], *_inward(cx, cy, 1))
    return _disc(g, *_inward(cx, cy, 1 + r // 3), r - 1 - r // 4, "Y")


def _fire(g, lobes, heart=None):
    for cx, cy, r in lobes:
        g = _lobe(g, cx, cy, r)
    if heart:
        g = _disc(g, *heart, "P")
    return g


def _cloud(g, cx, cy, r):
    """A puff of smoke: a round crown on two smaller bumps, each bump edged in ink so the lumps show.
    The smallest is a 2x2 scrap, which the build rounds off with ink."""
    if r <= 1:
        return stamp(g, ["SS", "SS"], cx, cy)
    for x, y, pr in [(cx - r + 1, cy + 1, r - 1), (cx + r - 1, cy + 1, r - 1), (cx, cy - 1, r)]:
        g = _disc(g, x, y, pr + 1, "o")
        g = _disc(g, x, y, pr, "S")
    return g


def _smoke(g, clouds):
    for cloud in clouds:
        g = _cloud(g, *cloud)
    return g


# Bones of the skull: a jaw with teeth, a piece of crown, a tooth and two splinters, each flying out
# along its own path, one position per frame.
_SHARD_SHAPES = [["BBBo", "BoBo"], ["BBB", ".BB"], ["B", "B"], ["BB"], ["B"]]
_SHARD_PATHS = [
    [(11, 18), (5, 22), (2, 25), (0, 27)],
    [(17, 10), (22, 5), (26, 2), (29, 0)],
    [(20, 19), (25, 22), (28, 25), (30, 28)],
    [(12, 11), (6, 7), (3, 4), None],
    [(16, 20), (16, 26), (17, 29), None],
]


def _shards(g, step):
    for shape, path in zip(_SHARD_SHAPES, _SHARD_PATHS):
        if step < len(path) and path[step]:
            g = stamp(g, shape, *path[step])
    return g


def _blast(t):
    g = _blank(32, 32)
    if t == 0:    # the flash: the skull splits round a pale-hot heart
        g = _fire(g, [(13, 15, 3), (19, 15, 3), (16, 18, 3), (16, 13, 3)], (16, 15, 2))
        g = _shards(g, 0)
    elif t == 1:  # the ball swells in lobes and throws the bones out
        g = _fire(g, [(16, 16, 6), (9, 14, 3), (22, 12, 5), (11, 21, 4), (22, 21, 3), (14, 9, 4)], (15, 14, 3))
        g = _shards(g, 1)
    elif t == 2:  # at its fullest; the heart has cooled, smoke boils off the top
        g = _smoke(g, [(12, 6, 3), (19, 5, 3)])
        g = _fire(g, [(8, 14, 4), (24, 11, 5), (9, 22, 3), (23, 22, 4), (15, 25, 3), (16, 16, 7), (13, 9, 4)],
                  (15, 14, 1))
        g = _shards(g, 2)
    elif t == 3:  # the lobes go to smoke where they were; a knot of fire is left in the middle
        g = _smoke(g, [(8, 12, 4), (16, 6, 4), (24, 12, 4), (8, 21, 3), (24, 21, 3), (16, 25, 3)])
        g = _fire(g, [(17, 18, 2), (16, 15, 4)])
        g = _shards(g, 3)
    elif t == 4:  # the smoke rolls out; the fire dies to a lick
        g = _smoke(g, [(6, 10, 3), (16, 4, 3), (26, 10, 3), (6, 22, 3), (26, 22, 3), (16, 27, 2)])
        g = _fire(g, [(16, 16, 2)])
    elif t == 5:  # the fire is gone; the smoke drifts and shrinks
        g = _smoke(g, [(5, 8, 2), (16, 3, 2), (27, 8, 2), (5, 23, 2), (27, 23, 2), (16, 28, 1)])
    elif t == 6:  # last scraps
        g = _smoke(g, [(4, 7, 1), (17, 2, 1), (28, 6, 1), (4, 24, 1), (27, 25, 1)])
    else:         # wisps, then nothing
        for x, y in [(3, 5), (29, 4), (3, 26), (17, 1)]:
            g = stamp(g, [","], x, y)
    return g


BOMB_BLAST = ([_blast(t) for t in range(8)], _BLAST_L)
