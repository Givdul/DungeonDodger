"""Cult Sanctum: the rolling fire and the trail it leaves. Everything else comes from the frozen v4."""
from sets.sanctum_v3 import *  # noqa: F401,F403
import math
from core import stamp
from sets.sanctum_palette import P, PALETTE  # noqa: F401

# ---------- spinner: a ball of fire rolling along the floor, turning like a catherine wheel ----------
# A flat ember disc. Three gold arms curl out of a white-hot heart and a ring of
# flame tongues stands round the rim, each bent back against the roll like a saw tooth. Both turn clockwise,
# the way a ball rolling right turns: 1/24 of a turn a frame, so 8 frames bring the three arms back round.
# Tongues on the top and back are whipped long; at the front they are short and underneath pressed flat.
# The same fire as every other in the set: ember disc and tongue tips, gold arms and tongue roots, a pale heart.
_ROLL_L = {"L": P["gold_pale"], "Y": P["gold"], "E": P["ember"], ";": P["gold"], ",": P["ember"]}
_CX, _CY, _RX, _RY = 8.0, 10.0, 4.6, 3.9
_ARMS, _TWIST = 3, 2.2        # gold arms, and how far each curls round between heart and rim
_TEETH, _BEND = 6, .6        # rim tongues, and how far back each leans per unit it reaches out


def _reach(a):
    """How far a tongue at screen angle a reaches past the rim, in rim radii."""
    up, back = -math.sin(a), -math.cos(a)
    return max(0.0, min(1.1, .3 + .55 * up + .35 * back))


def _polar(px, py, phi):
    """Distance from the heart in rim radii, angle, and where the point sits in its arm's sector (0-1)."""
    dx, dy = (px - _CX) / _RX, (py - _CY) / _RY
    r, th = math.hypot(dx, dy), math.atan2(dy, dx)
    return r, th, ((th - phi + _TWIST * min(r, 1)) % (2 * math.pi / _ARMS)) / (2 * math.pi / _ARMS)


def _sample(px, py, phi):
    """What lies at a point: an arm, the disc, a tongue (0 for one that carries an arm on), or nothing."""
    r, th, s = _polar(px, py, phi)
    if r < 1:
        return "arm" if s < _arm_width(r) else "disc"
    e = r - 1
    for k in range(_TEETH):
        a = phi - _TWIST + (k + .5) * 2 * math.pi / _TEETH   # each even tongue carries an arm on past the rim
        n = _reach(a - _BEND * e) * (1 if k % 2 == 0 else .6)
        half = .32 * (1 - e / n) if e < n else 0
        if abs((a - th) % (2 * math.pi) - _BEND * e - half) < half:
            return "tongue%d" % (k % 2)
    return "."


def _arm_width(r):
    return .5 - .2 * r


def _kind(x, y, phi):
    votes = [_sample(x + (i + .5) / 3, y + (j + .5) / 3, phi) for i in range(3) for j in range(3)]
    return max(sorted(set(votes)), key=votes.count)   # sorted, so ties break the same way every run


