# SharePoint setup — shared tickets + team context in 15 minutes

The goal: every ticket's `context.md` and one shared `team.md` live in a SharePoint
document library; OneDrive syncs it to each intern's machine as a plain local folder;
agents write there and everyone's dashboard live-follows. Nothing leaves the M365
tenant, no new server, no firewall exception — and SharePoint versions every save.

> **No OneDrive sync client on your machine?** Common on locked-down corporate builds.
> Two fallbacks: **(a)** a mapped network drive works exactly the same — skip step 2 and
> pass the drive path to `--shared` (you lose SharePoint version history but keep live
> sharing); **(b)** skip sharing entirely — the pipeline is **fully local by default**
> (same layout, same dashboard, same agents) and context moves person-to-person: the
> dashboard's copy-for-Teams buttons, and pasting `team.md` blocks or whole `context.md`
> files over Teams. Everything else in this guide is then optional reading.

## 1 · Create the shared library (once, any of you)

1. Go to your team's SharePoint site (or make one: SharePoint start page → **Create site** → Team site).
2. **New → Document library** — name it e.g. `Task Pipeline`.
3. Inside it, create **one folder per project**, e.g. `kids-onboarding-mfe`, `ib-platform`.
4. Share the site/library with the other two interns (normal M365 sharing).

> Version history is ON by default for document libraries (500 versions). Check under
> library **Settings → Versioning settings** if you want to confirm or raise it.

## 2 · Sync it locally (each of you)

1. Open the library in the browser → click **Sync** (top toolbar). OneDrive adds it to
   File Explorer under your org name, e.g.
   `C:\Users\<you>\SEB\Task Pipeline - kids-onboarding-mfe` (exact path varies — check Explorer).
2. Recommended: right-click the folder → **Always keep on this device**, so the
   dashboard and agents never wait for a cloud download.

## 3 · Wire the project to it (each of you, per project)

```
cd <your-project>
git clone <this-repo>        # or copy the folder in; or use the synced pipeline/ copy (step 6)
bash task-helper/install.sh --shared "C:\Users\<you>\SEB\Task Pipeline - kids-onboarding-mfe"
# PowerShell: powershell -ExecutionPolicy Bypass -File task-helper\install.ps1 -Shared "<same path>"
```

This makes `.github/task` a junction into the synced folder and scaffolds the layout:

```
<library>/<project>/
├── team.md                    ← super context — every agent reads it on every ticket
├── tasks/
│   ├── KIDS-1428/context.md   ← one folder per ticket
│   └── IB-877/context.md
└── archive/
```

## 4 · Daily workflow

- **Start a ticket:** open Copilot → **Context Getter** → "KIDS-1428" + paste the ticket.
  It creates `tasks/KIDS-1428/context.md`. Work the pipeline as usual.
- **Watch everything:** open `task-dashboard.html` → **Open task folder** → pick the synced
  folder **once**. The ticket switcher shows every ticket with live score/status; the
  Team context card shows `team.md`. Next visits auto-resume (or one-click Resume).
- **Cross-ticket facts:** tell Context Getter "add this to team context" — it appends a
  dated block to `team.md`. Or just edit `team.md` by hand; everyone's dashboard updates.
- **The one rule:** agents run on **one machine per ticket** (its owner's). Everyone else
  watches via the dashboard. Two machines writing the same ticket = OneDrive conflict
  copies (`context-<PC-name>.md`) — if you see one, merge it manually and delete it.

## 5 · Version history (built in — nothing to install)

Every synced save becomes a version in SharePoint:

- **Browser:** library → right-click `context.md` or `team.md` → **Version history** →
  open or **Restore** any version.
- **File Explorer:** right-click the file → **Version history** (OneDrive context menu).

That's the "git for the context files" — automatic, per save, restorable. The dashboard
and agents themselves are versioned by this git repo.

## 6 · Optional: share the pipeline itself without git

Copy this whole repo into the library as `Task Pipeline/pipeline/`. Anyone can then
install/update from their synced copy — no git access needed:

```
cd <your-project>
bash "C:\Users\<you>\SEB\Task Pipeline - pipeline\install.sh" --shared "<project library path>"
```

(The installer never deletes a source folder that lives outside your project.)
When someone improves an agent, they update `pipeline/` once; the other two re-run install.

## Troubleshooting

- **Dashboard shows "No tickets found"** — you picked the wrong folder; pick the project
  folder that contains `tasks/` (or `.github/task` in the repo, which points to it).
- **Chips not updating** — check the OneDrive tray icon is syncing (not paused), and that
  the file isn't "cloud-only" (make it Always keep on this device).
- **Junction shows as a weird shortcut in git** — it's gitignored (`.github/task`), ignore it.
- **Someone renamed a ticket folder** — the dashboard picks it up on the next folder rescan
  (~8 s); agents just use the new key.
