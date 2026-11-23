"""Cult Sanctum, flat-colour pass: foes. Everything else comes from the frozen v3."""
from sets.sanctum_v3 import *  # noqa: F401,F403
from core import stamp, shadow
from sets.sanctum_palette import P, PALETTE  # noqa: F401


# ---------- flyer: an imp familiar, big grinning head, round belly, one bat wing beating, spade tail ----------
_IMP_L = {"S": P["tan"], "s": P["tan_dark"], "M": P["violet"], "Y": P["gold"]}
_IMP_UP = [  # wing up, tail curled up behind
    "oo......o...o...",
    "oMo....oso.oso..",
    "oMMo..oso...oso.",
    "oMMMo.ossSSSsso.",
    "oMMMMMosSSoSSoSo",
    "oMMMMMoSSSYSSYSo",
    ".oMoMMosSoSSSSSo",
    "..o.oMoosSoooooo",
    "......oo.osSwSwo",
    "..o...oSoooooo..",
    ".oSo.oSSSoSSo...",
    "oSSo.oSSSoSSo...",
    ".ooSoosSsooSo...",
    "...oSSSooo.o....",
    "....ooo.........",
]
_IMP_SPREAD = [  # wing spread back, tail swinging out
    "........o...o...",
    ".......oso.oso..",
    "......oso...oso.",
    "ooooo.ossSSSsso.",
    "oMMMMoosSSoSSoSo",
    "oMMMMMoSSSYSSYSo",
    "oMMMMMosSoSSSSSo",
    ".oMoMMoosSoooooo",
    ".oMo.ooo.osSwSwo",
    "..o...oSoooooo..",
    "......oSSoSSo...",
    ".....oSSSoSSo...",
    "oSo..osSsooSo...",
    "oSSSSSSoooo.o...",
    ".oooooo.........",
]
_IMP_DOWN = [  # wing swept down, tail hanging
    "........o...o...",
    ".......oso.oso..",
    "......oso...oso.",
    "......ossSSSsso.",
    "......osSSoSSoSo",
    "......oSSSYSSYSo",
    "......osSoSSSSSo",
    ".....ooosSoooooo",
    "...ooMMo.osSwSwo",
    "..oMMMMoSoooooo.",
    ".oMMMMoSSoSSo...",
    "oMMMMoSSSoSSo...",
    "oMMoMosSsooSo...",
    "oMo.oSoooooo....",
    ".ooSSo..........",
    "..oo............",
]
_IMP_RISE = [  # wing rising, folded
    "........o...o...",
    ".......oso.oso..",
    "oo....oso...oso.",
    "oMoo..ossSSSsso.",
    "oMMMooosSSoSSoSo",
    ".oMMMMoSSSYSSYSo",
    "..oMMMosSoSSSSSo",
    "...oMMoosSoooooo",
    "....oooo.osSwSwo",
    "......oSoooooo..",
    "......oSSoSSo...",
    ".....oSSSoSSo...",
    ".....osSsooSo...",
    "oSo.oSSoooo.o...",
    "oSSSSoo.........",
    ".oooo...........",
]


def _imp(g, top):
    return stamp(shadow(8, 14, [6, 4]), g, 0, top)


FLYER = ([_imp(_IMP_UP, 1), _imp(_IMP_SPREAD, 1), _imp(_IMP_DOWN, 0), _imp(_IMP_RISE, 0)], _IMP_L)

# The charge: head low and level, body stretched out behind it, the wing beating short strokes swept back.
_IMP_DASH = [
    [
        "................",
        "................",
        "................",
        "ooo.............",
        "oMMoo...........",
        ".oMMMooo...oo...",
        "..oMMMosso.osso.",
        "...oMMossSSSsso.",
        "....oMosSSoSSoSo",
        "...ooooSSSYSSYSo",
        "o.oSSSSsSoSSSSSo",
        "oSSsSSoosSoooooo",
        ".oo.oSo..osSwSwo",
        "....o....oooooo.",
    ],
    [
        "................",
        "................",
        "................",
        "................",
        "oo..............",
        "oMoo..oo...oo...",
        ".oMMooosso.osso.",
        "..oMMMossSSSsso.",
        "...oMMosSSoSSoSo",
        "...ooooSSSYSSYSo",
        "o.oSSSSsSoSSSSSo",
        "oSSsSSoosSoooooo",
        ".oo.oSo..osSwSwo",
        "....o....oooooo.",
    ],
    [
        "................",
        "................",
        "................",
        "................",
        "................",
        "......oo...oo...",
        "......osso.osso.",
        "oooo..ossSSSsso.",
        "oMMMooosSSoSSoSo",
        ".oooMMoSSSYSSYSo",
        "o.oSSSSsSoSSSSSo",
        "oSSsSSoosSoooooo",
        ".oo.oSo..osSwSwo",
        "....o....oooooo.",
    ],
]
FLYER_CHARGE = ([_imp(g, 0) for g in _IMP_DASH], _IMP_L)

