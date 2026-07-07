# Task Pipeline

Four GitHub Copilot agents that take a Jira ticket from raw context to reviewed Angular code, around one shared file (`.github/task/context.md`) — plus a local, zero-network dashboard. Full project context for AI sessions lives in `CLAUDE.md`.

| Agent | Does |
|---|---|
| **Context Getter** | Collects everything, drafts colleague questions, scores context 0–100. Hands off at 100. |
| **Planner** | Angular architect — 100/100 context → unambiguous plan under `## Planning` (file registry, checkbox steps, tests). |
| **Implementer** | Executes steps one at a time with a readiness meter; flags unclear steps back instead of guessing. Never commits. |
| **Review** | Runs type check / build / tests itself (halts on failure), audits against plan + framework rules, appends APPROVED / REJECTED verdict. |

## Install into a project (git route — the normal one)

```
cd <your-project>
git clone <this-repo>            # drop it right into the project root
bash task-helper/install.sh      # Windows: powershell -ExecutionPolicy Bypass -File task-helper\install.ps1
```

One run does everything: it removes this pipeline's old files (the four agent files, `.github/task-helper/`, the old root `task-dashboard.html`), puts every fresh file where it belongs, gitignores `.github/task/`, prints a quick usage tutorial, and finally **deletes the imported repo folder itself** — your project root stays clean. Running it from inside the imported folder works too (it installs into the parent). To update later, just import the repo again and re-run install.

**Task data is preserved** across updates; add `--reset-task` / `-ResetTask` to archive `context.md` to `.github/task/archive/` and start clean. Add `--keep-source` / `-KeepSource` to keep the imported folder around. Add `--shared <path>` / `-Shared <path>` to share the task folder with your team (next section).

Then reload VS Code → pick **Context Getter**. Agents are pinned to Claude Opus 4.8 (falls back to Sonnet 4.6; Copilot admins must enable the Opus 4.8 model policy).

## The team workspace (SharePoint/OneDrive) — full guide in [SHAREPOINT-SETUP.md](SHAREPOINT-SETUP.md)

Every ticket has its own context; one `team.md` is the super context every agent reads on every ticket:

```
.github/task/                  ← local, or a junction into the OneDrive-synced SharePoint library
├── team.md                    ← shared across ALL tickets (humans edit; Context Getter appends on request)
├── tasks/<KEY>/context.md     ← one folder per Jira ticket
└── archive/
```

Point the install at your synced library and the whole team shares it — every dashboard live-follows every ticket, and SharePoint's built-in version history covers each save of the context files:

```
bash task-helper/install.sh --shared "$HOME/SEB/Task Pipeline - kids-onboarding-mfe"
# Windows: ...install.ps1 -Shared "C:\Users\you\SEB\Task Pipeline - kids-onboarding-mfe"
```

`.github/task/` becomes a link into the synced folder (junction on Windows — no admin rights needed); an old single `context.md` is migrated into `tasks/` automatically. **Single-writer convention:** agents run on ONE machine per ticket (its owner's); everyone else watches via the dashboard.

## Install via email (.txt route — when git can't reach)

`bash export-txt.sh` builds `export/` where every file carries a `.txt` suffix (passes corp attachment filters). Receiving side: rename `setup.ps1.txt` → `setup.ps1`, run it — it strips the suffixes and places everything.

## Dashboard

Open `task-dashboard.html` in Edge/Chrome → **Open task folder** → pick `.github/task` (or your synced library folder, or drag it in). You get a **ticket switcher** — one chip per ticket with live score and status — plus the Team context card; everything live-follows while agents write. A single `context.md` still works too. Zero network — nothing leaves the machine.

**You only pick it once.** The dashboard remembers the folder (locally, in the browser): next time it either reopens automatically or shows a one-click **Resume** button — no dialog. ("forget this file" clears the memory.) **Feel it first:** click "view with sample data" (three states: gathering → implementing → approved) or open `.github/task-helper/context-example.md` and edit it while watching.

It also works for you, not just at you: the status line always names the next move; every open question has a **copy for Teams** button that produces a ready-to-paste colleague message; sections flash when a live update changes them; the tab title + favicon dot show score/blockers from a background tab; theme toggles auto/light/dark; keys `o` open, `r` refresh, `1/2/3` samples — and yes, there's confetti when Review stamps APPROVED.

## Developing this repo (Claude Code)

`CLAUDE.md` carries the entire project context — architecture, contracts, the confidence-meter spec, the dashboard's parsing format, SEB constraints — and is auto-loaded every session. So the loop is:

```
cd task-pipeline
claude                # it already knows everything; ask for the change
bash export-txt.sh    # if the change needs to travel by email
```

Ground rules for changes are in CLAUDE.md; the two that matter most: agent output formats and the dashboard parser must move together, and the dashboard stays one file with zero network calls.

## Layout

```
CLAUDE.md              project memory for Claude Code (read it — it's the spec)
SHAREPOINT-SETUP.md    team setup tutorial: shared tickets + team context over SharePoint
bundle/                exactly what lands in a target project
install.sh / .ps1      run from a target project root to install/update
export-txt.sh          builds the .txt transfer set
setup.sh / .ps1        receiving-side installers for the .txt route
```

Team conventions and per-project verify commands live in `bundle/.github/task-helper/framework-rules.md` — edit that, not the agents. Never put credentials or real internal data in this repo; the sample ticket (KIDS-1428) is invented.
