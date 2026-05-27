# /handoff — Session Handoff

When the user invokes `/handoff`, perform the following steps in order.
Do not skip steps. Do not ask for confirmation — just execute.

---

## Step 1: Gather current state

Run these in parallel:
- `git log --oneline -10` — recent commits
- `git diff HEAD` — any uncommitted changes
- `git status` — untracked files

Then read these files (they hold the live build state):
- `scripts/house_room.gd`
- `scripts/player.gd`
- `scripts/enemy.gd`

---

## Step 2: Update project_current_state memory

Overwrite `/Users/campentz/.claude/projects/-Users-campentz-PycharmProjects-we-lost-dave/memory/project_current_state.md`
with a fully up-to-date snapshot using this structure:

```
---
name: project-current-state
description: "Current build state — what's working, what's next, key file locations"
metadata:
  type: project
---

## What's built and working (as of <TODAY'S DATE>)

<bullet list — one line per system, be specific: room names, sizes, coordinates if relevant>

## Uncommitted changes

<list any uncommitted changes, or "none">

## What's next (priority order)

<numbered list — exact next step first, specific enough that a cold-start session knows exactly where to pick up>

## Key file locations

<file: purpose — only files that matter>

## Pending decisions

<any design or implementation choices still open>
```

---

## Step 3: Write the HANDOFF file

Write `/Users/campentz/.claude/projects/-Users-campentz-PycharmProjects-we-lost-dave/memory/session_handoff.md`
with this structure:

```
---
name: session-handoff
description: "Latest session summary — read this at the start of every new session"
metadata:
  type: project
---

## Session date
<TODAY'S DATE>

## What we built this session
<2–5 bullet points — concrete changes made, not vague descriptions>

## Exact next step
<One clear sentence: what to build next, which function/file, which room, etc.>

## Current room layout (house_room.gd)
<bullet list of rooms that exist in the file with their x/y bounds>

## Watch-outs
<Anything that would trip up a cold-start — coordinate conventions, known quirks, pending Godot reloads, etc.>
```

---

## Step 4: Update MEMORY.md index

Read `/Users/campentz/.claude/projects/-Users-campentz-PycharmProjects-we-lost-dave/memory/MEMORY.md`.

If there is no entry pointing to `session_handoff.md`, add this line
under the existing entries:

```
- [Session Handoff](session_handoff.md) — latest session summary; read this first at the start of every new session
```

---

## Step 5: Confirm to the user

Reply with a short summary:
- What was updated in memory
- The "exact next step" you wrote into the handoff
- Remind the user to start the next session by saying "read the handoff" or just opening Claude Code (the memory loads automatically)