# The death: it smacks into something, flips over dazed, and pops into a puff of its own violet smoke. The puff
# breaks up and drifts off while its two gold eyes hang in it a moment longer.
_IMP_DEATH = [
    [r.replace("Y", "w") for r in _IMP_UP],
    [r.replace("Y", "w") for r in _IMP_UP[::-1]],
    [
        "................",
        "................",
        "................",
        "......oooo......",
        "....ooMMMMoo....",
        "...oMMMMMMMMo...",
        "..oMMMMMMMMMMo..",
        "..oMMMoYMoYMMo..",
        "..oMMMMMMMMMMo..",
        "...oMMMMMMMMo...",
        "....ooMMMMoo....",
        "......oooo......",
    ],
    [
        "................",
        "................",
        "....ooo..ooo....",
        "...oMMMooMMMo...",
        "..oMMoooooMMMo..",
        ".oMMo......oMMo.",
        ".oMo...o..o.oMo.",
        ".oMo..oY.oY.oMo.",
        ".oMMo......oMMo.",
        "..oMMoo..ooMMo..",
        "...oMMMooMMMo...",
        "....ooo..ooo....",
    ],
    [
        "................",
        "...ooo....ooo...",
        "..oMMMo..oMMMo..",
        "..oMMo....oMMo..",
        "...oo......oo...",
        "................",
        ".......o..o.....",
        ".oo...oY.oY..oo.",
        "oMMo.........oMo",
        "oMMo.......oooo.",
        ".oo.......oMMo..",
        "..........oMo...",
        "...........o....",
    ],
    [
        "..oo........oo..",
        ".oMMo......oMo..",
        "..oo........o...",
        "................",
        "................",
        "................",
        "................",
        ".......o..o.....",
        "......oY.oY.....",
        "o..............o",
        "................",
        "................",
    ],
    [
        ".o..........o...",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "......oo.oo.....",
        "................",
    ],
    ["................"],
]
FLYER_DEATH = ([stamp(shadow(8, 14, w), g, 0, 1) for g, w in
                zip(_IMP_DEATH, [[6, 4], [6, 4], [8, 6], [8, 6], [4], [0], [0], [0]])], _IMP_L)

