# Agent instructions

## Running the game

- Test without sound. Before `project_run`, check that `~/Library/Application Support/Godot/app_userdata/Dungeon Dodger/settings.cfg` has `muted=true` under `[audio]`. Every worktree shares that file, and the game reads it at startup. The mute button saves to it too, so if a test presses that button, leave it muted. Headless runs make no sound.
- Call `project_manage` with `op: "stop"` before closing the editor or ending the task. A running game outlives its editor and keeps playing.

## Web demo

`https://apps.givdul.com/dd` is the Web export, assembled by `tools/build_web_demo.sh <destination>`:

```sh
godot --headless --path . --import   # once per fresh checkout
tools/build_web_demo.sh ../zones-web/public/dd
```

The script exports the `Web` preset, gzips `index.wasm` (37.7 MiB, over Cloudflare's 25 MiB per-file limit), copies the assets from `web/`, and fails if any output file is too large. `web/shell.html` is the custom shell: tap-to-play start screen, desktop QR gate, Android fullscreen and portrait lock, and the loader that unpacks the gzipped engine.

From zones-web, `npm run build && npx wrangler dev` serves it at http://localhost:8787/dd. The page is at `/dd` without a trailing slash, so the shell sets `<base href="/dd/">`. On a desktop browser add `?play=1` (http://localhost:8787/dd?play=1) to skip the touch check.

## Pull requests

Every PR that changes the game includes screenshots of the running game, one per screen or state the PR adds or changes.

- Capture them with the godot-ai MCP: `project_run`, drive the game to each state with `game_manage`, then `editor_screenshot` with `source: "game"` and `max_resolution: 0`.
- Commit the PNGs to `pr-<number>/` on the `screenshots` branch, not the PR branch. That orphan branch only holds screenshots, so they stay out of `master`. Use a temporary `git worktree` so the PR branch's working tree is untouched.
- Embed them in the PR description as a table, each image as `<img src="https://github.com/Givdul/DungeonDodger/blob/screenshots/pr-<number>/<name>.png?raw=true" width="200">`.

## Gameplay bot

`tools/bot/` plays seeded runs headless, for balance testing. It's tooling, and the export presets leave it out. A fresh checkout needs `godot --headless --path . --import` first; without it the bot exits with an error. The first pass can stop after a couple of files, so run it again if `.godot/imported` looks nearly empty.

```sh
godot --headless --path . --fixed-fps 60 res://tools/bot/bot_runner.tscn -- --runs=30 --seed=1 --skill=casual
```

- Options: `--runs` (30), `--seed` (1), `--skill` (`casual` or `good`), `--max-seconds` (600 real seconds, after which a run ends as `timeout`).
- Run `n` seeds the global RNG with `seed + n`, so the same options give the same results, and `--runs=1 --seed=<seed>` replays one run. Keep `--fixed-fps 60`: without it the runs play in real time and stop being reproducible. 30 runs take about 1.5 minutes for `casual` and 6 for `good`. For more speed, run separate seed ranges in parallel processes.
- The bot starts each run the way PLAY does and steers only by pressing `move_*` actions, as a swipe does. It reacts after a delay and looks a short way ahead for holes, traps, solids, enemies, bat wind-ups, bomb markers and the scroll edges, and it goes for coins. The skills differ in reaction time, decision rate, lookahead and lapses (`SKILLS` in `autopilot.gd`). Those are in real time, since a person doesn't slow down with the game. Its predictions step in game time.
- Output: every line that starts with `{` is JSON. There is one `"type": "run"` line per run, with `survival_seconds` (real seconds from the first move, not game seconds), `score`, `hits` (lives lost, falls included), `death_cause` (an enemy's scene name, `hole`, `crumbling_floor`, `spikes`, `bomb`, `crush` or `timeout`), `max_plants_in_view`, `max_enemies_in_view`, and the longest run of rows without coins and with them. A final `"type": "summary"` line gives median, p10 and p90 survival, the median score and hits, death causes in percent, and the maxima of the per-run counts.
- Headless, the view is the project's 720x1280 with no safe-area insets. A tall phone shows about a tile row more, so counts in view and survival can differ a little from a device.
- To watch it, run `res://tools/bot/bot_runner.tscn` from the editor. It plays in real time with the defaults.
