"""Cult Sanctum, big polish: hero. Everything else comes from the frozen v3."""
from sets.sanctum_v3 import *  # noqa: F401,F403
from core import stamp, shadow, outline
from sets.sanctum_palette import P, PALETTE  # noqa: F401

# The sacrifice who got away: copper mop, a dusty smock with a rope belt, bare feet,
# and the cut rope still knotted round the left wrist.
_HERO_L = {"H": P["hair"], "h": P["hair_dark"], "S": P["skin"], "s": P["skin_dark"],
           "W": P["smock"], "V": P["smock_dark"], "B": P["ember"], "R": P["tan"], "r": P["hair_dark"]}


def _f(*parts):
    """Stamps (rows, dx, dy) parts in order onto a 16x16 frame over the hero's shadow."""
    g = shadow(10, 12, [6, 10, 8])
    for rows, dx, dy in parts:
        g = stamp(g, rows, dx, dy)
    return g


# ---- idle, facing the viewer ----
_FACE = [
    "........oo......",
    "......ooHho.....",
    "....ooHHHHho....",
    "...oHHHHHHHho...",
    "...oHHhHHhHho...",
    "...ohhhSSShho...",
    "...ohSoSSoSho...",
    "....oosSSsoo....",
]
_GLANCE = [
    ".........oo.....",
    "......oooHho....",
    "....ooHHHHho....",
    "...oHHHHHHHho...",
    "...oHhHHhHHho...",
    "...ohhSSShhho...",
    "...ohoSSoShho...",
    "....osSSsooo....",
]
_STAND = [
    "....ooWWWVoo....",
    "...oSSoWVoSSo...",
    "...oSsoRrosSRo..",
    "....oVWBWWVoro..",
    "....oSsoosSo.o..",
    "....oooo.ooo....",
]
_SWAY = [
    "....ooWWWVoo....",
    "...oSSoWVoSSo...",
    "...oSsoRrosSRo..",
    "....oVWBWWVooRo.",
    "....oSsoosSo.o..",
    "....oooo.ooo....",
]

_TUFT_LAG = ["........oo......", "........Hh......"]  # the head dips, the cowlick stays up

_IDLE = [
    _f((_STAND, 0, 8), (_FACE, 0, 0)),
    _f((_SWAY, 0, 8), (_FACE, 0, 0)),
    _f((_SWAY, 0, 8), (_FACE, 0, 1), (_TUFT_LAG, 0, 0)),
    _f((_STAND, 0, 8), (_GLANCE, 0, 1)),
    _f((_STAND, 0, 8), (_GLANCE, 0, 0)),
    _f((_SWAY, 0, 8), (_FACE, 0, 0)),
]

# ---- run up, seen from behind ----
_BACK = [  # rising: the locks trail down over the nape
    "......oooo......",
    "....ooHHHHoo....",
    "...oHHHHHHHho...",
    "...ohHHHoHhho...",
    "...oshhHohhso...",
    "....ohohhoho....",
]
_BACK_LAND = [  # landing: the cowlick flicks up and the locks bounce
    "......oo........",
    ".....oHhoo......",
    "....ooHHHHoo....",
    "...oHHHHHHHho...",
    "...ohHHHoHhho...",
    "...oshhHohhso...",
    "....oohhhhoo....",
]
# Bodies are drawn for the kid's left arm swinging back (low, on the viewer's left);
# the other half of the stride is their mirror. Row 0 is the shoulders. The belt
# knot's loose end hangs over the hem and swings behind the hips.
_CONTACT = [  # left heel planted, right foot kicked up under the hem, right elbow out
    ".....oVWWVo.....",
    ".....oWWWWoSo...",
    ".oSSooRrrRoo....",
    ".osSoVWRWWVo....",
    "..oo.oSoosSo....",
    ".....oSso.oo....",
    "......ooo.......",
]
_PUSH = [  # rising off the left foot; the left hand swings forward, the right comes down
    ".....oVWWVo.....",
    "...oSoWWWWoo....",
    "...osoRrrRoSo...",
    "....oVWRWWoso...",
    ".....oSoosSoo...",
    ".....oSso.oo....",
    "......ooo.......",
]
_PASS = [  # airborne, feet tucked under, hands passing the hips
    ".....oVWWVo.....",
    "...oSoWWWWoSo...",
    "...osoRrrRoso...",
    "....oVWRWWVo....",
    ".....oSsosSo....",
    "......oo.oo.....",
]


def _flip(rows):
    return [r.ljust(16, ".")[::-1] for r in rows]


