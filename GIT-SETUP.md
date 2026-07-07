# Git setup — the task hub in 10 minutes

The hub is ONE git repo the whole team shares: agents, dashboard, and every project's
ticket contexts. Clone it once per machine. Sharing = `git push` / `git pull` (with
full version history and authorship for free). Tool updates = one `git pull` from
upstream. **No installers, no scripts, nothing to unbundle.**

## 1 · Create your team's hub (once, any of you)

Your ticket contexts contain internal SEB text, so the hub must live on an
**internal/private** remote (Bitbucket at SEB, or a private GitHub repo):

1. Create an empty private repo, e.g. `task-hub`.
2. Push this repo's contents into it:

```
git clone <this-repo-url> task-hub
cd task-hub
git remote rename origin upstream        # upstream = the tool, for updates
git remote add origin <your-private-repo-url>
git push -u origin main
```

## 2 · Each intern (once per machine)

```
git clone <your-private-repo-url> task-hub
cd task-hub && git remote add upstream <this-repo-url>
```

**Connect it to a code project in VS Code:** open your project, then
*File → Add Folder to Workspace…* → pick `task-hub`, and *File → Save Workspace As…*
(e.g. `kids.code-workspace`). From now on open that workspace file — Copilot sees the
hub's four agents, and the agents can read your code AND write the hub's contexts.

**Dashboard:** open `task-hub/task-dashboard.html` in Edge/Chrome → *Open task folder*
→ pick the `task-hub` folder once (it's remembered). Project chips → ticket chips → live.

## 3 · Daily flow

```
git pull          # in task-hub, before you start — teammates' context arrives
… work the pipeline (agents write projects/<project>/tasks/<KEY>/context.md) …
git add -A && git commit -m "KIDS-1428: context + plan" && git push
```

- **One writer per ticket** at a time is still the smoothest. If two of you do touch
  the same ticket, git merges markdown well — and the dashboard flags leftover
  conflict copies with ⚠.
- Agents never run git; pushing/pulling the hub is always a human action.
- Version history = `git log -- projects/kids-onboarding-mfe/tasks/KIDS-1428/` or your
  git UI of choice. Restore anything, anytime.

## 4 · Tool updates — "an update arises, you pull, boom"

```
git pull upstream main && git push
```

Upstream only ever changes the tool (`.github/agents/`, `task-helper/`,
`task-dashboard.html`, docs) and never touches `projects/` or `team.md`, so this
merge is clean. One person does it; everyone else gets it on their next `git pull`.

## 5 · The layout (created by the agents as you work)

```
task-hub/
├── team.md                          global context — every agent, every project
├── projects/<project>/
│   ├── project.md                   per-project context (optional)
│   └── tasks/<KEY>/context.md       one folder per ticket
└── archive/                         park old projects/tickets here if you want
```

## 6 · Rules

- The hub remote stays **internal/private** — ticket text never leaves it.
- **No credentials, tokens, or personal data** in any context file, ever.
- Contexts never go into the product repos; the hub never contains product code.
- The dashboard stays one file, zero network — it reads your local clone; `git pull`
  is what refreshes it (the file watcher picks the pull up within seconds).

## Migrating from the old `.github/task` layout

Copy each old ticket folder into the hub and push:

```
cp -r <project>/.github/task/tasks/* task-hub/projects/<project>/tasks/
cp <project>/.github/task/team.md task-hub/team.md   # merge by hand if both exist
```

Then delete the project's `.github/task` link/folder and the four old agent files in
`<project>/.github/agents/` — the hub replaces them.
