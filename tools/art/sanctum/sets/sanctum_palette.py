"""Cult Sanctum's shared palette. Every sprite and tile in the set takes its colours from here.

o_lobster's sprites are flat: each material is one base colour and one shade, and the whole sprite
uses 4-8 colours including the outline. These ramps are two tones each on purpose. A third tone only
exists where a material needs a highlight the near-white can't give (gold, iron, stone, fire).
"""

P = {
    # shared by everything
    "ink": "#1b1520",        # OUTLINE
    "shadow": "#352c39",     # SHADOW, the ground shadow
    "white": "#f1eee6",      # the 'w' near-white: glints, teeth, spike tips, the hottest pixel of a flame

    # temple stone, darkest to lightest: void of a pit, mortar and pit walls, grout and floor shade, floor, brick and lit edges
    "void": "#150f16",
    "deep": "#2a2230",
    "grout": "#3d3342",
    "floor": "#4a3f4e",
    "brick": "#5a4e62",

    # iron and carved stone (gargoyle, gate, straps, key shaft): light, base, shade
    "iron_lit": "#a39bb0",
    "iron": "#81768a",
    "iron_dark": "#5e5569",

    # bone, wax, parchment, horn
    "bone": "#bdb09a",
    "bone_dark": "#8d8272",

    # wood
    "wood": "#6e4636",
    "wood_dark": "#523327",

    # the hero: skin, copper hair, dusty smock
    "skin": "#c6966f",
    "skin_dark": "#9a6d58",
    "hair": "#9d5a3a",
    "hair_dark": "#6e3a2b",
    "smock": "#7f7566",
    "smock_dark": "#5a514b",

    # tan: rope, the imp's hide
    "tan": "#a87d4c",
    "tan_dark": "#7a5737",

    # violet: the imp's wing
    "violet": "#7a5a80",
    "violet_dark": "#5a4262",

    # red: cult robes and blood (dark, base), and the hot red of embers, glowing eyes, lit runes, tongues
    "blood_dark": "#4e1f2b",
    "blood": "#6b2a36",
    "ember": "#c4473a",

    # gold: candle flame, coins, the reward colour (pale, base, shade)
    "gold_pale": "#f3d98a",
    "gold": "#e1b553",
    "gold_dark": "#b5803a",

    # pink: life, used only for the heart that rises from the goblet
    "life": "#d9606a",
}

PALETTE = set(P.values())
