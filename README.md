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

## The workspace — fully local by default

Every machine gets its own workspace (gitignored), scaffolded by the installer:

```
.github/task/
├── team.md                    ← your cross-ticket context: every agent reads it on every ticket
│                               (you edit it; Context Getter appends on request)
├── tasks/<KEY>/context.md     ← one folder per Jira ticket
└── archive/
```

**No OneDrive / no shared drive? This is the mode for you** — everything works locally, and context moves person-to-person instead: the dashboard's **copy for Teams** button for questions, and pasting `team.md` blocks or a whole `context.md` to a teammate (their Context Getter files it under the right ticket). Nothing is lost except live-watching each other's dashboards.

**If you do have any shared folder that shows up in File Explorer** — an OneDrive-synced SharePoint library *or a mapped network drive* — one flag shares the whole workspace (live dashboards for everyone; SharePoint adds version history). Full guide: [SHAREPOINT-SETUP.md](SHAREPOINT-SETUP.md).

```
bash task-helper/install.sh --shared "<path to the shared folder>"
# Windows: ...install.ps1 -Shared "<same path>"
```

`.github/task/` becomes a link into it (junction on Windows — no admin rights needed); existing local tickets migrate in automatically. **Single-writer convention:** agents run on ONE machine per ticket (its owner's).

## Install via email (.txt route — when git can't reach)

`bash export-txt.sh` builds `export/` where every file carries a `.txt` suffix (passes corp attachment filters). Receiving side: rename `setup.ps1.txt` → `setup.ps1`, run it — it strips the suffixes and places everything.

## Dashboard

Open `task-dashboard.html` in Edge/Chrome → **Open task folder** → pick `.github/task` (or your synced library folder, or drag it in). You get a **ticket switcher** — one chip per ticket with live score and status — plus the Team context card; everything live-follows while agents write. A single `context.md` still works too. Zero network — nothing leaves the machine.

**You only pick it once.** The dashboard remembers the folder (locally, in the browser): next time it either reopens automatically or shows a one-click **Resume** button — no dialog. ("forget this file" clears the memory.) **Feel it first:** click "view with sample data" — a three-ticket sample workspace (gathering → implementing → approved, plus a team.md) you can flip through with the ticket chips — or open `.github/task-helper/context-example.md` and edit it while watching.

It also works for you, not just at you: the status line always names the next move; a **Message the agents** box sends what you type straight toward Copilot (prefixed with the active ticket key, copied + a `vscode://` handoff that opens VS Code — paste if the chat doesn't prefill); every open question has **copy for Teams** buttons in English or Latvian; sections flash when a live update changes them; the tab title + favicon dot show score/blockers from a background tab; theme toggles auto/light/dark; keys `o` open, `r` refresh, `[ ]`/`1-3` switch ticket — and yes, there's confetti when Review stamps APPROVED.

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
