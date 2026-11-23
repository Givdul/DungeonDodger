"""Optional helpers for a set's tiles. Use them, copy them, or draw every frame yourself."""
from core import stamp


def trap(floor, down, tips, up):
    """A floor trap's loop from three overlays: resting, rising, fully out."""
    a, b, c = stamp(floor, down), stamp(floor, tips), stamp(floor, up)
    return [a, a, b, c, c, c, b, a]


def rising(base, drawing, steps=5):
    """A 16x32 barrier coming up out of the floor: `drawing` slides up from the bottom of `base`."""
    out = []
    for i in range(steps):
        h = round(len(drawing) * i / (steps - 1))
        out.append(stamp(base, drawing[:h], 0, len(base) - 2 - h) if h else base)
    return out


def breaking(floor, pit, cracks, tones):
    """A floor tile that cracks, splits into four pieces and sinks into `pit`.
    cracks: two overlays, light then heavy. tones: three legend characters the pieces
    take as they sink, from floor colour to nearly the pit's."""
    cracked = stamp(floor, cracks[0])
    out = [floor, cracked, stamp(cracked, cracks[1])]
    for inset, tone in enumerate(tones):
        g = [list(r) for r in pit]
        for qx, qy in ((0, 0), (8, 0), (0, 8), (8, 8)):
            x0, y0 = qx + inset + (1 if qx else 0), qy + inset + (1 if qy else 0)
            x1, y1 = qx + 8 - inset - (0 if qx else 1), qy + 8 - inset - (0 if qy else 1)
            for y in range(y0, y1):
                for x in range(x0, x1):
                    g[y][x] = tone
        out.append(["".join(r) for r in g])
    return out + [pit]
