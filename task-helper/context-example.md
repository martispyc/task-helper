# KIDS-1428 — Session timeout warning modal in onboarding

> Sample data. Open this file in the dashboard, then edit it in VS Code and watch the dashboard follow along. Delete once you've felt it.

## Confidence
OVERALL: 100/100 — READY FOR PLANNING ✅   (updated 2026-07-06)
- goal & why: 100
- done-definition: 100
- scope boundaries: 100
- code context: 100
- dependencies & environment: 100
- blocking questions: 100 — 0 open

## Ticket
As a child completing onboarding, I want a warning before my session times out, so I don't lose my progress.
Acceptance: warning modal at T-60s with countdown; Continue extends the session.

## Additional info
### 2026-07-03 — Jira comment (E. Ozola, design)
Modal uses the shared ds-modal component; countdown in brand amber. Figma: "KIDS timeout v2".
### 2026-07-04 — Teams, senior dev
Idle tracking exists twice — IdleService (legacy) and SessionActivityService. One is dead code.
### 2026-07-06 — code check
Onboarding shell verified ✅ apps/kids-onboarding-mfe/src/app/shell/onboarding-shell.component.ts. Both idle services present under core/.

## Open questions

## Q&A
### Q-1 ✅ — answered by Jira reporter, 2026-07-06
**Question:** If the session expires mid-step, do we restore that step after re-auth or restart onboarding?
**Answer:** Restore the step — progress must survive re-auth.
### Q-2 ✅ — answered by senior dev, 2026-07-06
**Question:** Which idle tracker is live in prod?
**Answer:** SessionActivityService. IdleService is dead code, slated for deletion.

## Planning
### 1 · Task summary
T-60s session-timeout warning modal in kids onboarding; Continue extends the session, mid-step expiry restores the step after re-auth.

### 3 · Implementation steps
- [x] Step 1 — Define SessionTimeoutState interface (models/session-timeout.state.ts)
- [x] Step 2 — TimeoutWarningService with countdown stream (AsyncPipe-ready)
- [x] Step 3 — Warning modal component on ds-modal
- [x] Step 4 — Hook SessionActivityService T-60s trigger in the onboarding shell
- [ ] Step 5 — Persist current step for post-re-auth restore — needs planning ⏳ (restore API unclear)
- [ ] Step 6 — Extend-session call + error path
- [ ] Step 7 — Unit tests per §5 (countdown, modal render, extend flow)

## Review
### Verdict — 2026-07-06
STATUS: REJECTED — RETURN TO IMPLEMENTER
- R1 [must-fix] timeout-warning.service.ts:41 — countdown interval never torn down on modal dismiss; use takeUntil(destroy$) per framework rules
- R2 [should-fix] warning-modal.component.html:12 — @for over actions is missing track
- R3 [nit] session-timeout.state.ts — rename remainingSecs to remainingSeconds for consistency
Verified: npx tsc --noEmit ✓ · ng build ✓ · ng test ChromeHeadless — 2 failing (countdown teardown spec)
