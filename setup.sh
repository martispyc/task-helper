#!/usr/bin/env bash
# Task Pipeline setup — run from the repo root with the transferred *.txt files present.
# First: mv setup.sh.txt setup.sh && bash setup.sh
set -e

mkdir -p .github/agents .github/task-helper .github/task

for f in *.md.txt *.html.txt; do
  [ -e "$f" ] && mv -f "$f" "${f%.txt}"
done

for f in context-getter.agent.md planner.agent.md implementer.agent.md review.agent.md; do
  [ -e "$f" ] && mv -f "$f" .github/agents/
done
for f in context-template.md framework-rules.md context-example.md; do
  [ -e "$f" ] && mv -f "$f" .github/task-helper/
done
# task-dashboard.html and README.md stay in the repo root

grep -qx '.github/task/' .gitignore 2>/dev/null || printf '\n.github/task/\n' >> .gitignore

# the transfer set has done its job — remove the setup scripts themselves
rm -f setup.sh setup.sh.txt setup.ps1 setup.ps1.txt

cat <<'TUTORIAL'

Task Pipeline installed ✅

── Quick tutorial ────────────────────────────────────────────────
 1. Reload VS Code  (Ctrl+Shift+P → "Developer: Reload Window").
 2. Open Copilot Chat → agent picker → "Context Getter".
 3. Paste your Jira ticket. Feed it chats/docs and relay its
    colleague questions until it says:  context 100/100 ✅ READY FOR PLANNING
 4. Switch agent → "Planner"      — writes the step plan under ## Planning.
 5. Switch agent → "Implementer"  — executes the steps one at a time.
 6. Switch agent → "Review"       — runs type check/build/tests itself,
    then appends an APPROVED / REJECTED verdict.
 7. Watch it live: open task-dashboard.html in Edge/Chrome and point it
    at .github/task/context.md (or click "view with sample data" first).

 Everything the agents know lives in .github/task/context.md (gitignored —
 it may hold internal ticket text, so it never leaves your machine).

 (Admins: enable the Claude Opus 4.8 model policy in Copilot settings.)
──────────────────────────────────────────────────────────────────
TUTORIAL
