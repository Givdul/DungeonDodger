"""Grid drawing in o_lobster's construction rules, with our own palette and designs.

A frame is a list of strings, one character per pixel:
  .  transparent
  o  outline (also used for inner lines: eyes, gaps between arms and body)
  _  ground shadow
  any other character is looked up in the sprite's legend (hex colour).
The outer outline is added automatically: every transparent or shadow pixel that
touches a coloured pixel on a side becomes outline. Tiles get no outline.
  , ;  ground colours that get no outline (leaves lying on the floor).
"""
from PIL import Image

OUTLINE = "#2f2b35"
SHADOW = "#47434d"
WHITE = "#f1eee6"


def hexc(c):
    c = c.lstrip("#")
    return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255)


def pad(g, w=16, h=16):
    g = [r.ljust(w, ".") for r in g]
    return g + ["." * w] * (h - len(g))


def outline(g):
    h, w = len(g), len(g[0])
    rows = [list(r) for r in g]
    for y in range(h):
        for x in range(w):
            if g[y][x] not in "._,;":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and g[ny][nx] not in "._o,;":
                    rows[y][x] = "o"
                    break
    return ["".join(r) for r in rows]


def stamp(base, part, dx=0, dy=0):
    """Draws part's non-transparent pixels over base, shifted by dx, dy."""
    rows = [list(r) for r in base]
    for y, r in enumerate(part):
        for x, c in enumerate(r):
            if c != "." and 0 <= y + dy < len(rows) and 0 <= x + dx < len(rows[0]):
                rows[y + dy][x + dx] = c
    return ["".join(r) for r in rows]


def shadow(w, top, rows=None, size=16, h=16):
    """A flat ground shadow like his: a rounded slab, wide and short."""
    rows = rows or [w - 4, w, w, w - 2, w - 6]
    g = ["." * size] * h
    for i, rw in enumerate(rows):
        if top + i < h and rw > 0:
            left = (size - rw) // 2
            g = stamp(g, ["." * left + "_" * rw], 0, top + i)
    return g


def mirror(g):
    return [r[::-1] for r in g]


def shift(g, dx=0, dy=0):
    return stamp(["." * len(g[0])] * len(g), g, dx, dy)


def image(g, legend, outlined=True):
    if outlined:
        g = outline(g)
    pal = {"o": hexc(OUTLINE), "_": hexc(SHADOW), "w": hexc(WHITE)}
    pal.update({k: hexc(v) for k, v in legend.items()})
    im = Image.new("RGBA", (len(g[0]), len(g)))
    for y, r in enumerate(g):
        for x, c in enumerate(r):
            if c != ".":
                im.putpixel((x, y), pal[c])
    return im


def count_colours(frames, legend):
    used = set()
    for g in frames:
        for r in outline(g):
            used.update(c for c in r if c != ".")
    return len(used)
