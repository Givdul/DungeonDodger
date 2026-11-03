---
name: file-issue
description: File GitHub issues in this repo from playtest feedback, bug reports, or feature ideas. Use when the user asks to file, create, register, or log an issue, or passes feedback in a thread they set up for filing issues. Produces one agent-ready issue per problem.
---

# File issue

The user plays the game on a phone and passes feedback, often short or dictated. Turn each item into an issue that a coding agent can pick up cold with the `ticket` skill. The user asked for the issues, so file them without a preview. Ask first only when you can't tell what the player saw or wanted.

## 1. Split and dedupe

- Make one issue per problem, sized for one branch and PR. Combine notes only when they share a fix.
- Search before filing: `gh issue list --state all --search "<keywords>"`. Also scan the open umbrella issues (`gh issue list --state open`), because polish ideas live as checklist bullets in issues like #25.
- If an open issue already covers the note, comment the new detail there instead. If the note was a bullet in an umbrella issue, file the issue and replace the bullet with `#<new>`.

## 2. Investigate

Find where the behavior comes from before writing. Read the scripts and scenes involved. Delegate to a cheap read-only agent when it spans many files. Spend minutes on this, not a fix.

- Write a `### Cause` section only for what you confirmed in code. Put guesses under `### Likely cause` and say what would confirm them.
- Name scripts, scenes, nodes, functions, and signals, for example `scripts/player.gd::_physics_process`. Don't cite line numbers.
- Quote exact values (speeds, timers, sizes) when they matter.

## 3. Write

The title is under 70 characters, in sentence case, with no prefix. A bug title names the symptom ("Swipe controls don't move the player"). An enhancement title names the change ("Blink the player during invulnerability").

Use this body, and leave out the sections that don't apply:

```markdown
<What the player sees, or what should change, in 1-3 sentences.>

Reported from playtest on <device> (build <master short SHA>).

### Steps to reproduce
1. ...

### Cause
<Confirmed cause, or use "Likely cause" with what would confirm it.>

### Expected
<The intended behavior, including touch input, pause, game over, and small screens where they apply.>

### Acceptance
- [ ] <Concrete, observable check in the running game>
- [ ] <Things that must keep working>

### Out of scope
<Nearby things the implementer should not change.>
```

Bugs need Steps to reproduce and Expected. Enhancements need Expected, and Steps to reproduce only when the current behavior needs showing. Write acceptance items as things you can check by playing. Don't write "code is clean".

## 4. File

1. Write the body to a temp file. Then run:
   `gh issue create --title "<title>" --body-file <file> --label <bug|enhancement> [--label ios] --project DungeonDodger --milestone "iOS 1.0"`
   Leave out the milestone when the user says the item can wait until after release. The board also auto-adds new issues, so `GraphQL: Content already exists in this project` means the issue was filed. Confirm it with `gh issue list --limit 3` instead of filing it again.
2. Phone screenshots from the user: commit them to `issue-<number>/` on the `screenshots` branch from a temporary `git worktree`, the same way AGENTS.md does it for PRs. Then edit the issue to embed `<img src="https://github.com/Givdul/DungeonDodger/blob/screenshots/issue-<number>/<name>.png?raw=true" width="200">`.
3. Reply with one line per issue: `#<n> <title> — <url>`, plus any comment you added to an existing issue instead.

Done when every feedback item is a filed issue or a comment on an existing one, and the user has the links.