def _up(body, rise):
    if rise:
        return _f((body, 0, 6), (_BACK, 0, 0))
    return _f((body, 0, 7), (_BACK_LAND, 0, 0))


# the cut rope on the kid's left wrist, trailing from the low hand
_WRIST = ["...R", "..r"]

_RUN_UP = [stamp(_up(_CONTACT, False), _WRIST, 0, 11), _up(_PUSH, True), _up(_PASS, True),
           _up(_flip(_CONTACT), False), _up(_flip(_PUSH), True), _up(_flip(_PASS), True)]

# ---- run, facing right: head forward, hips back, the belt end streaming behind ----
_SIDE = [  # the back lock streams out behind
    ".......ooooo....",
    "......ohHHHHo...",
    "....oohHHHHHHo..",
    "...ohhoHHHHHHo..",
    "....oohHhsSSSo..",
    ".....ohhsSSoSo..",
    "......ooosSSo...",
]
_SIDE_DROP = [  # ...and falls back against the head at the top of the stride
    ".......ooooo....",
    "......ohHHHHo...",
    ".....ohHHHHHHo..",
    "....ohhHHHHHHo..",
    "....ohhHhsSSSo..",
    ".....ohhsSSoSo..",
    "......ooosSSo...",
]
# near leg reaching forward, near arm swung back; the far hand peeks out in front
_R_CONTACT = [
    "......ooWWWo....",
    "....oSSoWWVoso..",
    "....osSoRrRoso..",
    "....rRoVWWVoo...",
    "....oSso..oSso..",
    "....ooo...ooo...",
]
_R_DOWN = [  # one row shorter: the knees take the landing
    "......ooWWWo....",
    ".....oSSRrRoso..",
    "...rrosSVWWVo...",
    ".....oSsoSso....",
    ".....ooo.ooo....",
]
_R_PASS = [  # airborne, near arm coming through
    "......ooWWWo....",
    "......oWWWVoo...",
    ".....rRRrRoSSo..",
    "....r.oVWWosSo..",
    "......oSsSooo...",
    "......oooo......",
]
# far leg reaching forward, near arm swung forward
_R_CONTACT2 = [
    "......ooWWWoSSo.",
    "......oWWWVosSo.",
    ".....rRRrRRooo..",
    "...rr.oVWWWVo...",
    "....osSo..osso..",
    "....ooo...ooo...",
]
_R_DOWN2 = [
    "......ooWWWoo...",
    ".....rRRrRRoSSo.",
    "....r.oVWWWosSo.",
    ".....osSoosSoo..",
    ".....ooo.ooo....",
]


def _run(body, top, head=_SIDE):
    return _f((body, 0, top + 7), (head, 0, top))


_RUN = [_run(_R_CONTACT, 1), _run(_R_DOWN, 2), _run(_R_PASS, 0, _SIDE_DROP),
        _run(_R_CONTACT2, 1), _run(_R_DOWN2, 2), _run(_R_PASS, 0, _SIDE_DROP)]

# ---- run down, toward the viewer: run_up's rhythm, the face bobbing over the stride ----
# Bodies swing the kid's right arm back (low, on the viewer's left); the other half is their
# mirror. The rope stays on the kid's left wrist (the viewer's right), stamped after the flip.
_D_CONTACT = [  # right heel planted, left foot kicked up under the hem, left hand swung forward
    "....ooWWWVoo....",
    "...oSoWWWVoSSo..",
    "..oSsoRrRrosSo..",
    "..oo.oVWBWVoo...",
    ".....oSsoooo....",
    ".....oooo.......",
]
_D_PUSH = [  # rising off the right foot, hands passing the hips
    "....ooWWWVoo....",
    "...oSoWWWVoSo...",
    "...osoRrRrosSo..",
    "....oVWBWWVoo...",
    "....oSsooSo.....",
    "....oooo.oo.....",
]
_D_PASS = [  # airborne, feet tucked under the hem
    "....ooWWWVoo....",
    "...oSoWWWVoSo...",
    "...osoRrRroso...",
    "....oVWBWWVo....",
    ".....oSsSso.....",
    ".....oooooo.....",
]
# where the rope hangs off the kid's left hand in each body, as (dx, dy) from the body's top-left
_D_ROPE = {"contact": (13, 2), "push": (13, 2), "pass": (12, 2),
           "contact_f": (11, 3), "push_f": (12, 3), "pass_f": (12, 2)}
_ROPE = ["R", "r"]


