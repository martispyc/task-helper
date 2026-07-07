# Task Pipeline — the task hub

Four GitHub Copilot agents that take a Jira ticket from raw context to reviewed Angular code, plus a local zero-network dashboard — all living in **one git repo (the hub)** that also holds every project's ticket contexts. Clone once, `git pull`/`git push` to share, `git pull upstream` to update the tooling. Full project context for AI sessions lives in `CLAUDE.md`.

| Agent | Does |
|---|---|
| **Context Getter** | Resolves project + ticket, collects everything into the ticket's context.md, drafts colleague questions (EN/LV), scores context 0–100. Hands off at 100. |
| **Planner** | Angular architect — 100/100 context → unambiguous plan under `## Planning` (file registry, checkbox steps, tests). |
| **Implementer** | Executes steps one at a time with a readiness meter; flags unclear steps back instead of guessing. Never commits. |
| **Review** | Runs type check / build / tests itself (halts on failure), audits against plan + framework rules, appends APPROVED / REJECTED verdict. |

## Setup — clone once, no installers ([full guide](GIT-SETUP.md))

```
git clone <your-team's-private-hub-repo> task-hub
```

Then in VS Code: open your code project → **File → Add Folder to Workspace…** → `task-hub` → save the workspace. Copilot now offers the four agents; they read your code and write the hub's contexts. Updates: `git pull upstream main` — that's the whole update story.

## The hub layout

```
task-hub/
├── .github/agents/              the four agents (picked up via the VS Code workspace)
├── task-helper/                 templates + framework-rules.md (team conventions — edit these, not the agents)
├── task-dashboard.html          the dashboard
├── team.md                      GLOBAL context — every agent reads it on every ticket
├── projects/<project>/
│   ├── project.md               per-project context (optional)
│   └── tasks/<KEY>/context.md   one folder per Jira ticket
└── GIT-SETUP.md · CLAUDE.md · README.md
```

Sharing = `git pull` before you start, `git push` when you pause. One writer per ticket; git's history is your version history. The hub remote must be **internal/private** — context files hold internal ticket text (never credentials, never in product repos).

## Dashboard

Open `task-dashboard.html` in Edge/Chrome → **Open task folder** → pick your `task-hub` clone (once — it's remembered and auto-resumes). You get **project chips → ticket chips**, each ticket with live score and status; the Team context card shows global `team.md` plus the active project's `project.md`; everything live-follows the files, so a `git pull` refreshes the view within seconds. A single `context.md` still works too. Zero network — nothing leaves the machine.

**Feel it first:** click "view with sample data" — a three-ticket sample workspace (gathering → implementing → approved, plus a team.md) — or open `task-helper/context-example.md` and edit it while watching.

It also works for you, not just at you: the status line always names the next move — with a **one-click AI button** beside it that assembles the right prompt for the current stage (generate questions, make the plan, next step, run Review, fix R-items); a **"+ new ticket"** form kicks off the Context Getter from pasted Jira material; **"+ generate more"** sits on the questions card and every question has **answer → AI** filing plus **copy for Teams** in English or Latvian; a **Message the agents** box sends anything else you type (all of these copy the prompt + a `vscode://` handoff that opens VS Code — paste if the chat doesn't prefill); sections flash when a live update changes them; the tab title + favicon dot show score/blockers from a background tab; theme toggles auto/light/dark; keys `o` open, `n` new ticket, `r` refresh, `[ ]`/`1-3` switch ticket — and yes, there's confetti when Review stamps APPROVED.

## Developing this repo (Claude Code)

`CLAUDE.md` carries the entire project context — architecture, contracts, the confidence-meter spec, the dashboard's parsing format, SEB constraints — and is auto-loaded every session:

```
cd task-hub
claude                # it already knows everything; ask for the change
```

Ground rules: agent output formats and the dashboard parser must move together; the dashboard stays one file with zero network calls; tool changes never touch `projects/` or `team.md` (that's what makes team pulls conflict-free). Never put credentials or real internal data in this repo; the sample tickets (KIDS-1428 etc.) are invented.
