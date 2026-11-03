# Agent instructions

## Pull requests

Every PR that changes the game includes screenshots of the running game, one per screen or state the PR adds or changes.

- Capture them with the godot-ai MCP: `project_run`, drive the game to each state with `game_manage`, then `editor_screenshot` with `source: "game"` and `max_resolution: 0`.
- Commit the PNGs to `pr-<number>/` on the `screenshots` branch, not the PR branch. That orphan branch only holds screenshots, so they stay out of `master`. Use a temporary `git worktree` so the PR branch's working tree is untouched.
- Embed them in the PR description as a table, each image as `<img src="https://github.com/Givdul/DungeonDodger/blob/screenshots/pr-<number>/<name>.png?raw=true" width="200">`.

## Gameplay bot

`tools/bot/` plays seeded runs headless, for balance testing. It's tooling, and the export presets leave it out.

```sh
godot --headless --path . --fixed-fps 60 res://tools/bot/bot_runner.tscn -- --runs=30 --seed=1 --skill=casual
```

- Options: `--runs` (30), `--seed` (1), `--skill` (`casual` or `good`), `--max-seconds` (600, after which a run ends as `timeout`).
- Run `n` seeds the global RNG with `seed + n`, so the same options give the same results, and `--runs=1 --seed=<seed>` replays one run. Keep `--fixed-fps 60`: without it the runs play in real time and stop being reproducible. 30 runs take about 1 minute for `casual` and 4 for `good`. For more speed, run separate seed ranges in parallel processes.
- The bot starts each run the way PLAY does and steers only by pressing `move_*` actions, as a swipe does. It reacts after a delay and looks a short way ahead for holes, traps, solids, enemies, bat rush markers, bomb markers and the scroll edges, and it goes for coins. It never dodge-rolls. The skills differ in reaction time, decision rate, lookahead and lapses (`SKILLS` in `autopilot.gd`).
- Output: every line that starts with `{` is JSON. There is one `"type": "run"` line per run, with `survival_seconds` (from the first move), `score`, `hits` (lives lost, falls included), `death_cause` (an enemy's scene name, `hole`, `crumbling_floor`, `spikes`, `bomb`, `crush` or `timeout`), `max_plants_in_view`, `max_enemies_in_view`, and the longest run of rows without coins and with them. A final `"type": "summary"` line gives median, p10 and p90 survival, the median score and hits, death causes in percent, and the maxima of the per-run counts.
- To watch it, run `res://tools/bot/bot_runner.tscn` from the editor. It plays in real time with the defaults.