def _fire(t):
    phi = t * 2 * math.pi / _ARMS / 8
    g = [["."] * 16 for _ in range(16)]
    for y in range(16):
        for x in range(16):
            kind = _kind(x, y, phi)
            r, _, s = _polar(x + .5, y + .5, phi)
            if kind == "arm":
                g[y][x] = "L" if r < .5 else "Y"
            elif kind == "disc":
                # ink edges each arm on its trailing side, so the arms read as separate curls
                g[y][x] = "o" if s > .88 and .35 < r < .9 else "E"
            elif kind.startswith("tongue"):
                hot = kind == "tongue0"
                g[y][x] = "Y" if hot and r < 1.15 else "E"
    for y in range(16):   # ink only where it actually edges an arm
        for x in range(16):
            if g[y][x] == "o" and not any(g[y + b][x + a] in "LY" for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                g[y][x] = "E"
    g[9][7] = g[9][8] = g[10][7] = g[10][8] = "L"
    g[9][8] = "w"
    g = ["".join(r) for r in g]
    if t in (2, 6):   # now and then a spark tears off the top-back
        g = stamp(g, [";"], 2 + t // 6, 1)
    return stamp(g, ["....__,,,,__...."], 0, 15)


SPINNER_DRIFT = 80
SPINNER = ([_fire(t) for t in range(8)], _ROLL_L)

# ---------- trail: fire left on the floor, burning down to a scorch ----------
# Freshest first. Pieces land 13px apart, so each is about 14 wide and the flames and scorch run together.
# Ember glow under the flames, dying to ember coals in a scorch of ground shadow.
_TRAIL_L = {"L": P["gold_pale"], "Y": P["gold"], "E": P["ember"], ",": P["ember"], ";": P["shadow"]}
_TRAIL = [
    {10: "......E.........",
     11: ".....EE.........",
     12: "....EYE....E....",
     13: "..E.YLEY..EE.E..",
     14: "..EYYLLLYYYEEEE.",
     15: "..;,,,,,,,,,,,,;"},
    {11: ".........E......",
     12: "...E.....EE.....",
     13: "...E..E..EE..E..",
     14: "..EEYYLYLYYEEEE.",
     15: "..;,,,,,,,,,,,,;"},
    {13: "....E....E..E...",
     14: "...EEEEEYYEEEEE.",
     15: "..;,,,,,,,,,,,,;"},
    {14: "...;,,,EE,,,E,;.",
     15: "..;;,,,,,,,,,,;;"},
    {14: "...;;,;;;,;;;;..",
     15: "..;;;;,;;;;;;;;."},
    {14: "....;;.;;;..;;..",
     15: ".....;;;..;;;..."},
]
SPINNER_TRAIL = ([[f.get(y, "").ljust(16, ".") for y in range(16)] for f in _TRAIL], _TRAIL_L)

# ---------- the same fire rolling along the corridor, and paused between runs ----------
# Rolling down or up the screen the ball turns about a level axis, so its gold arms become bands that come over
# the trailing rim, sweep across its face and bunch up as they go under the leading one. Rolling down, the tongues
# stream back up behind it. Both sit at the idle's height, so the game can switch between them without a hop.
_V_ARMS, _V_TWIST = 3, .55     # bands round the whole ball (one or two show), and how far they slant across it


def _v_body(dx, dy, r, phase):
    """'arm' or 'disc' for a point on a ball turning about a level axis, and where it sits in its band (0-1)."""
    z = math.sqrt(max(0.0, 1 - r * r))
    lat = math.atan2(dy, z) + _V_TWIST * dx
    s = ((lat - phase) % (2 * math.pi / _V_ARMS)) / (2 * math.pi / _V_ARMS)
    return ("arm" if s < .3 else "disc"), s


def _tongue_hit(px, py, cx, cy, tongues, size=1.0):
    """Which tongue covers a point: 'tongue0' down the middle of its root half, 'tongue1' elsewhere, or None.
    A tongue roots inside the rim at angle base, sets off along aim and curls by bend radians by its tip."""
    for base, aim, length, half, bend in tongues:
        x, y = cx + _RX * size * .85 * math.cos(base), cy + _RY * size * .85 * math.sin(base)
        u = 0.0
        while u < length:
            h = aim + bend * u / length
            w, d = half * (1 - u / length), math.hypot(px - x, py - y)
            if d < w:
                return "tongue0" if u < length * .6 and d < max(w * .55, .75) else "tongue1"
            x, y, u = x + .25 * math.cos(h), y + .25 * math.sin(h), u + .25
    return None


def _ball(cx, cy, body, tongues, seams=True, size=1.0, floor="....__,,,,__...."):
    """The fire ball centred at cx, cy: body(dx, dy, r) gives ('arm' or 'disc', place in the arm) inside the rim,
    tongues are as in _tongue_hit. seams inks the trailing edge of each arm; size scales the ball's radii."""
    rx, ry = _RX * size, _RY * size

    def inside(px, py):
        return math.hypot((px - cx) / rx, (py - cy) / ry) < 1

    g = [["."] * 16 for _ in range(16)]
    g[15] = list(floor)
    for y in range(16):
        for x in range(16):
            dx, dy = (x + .5 - cx) / rx, (y + .5 - cy) / ry
            r = math.hypot(dx, dy)
            # the ball by a 3x3 vote, so its rim steps cleanly; tongues at the pixel centre, so gaps between them stay open
            if sum(inside(x + (i + .5) / 3, y + (j + .5) / 3) for i in range(3) for j in range(3)) >= 5:
                kind, s = body(dx, dy, min(r, .999))
                if kind == "arm":
                    g[y][x] = "L" if r < .45 else "Y"
                else:
                    g[y][x] = "o" if seams and s > .9 and .3 < r < .92 else "E"
            else:
                kind = _tongue_hit(x + .5, y + .5, cx, cy, tongues, size)
                if kind:
                    g[y][x] = "Y" if kind == "tongue0" else "E"
    for y in range(16):
        for x in range(16):
            if g[y][x] == "o" and not any(0 <= y + b < 16 and 0 <= x + a < 16 and g[y + b][x + a] in "LY"
                                          for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                g[y][x] = "E"
    ix, iy = int(cx - .5), int(cy - .5)
    g[iy][ix] = g[iy][ix + 1] = g[iy + 1][ix] = g[iy + 1][ix + 1] = "L"
    g[iy][ix + 1] = "w"
    return ["".join(r) for r in g]


def _flick(t, n, k, lo=.7):
    return lo + (1 - lo) * (.5 + .5 * math.sin(2 * math.pi * t / n + k * 2.3))


# Per tongue: where it roots, in radians round the rim from straight back; how much of that angle it keeps as it
# sets off (under 0 leans in toward the tail's middle); length and half width in px; how far it curls by its tip.
_V_TONGUES = {True: ((-1.3, .3, 4.5, 1.3, .7), (-.7, .2, 7.0, 1.5, .6), (0, 0, 9.5, 1.8, .3), (.7, .2, 6.5, 1.5, -.6),
                     (1.3, .3, 4.0, 1.3, -.7)),
              # rolling away the ball keeps only short tongues on its leading top, pressed down by the run; a tail
              # below it would sit on the trail's newest flame like a cap on a stem, and the trail shows the motion
              False: ((math.pi - .8, 1, 3.0, 1.3, .6), (math.pi - .25, 1, 3.5, 1.5, .4), (math.pi + .35, 1, 3.0, 1.4, .3),
                      (math.pi + .9, 1, 2.5, 1.2, .3))}


def _roll_v(t, down):
    phase = (t if down else -t) * 2 * math.pi / _V_ARMS / 8
    back = -math.pi / 2 if down else math.pi / 2          # the way the tongues stream
    sway = lambda k: .15 * math.sin(math.pi * t / 4 + k * 1.7)
    tongues = [(back + off, back + off * lean + sway(k), reach * _flick(t, 8, k), half, (bend if down else -bend) + sway(k))
               for k, (off, lean, reach, half, bend) in enumerate(_V_TONGUES[down])]
    g = _ball(8.0, 10.0, lambda dx, dy, r: _v_body(dx, dy, r, phase), tongues, seams=False)
    if down and t in (1, 5):   # a spark tears off the tail
        g = stamp(g, [";"], 5 + t // 2, 0)
    return g


SPINNER_DOWN = ([_roll_v(t, True) for t in range(8)], _ROLL_L)
SPINNER_UP = ([_roll_v(t, False) for t in range(8)], _ROLL_L)


def _wheel(phi):
    """The idle's body: the catherine wheel's arms at angle phi."""
    def body(dx, dy, r):
        th = math.atan2(dy, dx)
        s = ((th - phi + _TWIST * min(r, 1)) % (2 * math.pi / _ARMS)) / (2 * math.pi / _ARMS)
        return ("arm" if s < _arm_width(r) else "disc"), s
    return body


def _standing(t, n, scale=1.0, spread=1.0):
    """Tongues standing straight up, drawn in to one flame, flickering over an n-frame loop."""
    up = -math.pi / 2
    return [(up + off * spread, up - off * .15 + .12 * math.sin(2 * math.pi * t / n + k), scale * reach * _flick(t, n, k, .65),
             half, -off * .5)
            for k, (off, reach, half) in enumerate(((-1.15, 4.0, 1.4), (-.55, 6.0, 1.7), (0, 7.5, 2.0), (.55, 5.5, 1.7),
                                                     (1.15, 3.5, 1.4)))]


# Paused between runs: the wheel rocks instead of turning and its tongues stand straight up, drawn in to one flame.
def _idle(t):
    return _ball(_CX, _CY, _wheel(.12 * math.sin(2 * math.pi * t / 6)), _standing(t, 6))


SPINNER_IDLE = ([_idle(t) for t in range(6)], _ROLL_L)

# ---------- the trail on runs along the corridor ----------
# The same six-step burn-down as SPINNER_TRAIL, as one flame standing on a thin line down the middle of the cell.
# Pieces land 13-14px apart down a column: each flame's tip licks up into the base of the one above, and every
# frame keeps the line running top to bottom (rows 13-15 repeat rows 0-2), so the column never breaks.
_TRAIL_V = [
    ["........E.......",
     ".......EE.......",
     ".......EYE......",
     "......EYYE......",
     "......EYYE......",
     ".....EYYYE......",
     "....E.EYLYE.....",
     "....EEYYLYE.....",
     ".....EYLLYYE....",
     "....EYYLLYYE....",
     "....EEYYYYEE....",
     ".....EEYYEE.....",
     "......EEEE......",
     "........E.......",
     ".......EE.......",
     ".......EYE......"],
    ["........E.......",
     "........E.......",
     ".......EE.......",
     ".......EYE......",
     "......EYYE......",
     "......EYYE......",
     ".....EYYYE......",
     ".....EYLYYE.....",
     ".....EYYYYE.....",
     ".....EEYYEE.....",
     "......EEEE......",
     "......E,,E......",
     ".......,,.......",
     "........,.......",
     "........E.......",
     ".......EE......."],
    ["........,.......",
     "........,.......",
     "........E.......",
     ".......EE.......",
     ".......EE.......",
     "......EEEE......",
     "......EYEE......",
     ".....EEEYEE.....",
     ".....EEYEEE.....",
     "......EEEE......",
     "......,,,,......",
     ".......,,.......",
     ".......,,.......",
     "........,.......",
     "........,.......",
     "........E......."],
    ["........,.......",
     "........,.......",
     "........,.......",
     "........;.......",
     ".......;,;......",
     "......;,,,;.....",
     "......,,E,;.....",
     ".....;,,,,,;....",
     ".....;,E,,,;....",
     "......;,,,;.....",
     "......;,,,;.....",
     ".......;,;......",
     ".......;,;......",
     "........,.......",
     "........;.......",
     "........;......."],
    ["........;.......",
     "........;.......",
     "........;.......",
     "........;.......",
     ".......;;.......",
     "......;;;;......",
     "......;,;;;.....",
     ".....;;;;;;;....",
     ".....;;;;,;;....",
     "......;;;;;.....",
     "......;;;;;.....",
     ".......;;;......",
     ".......;;;......",
     "........;.......",
     "........;.......",
     "........;......."],
    ["........;.......",
     "................",
     "........;.......",
     "........;.......",
     "................",
     ".......;........",
     "......;.;;......",
     ".....;;;.;;.....",
     "......;;;;;.....",
     ".....;;.;;......",
     "......;;.;......",
     ".......;;.......",
     "........;.......",
     "................",
     "........;.......",
     "........;......."],
]
SPINNER_TRAIL_V = (_TRAIL_V, _TRAIL_L)

# ---------- death: rolled into a hole, the fire gutters, sputters and goes out in a puff of smoke ----------
# From the idle: the tongues duck and the ball shrinks, one last flare jumps off the coal, then it is smoke that
# swells into a ring, breaks up and is gone. The ground glow goes with the first frame; there is no floor under it.
_DEATH_L = {**_ROLL_L, ";": P["iron_lit"]}
_PUFF = [
    {6: "......;;..;.....",
     7: "....;;;;;;;;....",
     8: "...;;;;;;;;;;...",
     9: "...;;;;;;;;;;...",
     10: "....;;;;;;;;....",
     11: ".....;;..;;....."},
    {4: "......;;;.......",
     5: "....;;;..;;;....",
     6: "...;;.......;...",
     7: "..;;.........;..",
     8: "..;..........;;.",
     9: "...;;.......;;..",
     10: "....;;;..;;;....",
     11: ".......;;......."},
    {2: ".....;.....;....",
     3: "...;;.......;...",
     5: ".;.............;",
     6: ".;..............",
     8: "..............;.",
     9: ".;..............",
     10: "....;.......;;..",
     11: ".......;........"},
    {},
]


def _death(t):
    if t >= 4:
        return [_PUFF[t - 4].get(y, "").ljust(16, ".") for y in range(16)]
    size, tongues, floor = {
        0: (1.0, _standing(0, 6, .55), "....__,,,,__...."),
        1: (.8, _standing(3, 6, .7, 1.3), "." * 16),
        2: (.6, [(-math.pi / 2, -math.pi / 2 + .2, 6.5, 1.3, -.4)], "." * 16),   # the last flare
        3: (.4, [], "." * 16),
    }[t]
    g = _ball(_CX, _CY, _wheel(0), tongues, size=size, floor=floor)
    g = [r.replace("w", "L") for r in g]
    if t == 3:   # a dull coal, and the first smoke leaves it
        g = stamp([r.replace("L", "Y") for r in g], [".;...", "..;;.", ".;;.."], 6, 6)
    return g


SPINNER_DEATH = ([_death(t) for t in range(8)], _DEATH_L)
