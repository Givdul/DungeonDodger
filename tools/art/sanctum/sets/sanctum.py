"""Cult Sanctum: a forbidden temple under the dungeon, mid-ritual. The current version of the set.

Each part file holds its own drawings; this one only assembles them.
"""
from sets.sanctum_v3 import *  # noqa: F401,F403
from sets.sanctum_palette import PALETTE  # noqa: F401
from sets.sanctum_hero import HERO  # noqa: F401
from sets.sanctum_foes import FLYER, FLYER_CHARGE, FLYER_DEATH, DRIFTER, DRIFTER_IDLE, DRIFTER_DEATH, BOMBER, BOMBER_SPIT
from sets.sanctum_bomb import BOMB, BOMB_UP, BOMB_DOWN, BOMB_MARKER, BOMB_BLAST  # noqa: F401
from sets.sanctum_fire import (SPINNER, SPINNER_DRIFT, SPINNER_TRAIL, SPINNER_IDLE, SPINNER_DOWN, SPINNER_UP,
                               SPINNER_TRAIL_V, SPINNER_DEATH)  # noqa: F401
from sets.sanctum_items import PICKUP, PICKUP_TAKEN, KEY, KEY_TAKEN, POTION, LIFE_ICON, ITEM_BOX  # noqa: F401
from sets.sanctum_chests import CHEST, CHEST_OPEN, MIMIC, MIMIC_BITE  # noqa: F401
from sets.sanctum_tiles import TILES  # noqa: F401

PITCH = ("Charcoal-plum temple mid-ritual: the runaway sacrifice, an imp familiar, a candle-bearing cultist, "
         "a rolling fire that leaves a burning trail, a fire-spitting gargoyle, a chest, the mimic that looks "
         "like it, and spell-circle traps.")
