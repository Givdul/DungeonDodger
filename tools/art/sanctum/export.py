"""Renders Cult Sanctum into the game's PNGs.

    python3 tools/art/sanctum/export.py

Needs Pillow. Writes asset strips, frames left to right at their native size on
a transparent background, into assets/sprites/sanctum/, and the tile atlas the
dungeon reads. The set's drawings are in sets/; this only draws them.
"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, HERE)

import sets.sanctum as S  # noqa: E402
from core import image, mirror  # noqa: E402

OUT = os.path.join(ROOT, "assets", "sprites", "sanctum")
T = S.TILES


def draw(g, legend, outlined=True):
    """A frame, the way the pack's own build.py draws it."""
    return image(g, {"o": S.OUTLINE, "_": S.SHADOW, **legend}, outlined)


def strip(frames, legend, outlined=True):
    ims = [draw(g, legend, outlined) for g in frames]
    out = Image.new("RGBA", (sum(im.width for im in ims), max(im.height for im in ims)))
    x = 0
    for im in ims:
        out.alpha_composite(im, (x, 0))
        x += im.width
    return out


def save(name, frames, legend, outlined=True):
    strip(frames, legend, outlined).save(os.path.join(OUT, name))


# Animations the game shows to one side. Our drawings face right; the other side is the drawing mirrored.
SIDED = {
    "bat_idle": S.FLYER,
    "bat_charge": S.FLYER_CHARGE,
    "bat_death": S.FLYER_DEATH,
    "phantom_idle": S.DRIFTER_IDLE,
    "phantom_run": S.DRIFTER,
    "phantom_death": S.DRIFTER_DEATH,
}

ANIMATIONS = {
    "spinner_idle": S.SPINNER_IDLE,
    "spinner_run": S.SPINNER,
    "spinner_run_down": S.SPINNER_DOWN,
    "spinner_run_up": S.SPINNER_UP,
    "spinner_death": S.SPINNER_DEATH,
    "bomberplant_idle": S.BOMBER,
    "bomberplant_spit": S.BOMBER_SPIT,
    "bomb_up": S.BOMB_UP,
    "bomb_down": S.BOMB_DOWN,
    "bomb_marker": S.BOMB_MARKER,
    "bomb_blast": S.BOMB_BLAST,
    "bomb_landed": S.BOMB,
    "crystal": S.PICKUP,
    "crystal_taken": S.PICKUP_TAKEN,
    "key": S.KEY,
    "key_taken": S.KEY_TAKEN,
    "chest": S.CHEST,
    "chest_open": S.CHEST_OPEN,
    "potion": (S.POTION[0][:1], S.POTION[1]),   # the game shows the goblet still, so its first frame only
    "life_icon": S.LIFE_ICON,
    "item_box": S.ITEM_BOX,
}

# The gate is one animation in the game: it closes, holds, then opens back up through the same frames.
GATE = T["gate"] + T["gate"][-2::-1]

# Where the dungeon and the pit read each tile from, in o_lobster's atlas' layout.
ATLAS_SIZE = (192, 208)
ATLAS = {
    (0, 9): T["wall"][0],
    (5, 9): mirror(T["wall"][0]),
    (7, 11): T["floor"][0],
    (8, 11): T["floor"][2],
    (8, 12): T["floor"][3],
    (9, 12): T["floor"][4],
    (10, 12): T["line"],
}


def atlas():
    im = Image.new("RGBA", ATLAS_SIZE)
    for (x, y), g in ATLAS.items():
        im.alpha_composite(draw(g, T["legend"], False), (x * 16, y * 16))
    # pit.tscn takes the hole's top edge from the atlas at this rect: one cell's width, six pixels tall.
    im.alpha_composite(draw(T["pit_lip"], T["legend"], False), (16, 16))
    im.save(os.path.join(OUT, "dungeon_tileset.png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, (frames, legend) in SIDED.items():
        save(f"{name}_right.png", frames, legend)
        save(f"{name}_left.png", [mirror(g) for g in frames], legend)
    for name, (frames, legend) in ANIMATIONS.items():
        save(f"{name}.png", frames, legend)
    save("spikes.png", T["spikes"], T["legend"], False)
    save("pit_crumble.png", T["crumble"], T["legend"], False)
    save("gate.png", GATE, T["legend"], False)
    atlas()


if __name__ == "__main__":
    main()
