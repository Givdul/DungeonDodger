"""Cult Sanctum, big polish: tiles. Everything else comes from the frozen v3."""
from sets.sanctum_v3 import *  # noqa: F401,F403
from core import stamp
from sets.sanctum_palette import P, PALETTE  # noqa: F401

_TILE_L = {
    "F": P["floor"], "f": P["floor"], "h": P["brick"], "g": P["grout"],                 # floor, falling slab, lit edge, grout
    "K": P["deep"], "B": P["brick"], "b": P["floor"], "e": P["void"], "C": P["brick"],  # mortar, brick, brick shade, deep edge, coping
    "s": P["deep"],                                                                     # wall's shadow on the floor
    "Y": P["gold"], "y": P["ember"], "W": P["bone"], "q": P["void"],                    # flame, ember, wax, niche
    "v": P["void"], "V": P["deep"], "X": P["grout"], "L": P["blood"],                   # void, shaft wall, lit course, red glow
    "E": P["ember"], "R": P["blood"], "U": P["ember"], "n": P["blood"], "G": P["blood_dark"],  # glow, flame tip, rune lit, rune dull, warm floor
    "d": P["grout"], "z": P["deep"],                                                    # dried stain, the smoulder far down the pit
    "I": P["iron"], "i": P["iron_dark"], "H": P["bone"], "j": P["bone_dark"],           # iron, horn
    "P": P["gold_pale"], ";": P["gold"], ",": P["ember"], "w": P["white"],              # flame core, sparks, the hottest pixel
}

_FLOOR = ["F" * 15 + "g"] * 15 + ["g" * 16]
_RUNE = [
    "", "", "", "",
    ".......g........",
    "......g.g.......",
    ".....g...g......",
    "......g.gh......",
    ".......gh.......",
    "......g.g.......",
    ".....gh..gh.....",
]
_CHIP = [
    "", "", "", "", "", "", "", "", "", "", "",
    ".........h......",
    ".........g...hhg",
    "............hggg",
    "...........hgggg",
]
_STAIN = [
    "", "", "", "", "", "", "", "",
    "...dd...........",
    "..dddd..........",
    "...ddddd........",
    ".....dddd.......",
    ".......dd...d...",
    "..........d.....",
]

