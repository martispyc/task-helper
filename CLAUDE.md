# CLAUDE.md — Task Pipeline

This repo is the source of truth for a four-agent GitHub Copilot pipeline + local dashboard used at SEB (Digital Channels) to take a Jira ticket from raw context to reviewed Angular code. This file carries the full project context so any session here can extend the system without re-explaining.

## What ships (bundle/)

`bundle/` mirrors exactly what lands in a target project:

```
bundle/
├── .github/agents/            context-getter · planner · implementer · review (.agent.md)
├── .github/task-helper/       context-template.md · framework-rules.md · context-example.md · team-template.md
└── task-dashboard.html        single-file, zero-network dashboard (goes to target repo root)
```

Target projects additionally get `.github/task/` (gitignored; local dir or `--shared` junction into a OneDrive-synced SharePoint library) with the **workspace layout** the install script scaffolds:

```
.github/task/
├── team.md                    super context — every agent reads it on every ticket;
│                              humans edit; only Context Getter appends (dated blocks
│                              under ## Shared notes), only on explicit user request
├── tasks/<KEY>/context.md     one folder per Jira ticket (per-file format unchanged)
└── archive/
```

Agents resolve the ticket first (key from the user's message, else ask) — `tasks/<KEY>/context.md` is the session's working file; Context Getter creates it from the template. SHAREPOINT-SETUP.md (repo root) is the team's setup tutorial; SharePoint's automatic version history is the versioning story for the context files.

## Architecture — the pipeline

**Context Getter → Planner → Implementer → Review**, all communicating through ONE file per ticket: `.github/task/tasks/<KEY>/context.md`. Section ownership is strict:

| Section | Owner | Behaviour |
|---|---|---|
| `## Confidence` | Context Getter | rewritten in place after every update |
| `## Ticket` | Context Getter | updated in place |
| `## Additional info` | Context Getter | append-only, `### YYYY-MM-DD — source` blocks |
| `## Open questions` / `## Q&A` | Context Getter | Q-items move to Q&A when answered |
| `## Planning` | Planner writes; Implementer ticks step checkboxes | Planner never writes above this heading |
| `## Review` | Review | appends dated verdicts |

Different teammates own different agents. Each agent file starts with a **Contract block** (input / output / boundary) — bodies are replaceable, contracts and file names are not.

**Why four agents + one file (not an orchestrator, not one agent):** an orchestrator agent would be the most fragile piece — Copilot `handoffs` are VS Code-only, there's no reliable programmatic sub-agent control across surfaces, and it removes the human checkpoint between stages where mistakes get caught. One merged agent hits the 30k body cap, loses per-stage tool scoping (Context Getter/Planner deliberately can't `execute` — a safety property at a bank), and role-bleeds (plans while gathering, defeating the meter's anti-inflation rule). The shared file with strict section ownership *is* the orchestrator: deterministic, auditable, surface-independent. For trivial tasks the pipeline degrades gracefully (stay in Context Getter, or use the recorded override).

## Non-negotiable specs

### Confidence meter (Context Getter)
Six dimensions 0–100: goal & why · done-definition · scope boundaries · code context · dependencies & environment · blocking questions. **Overall = min of the six.** A dimension reaches 100 only on ✅-verified evidence (🟡 caps 80, ❓ caps 40); an open blocking Q caps its dimension at 60; blocking-questions dimension = 100 − 15 per open blocker (floor 40); zero blockers required for overall 100. Anti-inflation: score rises only on new material. At 100 → stamp `READY FOR PLANNING ✅`. Override allowed but recorded.

### Confidence markers (all agents)
✅ verified (read this session, file cited) · 🟡 inferred · ❓ guess (must become a Q-item or `needs planning ⏳` flag).

### Dashboard format contract — DO NOT DRIFT
`task-dashboard.html` regex-parses these exact shapes. Changing an agent's output format requires updating the dashboard parser in the same commit, and vice versa:

- Title: `# KEY-123 — title` (H1, em-dash)
- `OVERALL: <n>/100 — <label>   (updated YYYY-MM-DD)` and optional `OVERRIDE: …` line
- Dimensions: `- <name>: <n> — <note>`
- Questions: `### Q-<n> ⏳ blocking — ask: <role>` / `### Q-<n> ✅ — answered by <who>, <date>` with `**Question:** / **Why it matters:** / **Best guess:** / **Answer:**`; optional `(LV)` twin lines (`**Question (LV):**` etc.) feed the dashboard's Latvian copy button
- Info blocks: `### YYYY-MM-DD — <source>`
- Plan steps: `- [ ] Step <n> — <name>` / `- [x] …`; flag text `needs planning ⏳`
- Verdicts: `### Verdict — <date>`, `STATUS: APPROVED | REJECTED — RETURN TO IMPLEMENTER`, items `- R<n> [must-fix|should-fix|nit] file:line — …`, `Verified: …`

### Copilot custom-agent facts (verified 2026-07)
- Location `.github/agents/<name>.agent.md`; frontmatter: `name`, `description`, `tools`, `model`, `handoffs`, `disable-model-invocation`. Body ≤ 30,000 chars.
- Portable tool aliases: `read`, `search`, `edit`, `execute`, `todo`, `agent`. Unrecognized tools are ignored.
- `model: ['Claude Opus 4.8', 'Claude Sonnet 4.6']` — array tries in order; Opus 4.8 is GA in Copilot but org admins must enable its model policy.
- `handoffs` (label/agent/prompt/send) are VS Code-only; other surfaces ignore them. Targets referenced by filename (e.g. `agent: planner`).
- Works identically with Bitbucket-hosted repos — Copilot reads these from the local workspace; the `.github/` folder name is fixed.
- Context Getter and Planner deliberately have no `execute` tool. Review has no `todo`. Only Implementer gets the full set.

## Environment constraints (SEB = bank)

- **Transfer:** corp filters block zip/html/ps1 attachments → the `.txt` suffix route (`export-txt.sh` builds it; `setup.ps1`/`setup.sh` are the receiving-side installers for that route).
- **Dashboard:** must stay ONE file, ZERO network calls (no CDN, no webfonts — system font stacks only), works in Edge. File System Access API gives live-follow in Edge/Chrome; `<input type=file>`/drag-drop is the fallback. This is the property that survives bank security review — never break it.
- **Data:** context.md holds internal ticket/chat text → `.github/task/` is always gitignored; never let agents store credentials/personal data; the sample data (KIDS-1428) is invented, keep it that way.
- **Team sharing is OPTIONAL:** corp machines often lack the OneDrive sync client, so **fully-local-per-machine is the default mode** — each intern has their own workspace (tickets + team.md as personal cross-ticket context) and context moves person-to-person (copy-for-Teams buttons, pasted team.md blocks / context.md files). Where a synced SharePoint library or a mapped network drive IS available, `--shared` junctions `.github/task` into it (agents/dashboard unchanged; SharePoint adds version history; single-writer per ticket). Never "fix" sharing by adding network calls to the dashboard.
- **Git:** agents never commit/push/branch/PR on their own.

## Angular specifics

Team facts live in `bundle/.github/task-helper/framework-rules.md` (projects kids-onboarding-mfe and ib-platform, per-project tsc/build/test commands run from inside the project folder, RxJS/typing/component rules). **Edit that file, not the agents**, when conventions change. Review runs those commands itself before reading any logic and halts to REJECTED on failure.

## Dashboard design system

Vercel/v0, **light by default, auto dark** via `@media (prefers-color-scheme: dark)` — every color flows through `:root` tokens; the dark block only overrides tokens, never rules. Light: bg/cards `#FFFFFF`, inset `#FAFAFA`, borders `#EAEAEA`/`#D9D9DE`, text `#171717` / muted `#666` / faint `#8F8F8F`, black primary button, green `#0A8A4A`, amber `#A15C07`, red `#CB2A2F`, focus blue `#0070F3`, subtle card shadow. Dark: bg `#0A0A0A`, cards `#111113`, borders `#26262A`, text `#EDEDED`, white primary button, green `#0CCE6B`, amber `#F5A623`, red `#F14C4C`, blue `#52A9FF`. Shared: faint blue radial top glow (`--glow`), 12px card radius, `ui-monospace/Cascadia Mono` for meta (system stacks only — zero network), 860px single column: branded top bar (CSS-triangle logo, primary + ghost buttons), pipeline dot strip, hero card (`--hero-grad`, green-tinted border via `:has` when ready) holding title + 72px weight-650 tabular score + 6px rounded gradient bars (`--fill-grad`/`--ready-grad` on `--track`), then one card per section with pill count badges; questions/severities/verdicts as tinted pills. Staggered `.rv` reveals, rAF count-up, `prefers-reduced-motion` respected. Demo mode: an embedded **three-ticket sample workspace** (KIDS-1433 gathering / KIDS-1428 implementing / IB-877 approved, plus a sample team.md) behind "view with sample data" — it runs through the real workspace code path via in-memory `File` handles; chips or `[ ]`/1-3 switch; opening a real file/folder exits demo. **Eyeball both color schemes** after any change.

UX layer (all local, zero network): **workspace mode** — `showDirectoryPicker` (or folder drag-drop) on `.github/task`/the synced library: scans `tasks/*/context.md` + `team.md`, renders a ticket-switcher chip row (key, live score, status dot, ⏳blockers; `[`/`]` cycles; "close folder" exits), active ticket goes through the normal single-file pipeline (2.5s poll) while an 8s folder rescan refreshes badges/new tickets and the Team-context card (parses `### date — source` blocks; flashes on change); accepts the library root, a `tasks/` dir, or a single ticket folder; single-file mode still fully works; **remembered handle** — the file/directory handle from picker or drag-drop (`getAsFileSystemHandle`) is stored in IndexedDB (`taskpipeline`/`kv`/`handle`); on load, `queryPermission` 'granted' auto-reopens + live-follows (branching on `handle.kind`), 'prompt' shows a one-click "Resume <name>" button (`requestPermission` needs the gesture), stale/denied handles are forgotten silently — everything no-ops on browsers without the FSA API; next-action status line in the hero (rejected → must-fix count, flagged steps → Planner, step x/y → Implementer, etc.); **compose box** ("Message the agents"): prefixes the active ticket key, copies, then hands off via `vscode://GitHub.Copilot-Chat/chat?query=…` (protocol launch to the local editor, NOT a network call — clipboard is the guaranteed path, the prefill is best-effort); per-open-question **"copy for Teams" buttons in EN and LV** (clipboard; message includes ask-role, why-it-matters, best-guess — parser also extracts `**Best guess:**` and the optional `(LV)` twins; LV framing is built in, LV body used when the file provides it); live-update flash on sections whose content changed; `document.title` (⏳n / ✅ + key + score) and canvas-drawn favicon status dot; theme toggle auto→light→dark persisted in localStorage `tp-theme` (sets `data-theme` on `<html>`, which overrides the token blocks); keyboard shortcuts o=open r=refresh `[`/`]` and 1-3=switch ticket; relative "loaded Xs ago" ticker; 4-step pipeline explainer on the empty state; brief canvas confetti on transition to APPROVED (never on first load, skipped under reduced-motion).

## Scripts

- `install.sh` / `install.ps1` — run from the target project's root OR from inside the imported repo folder (then it installs into the parent): removes only our four agent files + `.github/task-helper/` + the old root dashboard, copies fresh bundle, ensures `.github/task/` + gitignore (both `.github/task/` and slashless `.github/task` — the latter covers the link), prints a quick usage tutorial, then deletes the imported repo folder itself when it sits inside the target project (`--keep-source` / `-KeepSource` skips that; a source outside the project is never touched). Scaffolds the workspace layout (`tasks/` + `team.md` from team-template.md, seeded only if missing) and migrates a v1 single `context.md` into `tasks/<KEY from its H1, else migrated>/`. Preserves task data; `--reset-task` / `-ResetTask` archives the whole `tasks/` folder to `.github/task/archive/` first. `--shared <path>` / `-Shared <path>` turns `.github/task` into a symlink (bash) / directory junction (PowerShell, no admin needed) into a OneDrive-synced SharePoint library folder — local task data is migrated in without clobbering (collisions archived to `<shared>/archive/`); re-runs are idempotent and can re-target.
- `export-txt.sh` — builds `export/` with every deliverable as `<name>.txt` for the email route.
- `setup.ps1` / `setup.sh` — receiving-side: strip `.txt`, place files, delete the setup scripts + leftover transfer files, print the same tutorial (used only on the email route; git route uses install.*).

## Working in this repo

- After editing `task-dashboard.html`: extract the `<script>` block and `node --check` it; then open it and eyeball the sample workspace (all three tickets + team card), `context-example.md` via the picker, and real workspace mode (a folder with `tasks/<KEY>/context.md` + `team.md`) — in both color schemes.
- After editing agents: keep contracts + dashboard format contract in sync; keep each body well under 30k chars.
- Sample/test data: `bundle/.github/task-helper/context-example.md` (implementing-state KIDS-1428).
- Naming is temporary-neutral (Context Getter / Planner / Implementer / Review); owners may rename display `name:` but file names are load-bearing (handoff targets + install script lists).