def _down(body, rope, rise):
    face_y, body_y = (-1, 7) if rise else (0, 8)
    g = _f((body, 0, body_y), (_FACE, 0, face_y))
    return stamp(g, _ROPE, rope[0], body_y + rope[1])


_RUN_DOWN = [_down(_D_CONTACT, _D_ROPE["contact"], False), _down(_D_PUSH, _D_ROPE["push"], True),
             _down(_D_PASS, _D_ROPE["pass"], True), _down(_flip(_D_CONTACT), _D_ROPE["contact_f"], False),
             _down(_flip(_D_PUSH), _D_ROPE["push_f"], True), _down(_flip(_D_PASS), _D_ROPE["pass_f"], True)]


# ---- hits: recoil, a flash of red, then the flinch settling ----
def _flash(g):
    """The figure filled with ember inside its outer ink: the frame that says 'that hurt' at 1x."""
    g = outline(g)
    h, w = len(g), len(g[0])

    def outside(x, y):
        return not (0 <= x < w and 0 <= y < h) or g[y][x] in "._"

    return ["".join(c if c in "._" or (c == "o" and any(outside(x + dx, y + dy) for dx, dy in
                                                          ((1, 0), (-1, 0), (0, 1), (0, -1)))) else "B"
                    for x, c in enumerate(r)) for y, r in enumerate(g)]


_OUCH = [  # the face screwed up: eyes squeezed shut, mouth open
    "........oo......",
    "......ooHho.....",
    "....ooHHHHho....",
    "...oHHHHHHHho...",
    "...oHHhHHhHho...",
    "...ohhhSSShho...",
    "...ohooSSooho...",
    "....oosoosoo....",
]
_FLUNG = [  # arms thrown up and out, rope flying off the left wrist
    ".oo.........oo..",
    "oSSo.oWWWVo.oSSo",
    ".osSooWWWVoosSo.",
    "..oo.oRrBrRo.oRo",
    ".....oVWWWVo..r.",
    ".....oSsosSo....",
    ".....ooo.ooo....",
]
_HIT_DOWN_0 = _f((_FLUNG, 0, 6), (_OUCH, 0, -1))
_HIT_DOWN = [_HIT_DOWN_0, _flash(_HIT_DOWN_0), _f((_STAND, 0, 8), (_OUCH, 0, 0))]

_SIDE_OUCH = [  # knocked back: eye shut, mouth open
    ".......ooooo....",
    "......ohHHHHo...",
    "....oohHHHHHHo..",
    "...ohhoHHHHHHo..",
    "....oohHhsSSSo..",
    ".....ohhsSSooo..",
    "......ooosSoSo..",
    ".........ooo....",
]
_SIDE_FLUNG = [  # leaning back, both arms thrown forward, the lead foot off the floor
    ".......oWWWoSSo.",
    "......oWWWVosSo.",
    "....rrRRrRooSo..",
    "...r..oVWWVoo...",
    ".....oSso.oSSo..",
    ".....ooo...ooo..",
]
_HIT_SIDE_0 = _f((_SIDE_FLUNG, -1, 7), (_SIDE_OUCH, -2, 0))
_HIT_SIDE = [_HIT_SIDE_0, _flash(_HIT_SIDE_0), _run(_R_CONTACT, 1, _SIDE_OUCH)]

_BACK_FLUNG = [  # from behind: both arms up and out
    ".oo.........oo..",
    "oSSo.oVWWVo.oSSo",
    ".osSooWWWWoosSo.",
    "..ooRoRrrRo..oo.",
    "...oro.VWRWVo...",
    ".....oSsosSo....",
    ".....ooo.ooo....",
]
_HIT_UP_0 = _f((_BACK_FLUNG, 0, 5), (_BACK, 0, 0))
_HIT_UP = [_HIT_UP_0, _flash(_HIT_UP_0), _up(_CONTACT, False)]

