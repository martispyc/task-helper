# Framework rules

> Canonical, team-editable facts about our Angular environment. **Planner, Implementer, and Review must read this before working** and follow it over their general habits. Additions from agents are tagged 🟡 until a human confirms (then remove the tag).

## Projects & verification commands

Run everything from **inside the project folder — never the workspace root.**

| Project | Type check | Build | Tests |
|---|---|---|---|
| kids-onboarding-mfe | `npx tsc --noEmit` | `ng build` | `ng test --watch=false --browsers=ChromeHeadless` |
| ib-platform | `npx tsc --noEmit` | `ng build` | `npx nx test ib-platform` — or `npm run test` from within the folder |

`ng test --watch=false --browsers=ChromeHeadless` works **only** for kids-onboarding-mfe.

## Angular rules — enforced in planning, implementation, and review

- **Observables:** every subscription is cleaned up — `AsyncPipe` preferred; otherwise `takeUntil` or `DestroyRef`. A leaked subscription is a must-fix.
- **Typing:** strict everywhere; `any` is forbidden; strict null checking respected.
- **Components stay thin:** smart/dumb split; business logic and API calls live in injectable services, not components.
- **Templates:** modern control flow (`@if` / `@for`) or `*ngIf` / `*ngFor` matching the file's existing style; `track` / `trackBy` on every loop over a collection.
- **Order of definition:** interfaces/models first, then services, then components, then templates, then tests.
- **Security:** sanitize and validate inputs; nothing user-controlled reaches `innerHTML` or URLs unchecked; no secrets or personal data in logs.
- **Performance:** lazy-load routes where the pattern exists; avoid redundant subscriptions and change-detection churn.

## Adding to this file

Any convention an agent infers from the codebase gets appended here, tagged 🟡, for the team to confirm or correct.
