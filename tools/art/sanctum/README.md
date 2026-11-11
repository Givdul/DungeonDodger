# Cult Sanctum

The art Dungeon Dodger shows for everything but the hero: the corridor, traps, enemies,
pickups and the HUD frame. It is a forbidden temple mid-ritual, drawn in o_lobster's
construction rules (16x16, a 1px outline, one ground shadow, flat two-tone materials) and
in the same pixel-per-character style as his pack.

The drawings live in `sets/`, one file per group, with `sets/sanctum.py` assembling them and
`sets/sanctum_palette.py` holding every colour. `core.py` draws a grid of characters into an
image; `kit.py` has helpers for tiles. Nothing in here is generated at runtime: the game reads
only the PNGs.

Re-export after changing a drawing:

```sh
python3 tools/art/sanctum/export.py
```

It needs Pillow, and writes `assets/sprites/sanctum/`, frames left to right at their native
size on a transparent background, plus `dungeon_tileset.png`, the tile atlas laid out where
`scripts/dungeon.gd` and `scenes/pit.tscn` read their tiles. It is deterministic: running it
twice gives byte-identical files.

The set's first exploration happened in `/tmp/lstack/DungeonDodger/pack/dark/`, outside the
repo; those files are gone with the machine's temp dir. What survives is this folder: the
drawings, the palette and the export.
