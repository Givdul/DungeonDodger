# Agent instructions

## Pull requests

Every PR that changes the game includes screenshots of the running game, one per screen or state the PR adds or changes.

- Capture them with the godot-ai MCP: `project_run`, drive the game to each state with `game_manage`, then `editor_screenshot` with `source: "game"` and `max_resolution: 0`.
- Commit the PNGs to `pr-<number>/` on the `screenshots` branch, not the PR branch. That orphan branch only holds screenshots, so they stay out of `master`. Use a temporary `git worktree` so the PR branch's working tree is untouched.
- Embed them in the PR description as a table, each image as `<img src="https://github.com/Givdul/DungeonDodger/blob/screenshots/pr-<number>/<name>.png?raw=true" width="200">`.
