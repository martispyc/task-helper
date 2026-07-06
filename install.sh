#!/usr/bin/env bash
# Install/update the Task Pipeline into the CURRENT directory.
# Run from the TARGET PROJECT ROOT:
#   bash /path/to/task-pipeline/install.sh            # refresh tooling, keep task data
#   bash /path/to/task-pipeline/install.sh --reset-task   # also archive + clear .github/task/
set -e

SRC="$(cd "$(dirname "$0")" && pwd)/bundle"
[ -d "$SRC/.github" ] || { echo "error: bundle/ not found next to install.sh"; exit 1; }
[ -d .git ] || echo "warning: no .git here — make sure you're in the target project root"

mkdir -p .github/agents .github/task-helper .github/task

# remove only OUR old files (other teams' agents untouched)
for a in context-getter planner implementer review; do
  rm -f ".github/agents/$a.agent.md"
done
rm -rf .github/task-helper && mkdir -p .github/task-helper

cp "$SRC"/.github/agents/*.agent.md .github/agents/
cp "$SRC"/.github/task-helper/*.md  .github/task-helper/
cp "$SRC"/task-dashboard.html .

if [ "${1:-}" = "--reset-task" ] && [ -f .github/task/context.md ]; then
  mkdir -p .github/task/archive
  mv .github/task/context.md ".github/task/archive/$(date +%F-%H%M)-context.md"
  echo "task data archived to .github/task/archive/"
fi

grep -qx '.github/task/' .gitignore 2>/dev/null || printf '\n.github/task/\n' >> .gitignore

echo "Task Pipeline installed/updated."
echo "  Reload VS Code -> pick 'Context Getter' in the Copilot agent picker."
