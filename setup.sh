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

echo "Done."
echo "  1. Reload VS Code -> pick 'Context Getter' in the Copilot agent picker."
echo "  2. Dashboard: open task-dashboard.html."