# ---- death: hit, wobble, knees go, flat on the back, and a small ghost of the kid wanders off ----
_DIZZY = [  # eyes rolled, mouth a small o
    "........oo......",
    "......ooHho.....",
    "....ooHHHHho....",
    "...oHHHHHHHho...",
    "...oHHhHHhHho...",
    "...ohhhSSShho...",
    "...ohoSSSSoho...",
    "....oosoosoo....",
]
_WOBBLE = [  # arms dropping, one knee going
    "....ooWWWVoo....",
    "...oSSoWVoSSo...",
    "...oSsoRrosSRo..",
    "....oVWBWWVoro..",
    "....oSsoosSo....",
    "....oooo.oo.....",
]
_KNEEL = [  # dropped to the knees
    "...oSSoWVoSSo...",
    "...oSsoRrosSRo..",
    "...ooVWBWWVoro..",
    "..oSSooooSSo....",
    "..oooo..oooo....",
]
_BOWED = [  # the head lolls forward
    "......oooo......",
    "....ooHHHHoo....",
    "...oHHHHHHHho...",
    "...oHHhHHhHho...",
    "...ohhhhhhhho...",
    "....ohSSSSho....",
    "....oooooooo....",
]
_LIE = [  # flat on the back, head on the viewer's left, hands folded on the chest
    "..oooo..........",
    ".oHHHhoooooooo..",
    "oHHhSSSoVWRWSso.",
    "oHHhSoSsWSRWooo.",
    "oHHhSSSsWSBWSso.",
    "oHHhSoSoVWRVooo.",
    ".oHHhSSooooRo...",
    "..ooooo....r....",
]
_LIE_KICK = [  # the bounce: head and feet off the floor
    "..oooo......oo..",
    ".oHHHhooooooSso.",
    "oHHhSSSoVWRWoso.",
    "oHHhSoSsWSRWoo..",
    "oHHhSSSsWSBWSso.",
    "oHHhSoSoVWRVooo.",
    ".oHHhSSooooRo...",
    "..ooooo....r....",
]
_SOUL_PEEK = [  # a little ghost of the kid, cowlick and all, climbing out
    "..o..",
    ".owo.",
    "owwwo",
    "owowo",
]
_SOUL = [
    "...o...",
    "..owo..",
    ".owwwo.",
    "owowowo",
    "owwwwwo",
    ".owwwwo",
    "..owo.o",
    "...o...",
]


def _lying(body, dy=0):
    g = shadow(14, 11, [10, 14, 12])
    return stamp(g, body, 0, 7 + dy)


_DEATH = [
    _flash(_HIT_DOWN_0),
    _HIT_DOWN_0,
    _f((_WOBBLE, -1, 8), (_DIZZY, -1, 0)),
    _f((_WOBBLE, 1, 8), (_DIZZY, 1, 1)),
    _f((_KNEEL, 0, 9), (_DIZZY, 0, 2)),
    _f((_KNEEL, 0, 9), (_BOWED, 0, 4)),
    _lying(_LIE_KICK, -1),
    _lying(_LIE),
    stamp(_lying(_LIE), _SOUL_PEEK, 7, 4),
    stamp(_lying(_LIE), _SOUL, 8, 0),
]

# ---- fall: dropping into a hole, seen from above, shrinking to nothing ----
_FALL_0 = [  # arms flung up, looking back up at us in horror
    "..oo......oo....",
    ".oSSo....oSSo...",
    ".osSooooooSso...",
    "..ooHHHHHhoo....",
    "..ohHHhHHhHo....",
    "..ohhSSSShho....",
    "..ohSoSSoSho....",
    "...osSooSso.....",
    "...ooWWWVoo.....",
    "...oVWBWWVo.....",
    "...oSso.Sso.....",
    "...ooo..ooo.....",
]
_FALL_1 = [
    ".oo....oo.",
    "oSSooooSSo",
    ".ooHHHhoo.",
    ".ohHHhHho.",
    ".ohSooSho.",
    "..oWWBVo..",
    "..oSoSoo..",
    "..oo.oo...",
]
_FALL_2 = [
    "oo...oo",
    "oSoooSo",
    ".oHHHo.",
    ".ohSho.",
    ".oWBVo.",
    "..ooo..",
]
_FALL_3 = [
    "S.S",
    "HHH",
    ".W.",
]
_FALL_4 = ["H"]


def _drop(rows, dx, dy):
    return stamp(["." * 16] * 16, rows, dx, dy)


_FALL = [_drop(_FALL_0, 2, 2), _drop(_FALL_1, 3, 5), _drop(_FALL_2, 5, 6), _drop(_FALL_3, 7, 7),
         _drop(_FALL_4, 7, 8), _drop([], 0, 0)]

HERO = {
    "legend": _HERO_L,
    "idle": _IDLE,
    "run": _RUN,
    "run_up": _RUN_UP,
    "run_down": _RUN_DOWN,
    "hit_down": _HIT_DOWN,
    "hit_side": _HIT_SIDE,
    "hit_up": _HIT_UP,
    "death": _DEATH,
    "fall": _FALL,
}