def _brick_row(y):
    """One row of the wall's face: courses three rows high, the joints staggered, each brick's ends darker."""
    course, row = (y // 4) % 2, y % 4
    if row == 3:
        return "K" * 9
    seam = 5 if course == 0 else 2
    out = []
    for x in range(9):
        if x == seam:
            out.append("K")
            continue
        end = x == seam - 1 or x == 8
        out.append("b" if row == 2 or (end and row == 1) else "B")
    return "".join(out)


def _wall_base():
    """Coursed stone, the wall's coping, its dark face, then its shadow on the floor."""
    return [_brick_row(y) + ("h" if y % 8 == 0 else "C") + "e" + "s" + "g" + _FLOOR[y][13:] for y in range(16)]


_ALCOVE = [
    "..KKK..",
    ".KeUeK.",
    "KeYPYeK",
    "KeqyqeK",
    "KeqWqeK",
    "KeqWqeK",
    "KejWjeK",
    "KhhhhhK",
]
_WALL_PLAIN = _wall_base()
_WALL_B = stamp(_wall_base(), _ALCOVE, 1, 2)

# the shaft: its stone lip, the far wall going down into the dark; far below, a circle still smoulders
_PIT = stamp(["h" * 15 + "g",
              "XXXXXKXXXXXXXXKX",
              "XXXXXKXXXXXXXXKX",
              "eeeeeeeeeeeeeeee",
              "VVeVVVVVVVVeVVVV",
              "VVeVVVVVVVVeVVVV",
              "vvvvvvvvvvvvvvvv",
              "v" * 16] + ["v" * 16] * 8, [
    "", "", "", "", "", "", "", "", "",
    "......zzzz......",
    "....zz....zz....",
    "...z........z...",
    "....zz....zz....",
    "......zzzz......",
])

# the trap: a summoning circle drawn in old blood; its sigil lights, it bursts into flame
_RING = [
    "", "",
    "......nnnn......",
    "....nn....nn....",
    "...n........n...",
    "...n........n...",
    "..n..........n..",
    "..n..........n..",
    "..n..........n..",
    "..n..........n..",
    "...n........n...",
    "...n........n...",
    "....nn....nn....",
    "......nnnn......",
]
_SIGIL = [
    "", "", "",
    ".......nn.......",
    "......n..n......",
    "......n..n......",
    ".....n....n.....",
    ".....n....n.....",
    "....n......n....",
    "....n......n....",
    "....nnnnnnnn....",
]
_EYE = ["", "", "", "", "", "", "", ".......nn.......", ".......nn......."]
_DISC = [
    "", "", "",
    "......nnnn......",
    "....nnnnnnnn....",
    "....nnnnnnnn....",
    "...nnnnnnnnnn...",
    "...nnnnnnnnnn...",
    "...nnnnnnnnnn...",
    "...nnnnnnnnnn...",
    "....nnnnnnnn....",
    "....nnnnnnnn....",
    "......nnnn......",
]


def _paint(g, c):
    return [r.replace("n", c) for r in g]


def _circle(ring, sigil, eye=None, disc=None):
    g = _FLOOR
    if disc:
        g = stamp(g, _paint(_DISC, disc))
    g = stamp(stamp(g, _paint(_RING, ring)), _paint(_SIGIL, sigil))
    return stamp(g, _paint(_EYE, eye)) if eye else g


_DIM = _circle("n", "L")
_WAKING = _circle("U", "n", "Y")
_WARN = stamp(_circle("U", "Y", "P", "G"), ["", "", "", "", ".........;......", "", "......,........."])
_LIT = _circle("E", "Y", "P", "G")
_EMBERS = _circle("U", "n", None, "G")
_COOLING = _circle("R", "n", "E")
_TONGUES = [
    [
        "........o.......",
        ".......oEo......",
        ".......oyEo.....",
        "..o...oyYyo.....",
        ".oEo..oYPYo..o..",
        ".oyEo.oYPYo.oEo.",
        ".oyYoyPPPPYoyYo.",
        "..oyYyPPPPYyYyo.",
        "..oyYYPPwPPYYyo.",
        "...yYPPPPPPYy...",
        "....yYPPPPYy....",
        "....EyYPPYyE....",
        "......yYYy......",
    ],
    [
        ".......o........",
        "......oEo.......",
        "......oEyo...,..",
        "..o..oyYyo......",
        ".oEo.oYPYo...o..",
        ".oyEooYPPYo.oEo.",
        ".oyYoYPPPPYoyYo.",
        "..oyYyPPPPYyYyo.",
        "..oyYYPPwPPYYyo.",
        "...yYPPPPPPYy...",
        "....yYPPPPYy....",
        "....EyYPPYyE....",
        "......yYYy......",
    ],
    [
        "..,......o......",
        "........oEo.....",
        "........oyEo.o..",
        "...o...oyYo.oEo.",
        "..oEo.oyPYo.oyo.",
        "..oyEoYPPYooYyo.",
        ".oyYYoPPPPYoYyo.",
        "..oyYyPPPPYyYyo.",
        "..oyYYPPwPPYYyo.",
        "...yYPPPPPPYy...",
        "....yYPPPPYy....",
        "....EyYPPYyE....",
        "......yYYy......",
    ],
]
_DYING = [
    "", "",
    "..........;.....",
    "....,...........",
    "................",
    ".......;........",
    "................",
    "................",
    "........o.......",
    ".......oEo......",
    "...o..oyYyo.o...",
    "..oEyoyYPYyoEo..",
    "....yEYPPYEy....",
]


def _burn(tongues):
    return stamp(_LIT, tongues)


_TRAP = [_DIM, _WAKING, _WARN, _burn(_TONGUES[0]), _burn(_TONGUES[1]), _burn(_TONGUES[2]), stamp(_EMBERS, _DYING),
         _COOLING]

# the floor cracks from one point, red glow leaks through, the slabs part and drop into the shaft
_SLABS = [
    "AAAAAAAAA.BBBBBB",
    "AAAAAAAAA.BBBBBB",
    "AAAAAAAA.BBBBBBB",
    "AAAAAAAA.BBBBBBB",
    "AAAAAAA.BBBBBBBB",
    "AAAAAAA.BBBBBBBB",
    "AAAAAA.BBBBBBBBB",
    "......C.BBBBBBBB",
    "CCCCCCC.....BBBB",
    "CCCCCCCC.DDD....",
    "CCCCCCCC.DDDDDDD",
    "CCCCCCCCC.DDDDDD",
    "CCCCCCCCC.DDDDDD",
    "CCCCCCCCCC.DDDDD",
    "CCCCCCCCCC.DDDDD",
    "CCCCCCCCCCC.DDDD",
]
_HUB = (6.5, 7.5)


def _crack_px(reach):
    return [(x, y) for y in range(16) for x in range(16)
            if _SLABS[y][x] == "." and (x - _HUB[0]) ** 2 + (y - _HUB[1]) ** 2 <= reach ** 2]


def _cracked(reach, ink, glow=()):
    g = [list(r) for r in _FLOOR]
    for x, y in _crack_px(reach):
        g[y][x] = ink
    for x, y, c in glow:
        g[y][x] = c
    return ["".join(r) for r in g]


def _parted():
    """The slabs pulled apart: every crack two pixels wide, the glow from below in the gap."""
    g = [list(r) for r in _FLOOR]
    for x, y in _crack_px(30):
        g[y][x] = "L"
        for nx, ny in ((x + 1, y), (x, y + 1)):
            if nx < 16 and ny < 16 and _SLABS[ny][nx] != ".":
                g[ny][nx] = "o"
    for x, y in ((6, 7), (7, 8), (8, 9), (7, 6)):
        g[y][x] = "E"
    return ["".join(r) for r in g]


def _falling(scale, drop, rim, face, side):
    """Each slab shrunk towards its own middle and dropped: smaller, darker and deeper as it falls."""
    g = [list(r) for r in _PIT]
    mids = {}
    for p in "ABCD":
        px = [(x, y) for y in range(16) for x in range(16) if _SLABS[y][x] == p]
        mids[p] = (sum(x for x, _ in px) / len(px), sum(y for _, y in px) / len(px))
    lit = set()
    for p, (mx, my) in mids.items():
        for y in range(16):
            for x in range(16):
                sx, sy = round(mx + (x - mx) / scale), round(my + (y - drop - my) / scale)
                if 0 <= sx < 16 and 0 <= sy < 16 and _SLABS[sy][sx] == p:
                    lit.add((x, y))
    for x, y in lit:
        g[y][x] = rim if (x, y - 1) not in lit or (x - 1, y) not in lit else face
        if y + 1 < 16 and (x, y + 1) not in lit:
            g[y + 1][x] = side
    return ["".join(r) for r in g]


_CRUMBLE = [_cracked(3.6, "g", [(6, 7, "o")]),
            _cracked(7, "g", [(6, 7, "o"), (7, 6, "o"), (7, 8, "o")]),
            _cracked(30, "o", [(6, 7, "E"), (7, 8, "L"), (5, 7, "L"), (7, 5, "L")]), _parted(),
            _falling(0.8, 1, "h", "f", "e"), _falling(0.55, 3, "f", "g", "e"), _falling(0.3, 5, "g", "X", "v"), _PIT]

# a horned iron gate with a ward plate, pushing up out of a slot in the floor
_GATE_HALF = [
    ".o......",
    "oHo.....",
    "oHjo....",
    ".ojHoooo",
    "..ojHoIU",
    ".oIIIoUY",
    ".oiYioiU",
    ".ooooooo",
    ".oIioIio",
    ".oIioIio",
    ".oIioIio",
    ".oIioIio",
    ".oIioIio",
    ".oIioIio",
    ".ooooooo",
    ".oIIIIII",
    ".oiYiiii",
    ".ooooooo",
    ".oIioIio",
    ".oIioIio",
    ".ooiooio",
]
_GATE = [r + r[::-1] for r in _GATE_HALF]
_SLOT = stamp(_FLOOR + _FLOOR, ["o" * 16, "iiiIiiiiiiiiIiii"], 0, 28)


# how much of the gate shows in each frame of its closing: the horn tips break the slot, then it climbs
_GATE_RISE = [0, 1, 3, 7, 11, 15, 19, 21]


def _gate_frames():
    return [stamp(_SLOT, _GATE[:h], 0, 28 - h) if h else _SLOT for h in _GATE_RISE]


# the start line: a gold band inlaid across the floor between two grooves, a ward stud on every slab
_LINE = stamp(_FLOOR, [
    "", "", "",
    ".......K........",
    "......KYK.......",
    "KKKKKKYPYKKKKKKK",
    "YYYYYKPPPKYYYYYY",
    "YYYYYKPPPKYYYYYY",
    "KKKKKKYPYKKKKKKK",
    "......KYK.......",
    ".......K........",
])

# the hole's top edge: the floor's lit lip and its face dropping into the shaft, as the pit tile starts
_PIT_LIP = _PIT[:6]


TILES = {
    "legend": _TILE_L,
    "floor": [_FLOOR, _FLOOR, stamp(_FLOOR, _RUNE), stamp(_FLOOR, _CHIP), stamp(_FLOOR, _STAIN)],
    "wall": [_WALL_PLAIN, _WALL_B],
    "pit": _PIT,
    "line": _LINE,
    "pit_lip": _PIT_LIP,
    "spikes": _TRAP,
    "crumble": _CRUMBLE,
    "gate": _gate_frames(),
}