# ---------- drifter: a hooded cultist gliding with a candle held out ----------
# The candle is a fire like the others, ember tip over a gold body; the eyes glow in the same gold.
_CULT_L = {"R": P["blood"], "r": P["blood_dark"], "W": P["bone"], "Y": P["gold"], "y": P["ember"]}
_CULT = [
    [
        "....oo..........",
        "....oRo.........",
        ".....oRo....oy..",
        ".....oRRoo..oYo.",
        "....oRRRRRo..o..",
        "....oRRooooooWo.",
        "...oRRRoYooYoWo.",
        "...oRrRooooooWo.",
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
        "....oRRooooooWo.",
        "...oRRRoYooYoWo.",
        "...oRrRooooooWo.",
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

# Standing: the robe swells a row as it breathes in, and the candle flame flickers, 5 columns from x 11, rows 0-4.
_CANDLE = {
    "still": None,
    "tall": [".....", "..y..", "..Y..", "..Y..", "....."],
    "left": [".....", ".....", ".yy..", "..Y..", "....."],
    "right": [".....", ".....", "..yy.", "..Y..", "....."],
}


def _cult_idle(breath, flame):
    g = _CULT[0][:10] + [_CULT[0][10]] * (1 + breath) + _CULT[0][11:]
    if _CANDLE[flame]:
        g = [r[:11] + f + r[16:] for r, f in zip(g, _CANDLE[flame])] + g[5:]
    return stamp(shadow(8, 13, [6, 8, 6]), g, 0, 1 - breath)


DRIFTER_IDLE = ([_cult_idle(0, "still"), _cult_idle(1, "tall"), _cult_idle(1, "left"), _cult_idle(0, "right")],
                _CULT_L)

# The death: a jolt that lights its eyes red, then the robe folds into an empty heap, the candle tips into it, the
# cloth goes up in candle fire and burns down to one last ember.
_CULT_DEATH = [
    [r[:12].replace("Y", "y") + r[12:] for r in _cult_idle(1, "tall")],
    [
        "................",
        "................",
        "................",
        "................",
        ".............y..",
        "......oo.....Y..",
        ".....oRo....oWo.",
        "....oRRRoo..oWo.",
        "...oRRRRRRo.oWo.",
        "...oRRoooooRRoo.",
        "..oRrRooooorrRo.",
        ".orRRrRRRRRoooo.",
        "orRRrRRRrRRo....",
        "oooooooooooo....",
        "....________....",
        ".....______.....",
    ],
    [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "..........y.....",
        ".........oYo....",
        "....oo...ooWo...",
        "...oRRo...oWWo..",
        "..oRRRRoooRRWo..",
        ".orRRrRRRRRRoo..",
        "oooooooooooooo..",
        "...__________...",
        "....________....",
    ],
    [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "...y............",
        "..yYy...........",
        "..oYoooooo......",
        "...oRWWWWo......",
        "..oRRooooRRo....",
        ".oRRRRRRRRRRo...",
        "orRRrRRRRrRRRo..",
        "oooooooooooooo..",
        "...__________...",
        "....________....",
    ],
    [
        "................",
        "................",
        "................",
        "...y.......y....",
        "...Yy.....yY....",
        "..yYy..y..yYy...",
        "..yYYy.yy.yYYy..",
        "..yYYYyYYyYYYy..",
        "..yYYYYYYYYYYy..",
        "..oyYYYYYYYYyo..",
        "..ooWWoooRRRo...",
        ".oRRRRRRRRRRo...",
        "orRRrRRRRrRRRo..",
        "oooooooooooooo..",
        "...__________...",
        "....________....",
    ],
    [
        "................",
        "................",
        "................",
        "................",
        "................",
        "......y.........",
        ".....yYy..y.....",
        "....yYYy.yYy....",
        "...yYYYYyYYy....",
        "...yYYYYYYYYy...",
        "..oyyYYYYYYyyo..",
        ".orrrrrrrrrrro..",
        "orrrrrrrrrrrrro.",
        "ooooooooooooooo.",
        "...__________...",
        "....________....",
    ],
    [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "......y.........",
        ".....yYy........",
        ".....yYy..y.....",
        "....orrrrryo....",
        "..orrrrrrrrrro..",
        "..oooooooooooo..",
        "................",
        "................",
    ],
    [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "......y.........",
        ".....oyo........",
        "......o.........",
        "................",
        "................",
    ],
]
DRIFTER_DEATH = (_CULT_DEATH, _CULT_L)

# ---------- bomber: a gargoyle on its plinth that wakes, rears back and spits burning skulls ----------
_GARG_L = {"G": P["iron"], "g": P["iron_dark"], "H": P["iron_dark"], "p": P["shadow"], "E": P["ember"], "Y": P["gold"], "L": P["gold_pale"]}
_PLINTH = [
    "..oooooooooooo..",
    "..oggggggggggo..",
    "..opgppgppgppo..",
    "..oooooooooooo..",
]
_GARG = {
    "idle": [
        "................",
        ".o....ooo.......",
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
    ],
    "stretch": [
        ".o..............",
        "oGo...ooo.......",
        "oGgo...oHo......",
        "oGgGo...oHo.....",
        "ogGgGo.oGGHoooo.",
        ".oggGooGGGGGGGGo",
        ".oogooGGoEGGoooo",
        "..ooooGGGGGooGwo",
        "...oooGGGGGoooo.",
        "...oGGgGgGGo....",
        "...ogGGooGGgo...",
        "...oogGoogGo....",
    ],
    "rear": [
        "......ooo.......",
        ".o.....oHo......",
        "oGo.....oHoooo..",
        "oGgo...oGGHGGGo.",
        "oGgGo.oGGGGGoEo.",
        "ogGgGoGGGGGGGGGo",
        ".oggoGGGGGGoooo.",
        ".ooggoGGGGGGo...",
        "...ooGGGGGGo....",
        "...oGGgGgGGo....",
        "...ogGGooGGgo...",
        "...oogGoogGo....",
    ],
    "gape": [
        "................",
        ".o....ooo.......",
        "oGo....oHo......",
        "oGgo....oHo.....",
        "oGgGo..oGGHoooo.",
        "ogGgGooGGGGGGGGo",
        ".oggoGGGoEGGGwoo",
        ".ooggoGGGGGoEEEo",
        "...oooGGGGGGGwGo",
        "...oGGgGgGGooooo",
        "...ogGGooGGgo...",
        "...oogGoogGo....",
    ],
}
_GARG_GLOW = ["", "", "", "", "", "", ".............E"]
_GARG_BURST = [
    "",
    "",
    "",
    "..........o.oo..",
    ".........oEoEYo.",
    "..........oEoYYo",
    "..........oEYLYo",
    "..........EoYLLo",
    "...........oEYEo",
    "............ooo.",
]
_GARG_TRAIL = [
    "..............o.",
    ".............oYo",
    "............oEYo",
    "...........oEEo.",
    "...........oEo..",
    "",
    ".............E",
]
_GARG_SMOKE = [
    "",
    "............o...",
    "...........ogoo.",
    "............ogGo",
    ".............oo.",
]


def _garg(pose, eye=None, over=None):
    g = stamp(stamp(shadow(14, 14, [14, 14]), _PLINTH, 0, 12), _GARG[pose], 0, 0)
    if eye:
        g = [r.replace("E", eye) for r in g]
    if over:
        g = stamp(g, over)
    return g


BOMBER = ([_garg("idle", "g"), _garg("idle", "E"), _garg("stretch", "Y"), _garg("idle", "E"), _garg("idle", "g"),
           _garg("idle", "g")], _GARG_L)
BOMBER_SPIT = ([_garg("idle"), _garg("rear"), _garg("rear", "Y", _GARG_GLOW), _garg("gape", None, _GARG_BURST),
                _garg("gape", None, _GARG_TRAIL), _garg("idle", None, _GARG_SMOKE), _garg("idle")], _GARG_L)

# ---------- spinner: a fireball whooshing across the corridor, core leading, tongues streaming back ----------
_FIRE_L = {"L": "#f3d98a", "Y": "#e1b553", "y": "#c8742f", "E": "#d4513a", "R": "#8c2d35", ";": "#e1b553",
           ",": "#d4513a"}
_FIRE_CORE = [
    "..........ooo...",
    ".........oYYyo..",
    "........oyYLYyo.",
    ".......oyYLwLYyo",
    "........yLwwLYyo",
    ".......oyYLLYYyo",
    "........oyYYYyo.",
    ".........oyyyo..",
    "..........ooo...",
]
# Each tongue: its row, which way it may flick (away from the middle one), and its length per frame.
# A wave runs down every tongue from the core to the tip, so the loop flows instead of swapping shapes.
_TONGUES = [(2, -1, [4, 5, 5, 4, 4, 3, 3, 4]), (4, 0, [6, 7, 8, 8, 7, 7, 6, 6]), (6, 1, [4, 4, 3, 3, 4, 5, 5, 5])]


def _fire(t):
    g = ["." * 16] * 9
    for k, (row, away, lengths) in enumerate(_TONGUES):
        n = lengths[t]
        for d in range(n):
            c = "y" if d < 1 else "R" if d >= n - 1 else "E"
            if d == (t + 3 * k) % 5 + 1 and d < n - 1:
                c = "y"   # a hot bead travelling to the tip
            y = row + (away if (d - t + 2 * k) % 4 < 2 and d >= 2 else 0)
            g = stamp(g, [c], 7 - d, y)
        if n < lengths[t - 1]:   # the tongue just shortened: its tip broke off as a spark
            g = stamp(g, [";" if k == 0 else ","], 6 - lengths[t - 1], row + away)
    return stamp(g, _FIRE_CORE)


_FIRE = [_fire(t) for t in range(8)]
SPINNER_DRIFT = 80
SPINNER = ([stamp(shadow(6, 13, [6, 4]), f, 0, 3) for f in _FIRE], _FIRE_L)

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
