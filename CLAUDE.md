# CLAUDE.md — Task Pipeline

This repo is the source of truth for a four-agent GitHub Copilot pipeline + local dashboard used at SEB (Digital Channels) to take a Jira ticket from raw context to reviewed Angular code. This file carries the full project context so any session here can extend the system without re-explaining.

## What ships (bundle/)

`bundle/` mirrors exactly what lands in a target project:

```
bundle/
├── .github/agents/            context-getter · planner · implementer · review (.agent.md)
├── .github/task-helper/       context-template.md · framework-rules.md · context-example.md
└── task-dashboard.html        single-file, zero-network dashboard (goes to target repo root)
```

Target projects additionally get `.github/task/` (gitignored working dir) created by the install script; the agents create `context.md` inside it.

## Architecture — the pipeline

**Context Getter → Planner → Implementer → Review**, all communicating through ONE file: `.github/task/context.md`. Section ownership is strict:

| Section | Owner | Behaviour |
|---|---|---|
| `## Confidence` | Context Getter | rewritten in place after every update |
| `## Ticket` | Context Getter | updated in place |
| `## Additional info` | Context Getter | append-only, `### YYYY-MM-DD — source` blocks |
| `## Open questions` / `## Q&A` | Context Getter | Q-items move to Q&A when answered |
| `## Planning` | Planner writes; Implementer ticks step checkboxes | Planner never writes above this heading |
| `## Review` | Review | appends dated verdicts |

Different teammates own different agents. Each agent file starts with a **Contract block** (input / output / boundary) — bodies are replaceable, contracts and file names are not.

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
- Questions: `### Q-<n> ⏳ blocking — ask: <role>` / `### Q-<n> ✅ — answered by <who>, <date>` with `**Question:** / **Why it matters:** / **Best guess:** / **Answer:**`
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
- **Git:** agents never commit/push/branch/PR on their own.

## Angular specifics

Team facts live in `bundle/.github/task-helper/framework-rules.md` (projects kids-onboarding-mfe and ib-platform, per-project tsc/build/test commands run from inside the project folder, RxJS/typing/component rules). **Edit that file, not the agents**, when conventions change. Review runs those commands itself before reading any logic and halts to REJECTED on failure.

## Dashboard design system

Vercel/v0 dark: bg `#0A0A0A` with a faint blue radial top glow, cards `#111113` with 1px `#26262A` borders and 12px radius, text `#EDEDED` / muted `#A1A1AA` / faint `#63636B`; success green `#0CCE6B`, amber `#F5A623` for gaps, red `#F14C4C` for blockers, focus blue `#52A9FF`; `ui-monospace/Cascadia Mono` for meta (system stacks only — zero network). 860px single column: branded top bar (CSS-triangle logo, white primary button + ghost button), pipeline dot strip, hero card (green-tinted border via `:has` when ready) holding title + 72px weight-650 tabular score + 6px rounded gradient progress bar + pill stamp, then one card per section with pill count badges; questions/severities/verdicts as tinted pill badges. Staggered `.rv` reveals, rAF count-up, `prefers-reduced-motion` respected. Demo mode: three embedded sample states (gathering / implementing / approved) behind "view with sample data"; opening a real file exits demo.

## Scripts

- `install.sh` / `install.ps1` — run from the target project's root OR from inside the imported repo folder (then it installs into the parent): removes only our four agent files + `.github/task-helper/` + the old root dashboard, copies fresh bundle, ensures `.github/task/` + gitignore, prints a quick usage tutorial, then deletes the imported repo folder itself when it sits inside the target project (`--keep-source` / `-KeepSource` skips that; a source outside the project is never touched). Preserves task data; `--reset-task` / `-ResetTask` archives context.md to `.github/task/archive/` first.
- `export-txt.sh` — builds `export/` with every deliverable as `<name>.txt` for the email route.
- `setup.ps1` / `setup.sh` — receiving-side: strip `.txt`, place files, delete the setup scripts + leftover transfer files, print the same tutorial (used only on the email route; git route uses install.*).

## Working in this repo

- After editing `task-dashboard.html`: extract the `<script>` block and `node --check` it; then open it and eyeball all three demo states plus `context-example.md` via the picker.
- After editing agents: keep contracts + dashboard format contract in sync; keep each body well under 30k chars.
- Sample/test data: `bundle/.github/task-helper/context-example.md` (implementing-state KIDS-1428).
- Naming is temporary-neutral (Context Getter / Planner / Implementer / Review); owners may rename display `name:` but file names are load-bearing (handoff targets + install script lists).
